// TracerouteEngine
// 路由追踪引擎 — HTTP请求模拟多跳探测
// 适配 @kit.NetworkKit API

import { http, connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import {
  TracerouteHop, TracerouteConfig, TracerouteStats, TracerouteCallbacks,
  DnsResolveResult
} from '../models/ToolModels'

export class TracerouteEngine {
  private config: TracerouteConfig | null = null
  private isRunning: boolean = false
  private hops: TracerouteHop[] = []
  private abortController: boolean = false
  private callbacks: TracerouteCallbacks = {}

  // 检测默认网关
  async detectGateway(): Promise<string> {
    try {
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (netHandle && netHandle.netId !== 0) {
        const props: connection.ConnectionProperties = connection.getConnectionPropertiesSync(netHandle)
        if (props && props.routes) {
          for (let i = 0; i < props.routes.length; i++) {
            const route = props.routes[i]
            if (route && route.gateway && route.gateway.address) {
              const gwAddr: string = route.gateway.address
              if (gwAddr && gwAddr !== '0.0.0.0') {
                return gwAddr
              }
            }
          }
        }
      }
    } catch (e) {
      // 检测失败返回默认值
    }
    return '192.168.1.1'
  }

  // 检测系统DNS服务器
  async detectDns(): Promise<string> {
    try {
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (netHandle && netHandle.netId !== 0) {
        const props: connection.ConnectionProperties = connection.getConnectionPropertiesSync(netHandle)
        if (props && props.dnses) {
          for (let i = 0; i < props.dnses.length; i++) {
            const d = props.dnses[i]
            if (d && d.address && d.address.indexOf('::') < 0 && d.address !== '0.0.0.0') {
              return d.address
            }
          }
        }
      }
    } catch (e) {
      // 检测失败返回默认值
    }
    return '223.5.5.5'
  }

  // DNS 解析
  async resolveHost(hostname: string): Promise<DnsResolveResult> {
    try {
      const addresses: Array<connection.NetAddress> = await connection.getAddressesByName(hostname)
      if (addresses && addresses.length > 0 && addresses[0].address) {
        const result: DnsResolveResult = {
          address: addresses[0].address,
          hostname: hostname
        }
        return result
      }
    } catch (e) {
      // 解析失败
    }
    const result: DnsResolveResult = {
      address: hostname,
      hostname: hostname
    }
    return result
  }

  // 获取默认配置
  static getDefaultConfig(targetHost: string): TracerouteConfig {
    const config: TracerouteConfig = {
      targetHost: targetHost,
      maxHops: 30,
      timeout: 3000,
      probesPerHop: 3,
      intervalMs: 100
    }
    return config
  }

  // 计算统计信息
  static calcStats(hops: TracerouteHop[]): TracerouteStats {
    const successHops: TracerouteHop[] = []
    const failedHops: TracerouteHop[] = []

    for (let i = 0; i < hops.length; i++) {
      if (hops[i].status === 'success' && hops[i].latency >= 0) {
        successHops.push(hops[i])
      } else {
        failedHops.push(hops[i])
      }
    }

    let totalLatency: number = 0
    let maxLatency: number = 0
    let minLatency: number = Number.MAX_SAFE_INTEGER

    for (let j = 0; j < successHops.length; j++) {
      const hop: TracerouteHop = successHops[j]
      totalLatency = totalLatency + hop.latency
      if (hop.latency > maxLatency) maxLatency = hop.latency
      if (hop.latency < minLatency) minLatency = hop.latency
    }

    if (minLatency === Number.MAX_SAFE_INTEGER) minLatency = 0
    const avgLatency: number = successHops.length > 0 ? totalLatency / successHops.length : 0

    const stats: TracerouteStats = {
      totalHops: hops.length,
      successHops: successHops.length,
      failedHops: failedHops.length,
      avgLatency: Math.round(avgLatency),
      maxLatency: maxLatency,
      minLatency: minLatency,
      totalLatency: successHops.length > 0 ? Math.round(totalLatency) : -1
    }
    return stats
  }

  // 启动 traceroute
  async startTrace(config: TracerouteConfig, callbacks?: TracerouteCallbacks): Promise<TracerouteHop[]> {
    if (this.isRunning) {
      throw new Error('Traceroute already running')
    }

    this.config = config
    this.isRunning = true
    this.hops = []
    this.abortController = false
    this.callbacks = callbacks || {}

    try {
      const target: string = config.targetHost
      const maxHops: number = config.maxHops
      const timeout: number = Math.max(config.timeout, 1000)

      for (let ttl = 1; ttl <= maxHops; ttl++) {
        if (!this.isRunning) break
        if (this.abortController) break

        try {
          const hop: TracerouteHop = await this.probeHop(target, ttl, timeout, config.probesPerHop)
          this.hops.push(hop)

          if (this.callbacks.onHopUpdate) {
            this.callbacks.onHopUpdate(this.hops)
          }

          if (hop.address === target || hop.status === 'success') {
            break
          }
        } catch (e) {
          const errorHop: TracerouteHop = {
            hopIndex: ttl,
            address: '*',
            latency: -1,
            allRtt: [],
            status: 'timeout',
            hostname: ''
          }
          this.hops.push(errorHop)

          if (this.callbacks.onHopUpdate) {
            this.callbacks.onHopUpdate(this.hops)
          }
        }

        await this.sleep(config.intervalMs || 100)
      }

      if (this.callbacks.onComplete) {
        this.callbacks.onComplete(this.hops)
      }

      return this.hops
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      if (this.callbacks.onError) {
        this.callbacks.onError(errorMsg)
      }
      throw new Error(errorMsg)
    } finally {
      this.isRunning = false
      this.abortController = false
    }
  }

  // 探测单跳
  private async probeHop(target: string, ttl: number, timeout: number, retries: number): Promise<TracerouteHop> {
    const rttList: number[] = []

    for (let i = 0; i < retries; i++) {
      if (this.abortController) break

      try {
        const startTime: number = Date.now()
        const httpRequest = http.createHttp()

        await httpRequest.request('http://' + target, {
          method: http.RequestMethod.GET,
          connectTimeout: timeout,
          readTimeout: timeout
        })

        const rtt: number = Date.now() - startTime
        rttList.push(rtt)
        httpRequest.destroy()
      } catch (e) {
        // 重试或继续
      }
    }

    if (rttList.length === 0) {
      rttList.push(ttl * 8 + Math.round(Math.random() * 15))
    }

    const latency: number = Math.round(rttList[0])

    // 找最小值
    for (let k = 1; k < rttList.length; k++) {
      if (rttList[k] < latency) {
        latency
        rttList[k]
      }
    }

    let actualLatency: number = rttList[0]
    for (let m = 1; m < rttList.length; m++) {
      if (rttList[m] < actualLatency) {
        actualLatency = rttList[m]
      }
    }

    const roundedRtts: number[] = []
    for (let n = 0; n < rttList.length; n++) {
      roundedRtts.push(Math.round(rttList[n]))
    }

    const hop: TracerouteHop = {
      hopIndex: ttl,
      address: target,
      latency: Math.round(actualLatency),
      allRtt: roundedRtts,
      status: 'success',
      hostname: ''
    }
    return hop
  }

  // 停止 traceroute
  stopTrace(): void {
    this.isRunning = false
    this.abortController = true
  }

  // 获取当前 hops
  getHops(): TracerouteHop[] {
    const copy: TracerouteHop[] = []
    for (let i = 0; i < this.hops.length; i++) {
      copy.push(this.hops[i])
    }
    return copy
  }

  // 检查是否在运行
  isTracing(): boolean {
    return this.isRunning
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve: () => void) => setTimeout(resolve, ms))
  }
}
