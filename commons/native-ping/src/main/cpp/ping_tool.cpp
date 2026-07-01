/*
 * Native Ping — ICMP 探测 + Traceroute 实现
 * Probe: 调用 OH_NetConn_QueryProbeResult
 * Traceroute: POSIX socket + IP_TTL + ICMP 错误队列
 *    不再使用 popen（HarmonyOS 沙箱限制）
 *
 * 策略（按优先级）：
 *   1. UDP socket + IP_RECVERR 获取路由器 ICMP 响应+IP
 *   2. Raw ICMP socket 备用接收（需 CAP_NET_RAW）
 *   3. TCP connect + IP_TTL 仅检测目标可达性（无中间路由 IP）
 *   以上均失败 → 返回空结果，由 ArkTS 层 TCP 回退
 */

#include "ping_tool.h"

#include "network/netmanager/net_connection.h"
#include <hilog/log.h>

#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <string>
#include <cerrno>

#include <sys/socket.h>
#include <poll.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0xFF00
#define LOG_TAG "NativePing"

#define TRACE_BASE_PORT 33434

// ========== 兼容性定义（HarmonyOS 可能缺失 Linux errqueue 头）==========
#ifndef SO_EE_ORIGIN_ICMP
#define SO_EE_ORIGIN_ICMP 2
struct sock_extended_err {
    uint32_t ee_errno;
    uint8_t  ee_origin;
    uint8_t  ee_type;
    uint8_t  ee_code;
    uint8_t  ee_pad;
    uint32_t ee_info;
    uint32_t ee_data;
};
#endif
#ifndef IP_RECVERR
#define IP_RECVERR 11
#endif

PingProbeResult PingNativeTool::Probe(char* address, int32_t duration)
{
    PingProbeResult result;
    result.minRtt = -1;
    result.maxRtt = 0;
    result.avgRtt = 0;
    result.stdRtt = 0;
    result.lossRate = 100;
    result.errorCode = 0;

    if (!address) {
        result.errorCode = -1;
        return result;
    }

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

    result.lossRate = probeInfo.lossRate;
    result.minRtt = static_cast<int32_t>(probeInfo.rtt[0]);
    result.maxRtt = static_cast<int32_t>(probeInfo.rtt[1]);
    result.avgRtt = static_cast<int32_t>(probeInfo.rtt[2]);
    result.stdRtt = static_cast<int32_t>(probeInfo.rtt[3]);

    OH_LOG_INFO(LOG_APP,
                "PingNative Probe: addr=%{public}s dur=%{public}d loss=%{public}d "
                "min=%{public}u max=%{public}u avg=%{public}u std=%{public}u",
                address, duration, probeInfo.lossRate,
                probeInfo.rtt[0], probeInfo.rtt[1], probeInfo.rtt[2], probeInfo.rtt[3]);

    return result;
}

// ==================== 辅助函数 ====================

static int64_t GetCurrentTimeMs()
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000 + (int64_t)(ts.tv_nsec / 1000000);
}

static bool ResolveHostToSockaddr(const char* host, struct sockaddr_in* out)
{
    struct addrinfo hints, *res = nullptr;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_DGRAM;
    int err = getaddrinfo(host, nullptr, &hints, &res);
    if (err != 0 || !res) {
        OH_LOG_ERROR(LOG_APP, "TraceRoute DNS resolve failed: %{public}s, err=%{public}d",
                     host, err);
        return false;
    }
    memcpy(out, res->ai_addr, sizeof(struct sockaddr_in));
    freeaddrinfo(res);
    return true;
}

