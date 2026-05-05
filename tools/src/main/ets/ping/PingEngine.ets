// Ping 引擎 — 网络连通性检测
// 使用 TCP 连接 + HTTP 请求实现类似 Ping 的延迟检测
// 兼容模拟器和真机环境

import http from '@ohos.net.http'
import socket from '@ohos.net.socket'
import connection from '@ohos.net.connection'
import { ValidationPatterns } from '@wifi-analyzer/core'

// ==================== 接口定义 ====================

// HTTP Ping 结果
interface HttpPingResult {
  time: number
  status: string
}

// TCP Ping 结果
interface TcpPingResult {
  success: boolean
  error?: string
}

// 带 code 的错误对象
interface ErrorWithCode {
  code?: number
  message?: string
}

// Ping 单次结果
export interface PingResult {
  index: number           // 序号
  host: string            // 目标主机
  address: string         // 解析后的 IP
  time: number            // 延迟 (ms)，-1 表示超时
  ttl: number             // TTL 值（模拟）
  status: 'success' | 'timeout' | 'error'
  errorMessage?: string
}

// Ping 统计信息
export interface PingStats {
  sent: number            // 发送数
  received: number        // 成功数
  lost: number            // 丢失数
  lossRate: number        // 丢包率 (%)
  minTime: number         // 最小延迟
  maxTime: number         // 最大延迟
  avgTime: number         // 平均延迟
  totalTime: number       // 总延迟
}

// Ping 配置
export interface PingConfig {
  host: string
  count: number          // Ping 次数，默认 4
  timeout: number         // 超时时间 (ms)，默认 3000
  interval: number        // 间隔时间 (ms)，默认 1000
}

// Ping 回调接口
export interface PingCallbacks {
  onResult?: (result: PingResult) => void
  onProgress?: (sent: number, received: number) => void
  onComplete?: (results: PingResult[], stats: PingStats) => void
  onError?: (message: string) => void
}

// ==================== Ping 引擎 ====================

export class PingEngine {
  private isRunning: boolean = false
  private abortController: AbortController | null = null
  private results: PingResult[] = []

  // 获取默认配置
  static getDefaultConfig(host: string): PingConfig {
    return {
      host: host,
      count: 4,
      timeout: 3000,
      interval: 1000
    }
  }

  // 计算统计信息
  static calcStats(results: PingResult[]): PingStats {
    const successResults = results.filter(r => r.status === 'success')
    const sent = results.length
    const received = successResults.length
    const lost = sent - received
    const lossRate = sent > 0 ? Math.round((lost / sent) * 100) : 0

    const times = successResults.map(r => r.time)
    const minTime = times.length > 0 ? Math.min(...times) : 0
    const maxTime = times.length > 0 ? Math.max(...times) : 0
    const totalTime = times.reduce((sum, t) => sum + t, 0)
    const avgTime = times.length > 0 ? Math.round(totalTime / times.length) : 0

    return {
      sent,
      received,
      lost,
      lossRate,
      minTime,
      maxTime,
      avgTime,
      totalTime
    }
  }

  // 解析主机名为 IP 地址
  async resolveHost(host: string): Promise<string> {
    // 如果已经是 IP，直接返回
    if (ValidationPatterns.isValidIpv4(host)) {
      return host
    }

    try {
      const netConnection = await connection.getDefaultNet()
      if (netConnection) {
        const addresses = await netConnection.getAddressesByName(host)
        if (addresses && addresses.length > 0) {
          return addresses[0].address
        }
      }
    } catch (error) {
      console.error('[PingEngine] DNS resolve failed:', JSON.stringify(error))
    }

    // 如果解析失败，尝试直接连接域名
    return host
  }

  // 执行单次 Ping（TCP 连接方式）
  async pingOnce(index: number, host: string, timeout: number): Promise<PingResult> {
    const startTime = Date.now()
    let resolvedAddress = ''

    try {
      // 1. 解析主机
      resolvedAddress = await this.resolveHost(host)

      // 2. 尝试 TCP 连接到端口 80 或 443
      const result = await this.tcpPing(resolvedAddress, timeout)
      const endTime = Date.now()
      const time = endTime - startTime

      return {
        index,
        host,
        address: resolvedAddress,
        time: time,
        ttl: 64, // 模拟 TTL
        status: result.success ? 'success' : 'timeout',
        errorMessage: result.error
      }
    } catch (error) {
      const endTime = Date.now()
      const time = endTime - startTime

      return {
        index,
        host,
        address: resolvedAddress || host,
        time: -1,
        ttl: 0,
        status: 'error',
        errorMessage: this.getErrorMessage(error)
      }
    }
  }

