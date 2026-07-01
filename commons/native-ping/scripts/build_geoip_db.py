"""
GeoIP 离线数据库构建工具
从 db-ip.com 下载免费 IP-to-Country-Lite CSV 并生成紧凑二进制数据库

用法:
    python build_geoip_db.py

输出:
    geoip-country.dbip  → 放入 resources/rawfile/geoip-country.dbip

数据来源: https://db-ip.com (CC BY 4.0)
需要在应用中注明: "IP Geolocation by DB-IP <https://db-ip.com>"
"""

import urllib.request
import gzip
import struct
import os
import sys

CSV_URL = "https://download.db-ip.com/free/dbip-country-lite-2026-06.csv.gz"
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), "..", "..", "resources", "rawfile", "geoip-country.dbip")

def download_csv_gz(url: str) -> bytes:
    print(f"下载 {url} ...")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as resp:
        data = resp.read()
    print(f"  完成 ({len(data)} bytes)")
    return data

def parse_and_convert(data_gz: bytes) -> bytes:
    print("解压 CSV ...")
    csv_text = gzip.decompress(data_gz).decode("utf-8")
    lines = csv_text.strip().split("\n")
    print(f"  共 {len(lines)} 行")

    records = []
    for i, line in enumerate(lines):
        if not line.strip():
            continue
        parts = line.split(",")
        if len(parts) < 3:
            continue
        ip_start_str, ip_end_str = parts[0], parts[1]
        country_code = parts[2].strip()  # e.g. "CN"
        
        # IP 字符串 → uint32 (network byte order)
        try:
            ip_start = ip_to_uint32(ip_start_str)
            ip_end = ip_to_uint32(ip_end_str)
        except:
            continue
        
        # 国家代码转 bytes (2 字符, ASCII)
        cc_bytes = country_code.encode("ascii")
        if len(cc_bytes) != 2:
            cc_bytes = b"--"  # 未知
        
        records.append((ip_start, ip_end, cc_bytes))

    # 按起始 IP 排序
    records.sort(key=lambda r: r[0])
    print(f"  有效记录 {len(records)} 条")

    # 写入二进制
    out = bytearray()
    for start_ip, end_ip, cc in records:
        out.extend(struct.pack("!I", start_ip))  # 4 bytes, big-endian
        out.extend(struct.pack("!I", end_ip))    # 4 bytes, big-endian
        out.extend(cc)                           # 2 bytes
    
    return bytes(out)

def ip_to_uint32(ip_str: str) -> int:
    parts = ip_str.strip().split(".")
    if len(parts) != 4:
        raise ValueError(f"Invalid IP: {ip_str}")
    return (int(parts[0]) << 24) | (int(parts[1]) << 16) | (int(parts[2]) << 8) | int(parts[3])

def main():
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    raw = download_csv_gz(CSV_URL)
    db = parse_and_convert(raw)
    with open(OUTPUT_FILE, "wb") as f:
        f.write(db)
    mb = len(db) / (1024 * 1024)
    print(f"写入 {OUTPUT_FILE} ({mb:.1f} MB)")

if __name__ == "__main__":
    main()
