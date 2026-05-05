// 路由追踪引擎 — 基于 @ohos-rs/traceroute (Rust ICMP 实现)
// 真实 traceroute，可获取中间路由器 IP 和逐跳延迟

import { traceRoute, traceRouteWithSignal, HopResult, TraceOption, AbortSignal as OhosAbortSignal } from '@ohos-rs/traceroute'
import { connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

// ==================== 数据接口 ====================

// 单跳探测结果（对外暴露，兼容 TraceroutePage）
export interface TracerouteHop {
  hopIndex: number         // 跳数序号（1-based）
  address: string          // 节点地址（* 表示无响应）
  latency: number          // 最优延迟 ms（-1 表示超时/不可达）
  allRtt: number[]         // 全部探测 RTT（用于展示抖动）
  status: 'success' | 'timeout' | 'error'
  hostname: string         // 主机名（暂时与 address 相同，后续可反向 DNS）
}

// 路由追踪配置
export interface TracerouteConfig {
  targetHost: string       // 目标地址
  maxHops: number          // 最大跳数（传给 TraceOption.maxHops）
  timeout: number          // 单次探测超时（秒，传给 TraceOption.timeout）
  probesPerHop: number     // 每跳探测次数（传给 TraceOption.reTry）
  intervalMs: number       // 跳间间隔（毫秒，保留字段，ohos-rs 内部管理）
}

// 路由追踪回调
export interface TracerouteCallbacks {
  onHopUpdate?: (hops: TracerouteHop[]) => void   // 每完成一跳回调（实时更新）
  onComplete?: (hops: TracerouteHop[]) => void    // 追踪完成回调
  onError?: (message: string) => void             // 错误回调
}

// 路由追踪统计
export interface TracerouteStats {
  totalHops: number
  successHops: number
  failedHops: number
  avgLatency: number
  maxLatency: number
  minLatency: number
  totalLatency: number     // 端到端延迟（最后一跳最优 RTT）
}

// DNS 解析结果接口（兼容 TraceroutePage）
export interface DnsResolveResult {
  address: string
  hostname: string
}

// ==================== 引擎类 ====================

export class TracerouteEngine {
  private isRunning: boolean = false
  private abortSignal: OhosAbortSignal | null = null
  private detectedGateway: string = ''

  // ==================== 网关检测 ====================
  async detectGateway(): Promise<string> {
    if (this.detectedGateway !== '') {
      return this.detectedGateway
    }
    return await new Promise<string>((resolve: (v: string) => void) => {
      try {
        const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
        if (!netHandle) {
          resolve('192.168.1.1')
          return
        }
        connection.getConnectionProperties(
          netHandle,
          (err: BusinessError, data: connection.ConnectionProperties): void => {
            if (err) {
              resolve('192.168.1.1')
              return
            }
            let gwIp: string = ''
            if (data.routes && data.routes.length > 0) {
              for (let i = 0; i < data.routes.length; i++) {
                const r = data.routes[i]
                if (r.isDefaultRoute === true && r.hasGateway === true && r.gateway !== undefined) {
                  gwIp = r.gateway.address || ''
                  if (gwIp !== '') break
                }
              }
            }
            if (gwIp === '') gwIp = '192.168.1.1'
            this.detectedGateway = gwIp
            resolve(gwIp)
          }
        )
      } catch {
        resolve('192.168.1.1')
      }
    })
  }

  // ==================== 域名解析 ====================
  async resolveHost(host: string): Promise<DnsResolveResult> {
    return await new Promise<DnsResolveResult>((resolve: (v: DnsResolveResult) => void) => {
      let cleanHost: string = host
      if (cleanHost.indexOf('http') >= 0) {
        cleanHost = cleanHost.replace(/^https?:\/\//, '').replace(/\/.*$/, '')
      }
      // 已经是 IP 则直接返回
      if (/^\d+\.\d+\.\d+\.\d+$/.test(cleanHost)) {
        resolve({ address: cleanHost, hostname: cleanHost })
        return
      }
      try {
        const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
        if (!netHandle) {
          resolve({ address: cleanHost, hostname: cleanHost })
          return
        }
        connection.getAddressesByName(
          cleanHost,
          (err: BusinessError, addresses: Array<connection.NetAddress>): void => {
            if (!err && addresses && addresses.length > 0) {
              resolve({ address: addresses[0].address || cleanHost, hostname: cleanHost })
            } else {
              resolve({ address: cleanHost, hostname: cleanHost })
            }
          }
        )
      } catch {
        resolve({ address: cleanHost, hostname: cleanHost })
      }
    })
  }

  // ==================== 获取默认配置 ====================
  static getDefaultConfig(targetHost: string): TracerouteConfig {
    return {
      targetHost: targetHost,
      maxHops: 30,
      timeout: 3,
      probesPerHop: 3,
      intervalMs: 0
    }
  }

  // ==================== 启动追踪 ====================
  async startTrace(config: TracerouteConfig, callbacks: TracerouteCallbacks): Promise<void> {
    this.isRunning = true
    this.abortSignal = OhosAbortSignal.timeout(config.maxHops * config.timeout * 1000 + 10000)

    const allHops: TracerouteHop[] = []

    const options: TraceOption = {
      maxHops: config.maxHops,
      timeout: config.timeout,
      reTry: config.probesPerHop,
      ipVersion: 'auto',
      // onTrace 回调：每探测到一跳就实时通知 UI
      onTrace: (err: Error | null, hop: HopResult): void => {
        if (!this.isRunning) return

        const mappedHop: TracerouteHop = this.mapHopResult(hop)

        // 更新或插入（按 hopIndex 排序）
        let found: boolean = false
        for (let i = 0; i < allHops.length; i++) {
          if (allHops[i].hopIndex === mappedHop.hopIndex) {
            allHops[i] = mappedHop
            found = true
            break
          }
        }
        if (!found) {
          allHops.push(mappedHop)
        }

        if (callbacks.onHopUpdate) {
          callbacks.onHopUpdate(this.copyHops(allHops))
        }
      }
    }

    try {
      const results: HopResult[] = await traceRouteWithSignal(
        config.targetHost,
        this.abortSignal,
        options
      )

      // 追踪完成 — 用最终完整结果覆盖（比实时回调更准确）
      allHops.length = 0
      for (let i = 0; i < results.length; i++) {
        allHops.push(this.mapHopResult(results[i]))
      }

      this.isRunning = false
      if (callbacks.onComplete) {
        callbacks.onComplete(this.copyHops(allHops))
      }
    } catch (error) {
      this.isRunning = false
      let errMsg: string = '追踪失败'
      if (error instanceof Error) {
        // AbortSignal 超时或用户取消，allHops 已有部分结果
        if (error.message.indexOf('abort') >= 0 || error.message.indexOf('cancel') >= 0) {
          if (allHops.length > 0 && callbacks.onComplete) {
            callbacks.onComplete(this.copyHops(allHops))
            return
          }
        }
        errMsg = error.message
      }
      if (callbacks.onError) callbacks.onError(errMsg)
    }
  }

  // ==================== 停止追踪 ====================
  stopTrace(): void {
    this.isRunning = false
    // AbortSignal 不支持手动 abort，通过标志位控制回调行为
    // 下一次启动时会创建新的 AbortSignal
    this.abortSignal = null
  }

  getIsRunning(): boolean {
    return this.isRunning
  }

  // ==================== 转换 HopResult → TracerouteHop ====================
  private mapHopResult(hop: HopResult): TracerouteHop {
    const addr: string = hop.addr !== undefined && hop.addr !== '' ? hop.addr : '*'
    const rttList: number[] = hop.rtt !== undefined ? hop.rtt : []

    // 过滤掉无效的 RTT（0 或负值）
    const validRtt: number[] = []
    for (let i = 0; i < rttList.length; i++) {
      if (rttList[i] > 0) validRtt.push(rttList[i])
    }

    let bestLatency: number = -1
    if (validRtt.length > 0) {
      bestLatency = validRtt[0]
      for (let i = 1; i < validRtt.length; i++) {
        if (validRtt[i] < bestLatency) bestLatency = validRtt[i]
      }
    }

    let status: 'success' | 'timeout' | 'error' = 'timeout'
    if (addr !== '*' && bestLatency > 0) {
      status = 'success'
    } else if (addr === '*') {
      status = 'timeout'
    }

    return {
      hopIndex: hop.hop,
      address: addr,
      latency: bestLatency,
      allRtt: validRtt,
      status: status,
      hostname: addr !== '*' ? addr : ''
    }
  }

  // ==================== 计算统计 ====================
  static calcStats(hops: TracerouteHop[]): TracerouteStats {
    let totalHops: number = hops.length
    let successHops: number = 0
    let failedHops: number = 0
    let maxLatency: number = 0
    let minLatency: number = 999999
    let latencySum: number = 0
    let latencyCount: number = 0

    for (let i = 0; i < hops.length; i++) {
      const hop = hops[i]
      if (hop.status === 'success' && hop.latency > 0) {
        successHops++
        latencyCount++
        latencySum += hop.latency
        if (hop.latency > maxLatency) maxLatency = hop.latency
        if (hop.latency < minLatency) minLatency = hop.latency
      } else {
        failedHops++
      }
    }

    const lastHop: TracerouteHop | undefined = hops.length > 0 ? hops[hops.length - 1] : undefined
    let totalLatency: number = -1
    if (lastHop && lastHop.latency > 0) {
      totalLatency = lastHop.latency
    }

    return {
      totalHops: totalHops,
      successHops: successHops,
      failedHops: failedHops,
      avgLatency: latencyCount > 0 ? Math.round(latencySum / latencyCount * 100) / 100 : 0,
      maxLatency: maxLatency,
      minLatency: minLatency === 999999 ? 0 : minLatency,
      totalLatency: totalLatency
    }
  }

  // 复制数组（ArkTS 禁止展开运算符）
  private copyHops(hops: TracerouteHop[]): TracerouteHop[] {
    const copy: TracerouteHop[] = []
    for (let i = 0; i < hops.length; i++) {
      copy.push(hops[i])
    }
    return copy
  }
}
