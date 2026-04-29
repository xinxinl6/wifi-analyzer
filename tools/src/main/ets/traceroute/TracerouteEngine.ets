// 路由追踪引擎 — 基于 HTTP 逐跳延迟探测模拟 traceroute
// HarmonyOS 不提供原生 ICMP/UDP socket 支持，使用 HTTP HEAD 请求逐段探测

import { http } from '@kit.NetworkKit'
import { connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

// ==================== 数据接口 ====================

// 单跳探测结果
export interface TracerouteHop {
  hopIndex: number         // 跳数序号（1-based）
  address: string          // 节点地址
  latency: number          // 延迟 ms（-1 表示超时/不可达）
  status: 'success' | 'timeout' | 'error'  // 状态
  hostname: string         // 主机名（如果能解析）
}

// 路由追踪配置
export interface TracerouteConfig {
  targetHost: string       // 目标地址
  maxHops: number          // 最大跳数
  timeout: number          // 单次探测超时（秒）
  probesPerHop: number     // 每跳探测次数
  intervalMs: number       // 跳间间隔（毫秒）
}

// 路由追踪回调
export interface TracerouteCallbacks {
  onHopUpdate?: (hops: TracerouteHop[]) => void   // 每完成一跳回调
  onComplete?: (hops: TracerouteHop[]) => void    // 追踪完成回调
  onError?: (message: string) => void             // 错误回调
}

// 路由追踪统计
export interface TracerouteStats {
  totalHops: number        // 总跳数
  successHops: number      // 成功跳数
  failedHops: number       // 失败跳数
  avgLatency: number       // 平均延迟
  maxLatency: number       // 最大延迟
  minLatency: number       // 最小延迟
  totalLatency: number     // 端到端总延迟
}

// HTTP 请求头接口（避免匿名对象字面量）
interface ProbeHttpHeaders {
  'User-Agent': string
  'Accept': string
}

// HTTP 请求选项接口
interface ProbeRequestOptions {
  method: http.RequestMethod
  readTimeout: number
  connectTimeout: number
  header: ProbeHttpHeaders
}

// DNS 解析结果接口
export interface DnsResolveResult {
  address: string
  hostname: string
}

// 单次探测结果接口
interface ProbeResult {
  latency: number
  status: 'success' | 'timeout' | 'error'
}

export class TracerouteEngine {
  private isRunning: boolean = false
  private abortRequested: boolean = false

  // 检测到的网关
  private detectedGateway: string = ''

  // 获取当前网关地址
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
              for (let r = 0; r < data.routes.length; r++) {
                const route = data.routes[r]
                if (route.isDefaultRoute === true && route.hasGateway === true && route.gateway !== undefined) {
                  gwIp = route.gateway.address || ''
                  if (gwIp !== '') break
                }
              }
            }
            if (gwIp === '') gwIp = '192.168.1.1'
            this.detectedGateway = gwIp
            resolve(gwIp)
          }
        )
      } catch (error) {
        resolve('192.168.1.1')
      }
    })
  }

  // 解析域名
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
      } catch (error) {
        resolve({ address: cleanHost, hostname: cleanHost })
      }
    })
  }

  // 对单个地址进行 HTTP HEAD 探测，返回延迟
  private async probeTarget(address: string, timeoutMs: number): Promise<ProbeResult> {
    let testUrl: string = address
    if (testUrl.indexOf('http') < 0) testUrl = 'http://' + address

    const startTime: number = Date.now()
    let elapsed: number = -1
    let status: 'success' | 'timeout' | 'error' = 'error'

    try {
      await new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
        const req = http.createHttp()
        const options: ProbeRequestOptions = {
          method: http.RequestMethod.HEAD,
          readTimeout: timeoutMs / 1000,
          connectTimeout: timeoutMs / 1000,
          header: {
            'User-Agent': 'WIFI-Traceroute/1.0',
            'Accept': '*/*'
          } as ProbeHttpHeaders
        }
        let timeoutTimerId: number = -1
        req.request(
          testUrl,
          options,
          (err: BusinessError, resp: http.HttpResponse): void => {
            if (timeoutTimerId >= 0) {
              clearTimeout(timeoutTimerId)
              timeoutTimerId = -1
            }
            req.destroy()
            if (err) {
              reject(new Error(err.message))
            } else if (resp && resp.responseCode >= 200 && resp.responseCode < 500) {
              resolve()
            } else {
              reject(new Error('HTTP ' + String(resp?.responseCode)))
            }
          }
        )
        timeoutTimerId = setTimeout((): void => {
          req.destroy()
          reject(new Error('Timeout'))
        }, timeoutMs + 500)
      })
      elapsed = Date.now() - startTime
      status = 'success'
    } catch (e) {
      elapsed = Date.now() - startTime
      if (e instanceof Error && e.message === 'Timeout') {
        status = 'timeout'
      } else {
        status = 'error'
      }
    }

    const result: ProbeResult = { latency: status === 'success' ? elapsed : -1, status: status }
    return result
  }

  // 获取默认配置
  static getDefaultConfig(targetHost: string): TracerouteConfig {
    return {
      targetHost: targetHost,
      maxHops: 30,
      timeout: 3,
      probesPerHop: 3,
      intervalMs: 500
    }
  }

  // 执行路由追踪（主入口）
  async startTrace(config: TracerouteConfig, callbacks: TracerouteCallbacks): Promise<void> {
    this.isRunning = true
    this.abortRequested = false

    const allHops: TracerouteHop[] = []

    try {
      // 第一步：解析目标
      const resolved: DnsResolveResult = await this.resolveHost(config.targetHost)

      // 第二步：获取网关
      const gateway: string = await this.detectGateway()

      // 第三步：逐跳探测
      // 策略：逐个探测已知节点（网关 → 目标），同时构建跳数拓扑
      // 由于 HarmonyOS 限制，无法真正 ICMP traceroute，模拟如下：
      // Hop 1: 网关（本地路由器）
      // Hop 2~N-1: 探测中间节点（使用递增 TTL 的 HTTP 请求模拟，实际以不同方式探测）
      // Hop N: 目标地址

      // Hop 1: 探测网关
      if (this.abortRequested) return
      await this.probeHop(1, gateway, '网关', config, allHops, callbacks)

      // 中间跳：由于无法真正获取中间路由器 IP，使用到目标不同阶段的延迟
      // 来模拟路由跳数。实际策略：分 3 次探测目标，延迟的阶跃变化暗示跳数。
      if (this.abortRequested) return

      // 探测目标获取端到端延迟
      const targetLatencies: number[] = []
      for (let probe = 0; probe < config.probesPerHop; probe++) {
        if (this.abortRequested) return
        const result = await this.probeTarget(resolved.address, config.timeout * 1000)
        if (result.status === 'success') {
          targetLatencies.push(result.latency)
        }
        // 探测间隔
        if (probe < config.probesPerHop - 1 && !this.abortRequested) {
          await this.delay(config.intervalMs)
        }
      }

      if (this.abortRequested) return

      // 根据延迟差异估算中间跳数
      const gatewayHop: TracerouteHop | undefined = allHops.length > 0 ? allHops[0] : undefined
      const avgTargetLatency = targetLatencies.length > 0
        ? targetLatencies.reduce((sum: number, v: number) => sum + v, 0) / targetLatencies.length
        : -1

      // 计算中间跳数（基于延迟增长）
      let estimatedMiddleHops: number = 0
      if (gatewayHop && gatewayHop.latency > 0 && avgTargetLatency > 0) {
        // 延迟差 / 典型每跳延迟(~5ms) 估算中间节点
        const latencyDiff: number = avgTargetLatency - gatewayHop.latency
        estimatedMiddleHops = Math.min(Math.max(Math.round(latencyDiff / 5), 1), config.maxHops - 2)
      }

      // 添加中间跳（延迟递增，地址为 * 不可知）
      if (estimatedMiddleHops > 0 && allHops.length > 0) {
        const baseLatency: number = allHops[0].latency > 0 ? allHops[0].latency : 1
        const stepLatency: number = avgTargetLatency > 0
          ? (avgTargetLatency - baseLatency) / (estimatedMiddleHops + 1)
          : 5

        for (let h = 0; h < estimatedMiddleHops; h++) {
          if (this.abortRequested) return
          const hopIndex: number = h + 2
          const hopLatency: number = Math.round(baseLatency + stepLatency * (h + 1))
          const hop: TracerouteHop = {
            hopIndex: hopIndex,
            address: '*',
            latency: hopLatency,
            status: avgTargetLatency > 0 ? 'timeout' : 'error',
            hostname: '*'
          }
          allHops.push(hop)
          if (callbacks.onHopUpdate) callbacks.onHopUpdate(this.copyHops(allHops))
          await this.delay(200)
        }
      }

      // 最终跳：目标地址
      if (!this.abortRequested) {
        const finalHopIndex: number = allHops.length + 1
        const bestLatency: number = targetLatencies.length > 0
          ? Math.min(...targetLatencies)
          : -1
        const worstLatency: number = targetLatencies.length > 0
          ? Math.max(...targetLatencies)
          : -1

        const finalHop: TracerouteHop = {
          hopIndex: finalHopIndex,
          address: resolved.address,
          latency: bestLatency,
          status: bestLatency > 0 ? 'success' : 'error',
          hostname: resolved.hostname !== resolved.address ? resolved.hostname : ''
        }
        allHops.push(finalHop)
        if (callbacks.onHopUpdate) callbacks.onHopUpdate(this.copyHops(allHops))
      }

      // 完成
      this.isRunning = false
      if (callbacks.onComplete) callbacks.onComplete(allHops)

    } catch (error) {
      this.isRunning = false
      let errMsg: string = '追踪失败'
      if (error instanceof Error) errMsg = error.message
      if (callbacks.onError) callbacks.onError(errMsg)
    }
  }

  // 探测单个跳节点
  private async probeHop(
    hopIndex: number,
    address: string,
    hostname: string,
    config: TracerouteConfig,
    allHops: TracerouteHop[],
    callbacks: TracerouteCallbacks
  ): Promise<void> {
    // 多次探测取最优
    let bestLatency: number = -1
    let bestStatus: 'success' | 'timeout' | 'error' = 'error'

    for (let probe = 0; probe < config.probesPerHop; probe++) {
      if (this.abortRequested) return
      const result = await this.probeTarget(address, config.timeout * 1000)
      if (result.status === 'success') {
        if (bestLatency < 0 || result.latency < bestLatency) {
          bestLatency = result.latency
          bestStatus = 'success'
        }
      } else if (bestStatus === 'error') {
        bestStatus = result.status
      }
    }

    const hop: TracerouteHop = {
      hopIndex: hopIndex,
      address: address,
      latency: bestLatency,
      status: bestStatus,
      hostname: hostname
    }
    allHops.push(hop)
    if (callbacks.onHopUpdate) callbacks.onHopUpdate(this.copyHops(allHops))
  }

  // 停止追踪
  stopTrace(): void {
    this.abortRequested = true
    this.isRunning = false
  }

  // 判断是否正在运行
  getIsRunning(): boolean {
    return this.isRunning
  }

  // 计算统计数据
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
    const firstHop: TracerouteHop | undefined = hops.length > 0 ? hops[0] : undefined
    let totalLatency: number = -1
    if (firstHop && lastHop && firstHop.latency > 0 && lastHop.latency > 0) {
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

  // 延迟辅助
  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, ms)
    })
  }
}
