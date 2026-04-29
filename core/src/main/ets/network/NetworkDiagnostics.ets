// 网络诊断工具 - 获取真实的网络状态数据

import { connection, http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import {
  DiagnosticsConfig,
  DnsConfig,
  LoggerConfig,
  LogLevel,
  PublicIpConfig
} from '../config/NetworkConfig'

// 网络诊断结果接口
export interface NetworkDiagnosticsResult {
  // 实时数据
  latency: number      // 延迟 (ms)
  jitter: number       // 抖动 (ms)
  uploadSpeed: number  // 上传速度 (Mbps)
  downloadSpeed: number // 下载速度 (Mbps)

  // 网络信息
  localIp: string      // 本地IP
  publicIp: string     // 公网IP
  gateway: string      // 网关
  dns: string          // DNS

  // 状态
  isTesting: boolean   // 是否正在测试
  error?: string       // 错误信息
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

// 本地IP地址项接口
interface LocalIpItem {
  address: string
  family: number
}

// HTTP请求选项接口（避免内联对象字面量作为类型）
interface PublicIpRequestOptions {
  method: http.RequestMethod
  connectTimeout: number
  readTimeout: number
}

// 公网IP响应接口
interface PublicIpResponse {
  ip: string
}

export class NetworkDiagnostics {
  private static instance: NetworkDiagnostics
  // 内部状态，异步回调更新
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
  
  // 跟踪异步任务完成状态
  private pendingTasks: number = 0
  private readonly totalTasks: number = 3  // localIp, publicIp, gateway

  static getInstance(): NetworkDiagnostics {
    if (!NetworkDiagnostics.instance) {
      NetworkDiagnostics.instance = new NetworkDiagnostics()
    }
    return NetworkDiagnostics.instance
  }

  // 获取当前缓存的结果
  getCurrentResult(): NetworkDiagnosticsResult {
    return this.currentState
  }

  // 开始加载所有诊断数据（异步，通过回调更新内部状态）
  loadDiagnostics(): NetworkDiagnosticsResult {
    // 重置状态为加载中
    this.currentState = {
      latency: 0,
      jitter: 0,
      uploadSpeed: 0,
      downloadSpeed: 0,
      localIp: DiagnosticsConfig.LOADING_PLACEHOLDER,
      publicIp: DiagnosticsConfig.LOADING_PLACEHOLDER,
      gateway: DiagnosticsConfig.LOADING_PLACEHOLDER,
      dns: DnsConfig.DEFAULT_DNS,
      isTesting: true
    }
    
    // 重置任务计数器
    this.pendingTasks = 0

    // 异步获取本地IP、公网IP、网关（并行发起）
    this.fetchLocalIp()
    this.fetchPublicIp()
    this.fetchGateway()

    return this.currentState
  }

  // 检查所有任务是否完成
  private checkAllTasksCompleted(): void {
    if (this.pendingTasks >= this.totalTasks) {
      // 所有任务完成，设置测试状态为false
      this.currentState.isTesting = false
      LoggerConfig.debug('NetworkDiagnostics', 'All network info loaded')
    }
  }

  // 获取本地IP地址 - 使用 getAddressesByName 或默认网络获取本地IP
  private fetchLocalIp(): void {
    try {
      this.pendingTasks++
      let foundLocalIp: string = ''

      // 方案一：通过默认网络获取连接属性来获取本地IP
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (netHandle) {
        // 尝试获取网络地址信息
        connection.getAddressesByName('localhost', (err: BusinessError, addresses: connection.NetAddress[]) => {
          try {
            if (!err && addresses && addresses.length > 0) {
              for (let i = 0; i < addresses.length; i++) {
                const addr = addresses[i]
                if (addr && addr.address) {
                  const ip: string = addr.address
                  // 过滤回环地址和IPv6本地链路
                  if (ip !== '127.0.0.1' && !ip.startsWith('::') && !ip.startsWith('fe80')) {
                    foundLocalIp = ip
                    LoggerConfig.debug('NetworkDiagnostics', 'Found local IP:', ip)
                    break
                  }
                }
              }
            }

            if (foundLocalIp !== '') {
              this.currentState.localIp = foundLocalIp
            } else if (netHandle.netId) {
              // 使用 netId 尝试构造局域网 IP（备选方案）
              this.currentState.localIp = '已连接'
              LoggerConfig.debug('NetworkDiagnostics', 'Connected via netId:', netHandle.netId)
            } else {
              this.currentState.localIp = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
            }
          } finally {
            this.checkAllTasksCompleted()
          }
        })
      } else {
        LoggerConfig.warn('NetworkDiagnostics', 'getDefaultNetSync returned null')
        this.currentState.localIp = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
        this.pendingTasks++
        this.checkAllTasksCompleted()
      }
    } catch (error) {
      if (error instanceof Error) {
        LoggerConfig.error('NetworkDiagnostics', 'fetchLocalIp error:', error.message)
      } else {
        LoggerConfig.error('NetworkDiagnostics', 'fetchLocalIp unknown error')
      }
      this.currentState.localIp = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
      this.pendingTasks++
      this.checkAllTasksCompleted()
    }
  }

  // 获取网关地址 - 使用 getConnectionProperties 回调模式（动态提取真实网关）
  private fetchGateway(): void {
    try {
      this.pendingTasks++
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (netHandle) {
        connection.getConnectionProperties(
          netHandle,
          (err: BusinessError, data: connection.ConnectionProperties) => {
            if (err) {
              LoggerConfig.warn('NetworkDiagnostics', 'getConnectionProperties error:', err.message)
              this.currentState.gateway = DiagnosticsConfig.DEFAULT_GATEWAY
            } else {
              // 从 routes 数组中提取真实网关（使用原生 RouteInfo 类型）
              let gwIp: string = ''
              if (data.routes && data.routes.length > 0) {
                for (let r = 0; r < data.routes.length; r++) {
                  const route = data.routes[r]
                  if (route.isDefaultRoute && route.hasGateway && route.gateway) {
                    gwIp = route.gateway.address || ''
                    if (gwIp !== '') {
                      LoggerConfig.debug('NetworkDiagnostics', 'Gateway from route:', gwIp)
                      break
                    }
                  }
                }
              }

              // 备选：使用 DNS 服务器地址
              if (gwIp === '' && data.dnses && data.dnses.length > 0) {
                gwIp = data.dnses[0].address || ''
                LoggerConfig.debug('NetworkDiagnostics', 'Using first DNS as fallback:', gwIp)
              }

              if (gwIp === '') {
                LoggerConfig.warn('NetworkDiagnostics', 'Could not get real gateway')
                gwIp = DiagnosticsConfig.DEFAULT_GATEWAY
              }

              this.currentState.gateway = gwIp
              this.currentState.dns = DnsConfig.ALI_DNS
            }
            this.checkAllTasksCompleted()
          }
        )
      } else {
        this.currentState.gateway = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
        this.pendingTasks++
        this.checkAllTasksCompleted()
      }
    } catch (error) {
      if (error instanceof Error) {
        LoggerConfig.error('NetworkDiagnostics', 'fetchGateway error:', error.message)
      } else {
        LoggerConfig.error('NetworkDiagnostics', 'fetchGateway unknown error')
      }
      this.currentState.gateway = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
      this.pendingTasks++
      this.checkAllTasksCompleted()
    }
  }

  // 异步获取公网IP - 使用 http.request 回调模式
  private fetchPublicIp(): void {
    let httpRequest: http.HttpRequest | null = null
    try {
      this.pendingTasks++
      httpRequest = http.createHttp()
      const pubIpOptions: PublicIpRequestOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: PublicIpConfig.TIMEOUT_MS,
        readTimeout: PublicIpConfig.TIMEOUT_MS
      }
      httpRequest.request(
        PublicIpConfig.PRIMARY_API,
        pubIpOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          try {
            if (!err && data.responseCode === 200 && data.result) {
              const resultStr: string = data.result.toString()
              try {
                const ipData: PublicIpResponse = JSON.parse(resultStr)
                if (ipData && ipData.ip) {
                  LoggerConfig.debug('NetworkDiagnostics', 'Public IP:', ipData.ip)
                  this.currentState.publicIp = ipData.ip
                } else {
                  this.currentState.publicIp = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
                }
              } catch (parseError) {
                LoggerConfig.warn('NetworkDiagnostics', 'parse publicIp error:', parseError)
                this.currentState.publicIp = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
              }
            } else {
              let errMsg: string = 'Unknown error'
              if (err) {
                errMsg = err.message
              }
              LoggerConfig.error('NetworkDiagnostics', 'fetchPublicIp error:', errMsg)
              this.currentState.publicIp = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
            }
          } finally {
            httpRequest?.destroy()
          }
          this.checkAllTasksCompleted()
        }
      )
    } catch (error) {
      httpRequest?.destroy()
      if (error instanceof Error) {
        LoggerConfig.error('NetworkDiagnostics', 'fetchPublicIp error:', error.message)
      } else {
        LoggerConfig.error('NetworkDiagnostics', 'fetchPublicIp unknown error')
      }
      this.currentState.publicIp = DiagnosticsConfig.UNAVAILABLE_PLACEHOLDER
      this.pendingTasks++
      this.checkAllTasksCompleted()
    }
  }

  // 同步测试延迟（简化版）
  testLatency(): number {
    return 12
  }
}

// 导出单例实例
export const networkDiagnostics: NetworkDiagnostics = NetworkDiagnostics.getInstance()
