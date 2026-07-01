/*
 * Native Ping — NAPI 绑定层
 * 导出: nativeProbe(address, duration) + nativeTraceRoute(address, maxHops, timeout) + nativeReadArpTable()
 */

#include "napi/native_api.h"
#include "ping_tool.h"
#include "geoip_db.h"
#include <cstdint>
#include <cstring>
#include <sstream>
#include <string>

#include <hilog/log.h>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0xFF00
#define LOG_TAG "NativePingNAPI"

// ==================== Probe（Ping）====================

struct ProbeCallbackData {
    napi_async_work asyncWork = nullptr;
    napi_deferred deferred = nullptr;
    char* argAddress = nullptr;
    int32_t argDuration = 1;
    char* result = nullptr;
};

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

static void ProbeExecuteCB(napi_env env, void* data)
{
    ProbeCallbackData* callbackData = reinterpret_cast<ProbeCallbackData*>(data);
    PingProbeResult probeResult = PingNativeTool::Probe(
        callbackData->argAddress, callbackData->argDuration);

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

static void ProbeCompleteCB(napi_env env, napi_status status, void* data)
{
    ProbeCallbackData* callbackData = reinterpret_cast<ProbeCallbackData*>(data);
    napi_value resultValue = nullptr;
    napi_status createStatus = napi_create_string_utf8(env, callbackData->result,
                                                         NAPI_AUTO_LENGTH, &resultValue);
    if (createStatus != napi_ok) {
        napi_value errVal = nullptr;
        napi_create_string_utf8(env, "failed: result build error",
                                 NAPI_AUTO_LENGTH, &errVal);
        napi_reject_deferred(env, callbackData->deferred, errVal);
    } else {
        napi_resolve_deferred(env, callbackData->deferred, resultValue);
    }
    napi_delete_async_work(env, callbackData->asyncWork);
    ReleaseProbeCallbackData(callbackData);
}

static napi_value NativeProbe(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2] = {nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype addrType;
    napi_typeof(env, args[0], &addrType);
    if (addrType != napi_string || argc < 1) {
        napi_throw_type_error(env, nullptr, "First argument must be a string");
        return nullptr;
    }

    int32_t duration = 1;
    if (argc >= 2) {
        napi_valuetype durType;
        napi_typeof(env, args[1], &durType);
        if (durType == napi_number) {
            napi_get_value_int32(env, args[1], &duration);
        }
    }

    size_t strLen = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &strLen);
    char* buffer = new char[strLen + 1];
    size_t realLen = 0;
    napi_get_value_string_utf8(env, args[0], buffer, strLen + 1, &realLen);

    napi_value promiseValue = nullptr;
    napi_deferred deferred = nullptr;
    napi_create_promise(env, &deferred, &promiseValue);

    auto callbackData = new ProbeCallbackData();
    callbackData->deferred = deferred;
    callbackData->argAddress = buffer;
    callbackData->argDuration = duration;

    napi_value resourceName = nullptr;
    napi_create_string_utf8(env, "PingNativeProbe", NAPI_AUTO_LENGTH, &resourceName);
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

// ==================== TraceRoute =====================

struct TraceCallbackData {
    napi_async_work asyncWork = nullptr;
    napi_deferred deferred = nullptr;
    char* argAddress = nullptr;
    int32_t argMaxHops = 30;
    int32_t argTimeout = 2;
    char* result = nullptr;
};

static void ReleaseTraceCallbackData(TraceCallbackData* callbackData)
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

static void TraceExecuteCB(napi_env env, void* data)
{
    TraceCallbackData* callbackData = reinterpret_cast<TraceCallbackData*>(data);
    TracerouteResult traceResult = PingNativeTool::TraceRoute(
        callbackData->argAddress, callbackData->argMaxHops, callbackData->argTimeout);

    std::ostringstream oss;
    oss << "{";
    oss << "\"error\":" << traceResult.errorCode << ",";
    oss << "\"hopCount\":" << traceResult.hopCount << ",";
    oss << "\"hops\":[";
    for (int i = 0; i < traceResult.hopCount; i++) {
        if (i > 0) oss << ",";
        oss << "{";
        oss << "\"ttl\":" << traceResult.hops[i].ttl << ",";
        oss << "\"timeMs\":" << traceResult.hops[i].timeMs << ",";
        oss << "\"ip\":\"" << traceResult.hops[i].ip << "\",";
        oss << "\"isTarget\":" << traceResult.hops[i].isTarget;
        oss << "}";
    }
    oss << "]}";

    std::string str = oss.str();
    char* jsonStr = new char[str.size() + 1];
    str.copy(jsonStr, str.size(), 0);
    jsonStr[str.size()] = '\0';
    callbackData->result = jsonStr;
}

static void TraceCompleteCB(napi_env env, napi_status status, void* data)
{
    TraceCallbackData* callbackData = reinterpret_cast<TraceCallbackData*>(data);
    napi_value resultValue = nullptr;
    napi_status createStatus = napi_create_string_utf8(env, callbackData->result,
                                                         NAPI_AUTO_LENGTH, &resultValue);
    if (createStatus != napi_ok) {
        napi_value errVal = nullptr;
        napi_create_string_utf8(env, "traceroute result build error",
                                 NAPI_AUTO_LENGTH, &errVal);
        napi_reject_deferred(env, callbackData->deferred, errVal);
    } else {
        napi_resolve_deferred(env, callbackData->deferred, resultValue);
    }
    napi_delete_async_work(env, callbackData->asyncWork);
    ReleaseTraceCallbackData(callbackData);
}

static napi_value NativeTraceRoute(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype addrType;
    napi_typeof(env, args[0], &addrType);
    if (addrType != napi_string || argc < 1) {
        napi_throw_type_error(env, nullptr, "First argument must be a string");
        return nullptr;
    }

    int32_t maxHops = 30;
    if (argc >= 2) {
        napi_valuetype hopsType;
        napi_typeof(env, args[1], &hopsType);
        if (hopsType == napi_number) {
            napi_get_value_int32(env, args[1], &maxHops);
        }
    }

    int32_t timeoutSec = 2;
    if (argc >= 3) {
        napi_valuetype toType;
        napi_typeof(env, args[2], &toType);
        if (toType == napi_number) {
            napi_get_value_int32(env, args[2], &timeoutSec);
        }
    }

    size_t strLen = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &strLen);
    char* buffer = new char[strLen + 1];
    size_t realLen = 0;
    napi_get_value_string_utf8(env, args[0], buffer, strLen + 1, &realLen);

    napi_value promiseValue = nullptr;
    napi_deferred deferred = nullptr;
    napi_create_promise(env, &deferred, &promiseValue);

    auto callbackData = new TraceCallbackData();
    callbackData->deferred = deferred;
    callbackData->argAddress = buffer;
    callbackData->argMaxHops = maxHops;
    callbackData->argTimeout = timeoutSec;

    napi_value resourceName = nullptr;
    napi_create_string_utf8(env, "NativeTraceRoute", NAPI_AUTO_LENGTH, &resourceName);
    napi_create_async_work(env, nullptr, resourceName,
                           TraceExecuteCB, TraceCompleteCB, callbackData,
                           &(callbackData->asyncWork));
    if (napi_queue_async_work(env, callbackData->asyncWork) != napi_ok) {
        ReleaseTraceCallbackData(callbackData);
        napi_delete_async_work(env, callbackData->asyncWork);
        napi_throw_error(env, nullptr, "Failed to enqueue traceroute async work");
        return nullptr;
    }
    return promiseValue;
}

