"""使用 Upstage Document Parse API 批量识别视频帧文字"""
import os
import json
import sys
import traceback
import requests

frames_dir = r"c:\Users\xinxin\wifi-analyzer\frames"
output_file = r"c:\Users\xinxin\wifi-analyzer\ocr_results.txt"

try:
    # 读取 API Key
    config_path = os.path.expanduser("~/.openclaw/openclaw.json")
    api_key = None
    if os.path.exists(config_path):
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
            api_key = config.get("skills", {}).get("entries", {}).get(
                "upstage-document-parse", {}).get("apiKey")

    if not api_key:
        api_key = os.environ.get("UPSTAGE_API_KEY")

    if not api_key:
        print("ERROR: No Upstage API key found")
        exit(1)

    print(f"API Key found: {api_key[:8]}...")

    frames = sorted([f for f in os.listdir(frames_dir) if f.endswith(".png")])
    print(f"Found {len(frames)} frames")

    results = []
    for filename in frames:
        frame_path = os.path.join(frames_dir, filename)
        print(f"Processing: {filename}")

        with open(frame_path, "rb") as f:
            files = {"document": (filename, f, "image/png")}
            data = {
                "model": "document-parse",
                "output_formats": "['text']",
                "ocr": "force",
            }
            headers = {"Authorization": f"Bearer {api_key}"}
            resp = requests.post(
                "https://api.upstage.ai/v1/document-digitization",
                headers=headers,
                files=files,
                data=data,
                timeout=30,
            )

        print(f"  Status: {resp.status_code}")
        if resp.status_code == 200:
            result = resp.json()
            text = result.get("content", {}).get("text", "").strip()
            print(f"  -> {len(text)} chars")
            results.append(f"=== {filename} ===\n{text}\n")
        else:
            print(f"  -> ERROR: {resp.text[:200]}")
            results.append(f"=== {filename} ===\n[OCR FAILED: {resp.status_code}]\n")

    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(results))
    print(f"\nDone. Results saved to: {output_file}")

except Exception as e:
    print(f"ERROR: {e}")
    traceback.print_exc()
    sys.exit(1)
