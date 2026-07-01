/*
 * GeoIP 离线数据库 — 二分查找实现
 */

#include "geoip_db.h"
#define LOG_DOMAIN 0xFF00
#define LOG_TAG "GeoIpDb"
#include <hilog/log.h>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <arpa/inet.h>

static uint32_t IpStrToUint32(const char* ipStr)
{
    if (!ipStr || !ipStr[0]) return 0;
    unsigned int a, b, c, d;
    if (sscanf(ipStr, "%u.%u.%u.%u", &a, &b, &c, &d) != 4) return 0;
    return (a << 24) | (b << 16) | (c << 8) | d;
}

GeoIpResult GeoIpDb::Lookup(const unsigned char* dbData, size_t dbSize, const char* ipStr)
{
    GeoIpResult result;
    result.country[0] = '-';
    result.country[1] = '-';
    result.country[2] = '\0';
    result.errorCode = -1;

    if (!dbData || dbSize < GEOIP_RECORD_SIZE || !ipStr) {
        return result;
    }

    uint32_t targetIp = IpStrToUint32(ipStr);
    if (targetIp == 0) return result;

    size_t recordCount = dbSize / GEOIP_RECORD_SIZE;

    // 二分查找
    int32_t left = 0;
    int32_t right = (int32_t)recordCount - 1;

    while (left <= right) {
        int32_t mid = left + (right - left) / 2;
        const unsigned char* record = dbData + mid * GEOIP_RECORD_SIZE;

        uint32_t startIp;
        memcpy(&startIp, record, 4);
        startIp = ntohl(startIp);

        uint32_t endIp;
        memcpy(&endIp, record + 4, 4);
        endIp = ntohl(endIp);

        if (targetIp < startIp) {
            right = mid - 1;
        } else if (targetIp > endIp) {
            left = mid + 1;
        } else {
            // 找到！
            result.country[0] = (char)record[8];
            result.country[1] = (char)record[9];
            result.country[2] = '\0';
            result.errorCode = 0;
            return result;
        }
    }

    // 未找到
    result.errorCode = -2;
    return result;
}