  // TCP Ping 实现
  private tcpPing(address: string, timeout: number): Promise<TcpPingResult> {
    return new Promise((resolve) => {
      let tcpSocket = socket.constructTCPSocketInstance()
      let timeoutId = -1

      // 设置超时
      timeoutId = setTimeout(() => {
        try {
          tcpSocket.close(() => {})
        } catch {}
        const timeoutResult: TcpPingResult = { success: false, error: 'timeout' }
        resolve(timeoutResult)
      }, timeout)

      // 尝试连接 443 端口（HTTPS）
      tcpSocket.connect({
        address: {
          address: address,
          port: 443
        },
        timeout: timeout
      }, (error) => {
        clearTimeout(timeoutId)
        if (!error) {
          tcpSocket.close(() => {})
          const successResult: TcpPingResult = { success: true }
          resolve(successResult)
        } else {
          // 443 失败，尝试 80 端口（HTTP）
          this.tryPort80(address, timeout, tcpSocket, resolve)
        }
      })
    })
  }

  // 尝试连接到 80 端口
  private tryPort80(
    address: string,
    timeout: number,
    previousSocket: socket.TCPSocket,
    resolve: (result: TcpPingResult) => void
  ): void {
    let tcpSocket = socket.constructTCPSocketInstance()
    let timeoutId = -1

    timeoutId = setTimeout(() => {
      try {
        tcpSocket.close(() => {})
      } catch {}
      const timeoutResult: TcpPingResult = { success: false, error: 'port_closed' }
      resolve(timeoutResult)
    }, timeout)

    tcpSocket.connect({
      address: {
        address: address,
        port: 80
      },
      timeout: timeout
    }, (error) => {
      clearTimeout(timeoutId)
      if (!error) {
        tcpSocket.close(() => {})
        const successResult: TcpPingResult = { success: true }
        resolve(successResult)
      } else {
        tcpSocket.close(() => {})
        const failResult: TcpPingResult = { success: false, error: 'port_closed' }
        resolve(failResult)
      }
    })
  }

  // HTTP Ping 方式（备选方案）
  async httpPing(host: string, timeout: number): Promise<HttpPingResult> {
    return new Promise((resolve) => {
      const httpRequest = http.createHttp()
      let timeoutId = -1
      const startTime = Date.now()

      // 设置超时
      timeoutId = setTimeout(() => {
        try {
          httpRequest.destroy()
        } catch {}
        const timeoutResult: HttpPingResult = { time: -1, status: 'timeout' }
        resolve(timeoutResult)
      }, timeout)

      const url = host.startsWith('http') ? host : `https://${host}`

      httpRequest.request(
        url,
        {
          method: http.RequestMethod.GET,
          connectTimeout: timeout,
          readTimeout: timeout,
          expectDataType: http.HttpDataType.STRING,
          header: {
            'User-Agent': 'WiFiAnalyzer/1.0'
          } as Record<string, string>
        } as http.HttpRequestOptions,
        (error, result) => {
          clearTimeout(timeoutId)
          const endTime = Date.now()
          const time = endTime - startTime

          try {
            httpRequest.destroy()
          } catch {}

          if (error) {
            const errorResult: HttpPingResult = { time: -1, status: 'error' }
            resolve(errorResult)
          } else {
            const successResult: HttpPingResult = { time: time, status: 'success' }
            resolve(successResult)
          }
        }
      )
    })
  }

  // 开始 Ping
  async startPing(config: PingConfig, callbacks?: PingCallbacks): Promise<void> {
    if (this.isRunning) {
      callbacks?.onError?.('Ping already running')
      return
    }

    this.isRunning = true
    this.results = []
    this.abortController = new AbortController()

    const host = config.host
    const count = config.count
    const timeout = config.timeout
    const interval = config.interval

    try {
      // 预解析主机
      const resolvedHost = await this.resolveHost(host)
      callbacks?.onProgress?.(0, 0)

      // 执行多次 Ping
      for (let i = 0; i < count; i++) {
        if (!this.isRunning) break

        const result = await this.pingOnce(i + 1, host, timeout)
        this.results.push(result)

        callbacks?.onResult?.(result)
        callbacks?.onProgress?.(i + 1, result.status === 'success' ? 1 : 0)

        // 等待间隔（最后一次不等待）
        if (i < count - 1 && this.isRunning) {
          await this.sleep(interval)
        }
      }

      // 完成
      const stats = PingEngine.calcStats(this.results)
      callbacks?.onComplete?.(this.results, stats)

    } catch (error) {
      callbacks?.onError?.(this.getErrorMessage(error))
    } finally {
      this.isRunning = false
      this.abortController = null
    }
  }

  // 停止 Ping
  stopPing(): void {
    this.isRunning = false
    if (this.abortController) {
      try {
        this.abortController.abort()
      } catch {}
      this.abortController = null
    }
  }

  // 工具方法
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  private getErrorMessage(error: Object): string {
    try {
      const err = error as ErrorWithCode
      if (err.code !== undefined) {
        return `Error ${err.code}: ${err.message || 'Unknown'}`
      }
      return String(error)
    } catch {
      return 'Unknown error'
    }
  }
}

// ==================== AbortController 兼容 ====================
// HarmonyOS 基础库已包含 AbortController，这里仅作类型兼容

declare class AbortController {
  signal: AbortSignal
  abort(): void
}

declare class AbortSignal {
  aborted: boolean
}
