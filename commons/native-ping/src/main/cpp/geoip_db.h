/*
 * GeoIP 离线数据库 — 二分查找
 * 数据格式：紧凑二进制，每记录 10 bytes
 *   [4] start IP (big-endian uint32)
 *   [4] end IP   (big-endian uint32)
 *   [2] country code (ASCII, e.g. "CN")
 * 数据来源：DB-IP 免费数据库 (CC BY 4.0)
 */

#ifndef PINGNATIVE_GEOIP_DB_H
#define PINGNATIVE_GEOIP_DB_H

#include <cstdint>
#include <cstddef>

#define GEOIP_RECORD_SIZE 10

struct GeoIpResult {
    char country[4];   // 2 字母国家码 + null
    int32_t errorCode; // 0=成功
};

class GeoIpDb {
public:
    /*
     * 使用内存中的 .dbip 数据库执行 IP 归属查询
     * @param dbData   数据库文件内存指针（由 ArkTS 通过 rawfile API 读取）
     * @param dbSize   数据库大小 (bytes)
     * @param ipStr    要查询的 IP 地址字符串，如 "8.8.8.8"
     */
    static GeoIpResult Lookup(const unsigned char* dbData, size_t dbSize, const char* ipStr);
};

#endif
