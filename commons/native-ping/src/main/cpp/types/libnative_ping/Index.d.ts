/**
 * libpingnative — TypeScript 类型声明
 * ICMP Ping + Traceroute
 */

/**
 * 执行系统级 ICMP 探测
 * @param address 目标 IP 或域名
 * @param duration 探测持续时间（秒）
 * @returns JSON 格式的探测结果 Promise
 */
export function nativeProbe(address: string, duration: number): Promise<string>

/**
 * 执行 Traceroute 路由追踪
 * @param address 目标 IP 或域名
 * @param maxHops 最大跳数（默认30）
 * @param timeoutSec 每跳超时秒数（默认2）
 * @returns JSON 格式的追踪结果 Promise
 *   { error: 0, hopCount: N, hops: [{ ttl, timeMs, ip, isTarget }] }
 */
export function nativeTraceRoute(address: string, maxHops?: number, timeoutSec?: number): Promise<string>
