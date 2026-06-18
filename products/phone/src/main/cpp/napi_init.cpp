/*
 * Native Ping — NAPI 绑定层
 * 暴露 nativeProbe(address, duration) 给 ArkTS 侧调用
 *
 * Copyright (c) 2026 wifi-analyzer project
 */

#include "napi/native_api.h"
#include "ping_tool.h"
#include <cstdint>
#include <cstring>
#include <sstream>
#include <string>

#include <hilog/log.h>

#define LOG_DOMAIN 0xFF00
#define LOG_TAG "NativePingNAPI"

// 异步任务回调数据
struct ProbeCallbackData {
    napi_async_work asyncWork = nullptr;
    napi_deferred deferred = nullptr;
    char* argAddress = nullptr;
    int32_t argDuration = 1;   // 默认快速模式 1 秒
    char* result = nullptr;
};

// 释放回调数据内存
static void ReleaseProbeCallbackData(ProbeCallbackData* callbackData)
{
    if (callbackData->argAddress != nullptr) {
        delete[] callbackData->argAddress;
        callbackData->argAddress = nullptr;
    }
    callbackData->deferred = nullptr;
    callbackData->asyncWork = nullptr;

    if (callbackData->result != nullptr) {
        delete[] callbackData->result;
        callbackData->result = nullptr;
    }

    delete callbackData;
}

/**
 * 异步执行回调 — 在工作线程中调用 C++ Ping 探测
 */
static void ProbeExecuteCB(napi_env env, void* data)
{
    ProbeCallbackData* callbackData = reinterpret_cast<ProbeCallbackData*>(data);

    // 调用 Native 工具类执行 ICMP 探测
    PingProbeResult probeResult = PingNativeTool::Probe(
        callbackData->argAddress, callbackData->argDuration);

    // 构建返回 JSON 字符串（与 ArkTS 侧接口对齐）
    std::ostringstream oss;
    oss << "{";
    oss << "\"minRtt\":" << probeResult.minRtt << ",";
    oss << "\"maxRtt\":" << probeResult.maxRtt << ",";
    oss << "\"avgRtt\":" << probeResult.avgRtt << ",";
    oss << "\"stdRtt\":" << probeResult.stdRtt << ",";
    oss << "\"lossRate\":" << static_cast<int>(probeResult.lossRate) << ",";
    oss << "\"error\":" << probeResult.errorCode;
    oss << "}";

    std::string str = oss.str();
    char* jsonStr = new char[str.size() + 1];
    str.copy(jsonStr, str.size(), 0);
    jsonStr[str.size()] = '\0';

    callbackData->result = jsonStr;
}

/**
 * 异步完成回调 — 将结果 resolve/reject 回 ArkTS
 */
static void ProbeCompleteCB(napi_env env, napi_status status, void* data)
{
    ProbeCallbackData* callbackData = reinterpret_cast<ProbeCallbackData*>(data);

    napi_value resultValue = nullptr;
    napi_status createStatus = napi_create_string_utf8(env, callbackData->result,
                                                         NAPI_AUTO_LENGTH, &resultValue);

    if (createStatus != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "napi_create_string_utf8 failed");
        napi_value errVal = nullptr;
        napi_create_string_utf8(env, "failed: result build error",
                                 NAPI_AUTO_LENGTH, &errVal);
        napi_reject_deferred(env, callbackData->deferred, errVal);
    } else {
        if (callbackData->result == nullptr ||
            (strcmp(callbackData->result, "") == 0)) {
            napi_reject_deferred(env, callbackData->deferred, resultValue);
        } else {
            napi_resolve_deferred(env, callbackData->deferred, resultValue);
        }
    }

    // 清理异步工作对象
    napi_delete_async_work(env, callbackData->asyncWork);
    ReleaseProbeCallbackData(callbackData);
}

/**
 * 主入口：nativeProbe(address, duration)
 * @param address string — 目标 IP 或域名
 * @param duration number — 探测持续时间（秒）
 * @return Promise<string> — JSON 格式的探测结果
 */
static napi_value NativeProbe(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 参数1：地址字符串
    napi_valuetype addrType;
    napi_typeof(env, args[0], &addrType);
    if (addrType != napi_string || argc < 1) {
        napi_throw_type_error(env, nullptr,
                              "First argument must be a string (IP or domain)");
        return nullptr;
    }

    // 参数2：探测持续时间（秒），可选，默认为 1
    int32_t duration = 1;
    if (argc >= 2) {
        napi_valuetype durType;
        napi_typeof(env, args[1], &durType);
        if (durType == napi_number) {
            napi_get_value_int32(env, args[1], &duration);
        }
    }

    // 读取地址字符串
    size_t strLen = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &strLen);
    char* buffer = new char[strLen + 1];
    size_t realLen = 0;
    napi_get_value_string_utf8(env, args[0], buffer, strLen + 1, &realLen);

    // 创建 Promise
    napi_value promiseValue = nullptr;
    napi_deferred deferred = nullptr;
    napi_create_promise(env, &deferred, &promiseValue);

    // 准备异步工作数据
    auto callbackData = new ProbeCallbackData();
    callbackData->deferred = deferred;
    callbackData->argAddress = buffer;
    callbackData->argDuration = duration;

    // 创建资源名称
    napi_value resourceName = nullptr;
    napi_create_string_utf8(env, "PingNativeProbe", NAPI_AUTO_LENGTH, &resourceName);

    // 创建并排队异步工作
    napi_create_async_work(env, nullptr, resourceName,
                           ProbeExecuteCB, ProbeCompleteCB, callbackData,
                           &(callbackData->asyncWork));

    if (napi_queue_async_work(env, callbackData->asyncWork) != napi_ok) {
        ReleaseProbeCallbackData(callbackData);
        napi_delete_async_work(env, callbackData->asyncWork);
        napi_throw_error(env, nullptr, "Failed to enqueue async work");
        return nullptr;
    }

    return promiseValue;
}

// ==================== 模块注册 ====================

EXTERN_C_START

static napi_value Init(napi_env env, napi_value exports)
{
    // 注册 nativeProbe 方法给 ArkTS 调用
    napi_property_descriptor desc[] = {
        {"nativeProbe", nullptr, NativeProbe, nullptr, nullptr, nullptr,
         napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

EXTERN_C_END

// 模块定义：模块名必须与 ArkTS import 的名称匹配
static napi_module pingnativeModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "pingnative",     // ← 对应 ArkTS: import pingnative from 'libpingnative.so'
    .nm_priv = ((void*)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterPingNativeModule(void) {
    napi_module_register(&pingnativeModule);
}
