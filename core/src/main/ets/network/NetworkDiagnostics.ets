// 网络诊断工具 - 获取真实的网络状态数据

import { connection, http } from '@kit.NetworkKit'
import { wifiManager } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { PublicIpConfig } from '../config/NetworkConfig'

const DOMAIN = 0xFF00
const TAG = 'NetworkDiagnostics'

// 简单的日志函数
function logInfo(msg: string): void {
  hilog.info(DOMAIN, TAG, msg)
}
function logWarn(msg: string): void {
  hilog.warn(DOMAIN, TAG, msg)
}

// 网络诊断结果接口
export interface NetworkDiagnosticsResult {
  latency: number
  jitter: number
  uploadSpeed: number
  downloadSpeed: number
  localIp: string
  publicIp: string
  gateway: string
  dns: string
  isTesting: boolean
  error?: string
}

// 默认结果
export const defaultDiagnosticsResult: NetworkDiagnosticsResult = {
  latency: 0,
  jitter: 0,
  uploadSpeed: 0,
  downloadSpeed: 0,
  localIp: '--',
  publicIp: '--',
  gateway: '--',
  dns: '--',
  isTesting: false
}

export class NetworkDiagnostics {
  private static instance: NetworkDiagnostics
  private currentState: NetworkDiagnosticsResult = {
    latency: 0,
    jitter: 0,
    uploadSpeed: 0,
    downloadSpeed: 0,
    localIp: '--',
    publicIp: '--',
    gateway: '--',
    dns: '--',
    isTesting: false
  }

  // 完成回调
  private onComplete?: (result: NetworkDiagnosticsResult) => void

  // 任务完成计数器（localIp, gateway, publicIp 三个任务）
  private completedTasks: number = 0
  private totalTasks: number = 3

  static getInstance(): NetworkDiagnostics {
    if (!NetworkDiagnostics.instance) {
      NetworkDiagnostics.instance = new NetworkDiagnostics()
    }
    return NetworkDiagnostics.instance
  }

  getCurrentResult(): NetworkDiagnosticsResult {
    return this.currentState
  }

  // 开始诊断
  startDiagnostics(onComplete?: (result: NetworkDiagnosticsResult) => void): void {
    this.onComplete = onComplete

    // 重置为加载中状态
    this.currentState = {
      latency: 0,
      jitter: 0,
      uploadSpeed: 0,
      downloadSpeed: 0,
      localIp: '获取中...',
      publicIp: '获取中...',
      gateway: '获取中...',
      dns: '获取中...',
      isTesting: true
    }
    this.completedTasks = 0

    logInfo('Starting diagnostics...')

    // 并行执行三个任务
    this.fetchLocalIp()
    this.fetchGateway()
    this.fetchPublicIp()
  }

