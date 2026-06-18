# Native Ping — 基于 OH_NetConn_QueryProbeResult 的 ICMP 探测
# HarmonyOS API 20+ (6.0.0+)

cmake_minimum_required(VERSION 3.5.0)
project(pingnative)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH})

# 系统库依赖
set(BASE_LIBRARY
    libace_napi.z.so
    libnet_connection.so
    libhilog_ndk.z.so)

add_library(pingnative SHARED
    napi_init.cpp
    ping_tool.h
    ping_tool.cpp)

target_link_libraries(pingnative PUBLIC ${BASE_LIBRARY})