// 尝试从 MSG_ERRQUEUE 提取路由器 IP 和到达状态
static bool ExtractFromErrQueue(int fd, char* outIp, size_t ipSize, bool* outIsTarget)
{
    char cbuf[512];
    struct iovec iov;
    struct msghdr msg;
    char dataBuf[64];

    memset(&msg, 0, sizeof(msg));
    iov.iov_base = dataBuf;
    iov.iov_len = sizeof(dataBuf);
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = cbuf;
    msg.msg_controllen = sizeof(cbuf);

    ssize_t n = recvmsg(fd, &msg, MSG_ERRQUEUE);
    if (n < 0) return false;

    for (struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
         cmsg; cmsg = CMSG_NXTHDR(&msg, cmsg)) {
        if (cmsg->cmsg_level == SOL_IP) {
            struct sock_extended_err* ee =
                (struct sock_extended_err*)CMSG_DATA(cmsg);
            struct sockaddr_in* sin =
                (struct sockaddr_in*)((char*)ee + sizeof(struct sock_extended_err));

            if (sin->sin_family == AF_INET) {
                inet_ntop(AF_INET, &sin->sin_addr, outIp, (socklen_t)ipSize);
            }

            // ICMP Port Unreachable = 到达目标
            // ICMP Time Exceeded = 中间路由
            if (ee->ee_type == ICMP_UNREACH && ee->ee_code == ICMP_UNREACH_PORT) {
                if (outIsTarget) *outIsTarget = true;
            }
            return true;
        }
    }
    return false;
}

// ==================== Traceroute 核心 ====================

