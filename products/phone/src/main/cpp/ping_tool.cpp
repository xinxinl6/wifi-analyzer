/*
 * Native Ping — ICMP 探测实现
 * 调用 OH_NetConn_QueryProbeResult 执行系统级 ICMP 探测
 *
 * Copyright (c) 2026 wifi-analyzer project
 */

#include "ping_tool.h"
#define LOG_DOMAIN 0xFF00
#define LOG_TAG "NativePing"

// HarmonyOS 网络连接模块头文件（系统 NDK 提供）
#include "network/netmanager/net_connection.h"
#include <hilog/log.h>

PingProbeResult PingNativeTool::Probe(char* address, int32_t duration)
{
    // 初始化默认值（全部失败状态）
    PingProbeResult result;
    result.minRtt = -1;
    result.maxRtt = 0;
    result.avgRtt = 0;
    result.stdRtt = 0;
    result.lossRate = 100;     // 默认全丢包
    result.errorCode = 0;

    if (!address) {
        result.errorCode = -1;   // 无效参数
        return result;
    }

    // 构建探测结果结构体并调用系统 API
    NetConn_ProbeResultInfo probeInfo;
    probeInfo.lossRate = 0;
    probeInfo.rtt[0] = 0;
    probeInfo.rtt[1] = 0;
    probeInfo.rtt[2] = 0;
    probeInfo.rtt[3] = 0;

    int32_t ret = OH_NetConn_QueryProbeResult(address, duration, &probeInfo);

    if (ret != 0) {
        OH_LOG_ERROR(LOG_APP, "OH_NetConn_QueryProbeResult error: ret=%{public}d, addr=%{public}s",
                     ret, address);
        result.errorCode = ret;
        return result;
    }

    // 成功：解析探测结果
    result.lossRate = probeInfo.lossRate;
    result.minRtt = static_cast<int32_t>(probeInfo.rtt[0]);   // 最小延迟(μs)
    result.maxRtt = static_cast<int32_t>(probeInfo.rtt[1]);   // 最大延迟(μs)
    result.avgRtt = static_cast<int32_t>(probeInfo.rtt[2]);   // 平均延迟(μs)
    result.stdRtt = static_cast<int32_t>(probeInfo.rtt[3]);   // 标准差(μs)

    OH_LOG_INFO(LOG_APP,
                "PingNative Probe: addr=%{public}s dur=%{public}d loss=%{public}d "
                "min=%{public}u max=%{public}u avg=%{public}u std=%{public}u",
                address, duration, probeInfo.lossRate,
                probeInfo.rtt[0], probeInfo.rtt[1], probeInfo.rtt[2], probeInfo.rtt[3]);

    return result;
}