  // 提取IP地址（从各种响应格式）
  private extractIp(text: string): string {
    if (!text) {
      return ''
    }
    // 直接匹配IP地址
    const match = text.match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)
    return match ? match[1] : ''
  }

  // 获取本地IP - 简化版本，只用 wifiManager.getIpInfo()
  private fetchLocalIp(): void {
    try {
      const ipInfo = wifiManager.getIpInfo()
      if (ipInfo && ipInfo.ipAddress && ipInfo.ipAddress !== 0) {
        const ip: string = ((ipInfo.ipAddress >>> 24) & 0xFF) + '.' +
                   ((ipInfo.ipAddress >> 16) & 0xFF) + '.' +
                   ((ipInfo.ipAddress >> 8) & 0xFF) + '.' +
                   (ipInfo.ipAddress & 0xFF)
          if (ip !== '0.0.0.0') {
            this.currentState.localIp = ip
            logInfo('Local IP fetched successfully')
            this.markTaskComplete()
            return
          }
      }
    } catch (e) {
      const err: Error = e as Error
      logWarn('wifiManager.getIpInfo failed: ' + err.message)
    }
    this.currentState.localIp = '--'
    logInfo('fetchLocalIp completed: --')
    this.markTaskComplete()
  }

  // 获取网关和DNS - 使用同步API
  private fetchGateway(): void {
    try {
      const netHandle = connection.getDefaultNetSync()
      if (netHandle && netHandle.netId !== 0) {
        // 使用同步方法获取连接属性
        const connectionProperties: connection.ConnectionProperties = connection.getConnectionPropertiesSync(netHandle)
        if (connectionProperties) {
          // 获取网关
          let gateway = ''
          if (connectionProperties.routes) {
            for (let i = 0; i < connectionProperties.routes.length; i++) {
              const route = connectionProperties.routes[i]
              if (route && route.isDefaultRoute && route.hasGateway && route.gateway) {
                const gatewayAddr: connection.NetAddress = route.gateway as connection.NetAddress
                gateway = gatewayAddr.address || ''
                if (gateway) {
                  break
                }
              }
            }
          }
          // 获取DNS
          let dns = ''
          if (connectionProperties.dnses) {
            for (let i = 0; i < connectionProperties.dnses.length; i++) {
              const d = connectionProperties.dnses[i]
              if (d && d.address && !d.address.startsWith('::') && d.address !== '0.0.0.0') {
                dns = d.address
                break
              }
            }
          }

          this.currentState.gateway = gateway || '--'
          this.currentState.dns = dns || '--'
          // 脱敏：不在日志中输出可能的敏感网络信息
          logInfo('Gateway and DNS fetched successfully')
        }
        this.markTaskComplete()
        return
      }
    } catch (e) {
      const err: Error = e as Error
      logWarn('fetchGateway error: ' + err.message)
    }

    this.currentState.gateway = '--'
    this.currentState.dns = '--'
    this.markTaskComplete()
  }

  // 获取公网IP - 使用Promise版本，更可靠
  private async fetchPublicIp(): Promise<void> {
    const apis = [
      PublicIpConfig.PRIMARY_API,
      PublicIpConfig.FALLBACK_API,
      PublicIpConfig.THIRD_API,
    ]

    for (let i = 0; i < apis.length; i++) {
      try {
        const request = http.createHttp()
        const result: http.HttpResponse = await request.request(apis[i], {
          method: http.RequestMethod.GET,
          connectTimeout: 3000,
          readTimeout: 3000
        } as http.HttpRequestOptions)
        
        request.destroy()
        
        if (result.responseCode === 200 && result.result) {
          const ip: string = this.extractIp(result.result.toString())
          if (ip) {
            this.currentState.publicIp = ip
            logInfo('Public IP: ' + ip)
            this.markTaskComplete()
            return
          }
        }
        logWarn('API ' + apis[i] + ' failed, trying next...')
      } catch (e) {
        const err: Error = e as Error
        logWarn('API ' + apis[i] + ' error: ' + err.message)
      }
    }

    logWarn('All public IP APIs failed')
    this.currentState.publicIp = '--'
    this.markTaskComplete()
  }

  // 标记单个任务完成，当所有任务完成后通知
  private markTaskComplete(): void {
    this.completedTasks++
    logInfo('Task completed: ' + this.completedTasks + '/' + this.totalTasks)
    if (this.completedTasks >= this.totalTasks) {
      this.notifyComplete()
    }
  }

  private notifyComplete(): void {
    this.currentState.isTesting = false
    logInfo('Diagnostics complete')

    if (this.onComplete) {
      const result = this.currentState
      this.onComplete({
        latency: result.latency,
        jitter: result.jitter,
        uploadSpeed: result.uploadSpeed,
        downloadSpeed: result.downloadSpeed,
        localIp: result.localIp,
        publicIp: result.publicIp,
        gateway: result.gateway,
        dns: result.dns,
        isTesting: result.isTesting,
        error: result.error
      })
    }
  }
}

export const networkDiagnostics: NetworkDiagnostics = NetworkDiagnostics.getInstance()