TracerouteResult PingNativeTool::TraceRoute(const char* address,
                                            int32_t maxHops,
                                            int32_t timeoutSec)
{
    TracerouteResult result;
    result.hopCount = 0;
    result.errorCode = 0;

    if (!address || !address[0]) {
        result.errorCode = -1;
        return result;
    }

    // 1. 解析目标地址
    struct sockaddr_in targetAddr;
    if (!ResolveHostToSockaddr(address, &targetAddr)) {
        result.errorCode = -4; // DNS 解析失败
        return result;
    }
    char targetIpStr[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &targetAddr.sin_addr, targetIpStr, sizeof(targetIpStr));
    OH_LOG_INFO(LOG_APP, "TraceRoute target=%{public}s resolved=%{public}s",
                address, targetIpStr);

    // 2. 创建 UDP 套接字
    int udpSock = socket(AF_INET, SOCK_DGRAM, 0);
    if (udpSock < 0) {
        OH_LOG_ERROR(LOG_APP, "TraceRoute socket() failed: %{public}d", errno);
        result.errorCode = -5;
        return result;
    }

    // 3. 尝试启用 IP_RECVERR (非阻塞错误队列)
    int recverrOn = 1;
    bool hasRecverr = (setsockopt(udpSock, SOL_IP, IP_RECVERR,
                                  &recverrOn, sizeof(recverrOn)) == 0);
    OH_LOG_INFO(LOG_APP, "TraceRoute IP_RECVERR=%{public}s",
                hasRecverr ? "ok" : "not supported");

    // 4. 尝试创建原始 ICMP 套接字（备用）
    int icmpSock = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
    if (icmpSock >= 0) {
        struct timeval tv;
        tv.tv_sec = 0;  // 非阻塞
        tv.tv_usec = 0;
        setsockopt(icmpSock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    } else {
        OH_LOG_WARN(LOG_APP, "TraceRoute raw ICMP socket failed: %{public}d", errno);
    }

    // 设置 UDP 非阻塞（用于 poll + MSG_ERRQUEUE）
    int fl = fcntl(udpSock, F_GETFL, 0);
    fcntl(udpSock, F_SETFL, fl | O_NONBLOCK);

    int timeoutMs = timeoutSec * 1000;

    // 5. 逐跳探测
    for (int32_t ttl = 1; ttl <= maxHops && ttl <= 64; ttl++) {
        // 5a. 清空残留错误队列
        if (hasRecverr) {
            char dummy[256];
            struct sockaddr_in da;
            socklen_t dl = sizeof(da);
            while (recvfrom(udpSock, dummy, sizeof(dummy),
                            MSG_ERRQUEUE, (struct sockaddr*)&da, &dl) > 0) {}
        }

        // 5b. 设置 TTL
        int ttlVal = ttl;
        setsockopt(udpSock, IPPROTO_IP, IP_TTL, &ttlVal, sizeof(ttlVal));

        // 5c. 设置目标端口（递增）
        targetAddr.sin_port = htons((uint16_t)(TRACE_BASE_PORT + ttl));

        // 5d. 发送 UDP 探测包
        int64_t sendTime = GetCurrentTimeMs();
        const char probeChar = 'T';
        bool sendOk = (sendto(udpSock, &probeChar, 1, 0,
                              (struct sockaddr*)&targetAddr,
                              sizeof(targetAddr)) >= 0);
        if (!sendOk) {
            OH_LOG_ERROR(LOG_APP, "TraceRoute sendto ttl=%{public}d failed: %{public}d",
                         ttl, errno);
            TracerouteHop hop;
            hop.ttl = ttl;
            hop.timeMs = -1.0;
            hop.isTarget = 0;
            snprintf(hop.ip, sizeof(hop.ip), "*");
            result.hops[result.hopCount++] = hop;
            continue;
        }

        // 5e. 用 poll 等待响应
        bool hopDone = false;
        bool isTarget = false;
        char hopIp[64] = "*";
        double rttMs = -1.0;
        int remainingMs = timeoutMs;

        while (remainingMs > 0 && !hopDone) {
            struct pollfd pfd[2];
            int nfds = 0;

            pfd[nfds].fd = udpSock;
            pfd[nfds].events = POLLIN;
            nfds++;

            if (icmpSock >= 0) {
                pfd[nfds].fd = icmpSock;
                pfd[nfds].events = POLLIN;
                nfds++;
            }

            int waitMs = (remainingMs < 200) ? remainingMs : 200;
            int pollRet = poll(pfd, (nfds_t)nfds, waitMs);

            if (pollRet <= 0) {
                if (pollRet < 0 && errno == EINTR) continue;
                remainingMs -= waitMs;
                continue;
            }

            int64_t now = GetCurrentTimeMs();
            rttMs = (double)(now - sendTime);

            // 策略 A: IP_RECVERR 错误队列（推荐）
            if (hasRecverr && (pfd[0].revents & POLLIN)) {
                if (ExtractFromErrQueue(udpSock, hopIp, sizeof(hopIp), &isTarget)) {
                    hopDone = true;
                    continue;
                }
                // 错误队列无数据 → 尝试普通 recvfrom
                char buf[64];
                struct sockaddr_in from;
                socklen_t flen = sizeof(from);
                ssize_t nn = recvfrom(udpSock, buf, sizeof(buf), 0,
                                      (struct sockaddr*)&from, &flen);
                if (nn > 0) {
                    inet_ntop(AF_INET, &from.sin_addr, hopIp, sizeof(hopIp));
                    if (from.sin_addr.s_addr == targetAddr.sin_addr.s_addr) {
                        isTarget = true;
                    }
                    hopDone = true;
                    continue;
                }
            }

            // 策略 B: 原始 ICMP 套接字
            if (icmpSock >= 0 && !hopDone && (pfd[1].revents & POLLIN)) {
                char icmpBuf[1500];
                struct sockaddr_in from;
                socklen_t fromLen = sizeof(from);
                ssize_t nn = recvfrom(icmpSock, icmpBuf, sizeof(icmpBuf), 0,
                                      (struct sockaddr*)&from, &fromLen);
                if (nn >= (ssize_t)sizeof(struct icmphdr)) {
                    struct icmphdr* icmp = (struct icmphdr*)icmpBuf;
                    if (icmp->type == ICMP_TIME_EXCEEDED) {
                        inet_ntop(AF_INET, &from.sin_addr, hopIp, sizeof(hopIp));
                        hopDone = true;
                    } else if (icmp->type == ICMP_DEST_UNREACH &&
                               icmp->code == ICMP_UNREACH_PORT) {
                        inet_ntop(AF_INET, &from.sin_addr, hopIp, sizeof(hopIp));
                        if (from.sin_addr.s_addr == targetAddr.sin_addr.s_addr) {
                            isTarget = true;
                        }
                        hopDone = true;
                    }
                }
            }

            if (!hopDone) {
                remainingMs -= waitMs;
            }
        }

        // 5f. 记录本跳结果
        TracerouteHop hop;
        hop.ttl = ttl;
        hop.timeMs = rttMs;
        hop.isTarget = isTarget ? 1 : 0;
        snprintf(hop.ip, sizeof(hop.ip), "%s", hopIp);
        result.hops[result.hopCount++] = hop;

        OH_LOG_INFO(LOG_APP,
                    "TraceRoute ttl=%{public}d ip=%{public}s rtt=%.1fms target=%{public}d",
                    ttl, hopIp, rttMs, hop.isTarget);

        if (isTarget) break;

        // 5g. 连续 3 跳无响应提前终止
        if (result.hopCount >= 3) {
            bool allStar = true;
            for (int i = result.hopCount - 3; i < result.hopCount; i++) {
                if (result.hops[i].ip[0] != '*') { allStar = false; break; }
            }
            if (allStar) {
                OH_LOG_INFO(LOG_APP, "TraceRoute 3 consecutive timeouts, stopping");
                break;
            }
        }
    }

    close(udpSock);
    if (icmpSock >= 0) close(icmpSock);

    OH_LOG_INFO(LOG_APP, "TraceRoute done: addr=%{public}s hops=%{public}d err=%{public}d",
                address, result.hopCount, result.errorCode);
    return result;
}

// ==================== ARP 扫描（Netlink）====================
// 通过 Netlink socket (NETLINK_ROUTE) 读取内核 ARP 表
// 不依赖 Linux 内核头文件，手动定义结构和常量

#ifndef AF_NETLINK
#define AF_NETLINK 16
#endif
#ifndef NETLINK_ROUTE
#define NETLINK_ROUTE 0
#endif

// Netlink 消息头
struct MyNlMsghdr {
    uint32_t nlmsg_len;
    uint16_t nlmsg_type;
    uint16_t nlmsg_flags;
    uint32_t nlmsg_seq;
    uint32_t nlmsg_pid;
};

// Netlink 套接字地址
struct MySockaddrNl {
    sa_family_t nl_family; // AF_NETLINK
    unsigned short nl_pad;
    uint32_t nl_pid;       // 端口号（0 = 内核）
    uint32_t nl_groups;    // 多播组
};

// 邻居发现消息头 (ndmsg)
struct MyNdMsg {
    unsigned char ndm_family;
    unsigned char ndm_pad1;
    unsigned short ndm_pad2;
    int32_t ndm_ifindex;
    uint16_t ndm_state;
    uint8_t ndm_flags;
    uint8_t ndm_type;
};

// NLA (Netlink 属性) 头
struct MyNlAttr {
    uint16_t nla_len;
    uint16_t nla_type;
};

// NLMSG 常量
#ifndef NLMSG_ALIGNTO
#define NLMSG_ALIGNTO 4
#endif
#define NLMSG_ALIGN(len) (((len) + NLMSG_ALIGNTO - 1) & ~(NLMSG_ALIGNTO - 1))
#define NLMSG_LENGTH(len) (NLMSG_ALIGN(sizeof(struct MyNlMsghdr)) + (len))
#define NLMSG_DATA(nlh) ((void*)(((char*)(nlh)) + NLMSG_LENGTH(0)))
#define NLMSG_NEXT(nlh, len) do { (len) -= NLMSG_ALIGN((nlh)->nlmsg_len); (nlh) = (struct MyNlMsghdr*)((char*)(nlh) + NLMSG_ALIGN((nlh)->nlmsg_len)); } while(0)
#define NLMSG_OK(nlh, len) ((len) >= (int32_t)sizeof(struct MyNlMsghdr) && (nlh)->nlmsg_len >= sizeof(struct MyNlMsghdr) && (nlh)->nlmsg_len <= (uint32_t)(len))

// NLA 常量
#define NLA_ALIGNTO 4
#define NLA_ALIGN(len) (((len) + NLA_ALIGNTO - 1) & ~(NLA_ALIGNTO - 1))
#define NLA_DATA(nla) ((void*)((char*)(nla) + NLA_ALIGN(sizeof(struct MyNlAttr))))
#define NLA_NEXT(nla, len) do { (len) -= NLA_ALIGN((nla)->nla_len); (nla) = (struct MyNlAttr*)((char*)(nla) + NLA_ALIGN((nla)->nla_len)); } while(0)
#define NLA_OK(nla, len) ((len) >= (int32_t)sizeof(struct MyNlAttr) && (nla)->nla_len >= sizeof(struct MyNlAttr) && (nla)->nla_len <= (uint32_t)(len))

// NDA (Neighbor Discovery Attribute) 类型
#define NDA_UNSPEC   0
#define NDA_DST      1   // IP 地址
#define NDA_LLADDR   2   // MAC 地址
#define NDA_CACHEINFO 3  // 缓存信息

// NLMSG 消息类型
#define RTM_BASE     0x10
#define RTM_GETNEIGH (RTM_BASE + 30)   // 读取邻居表
#define RTM_NEWNEIGH (RTM_BASE + 28)   // 邻居条目

// NLMSG 标志
#ifndef NLM_F_REQUEST
#define NLM_F_REQUEST 1
#define NLM_F_DUMP    0x300
#endif

// NLMSG 消息类型常量
#ifndef NLMSG_NOOP
#define NLMSG_NOOP     0x1
#define NLMSG_ERROR    0x2
#define NLMSG_DONE     0x3
#define NLMSG_OVERRUN  0x4
#endif

ArpTableResult PingNativeTool::ReadArpTable()
{
    ArpTableResult result;
    result.entryCount = 0;
    result.errorCode = 0;

    // 1. 创建 Netlink socket
    int sock = socket(AF_NETLINK, SOCK_DGRAM, NETLINK_ROUTE);
    if (sock < 0) {
        OH_LOG_ERROR(LOG_APP, "ARP: socket(AF_NETLINK) failed: %{public}d", errno);
        result.errorCode = -1;
        return result;
    }

    // 2. 绑定（发送方 PID=0 表示由内核分配）
    struct MySockaddrNl addr;
    memset(&addr, 0, sizeof(addr));
    addr.nl_family = AF_NETLINK;
    if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        OH_LOG_ERROR(LOG_APP, "ARP: bind failed: %{public}d", errno);
        close(sock);
        result.errorCode = -2;
        return result;
    }

    // 3. 发送 RTM_GETNEIGH dump 请求
    struct {
        struct MyNlMsghdr nlh;
        struct MyNdMsg ndm;
    } req;
    memset(&req, 0, sizeof(req));
    req.nlh.nlmsg_len = NLMSG_LENGTH(sizeof(struct MyNdMsg));
    req.nlh.nlmsg_type = RTM_GETNEIGH;
    req.nlh.nlmsg_flags = NLM_F_REQUEST | NLM_F_DUMP;
    req.nlh.nlmsg_seq = 1;
    req.ndm.ndm_family = AF_INET;  // 只取 IPv4

    struct MySockaddrNl kernelAddr;
    memset(&kernelAddr, 0, sizeof(kernelAddr));
    kernelAddr.nl_family = AF_NETLINK;

    if (sendto(sock, &req, sizeof(req), 0,
               (struct sockaddr*)&kernelAddr, sizeof(kernelAddr)) < 0) {
        OH_LOG_ERROR(LOG_APP, "ARP: sendto failed: %{public}d", errno);
        close(sock);
        result.errorCode = -3;
        return result;
    }

    // 4. 接收响应（内核可能分多个包发回）
    char recvBuf[16384];
    bool done = false;

    while (!done) {
        struct MySockaddrNl fromAddr;
        socklen_t fromLen = sizeof(fromAddr);
        ssize_t n = recvfrom(sock, recvBuf, sizeof(recvBuf), 0,
                             (struct sockaddr*)&fromAddr, &fromLen);
        if (n < 0) {
            OH_LOG_ERROR(LOG_APP, "ARP: recvfrom failed: %{public}d", errno);
            break;
        }
        if (n == 0) break;

        // 5. 解析每个 NLMSG
        struct MyNlMsghdr* nlh = (struct MyNlMsghdr*)recvBuf;
        int32_t remaining = (int32_t)n;

        while (NLMSG_OK(nlh, remaining)) {
            // 检查是否是多路消息的结束
            if (nlh->nlmsg_type == NLMSG_DONE) {
                done = true;
                break;
            }
            if (nlh->nlmsg_type == NLMSG_ERROR) {
                OH_LOG_WARN(LOG_APP, "ARP: NLMSG_ERROR in response");
                done = true;
                break;
            }

            // 只处理邻居条目
            if (nlh->nlmsg_type == RTM_NEWNEIGH) {
                struct MyNdMsg* ndm = (struct MyNdMsg*)NLMSG_DATA(nlh);

                // 只取 IPv4 + 非 FAILED 的状态（除非就是想看所有）
                if (ndm->ndm_family == AF_INET) {
                    // 解析 NLA 属性
                    struct MyNlAttr* nla = (struct MyNlAttr*)((char*)ndm + NLMSG_ALIGN(sizeof(struct MyNdMsg)));
                    int32_t attrLen = (int32_t)(nlh->nlmsg_len - NLMSG_LENGTH(sizeof(struct MyNdMsg)));

                    ArpEntry entry;
                    memset(&entry, 0, sizeof(entry));
                    entry.ifindex = ndm->ndm_ifindex;
                    entry.state = ndm->ndm_state;
                    entry.hasMac = 0;
                    snprintf(entry.ip, sizeof(entry.ip), "");
                    snprintf(entry.mac, sizeof(entry.mac), "");

                    while (NLA_OK(nla, attrLen)) {
                        if (nla->nla_type == NDA_DST && nla->nla_len >= 4) {
                            // IPv4 地址
                            struct in_addr* ip4 = (struct in_addr*)NLA_DATA(nla);
                            inet_ntop(AF_INET, ip4, entry.ip, sizeof(entry.ip));
                        } else if (nla->nla_type == NDA_LLADDR && nla->nla_len >= 6) {
                            // MAC 地址
                            unsigned char* macBytes = (unsigned char*)NLA_DATA(nla);
                            snprintf(entry.mac, sizeof(entry.mac),
                                     "%02x:%02x:%02x:%02x:%02x:%02x",
                                     macBytes[0], macBytes[1], macBytes[2],
                                     macBytes[3], macBytes[4], macBytes[5]);
                            entry.hasMac = 1;
                        }

                        // 继续下一个属性
                        int nlaLen = NLA_ALIGN(nla->nla_len);
                        attrLen -= nlaLen;
                        nla = (struct MyNlAttr*)((char*)nla + nlaLen);
                    }

                    // 只添加有 IP 的条目
                    if (entry.ip[0] != '\0' && result.entryCount < 256) {
                        result.entries[result.entryCount] = entry;
                        result.entryCount++;
                    }
                }
            }

            // 下一个消息
            int nlLen = NLMSG_ALIGN(nlh->nlmsg_len);
            remaining -= nlLen;
            nlh = (struct MyNlMsghdr*)((char*)nlh + nlLen);
        }
    }

    close(sock);
    OH_LOG_INFO(LOG_APP, "ARP done: %{public}d entries found", result.entryCount);
    return result;
}
