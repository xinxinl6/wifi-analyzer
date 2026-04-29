// 查找终端引擎
// 通过局域网扫描 + MAC 厂商查询，定位特定设备
// 支持按设备名、MAC地址、厂商等条件筛选

import { LanEngine, LanDevice, LanNetworkInfo } from '../lanscan/LanEngine'
import { MacLookupEngine, MacLookupResult } from '../maclookup/MacLookupEngine'

// 设备搜索条件
export interface DeviceFilter {
  keyword: string           // 关键字 (MAC/IP/厂商名)
  vendorKeyword: string     // 厂商关键字
  onlineOnly: boolean       // 仅在线设备
}

// 终端查找结果
export interface DeviceSearchResult {
  devices: LanDevice[]          // 匹配的设备列表
  enrichedDevices: EnrichedDevice[]  // 带厂商信息的设备
  totalScanned: number          // 总扫描数量
  scanDuration: number          // 扫描耗时
}

// 丰富设备信息（带厂商查询结果）
export interface EnrichedDevice {
  device: LanDevice
  macInfo: MacLookupResult
  deviceType: string
}

// 查找回调
export interface FindDeviceCallbacks {
  onProgress: (scanned: number, total: number, currentIp: string) => void
  onDeviceFound: (enriched: EnrichedDevice) => void
  onMatchFound: (enriched: EnrichedDevice) => void
  onComplete: (result: DeviceSearchResult) => void
  onError: (message: string) => void
}

export class FindDeviceEngine {
  private lanEngine: LanEngine = new LanEngine()
  private macEngine: MacLookupEngine = new MacLookupEngine()
  private abortController: boolean = false

  /**
   * 快速查找：仅扫描网关和已知常见 IP
   */
  async quickFind(callbacks: FindDeviceCallbacks): Promise<void> {
    this.abortController = false
    const startTime: number = Date.now()
    const allDevices: LanDevice[] = []
    const enrichedDevices: EnrichedDevice[] = []
    const quickIps: string[] = [
      '.1', '.2', '.100', '.101', '.102', '.103', '.104', '.105',
      '.254', '.253', '.252', '.251', '.250',
      '.10', '.11', '.12', '.13', '.14', '.15'
    ]

    // 获取网络信息
    const networkInfo: LanNetworkInfo = await this.lanEngine.detectNetworkInfo()
    const prefix: string = networkInfo.networkPrefix
    const total: number = quickIps.length

    for (let i = 0; i < quickIps.length; i++) {
      if (this.abortController) {
        callbacks.onError('查找已停止')
        return
      }

      const ip: string = prefix + quickIps[i]
      callbacks.onProgress(i + 1, total, ip)

      const device: LanDevice | null = await this.lanEngine.probeHost(ip, 80, 1000)
      if (!device) {
        const httpDevice: LanDevice | null = await this.lanEngine.probeHost(ip, 443, 1000)
        if (!httpDevice) continue
        httpDevice.port = 443
        allDevices.push(httpDevice)
      } else {
        allDevices.push(device)
      }
    }

    // 丰富设备信息
    for (let j = 0; j < allDevices.length; j++) {
      const enriched: EnrichedDevice = await this.enrichDevice(allDevices[j])
      enrichedDevices.push(enriched)
      callbacks.onDeviceFound(enriched)
      callbacks.onMatchFound(enriched)
    }

    const result: DeviceSearchResult = {
      devices: allDevices,
      enrichedDevices: enrichedDevices,
      totalScanned: total,
      scanDuration: Date.now() - startTime
    }
    callbacks.onComplete(result)
  }

