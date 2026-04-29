// 局域网扫描引擎
// 通过 HTTP 探测发现局域网内活跃设备
// HarmonyOS 无原生 ARP/Ping 能力，使用 HTTP HEAD 请求扫描网段

import { http } from '@kit.NetworkKit'
import { connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

// 扫描发现的设备
export interface LanDevice {
  ip: string               // IP 地址
  mac: string              // MAC 地址 (如果能获取)
  hostname: string         // 主机名
  status: 'online' | 'offline' | 'scanning'
  vendor: string           // 厂商信息
  port: number             // 响应端口
  latency: number          // 响应延迟 (ms)
  firstSeen: number        // 首次发现时间
  lastSeen: number         // 最后在线时间
}

// 扫描进度回调
export interface LanScanCallbacks {
  onProgress: (scanned: number, total: number, currentIp: string) => void
  onDeviceFound: (device: LanDevice) => void
  onComplete: (devices: LanDevice[]) => void
  onError: (message: string) => void
}

// 网络信息
export interface LanNetworkInfo {
  localIp: string
  gateway: string
  subnetMask: string
  networkPrefix: string    // 如 "192.168.1"
  hostCount: number
}

// HTTP 请求选项接口
interface LanHttpOptions {
  method: http.RequestMethod
  connectTimeout: number
  readTimeout: number
}

export class LanEngine {
  private abortController: boolean = false
  private cachedNetworkInfo: LanNetworkInfo | null = null

  /**
   * 检测网关地址
   */
  async detectNetworkInfo(): Promise<LanNetworkInfo> {
    if (this.cachedNetworkInfo) return this.cachedNetworkInfo

    try {
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (!netHandle) {
        const fallback: LanNetworkInfo = {
          localIp: '', gateway: '192.168.1.1', subnetMask: '255.255.255.0',
          networkPrefix: '192.168.1', hostCount: 254
        }
        return fallback
      }

      const info: LanNetworkInfo = await new Promise<LanNetworkInfo>((resolve: (v: LanNetworkInfo) => void) => {
        connection.getConnectionProperties(
          netHandle,
          (err: BusinessError, data: connection.ConnectionProperties): void => {
            if (err || !data) {
              resolve({
                localIp: '', gateway: '192.168.1.1', subnetMask: '255.255.255.0',
                networkPrefix: '192.168.1', hostCount: 254
              })
              return
            }

            let localIp: string = ''
            let gwIp: string = '192.168.1.1'
            let netPrefix: string = '192.168.1'

            // 获取本地 IP
            if (data.linkAddresses && data.linkAddresses.length > 0) {
              localIp = data.linkAddresses[0].address.address || ''
              if (localIp.length > 0) {
                // 提取网络前缀
                const parts: string[] = localIp.split('.')
                if (parts.length === 4) {
                  netPrefix = parts[0] + '.' + parts[1] + '.' + parts[2]
                }
              }
            }

            // 获取网关
            if (data.routes && data.routes.length > 0) {
              for (let r = 0; r < data.routes.length; r++) {
                const route = data.routes[r]
                if (route.isDefaultRoute === true && route.hasGateway === true && route.gateway !== undefined) {
                  const addr: string = route.gateway.address || ''
                  if (addr.length > 0) {
                    gwIp = addr
                  }
                  break
                }
              }
            }

            const result: LanNetworkInfo = {
              localIp: localIp,
              gateway: gwIp,
              subnetMask: '255.255.255.0',
              networkPrefix: netPrefix,
              hostCount: 254
            }
            resolve(result)
          }
        )
      })

      this.cachedNetworkInfo = info
      return info
    } catch (e) {
      const fallback: LanNetworkInfo = {
        localIp: '', gateway: '192.168.1.1', subnetMask: '255.255.255.0',
        networkPrefix: '192.168.1', hostCount: 254
      }
      return fallback
    }
  }

  /**
   * 探测单个 IP 是否在线
   */
  public async probeHost(ip: string, port: number, timeout: number): Promise<LanDevice | null> {
    const startTime: number = Date.now()

    try {
      const req = http.createHttp()
      const options: LanHttpOptions = {
        method: http.RequestMethod.HEAD,
        connectTimeout: timeout,
        readTimeout: timeout,
      }

      let timeoutTimerId: number = -1

      await new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
        req.request(
          'http://' + ip + ':' + String(port),
          options,
          (err: BusinessError, resp: http.HttpResponse): void => {
            if (timeoutTimerId >= 0) {
              clearTimeout(timeoutTimerId)
              timeoutTimerId = -1
            }
            req.destroy()
            // 无论成功失败，只要能连上就认为在线
            resolve()
          }
        )
        timeoutTimerId = setTimeout((): void => {
          req.destroy()
          reject(new Error('timeout'))
        }, timeout + 500)
      })

      const device: LanDevice = {
        ip: ip, mac: '', hostname: '', status: 'online',
        vendor: '', port: port, latency: Date.now() - startTime,
        firstSeen: Date.now(), lastSeen: Date.now()
      }
      return device
    } catch (e) {
      return null
    }
  }

  /**
   * 执行局域网扫描（并行探测，控制并发数）
   */
  async scan(callbacks: LanScanCallbacks): Promise<void> {
    this.abortController = false
    const devices: LanDevice[] = []
    const maxConcurrency: number = 30
    const timeout: number = 1500
    const scanPorts: number[] = [80, 443, 8080, 7681, 3000, 8443]

    // 获取网络信息
    const networkInfo: LanNetworkInfo = await this.detectNetworkInfo()
    const prefix: string = networkInfo.networkPrefix
    const total: number = 254

    // 分批并行扫描
    for (let batchStart = 0; batchStart < total; batchStart += maxConcurrency) {
      if (this.abortController) {
        callbacks.onError('扫描已停止')
        return
      }

      const batchEnd: number = Math.min(batchStart + maxConcurrency, total)
      const batchPromises: Array<Promise<LanDevice | null>> = []

      for (let host = batchStart + 1; host <= batchEnd; host++) {
        const ip: string = prefix + '.' + String(host)
        // 尝试多个端口
        batchPromises.push(this.probeWithPortFallback(ip, scanPorts, timeout))
        callbacks.onProgress(host, total, ip)
      }

      const batchResults: Array<LanDevice | null> = await Promise.all(batchPromises)

      for (let j = 0; j < batchResults.length; j++) {
        if (batchResults[j]) {
          devices.push(batchResults[j] as LanDevice)
          callbacks.onDeviceFound(batchResults[j] as LanDevice)
        }
      }
    }

    // 排序：按 IP 地址
    devices.sort((a: LanDevice, b: LanDevice): number => {
      return this.ipToNumber(a.ip) - this.ipToNumber(b.ip)
    })

    callbacks.onComplete(devices)
  }

  /**
   * 多端口回退探测
   */
  private async probeWithPortFallback(ip: string, ports: number[], timeout: number): Promise<LanDevice | null> {
    // 缩短单个端口超时
    const perPortTimeout: number = Math.max(500, Math.floor(timeout / 2))

    for (let p = 0; p < ports.length; p++) {
      if (this.abortController) return null
      const device: LanDevice | null = await this.probeHost(ip, ports[p], perPortTimeout)
      if (device) {
        device.port = ports[p]
        return device
      }
    }
    return null
  }

  /**
   * 停止扫描
   */
  stopScan(): void {
    this.abortController = true
  }

  /**
   * IP 转数字（排序用）
   */
  private ipToNumber(ip: string): number {
    const octets: string[] = ip.split('.')
    if (octets.length !== 4) return 0
    return ((parseInt(octets[0], 10) << 24) | (parseInt(octets[1], 10) << 16) |
      (parseInt(octets[2], 10) << 8) | parseInt(octets[3], 10)) >>> 0
  }

  /**
   * 判断是否为网关 IP
   */
  static isGateway(ip: string, gateway: string): boolean {
    return ip === gateway
  }

  /**
   * 判断是否为本机 IP
   */
  static isLocalHost(ip: string, localIp: string): boolean {
    return ip === localIp || ip === '127.0.0.1'
  }

  /**
   * 获取设备类型推测
   */
  static guessDeviceType(device: LanDevice): string {
    if (LanEngine.isGateway(device.ip, '')) return 'router'
    if (device.port === 80 || device.port === 443 || device.port === 8080) return 'server'
    if (device.port === 7681) return 'phone' // HarmonyOS 分布式端口
    return 'unknown'
  }
}
