// WiFi 服务抽象层
// 封装 HarmonyOS WiFi API，为未来迁移到新 API 做准备

import { hilog } from '@kit.PerformanceAnalysisKit'
import { wifiManager } from '@kit.ConnectivityKit'

const DOMAIN = 0x0000

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

// 基于 HarmonyOS wifiManager API 的实现（使用 API 10+ 新同步方法）
// getScanInfoList (API 10+) / getLinkedInfoSync (API 18+) 替代已废弃的异步版本
export class DeprecatedWifiService implements IWifiService {
  async startScan(): Promise<void> {
    try {
      const scanResult = await wifiManager.startScan()
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[WifiService] startScan result:' + scanResult)
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[WifiService] startScan error:' + JSON.stringify(error))
      if (error instanceof Error) {
        throw error
      } else {
        throw new Error(String(error))
      }
    }
  }

  async getScanResults(): Promise<WifiScanInfo[]> {
    try {
      // 使用 getScanInfoList (API 10+) 替代已废弃的 getScanResults
      const apiResult = wifiManager.getScanInfoList()
      const rawResults: RawScanInfo[] = apiResult as RawScanInfo[]
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[WifiService] getScanInfoList count:' + JSON.stringify(rawResults.length))
      return rawResults.map((item: RawScanInfo): WifiScanInfo => ({
        ssid: item.ssid || '<隐藏网络>',
        bssid: item.bssid || '',
        rssi: item.rssi || -80,
        frequency: item.frequency || 0,
        securityType: item.securityType || 0
      }))
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[WifiService] getScanInfoList error:' + JSON.stringify(error))
      return []
    }
  }

  async getLinkedInfo(): Promise<WifiLinkedInfo | null> {
    try {
      // 使用 getLinkedInfoSync (API 18+) 替代已废弃的 getLinkedInfo
      const linkedInfo = wifiManager.getLinkedInfoSync()
      if (!linkedInfo) {
        return null
      }
      // 安全获取 rssi 值
      let rssiValue = -55
      try {
        const rssi = linkedInfo.rssi as number
        if (rssi !== undefined && rssi !== null) {
          rssiValue = rssi
        }
      } catch (_e) {
        // 静默失败，使用默认值
      }
      return {
        ssid: linkedInfo.ssid || '',
        bssid: linkedInfo.bssid || '',
        rssi: rssiValue
      }
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[WifiService] getLinkedInfoSync error:' + JSON.stringify(error))
      return null
    }
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
