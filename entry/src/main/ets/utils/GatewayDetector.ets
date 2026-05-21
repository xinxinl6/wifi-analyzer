// 网关检测工具

import { http, connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * 网关检测结果
 */
export interface GatewayDetectionResult {
  gateway: string
  dns: string
  status: 'loading' | 'ready' | 'failed'
}

/**
 * GatewayDetector - 网关和 DNS 检测工具类
 */
export class GatewayDetector {
  private static readonly DEFAULT_GATEWAY: string = '192.168.1.1'
  private static readonly DEFAULT_DNS: string = '223.5.5.5'

  /**
   * 检测默认网关和 DNS 服务器
   * @param callback 回调函数，接收检测结果
   */
  static detect(callback: (result: GatewayDetectionResult) => void): void {
    callback({ gateway: '', dns: '', status: 'loading' })

    try {
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (!netHandle) {
        callback({ gateway: '', dns: '', status: 'failed' })
        return
      }

      connection.getConnectionProperties(
        netHandle,
        (err: BusinessError, data: connection.ConnectionProperties): void => {
          if (err) {
            callback({ gateway: '', dns: '', status: 'failed' })
            return
          }

          let gwIp: string = ''
          if (data.routes && data.routes.length > 0) {
            for (let r = 0; r < data.routes.length; r++) {
              const route = data.routes[r]
              // 只检查 hasGateway + gateway，不强制要求 isDefaultRoute
              if (route && route.hasGateway && route.gateway !== undefined) {
                const gatewayAddr: connection.NetAddress = route.gateway as connection.NetAddress
                const addr: string = gatewayAddr.address || ''
                if (addr !== '') {
                  gwIp = addr
                  break
                }
              }
            }
          }

          let dnsIp: string = GatewayDetector.DEFAULT_DNS
          if (data.dnses && data.dnses.length > 0) {
            const firstDns = data.dnses[0]
            if (firstDns && firstDns.address && firstDns.address.length > 0) {
              dnsIp = firstDns.address
            }
          }

          if (gwIp !== '') {
            callback({
              gateway: gwIp,
              dns: dnsIp,
              status: 'ready'
            })
          } else {
            callback({ gateway: '', dns: dnsIp, status: 'failed' })
          }
        }
      )
    } catch (error) {
      callback({ gateway: '', dns: '', status: 'failed' })
    }
  }

  /**
   * 获取默认网关地址
   */
  static getDefaultGateway(): string {
    return GatewayDetector.DEFAULT_GATEWAY
  }

  /**
   * 获取默认 DNS 地址
   */
  static getDefaultDns(): string {
    return GatewayDetector.DEFAULT_DNS
  }
}
