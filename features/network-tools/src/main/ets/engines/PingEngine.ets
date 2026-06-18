// Ping 引擎 — 网络连通性检测
// 使用 TCP 连接实现类似 Ping 的延迟检测
// 适配 @kit.NetworkKit API

import { http, socket, connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { PingResult, PingStats, PingConfig, PingCallbacks } from '../models/ToolModels'

// 内部接口
interface TcpPingResult {
  success: boolean
  error: string
}

export class PingEngine {
  private isRunning: boolean = false
  private results: PingResult[] = []

  // 获取默认配置
  static getDefaultConfig(host: string): PingConfig {
    const config: PingConfig = {
      host: host,
      count: 4,
      timeout: 3000,
      interval: 1000
    }
    return config
  }

  // 计算统计信息
  static calcStats(results: PingResult[]): PingStats {
    const successResults: PingResult[] = []
    for (let i = 0; i < results.length; i++) {
      if (results[i].status === 'success') {
        successResults.push(results[i])
      }
    }
    const sent: number = results.length
    const received: number = successResults.length
    const lost: number = sent - received
    const lossRate: number = sent > 0 ? Math.round((lost / sent) * 100) : 0

    let minTime: number = 0
    let maxTime: number = 0
    let totalTime: number = 0

    if (successResults.length > 0) {
      minTime = successResults[0].time
      maxTime = successResults[0].time
      for (let j = 0; j < successResults.length; j++) {
        const t: number = successResults[j].time
        totalTime = totalTime + t
        if (t < minTime) minTime = t
        if (t > maxTime) maxTime = t
      }
    }

    const avgTime: number = successResults.length > 0 ? Math.round(totalTime / successResults.length) : 0

    const stats: PingStats = {
      sent: sent, received: received, lost: lost, lossRate: lossRate,
      minTime: minTime, maxTime: maxTime, avgTime: avgTime, totalTime: totalTime
    }
    return stats
  }

  // 验证是否为有效 IPv4
  private static isValidIpv4(address: string): boolean {
    const octets: string[] = address.split('.')
    if (octets.length !== 4) return false
    for (let i = 0; i < 4; i++) {
      const num: number = parseInt(octets[i], 10)
      if (isNaN(num) || num < 0 || num > 255 || octets[i] !== String(num)) return false
    }
    return true
  }

  // 解析主机名为 IP 地址
  async resolveHost(host: string): Promise<string> {
    if (PingEngine.isValidIpv4(host)) {
      return host
    }

    try {
      const netConnection: connection.NetConnection = connection.createNetConnection()
      const netHandle: connection.NetHandle | null = await connection.getDefaultNet()
      if (netHandle) {
        const addresses: Array<connection.NetAddress> = await netHandle.getAddressesByName(host)
        if (addresses && addresses.length > 0 && addresses[0].address) {
          return addresses[0].address
        }
      }
    } catch (e) {
      // DNS 解析失败，直接返回原始主机名
    }

    return host
  }

  // 执行单次 Ping（TCP 连接方式）
  async pingOnce(index: number, host: string, timeout: number): Promise<PingResult> {
    const startTime: number = Date.now()
    let resolvedAddress: string = ''

    try {
      resolvedAddress = await this.resolveHost(host)

      const result: TcpPingResult = await this.tcpPing(resolvedAddress, timeout)
      const endTime: number = Date.now()
      const time: number = endTime - startTime

      const pingResult: PingResult = {
        index: index,
        host: host,
        address: resolvedAddress,
        time: time,
        ttl: 64,
        status: result.success ? 'success' : 'timeout',
        errorMessage: result.error || ''
      }
      return pingResult
    } catch (e) {
      const endTime: number = Date.now()
      const time: number = endTime - startTime

      const errorResult: PingResult = {
        index: index,
        host: host,
        address: resolvedAddress || host,
        time: -1,
        ttl: 0,
        status: 'error',
        errorMessage: this.getErrorMessage(e)
      }
      return errorResult
    }
  }

  // TCP Ping 实现
  private tcpPing(address: string, timeout: number): Promise<TcpPingResult> {
    return new Promise((resolve: (v: TcpPingResult) => void) => {
      let tcpSocket: socket.TCPSocket = socket.constructTCPSocketInstance()
      let timeoutId: number = -1
      let resolved: boolean = false

      timeoutId = setTimeout((): void => {
        if (resolved) return
        resolved = true
        try {
          tcpSocket.close((): void => {})
        } catch (e) {}
        const timeoutResult: TcpPingResult = { success: false, error: 'timeout' }
        resolve(timeoutResult)
      }, timeout)

      tcpSocket.connect({
        address: {
          address: address,
          port: 443
        },
        timeout: timeout
      }, (err: BusinessError): void => {
        if (resolved) return
        clearTimeout(timeoutId)
        if (!err) {
          resolved = true
          tcpSocket.close((): void => {})
          const successResult: TcpPingResult = { success: true, error: '' }
          resolve(successResult)
        } else {
          this.tryPort80(address, timeout, resolved, resolve)
        }
      })
    })
  }

  // 尝试连接到 80 端口
  private tryPort80(
    address: string,
    timeout: number,
    alreadyResolved: boolean,
    resolve: (v: TcpPingResult) => void
  ): void {
    if (alreadyResolved) return
    let tcpSocket: socket.TCPSocket = socket.constructTCPSocketInstance()
    let timeoutId: number = -1
    let resolved: boolean = false

    timeoutId = setTimeout((): void => {
      if (resolved) return
      resolved = true
      try {
        tcpSocket.close((): void => {})
      } catch (e) {}
      const timeoutResult: TcpPingResult = { success: false, error: 'port_closed' }
      resolve(timeoutResult)
    }, timeout)

    tcpSocket.connect({
      address: {
        address: address,
        port: 80
      },
      timeout: timeout
    }, (err: BusinessError): void => {
      if (resolved) return
      resolved = true
      clearTimeout(timeoutId)
      if (!err) {
        tcpSocket.close((): void => {})
        const successResult: TcpPingResult = { success: true, error: '' }
        resolve(successResult)
      } else {
        tcpSocket.close((): void => {})
        const failResult: TcpPingResult = { success: false, error: 'port_closed' }
        resolve(failResult)
      }
    })
  }

  // 开始 Ping
  async startPing(config: PingConfig, callbacks?: PingCallbacks): Promise<void> {
    if (this.isRunning) {
      if (callbacks && callbacks.onError) {
        callbacks.onError('Ping already running')
      }
      return
    }

    this.isRunning = true
    this.results = []

    const host: string = config.host
    const count: number = config.count
    const timeout: number = config.timeout
    const interval: number = config.interval

    try {
      if (callbacks && callbacks.onProgress) {
        callbacks.onProgress(0, 0)
      }

      for (let i = 0; i < count; i++) {
        if (!this.isRunning) break

        const result: PingResult = await this.pingOnce(i + 1, host, timeout)
        this.results.push(result)

        if (callbacks && callbacks.onResult) {
          callbacks.onResult(result)
        }
        if (callbacks && callbacks.onProgress) {
          callbacks.onProgress(i + 1, result.status === 'success' ? 1 : 0)
        }

        if (i < count - 1 && this.isRunning) {
          await this.sleep(interval)
        }
      }

      const stats: PingStats = PingEngine.calcStats(this.results)
      if (callbacks && callbacks.onComplete) {
        callbacks.onComplete(this.results, stats)
      }
    } catch (e) {
      if (callbacks && callbacks.onError) {
        callbacks.onError(this.getErrorMessage(e))
      }
    } finally {
      this.isRunning = false
    }
  }

  // 停止 Ping
  stopPing(): void {
    this.isRunning = false
  }

  // 工具方法
  private sleep(ms: number): Promise<void> {
    return new Promise((resolve: () => void) => setTimeout(resolve, ms))
  }

  private getErrorMessage(error: Object): string {
    try {
      return String(error)
    } catch (e) {
      return 'Unknown error'
    }
  }
}
