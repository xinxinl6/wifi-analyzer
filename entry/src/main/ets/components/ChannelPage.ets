// 信道分析页面 - 包装 ChannelSection 组件为独立页面
import { ChannelSection } from './ChannelSection'
import { SharedWifiState, WifiDataManager } from '@wifi-analyzer/core'
import { adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium } from '@wifi-analyzer/design-system'

@Component
export struct ChannelPage {
  // 使用 @StorageLink 从 AppStorage 读取 wifiState
  // Index.ets 会将 wifiState 同步到 AppStorage
  @StorageLink('wifiState') wifiState: SharedWifiState = {
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
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  private dataManager: WifiDataManager = WifiDataManager.getInstance()

  aboutToAppear(): void {
    // 如果没有数据，触发一次扫描
    if (!this.wifiState.isLoaded && !this.wifiState.isScanning) {
      this.dataManager.scanAndUpdate(this.wifiState, (newState) => {
        AppStorage.setOrCreate('wifiState', newState)
      })
    }
  }

  build() {
    Stack() {
      // Aurora 天蓝渐变背景
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })

      // 信道分析内容（无返回按钮）
      ChannelSection()
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
