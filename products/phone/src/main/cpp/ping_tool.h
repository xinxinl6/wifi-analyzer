/*
 * Native Ping — ICMP 探测工具
 * 基于 OH_NetConn_QueryProbeResult 实现系统级 Ping
 *
 * Copyright (c) 2026 wifi-analyzer project
 */

#ifndef PINGNATIVE_PING_TOOL_H
#define PINGNATIVE_PING_TOOL_H

#include <cstdint>

// 单次 Ping 探测结果（与 ArkTS 侧接口对齐）
struct PingProbeResult {
    int32_t minRtt;      // 最小RTT (微秒)，-1 表示失败
    int32_t maxRtt;      // 最大RTT (微秒)
    int32_t avgRtt;      // 平均RTT (微秒)
    int32_t stdRtt;      // 标准差 (微秒)
    uint8_t lossRate;     // 丢包率 (%)
    int32_t errorCode;   // 错误码，0=成功，非0=失败
};

class PingNativeTool {
public:
    /**
     * 对指定地址进行 ICMP 探测
     * @param address 目标 IP 地址或域名
     * @param duration 探测持续时间（秒），建议 1（快速模式）或 3（准确模式）
     * @return 探测结果结构体
     */
    static PingProbeResult Probe(char* address, int32_t duration);
};

#endif // PINGNATIVE_PING_TOOL_H
