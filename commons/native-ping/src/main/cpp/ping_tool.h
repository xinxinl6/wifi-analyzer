/*
 * Native Ping — ICMP 探测 + Traceroute + ARP 扫描 工具
 * Probe: OH_NetConn_QueryProbeResult
 * Traceroute: POSIX socket + IP_TTL + ICMP 错误队列
 * ARP: Netlink socket (RTM_GETNEIGH) 读内核 ARP 表
 */

#ifndef PINGNATIVE_PING_TOOL_H
#define PINGNATIVE_PING_TOOL_H

#include <cstdint>
#include <cstddef>

struct PingProbeResult {
    int32_t minRtt;      // 最小RTT (微秒)，-1 表示失败
    int32_t maxRtt;      // 最大RTT (微秒)
    int32_t avgRtt;      // 平均RTT (微秒)
    int32_t stdRtt;      // 标准差 (微秒)
    uint8_t lossRate;     // 丢包率 (%)
    int32_t errorCode;   // 错误码，0=成功
};

struct TracerouteHop {
    int32_t ttl;         // TTL 跳数
    double timeMs;       // 延迟 (毫秒)，-1 表示超时
    char ip[64];         // 响应 IP 地址
    int32_t isTarget;    // 1=到达目标, 0=中间路由
};

struct TracerouteResult {
    int32_t hopCount;    // 实际跳数
    int32_t errorCode;   // 错误码
    TracerouteHop hops[64]; // 最多 64 跳
};

// ==================== ARP 扫描 ====================

// ARP 邻居状态 (ndm_state)
#define NUD_NUD     0x00   // 无
#define NUD_INCOMPLETE 0x01  // 正在解析
#define NUD_REACHABLE  0x02  // 可达
#define NUD_STALE      0x04  // 过期
#define NUD_DELAY      0x08  // 延迟检测
#define NUD_PROBE      0x10  // 正在探测
#define NUD_FAILED     0x20  // 失败
#define NUD_NOARP      0x40  // 无 ARP
#define NUD_PERMANENT  0x80  // 静态

struct ArpEntry {
    int32_t ifindex;       // 网卡索引
    int32_t state;         // NUD_* 状态位
    char ip[64];           // IPv4 地址
    char mac[64];          // MAC 地址（无则为空）
    int32_t hasMac;        // 1=有MAC, 0=无
};

struct ArpTableResult {
    int32_t entryCount;    // 条目数
    int32_t errorCode;     // 错误码，0=成功
    ArpEntry entries[256]; // 最大 256 条
};

class PingNativeTool {
public:
    static PingProbeResult Probe(char* address, int32_t duration);
    static TracerouteResult TraceRoute(const char* address, int32_t maxHops, int32_t timeoutSec);
    static ArpTableResult ReadArpTable();
};

#endif