// ==================== ARP（ReadArpTable）=====================

struct ArpCallbackData {
    napi_async_work asyncWork = nullptr;
    napi_deferred deferred = nullptr;
    char* result = nullptr;
};

static void ReleaseArpCallbackData(ArpCallbackData* data)
{
    data->deferred = nullptr;
    data->asyncWork = nullptr;
    if (data->result != nullptr) {
        delete[] data->result;
        data->result = nullptr;
    }
    delete data;
}

static void ArpExecuteCB(napi_env env, void* data)
{
    ArpCallbackData* cbData = reinterpret_cast<ArpCallbackData*>(data);
    ArpTableResult arpResult = PingNativeTool::ReadArpTable();

    std::ostringstream oss;
    oss << "{";
    oss << "\"error\":" << arpResult.errorCode << ",";
    oss << "\"entryCount\":" << arpResult.entryCount << ",";
    oss << "\"entries\":[";
    for (int i = 0; i < arpResult.entryCount; i++) {
        if (i > 0) oss << ",";
        oss << "{";
        oss << "\"ifindex\":" << arpResult.entries[i].ifindex << ",";
        oss << "\"state\":" << arpResult.entries[i].state << ",";
        oss << "\"ip\":\"" << arpResult.entries[i].ip << "\",";
        oss << "\"mac\":\"" << arpResult.entries[i].mac << "\",";
        oss << "\"hasMac\":" << arpResult.entries[i].hasMac;
        oss << "}";
    }
    oss << "]}";

    std::string str = oss.str();
    char* jsonStr = new char[str.size() + 1];
    str.copy(jsonStr, str.size(), 0);
    jsonStr[str.size()] = '\0';
    cbData->result = jsonStr;
}