  /**
   * 完整扫描查找
   */
  async fullScan(callbacks: FindDeviceCallbacks): Promise<void> {
    this.abortController = false
    const startTime: number = Date.now()
    const allDevices: LanDevice[] = []
    const enrichedDevices: EnrichedDevice[] = []

    await this.lanEngine.scan({
      onProgress: (scanned: number, total: number, currentIp: string): void => {
        callbacks.onProgress(scanned, total, currentIp)
      },
      onDeviceFound: (device: LanDevice): void => {
        allDevices.push(device)
      },
      onComplete: (devices: LanDevice[]): void => {
        // 批量丰富设备信息（同步方式）
        const enrichedDevices: EnrichedDevice[] = []
        for (let i = 0; i < devices.length; i++) {
          const enriched: EnrichedDevice = {
            device: devices[i],
            macInfo: {
              mac: '', vendor: '', country: '', address: '',
              prefix: '', type: 'unknown', status: 'not_found',
              errorMessage: '', queryTime: 0, source: 'local'
            },
            deviceType: LanEngine.guessDeviceType(devices[i])
          }
          enrichedDevices.push(enriched)
          callbacks.onDeviceFound(enriched)
          callbacks.onMatchFound(enriched)
        }

        const result: DeviceSearchResult = {
          devices: allDevices,
          enrichedDevices: enrichedDevices,
          totalScanned: 254,
          scanDuration: Date.now() - startTime
        }
        callbacks.onComplete(result)
      },
      onError: (message: string): void => {
        callbacks.onError(message)
      }
    })
  }

  /**
   * 丰富单个设备信息
   */
  private async enrichDevice(device: LanDevice): Promise<EnrichedDevice> {
    // 尝试通过 IP 查 MAC (通过路由器页面等，此处模拟)
    // 直接使用空 MAC 查询
    let macInfo: MacLookupResult = {
      mac: '', vendor: '', country: '', address: '',
      prefix: '', type: 'unknown', status: 'not_found',
      errorMessage: '', queryTime: 0, source: 'local'
    }

    // 推测设备类型
    let deviceType: string = LanEngine.guessDeviceType(device)

    // 通过 IP 尾号简单推测
    const lastOctet: number = parseInt(device.ip.split('.').pop() || '0', 10)
    if (lastOctet === 1) deviceType = 'router'
    if (lastOctet >= 100 && lastOctet <= 200) deviceType = 'computer'
    if (lastOctet >= 2 && lastOctet <= 10) deviceType = 'server'

    const result: EnrichedDevice = {
      device: device,
      macInfo: macInfo,
      deviceType: deviceType
    }
    return result
  }

  /**
   * 按条件筛选设备
   */
  filterDevices(devices: EnrichedDevice[], filter: DeviceFilter): EnrichedDevice[] {
    const result: EnrichedDevice[] = []
    for (let i = 0; i < devices.length; i++) {
      const d: EnrichedDevice = devices[i]

      if (filter.onlineOnly && d.device.status !== 'online') continue

      if (filter.keyword.length > 0) {
        const kw: string = filter.keyword.toUpperCase()
        const ipMatch: boolean = d.device.ip.toUpperCase().indexOf(kw) >= 0
        const macMatch: boolean = d.macInfo.mac.toUpperCase().indexOf(kw) >= 0
        const vendorMatch: boolean = d.macInfo.vendor.toUpperCase().indexOf(kw) >= 0
        if (!ipMatch && !macMatch && !vendorMatch) continue
      }

      if (filter.vendorKeyword.length > 0) {
        const vk: string = filter.vendorKeyword.toUpperCase()
        if (d.macInfo.vendor.toUpperCase().indexOf(vk) < 0) continue
      }

      result.push(d)
    }
    return result
  }

  /**
   * 停止查找
   */
  stopFind(): void {
    this.abortController = true
    this.lanEngine.stopScan()
  }

  /**
   * 获取设备类型图标
   */
  static getDeviceIcon(type: string): string {
    switch (type) {
      case 'router': return 'ic_lan'
      case 'server': return 'ic_port'
      case 'computer': return 'ic_mac'
      case 'phone': return 'ic_mac'
      default: return 'ic_mac'
    }
  }

  /**
   * 获取设备类型显示名
   */
  static getDeviceTypeName(type: string): string {
    switch (type) {
      case 'router': return '路由器'
      case 'server': return '服务器'
      case 'computer': return '电脑'
      case 'phone': return '手机'
      default: return '未知设备'
    }
  }
}
