// WiFi 服务抽象层
// 封装 HarmonyOS WiFi API，为未来迁移到新 API 做准备

import { wifiManager } from '@kit.ConnectivityKit'

// WiFi 扫描结果原始数据结构（用于接收 wifiManager 返回值）
interface RawScanInfo {
  ssid?: string
  bssid?: string
  rssi?: number
  frequency?: number
  securityType?: number
}

// WiFi 连接信息原始数据结构（用于接收 wifiManager 返回值）
interface RawLinkedInfo {
  ssid?: string
  bssid?: string
  rssi?: number
}

// WiFi 扫描信息接口
export interface WifiScanInfo {
  ssid: string
  bssid: string
  rssi: number
  frequency: number
  securityType: number
}

// WiFi 连接信息接口
export interface WifiLinkedInfo {
  ssid: string
  bssid: string
  rssi: number
}

// WiFi 服务接口
export interface IWifiService {
  // 开始扫描
  startScan(): Promise<void>

  // 获取扫描结果
  getScanResults(): Promise<WifiScanInfo[]>

  // 获取当前连接信息
  getLinkedInfo(): Promise<WifiLinkedInfo | null>
}

// 基于 HarmonyOS wifiManager API 的实现（API 标记为 deprecated 但功能正常）
export class DeprecatedWifiService implements IWifiService {
  async startScan(): Promise<void> {
    console.warn('[WifiService] Using deprecated startScan API')
    try {
      const scanResult = await wifiManager.startScan()
      console.log('[WifiService] startScan result:', scanResult)
    } catch (error) {
      console.error('[WifiService] startScan error:', JSON.stringify(error))
      if (error instanceof Error) {
        throw error
      } else {
        throw new Error(String(error))
      }
    }
  }

  async getScanResults(): Promise<WifiScanInfo[]> {
    console.warn('[WifiService] Using deprecated getScanResults API')
    try {
      const apiResult = await wifiManager.getScanResults()
      console.log('[WifiService] getScanResults raw result:', JSON.stringify(apiResult))
      const rawResults: RawScanInfo[] = apiResult as RawScanInfo[]
      console.log('[WifiService] getScanResults count:', rawResults.length)
      return rawResults.map((item: RawScanInfo): WifiScanInfo => ({
        ssid: item.ssid || '<隐藏网络>',
        bssid: item.bssid || '',
        rssi: item.rssi || -80,
        frequency: item.frequency || 0,
        securityType: item.securityType || 0
      }))
    } catch (error) {
      console.error('[WifiService] getScanResults error:', JSON.stringify(error))
      return []
    }
  }

  async getLinkedInfo(): Promise<WifiLinkedInfo | null> {
    console.warn('[WifiService] Using deprecated getLinkedInfo API')
    try {
      const apiResult = await wifiManager.getLinkedInfo()
      const linkedInfo: RawLinkedInfo | null = apiResult as RawLinkedInfo | null
      if (!linkedInfo) {
        return null
      }
      return {
        ssid: linkedInfo.ssid || '',
        bssid: linkedInfo.bssid || '',
        rssi: this.safeGetRssi(linkedInfo)
      }
    } catch (error) {
      console.error('[WifiService] getLinkedInfo error:', error)
      return null
    }
  }

  private safeGetRssi(linkedInfo: RawLinkedInfo): number {
    try {
      const rssiValue: number = (linkedInfo.rssi) as number
      if (rssiValue !== undefined && rssiValue !== null) {
        return rssiValue
      }
    } catch (_e) {
      // 静默失败
    }
    return -55
  }
}

// WiFi 服务工厂
export class WifiServiceFactory {
  private static instance: IWifiService | null = null

  static getService(): IWifiService {
    if (!WifiServiceFactory.instance) {
      WifiServiceFactory.instance = new DeprecatedWifiService()
    }
    return WifiServiceFactory.instance
  }

  // 未来可以添加 setService 方法以动态切换实现
  static setService(service: IWifiService): void {
    WifiServiceFactory.instance = service
  }
}