static void ArpCompleteCB(napi_env env, napi_status status, void* data)
{
    ArpCallbackData* cbData = reinterpret_cast<ArpCallbackData*>(data);
    napi_value resultValue = nullptr;
    napi_status createStatus = napi_create_string_utf8(env, cbData->result,
                                                         NAPI_AUTO_LENGTH, &resultValue);
    if (createStatus != napi_ok) {
        napi_value errVal = nullptr;
        napi_create_string_utf8(env, "ARP result build error", NAPI_AUTO_LENGTH, &errVal);
        napi_reject_deferred(env, cbData->deferred, errVal);
    } else {
        napi_resolve_deferred(env, cbData->deferred, resultValue);
    }
    napi_delete_async_work(env, cbData->asyncWork);
    ReleaseArpCallbackData(cbData);
}

static napi_value NativeReadArpTable(napi_env env, napi_callback_info info)
{
    napi_value promiseValue = nullptr;
    napi_deferred deferred = nullptr;
    napi_create_promise(env, &deferred, &promiseValue);

    auto cbData = new ArpCallbackData();
    cbData->deferred = deferred;

    napi_value resourceName = nullptr;
    napi_create_string_utf8(env, "NativeReadArpTable", NAPI_AUTO_LENGTH, &resourceName);
    napi_create_async_work(env, nullptr, resourceName,
                           ArpExecuteCB, ArpCompleteCB, cbData,
                           &(cbData->asyncWork));
    if (napi_queue_async_work(env, cbData->asyncWork) != napi_ok) {
        ReleaseArpCallbackData(cbData);
        napi_delete_async_work(env, cbData->asyncWork);
        napi_throw_error(env, nullptr, "Failed to enqueue ARP async work");
        return nullptr;
    }
    return promiseValue;
}

// ==================== GeoIP（离线查询）====================

static napi_value NativeGeoIpLookup(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // args[0]: dbArrayBuffer, args[1]: dbSize, args[2]: ipString
    if (argc < 3) {
        napi_throw_type_error(env, nullptr, "requires 3 args: buffer, size, ip");
        return nullptr;
    }

    // 获取 ArrayBuffer 数据指针
    void* bufData = nullptr;
    size_t bufSize = 0;
    napi_get_arraybuffer_info(env, args[0], &bufData, &bufSize);

    // 获取 IP 字符串
    size_t ipLen = 0;
    napi_get_value_string_utf8(env, args[2], nullptr, 0, &ipLen);
    char* ipStr = new char[ipLen + 1];
    size_t realLen = 0;
    napi_get_value_string_utf8(env, args[2], ipStr, ipLen + 1, &realLen);

    // 执行查询
    GeoIpResult geoResult = GeoIpDb::Lookup(
        (const unsigned char*)bufData, bufSize, ipStr);
    delete[] ipStr;

    // 构建 JSON 结果
    std::string json = "{\"country\":\"";
    json += geoResult.country[0] ? geoResult.country : "--";
    json += "\",\"error\":";
    json += std::to_string(geoResult.errorCode);
    json += "}";

    napi_value resultValue = nullptr;
    napi_create_string_utf8(env, json.c_str(), NAPI_AUTO_LENGTH, &resultValue);
    return resultValue;
}

// ==================== 模块注册 ====================

EXTERN_C_START

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        {"nativeProbe", nullptr, NativeProbe, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeTraceRoute", nullptr, NativeTraceRoute, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeReadArpTable", nullptr, NativeReadArpTable, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeGeoIpLookup", nullptr, NativeGeoIpLookup, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

EXTERN_C_END

static napi_module pingnativeModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "pingnative",
    .nm_priv = ((void*)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterPingNativeModule(void) {
    napi_module_register(&pingnativeModule);
}
