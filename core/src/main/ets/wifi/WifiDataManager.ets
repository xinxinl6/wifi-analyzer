// WiFi 数据共享管理器
// 作为 Index 和各页面组件之间的数据桥梁
// 使用 @Provide/@Consume 机制实现跨组件数据共享

import { WifiItem } from '../models/WifiItem'
import { WifiScanner, WifiScanResult } from './WifiScanner'

export interface SharedWifiState {
  // WiFi 列表
  wifiList: WifiItem[]

  // 当前已连接的 WiFi 信息
  connectedSsid: string
  connectedBssid: string
  connectedSignal: number
  connectedFreq: number
  connectedChannel: number

  // 扫描状态
  isScanning: boolean

  // 筛选状态: 'all' | '5g' | '2.4g'
  currentFilter: string

  // 是否已加载数据
  isLoaded: boolean

  // 子组件请求刷新计数器（子组件++，父组件检测到变化后重新扫描）
  scanRequestCount: number

  // 错误信息
  error: string | Resource
}

export class WifiDataManager {
  private static instance: WifiDataManager | null = null
  private scanner: WifiScanner = WifiScanner.getInstance()

  private constructor() {}

  static getInstance(): WifiDataManager {
    if (!WifiDataManager.instance) {
      WifiDataManager.instance = new WifiDataManager()
    }
    return WifiDataManager.instance
  }

  // 获取初始状态
  getInitialState(): SharedWifiState {
    return {
      wifiList: [],
      connectedSsid: '',
      connectedBssid: '',
      connectedSignal: -100,
      connectedFreq: 0,
      connectedChannel: 0,
      isScanning: false,
      currentFilter: 'all',
      isLoaded: false,
      scanRequestCount: 0,
      error: ''
    }
  }

  // 开始扫描并更新状态
  async scanAndUpdate(
    currentState: SharedWifiState,
    onUpdate: (state: SharedWifiState) => void
  ): Promise<void> {
    console.log('[WifiDataManager] === scanAndUpdate START ===')
    console.log('[WifiDataManager] Current state: connectedSsid=' + currentState.connectedSsid +
      ', isLoaded=' + currentState.isLoaded)

    await this.scanner.startScan((result: WifiScanResult) => {
      console.log('[WifiDataManager] === Scanner callback invoked ===')
      console.log('[WifiDataManager] Scan callback: isScanning=' + result.isScanning +
        ', connectedSsid=' + result.connectedSsid +
        ', wifiList.length=' + result.wifiList.length)
      const newState: SharedWifiState = {
        wifiList: result.wifiList || [],
        connectedSsid: result.connectedSsid || '',
        connectedBssid: result.connectedBssid || '',
        connectedSignal: result.connectedSignal,
        connectedFreq: 0,  // 稍后在下面填充
        connectedChannel: 0,  // 稍后在下面填充
        isScanning: result.isScanning,
        isLoaded: !result.isScanning && (result.wifiList.length > 0 || result.connectedSsid !== ''),
        currentFilter: currentState.currentFilter,
        scanRequestCount: currentState.scanRequestCount,
        error: result.error || ''
      }

      // 从已连接WiFi列表项获取频段和信道信息（单次遍历替代两次 find）
      console.log('[WifiDataManager] Looking for connected item in ' + result.wifiList.length + ' items')
      console.log('[WifiDataManager] Connected SSID: ' + result.connectedSsid + ', BSSID: ' + result.connectedBssid)

      let foundConnected: boolean = false
      for (let i = 0; i < result.wifiList.length; i++) {
        const item: WifiItem = result.wifiList[i]
        if (item.isConnected) {
          newState.connectedFreq = item.freq
          newState.connectedChannel = item.channel
          foundConnected = true
          console.log('[WifiDataManager] Found connected item: ' + item.ssid +
            ' freq=' + item.freq + ' channel=' + item.channel)
          break
        }
      }
      if (!foundConnected && result.connectedSsid !== '') {
        for (let j = 0; j < result.wifiList.length; j++) {
          if (result.wifiList[j].ssid === result.connectedSsid) {
            newState.connectedFreq = result.wifiList[j].freq
            newState.connectedChannel = result.wifiList[j].channel
            console.log('[WifiDataManager] Matched by SSID: ' + result.wifiList[j].ssid +
              ' freq=' + result.wifiList[j].freq + ' channel=' + result.wifiList[j].channel)
            break
          }
        }
      }

      console.log('[WifiDataManager] Calling onUpdate: connectedSsid=' + newState.connectedSsid +
        ', wifiList.length=' + newState.wifiList.length +
        ', isLoaded=' + newState.isLoaded)
      onUpdate(newState)
      console.log('[WifiDataManager] === scanAndUpdate END ===')
    })
  }
}
