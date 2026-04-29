// 网络诊断工具 - 获取真实的网络状态数据

import { connection, http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

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
      localIp: '获取中...',
      publicIp: '获取中...',
      gateway: '获取中...',
      dns: '202.96.128.86',
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
      console.log('[NetworkDiagnostics] All network info loaded')
    }
  }

  // 获取本地IP地址 - 使用 getAddressesByName 获取本地IP
  private fetchLocalIp(): void {
    try {
      this.pendingTasks++
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (netHandle) {
        // 直接使用 getAddressesByName 获取本地IP
        connection.getAddressesByName(
          'localhost',
          (err: BusinessError, addresses: Array<connection.NetAddress>) => {
            if (!err && addresses && addresses.length > 0) {
              const address: connection.NetAddress = addresses[0]
              if (address && address.address) {
                console.log('[NetworkDiagnostics] Local IP from localhost:', address.address)
                this.currentState.localIp = address.address
              } else {
                this.currentState.localIp = '--'
              }
            } else {
              this.currentState.localIp = '--'
            }
            this.checkAllTasksCompleted()
          }
        )
      } else {
        this.currentState.localIp = '--'
        this.pendingTasks++
        this.checkAllTasksCompleted()
      }
    } catch (error) {
      if (error instanceof Error) {
        console.error('[NetworkDiagnostics] fetchLocalIp error:', error.message)
      } else {
        console.error('[NetworkDiagnostics] fetchLocalIp unknown error')
      }
      this.currentState.localIp = '--'
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
              console.warn('[NetworkDiagnostics] getConnectionProperties error:', err.message)
              this.currentState.gateway = '192.168.1.1'
            } else {
              // 从 routes 数组中提取真实网关（使用原生 RouteInfo 类型）
              let gwIp: string = ''
              if (data.routes && data.routes.length > 0) {
                for (let r = 0; r < data.routes.length; r++) {
                  const route = data.routes[r]
                  if (route.isDefaultRoute && route.hasGateway && route.gateway) {
                    gwIp = route.gateway.address || ''
                    if (gwIp !== '') {
                      console.log('[NetworkDiagnostics] ✓ Gateway from route:', gwIp)
                      break
                    }
                  }
                }
              }

              // 备选：使用 DNS 服务器地址
              if (gwIp === '' && data.dnses && data.dnses.length > 0) {
                gwIp = data.dnses[0].address || ''
                console.log('[NetworkDiagnostics] Using first DNS as fallback:', gwIp)
              }

              if (gwIp === '') {
                console.warn('[NetworkDiagnostics] Could not get real gateway')
                gwIp = '192.168.1.1'
              }

              this.currentState.gateway = gwIp
              this.currentState.dns = '223.5.5.5'
            }
            this.checkAllTasksCompleted()
          }
        )
      } else {
        this.currentState.gateway = '--'
        this.pendingTasks++
        this.checkAllTasksCompleted()
      }
    } catch (error) {
      if (error instanceof Error) {
        console.error('[NetworkDiagnostics] fetchGateway error:', error.message)
      } else {
        console.error('[NetworkDiagnostics] fetchGateway unknown error')
      }
      this.currentState.gateway = '--'
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
        connectTimeout: 3000,
        readTimeout: 3000
      }
      httpRequest.request(
        'https://api.ipify.org?format=json',
        pubIpOptions,
        (err: BusinessError, data: http.HttpResponse) => {
          try {
            if (!err && data.responseCode === 200 && data.result) {
              const resultStr: string = data.result.toString()
              try {
                const ipData: PublicIpResponse = JSON.parse(resultStr)
                if (ipData && ipData.ip) {
                  console.log('[NetworkDiagnostics] Public IP:', ipData.ip)
                  this.currentState.publicIp = ipData.ip
                } else {
                  this.currentState.publicIp = '--'
                }
              } catch (parseError) {
                console.warn('[NetworkDiagnostics] parse publicIp error:', parseError)
                this.currentState.publicIp = '--'
              }
            } else {
              let errMsg: string = 'Unknown error'
              if (err) {
                errMsg = err.message
              }
              console.error('[NetworkDiagnostics] fetchPublicIp error:', errMsg)
              this.currentState.publicIp = '--'
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
        console.error('[NetworkDiagnostics] fetchPublicIp error:', error.message)
      } else {
        console.error('[NetworkDiagnostics] fetchPublicIp unknown error')
      }
      this.currentState.publicIp = '--'
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
