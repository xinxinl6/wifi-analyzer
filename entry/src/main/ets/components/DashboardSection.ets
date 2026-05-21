// 首页仪表盘组件 — 接入真实WiFi数据
// 通过 @Consume 从 Index.ets 获取真实 WiFi 扫描数据

import { COLOR_PRIMARY, COLOR_PRIMARY_LIGHT, COLOR_SUCCESS, COLOR_INFO,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY, COLOR_TEXT_DISABLED,
  COLOR_SURFACE, COLOR_BORDER,
  COLOR_SIGNAL_EXCELLENT, COLOR_SIGNAL_GOOD, COLOR_SIGNAL_FAIR, COLOR_SIGNAL_POOR,
  COLOR_SIGNAL_EXCELLENT_BG, COLOR_SIGNAL_GOOD_BG, COLOR_SIGNAL_FAIR_BG, COLOR_SIGNAL_POOR_BG,
  SIGNAL_THRESHOLD_EXCELLENT, SIGNAL_THRESHOLD_GOOD, SIGNAL_THRESHOLD_FAIR,
  COLOR_FADE_TOP, COLOR_FADE_BOTTOM, COLOR_CARD_SHADOW, COLOR_DIVIDER,
  COLOR_CHART_GRID,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD, FONT_WEIGHT_NORMAL,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  ICON_SIZE_XL, CARD_RADIUS, CARD_SHADOW_RADIUS, STROKE_WIDTH_MD,
  RADIUS_FULL, RADIUS_MD, COLOR_BACKGROUND, TAB_BAR_SAFE_BOTTOM } from '@wifi-analyzer/design-system'
import { SharedWifiState, NetworkDiagnosticsResult, defaultDiagnosticsResult, networkDiagnostics, RouterManager } from '@wifi-analyzer/core'
import { getSignalGaugeSize, getSignalGaugeStrokeWidth, getSignalGaugeCircumference,
  getSmallGaugeSize, getSmallGaugeStrokeWidth, isLandscape, isMediumOrLarger, getGridColumns } from '../utils/ResponsiveUtils'
import { DashboardConnectionCard } from './DashboardConnectionCard'
import { DashboardSignalCard } from './DashboardSignalCard'
import { DashboardNetworkCard } from './DashboardNetworkCard'
import { DashboardToolsGrid } from './DashboardToolsGrid'

interface SignalLevelInfo {
  label: Resource
  color: string
}

@Component
export struct DashboardSection {
  @Consume('wifiState') wifiState: SharedWifiState
  @State diagnostics: NetworkDiagnosticsResult = defaultDiagnosticsResult
  @State isLoadingDiagnostics: boolean = false

  // 预计算缓存（避免 build() 中重复计算）
  @State private cachedConnected: boolean = false
  @State private cachedSignalLevel: SignalLevelInfo = { label: $r('app.string.signal_poor'), color: COLOR_SIGNAL_POOR }
  @State private cachedSignalLevelBg: string = COLOR_SIGNAL_POOR_BG
  @State private cachedDashArray: [number, number] = [0, 1]

  // 轮询定时器 ID（用于组件销毁时清理）
  private pollTimerId: number = -1

  aboutToAppear(): void {
    networkDiagnostics.loadDiagnostics()
    this.recomputeCache()

    let retryCount: number = 0
    const maxRetry: number = 20
    const pollInterval: number = 500

    this.pollTimerId = setInterval(() => {
      retryCount++
      if (retryCount > maxRetry) {
        clearInterval(this.pollTimerId)
        this.pollTimerId = -1
        return
      }
      const latest: NetworkDiagnosticsResult = networkDiagnostics.getCurrentResult()
      // 只有数据发生变化时才赋值，减少无意义的重渲染
      if (latest.localIp !== this.diagnostics.localIp ||
          latest.publicIp !== this.diagnostics.publicIp ||
          latest.gateway !== this.diagnostics.gateway ||
          latest.dns !== this.diagnostics.dns ||
          latest.isTesting !== this.diagnostics.isTesting) {
        this.diagnostics = latest
      }
      // 当 wifiState 变化时，更新缓存
      if (this.wifiState.connectedSsid !== '' || this.cachedConnected) {
        this.recomputeCache()
      }
      if (latest.localIp !== '获取中...' && latest.publicIp !== '获取中...' && latest.gateway !== '获取中...') {
        clearInterval(this.pollTimerId)
        this.pollTimerId = -1
      }
    }, pollInterval)
  }

  // 组件销毁时清理定时器，防止内存泄漏
  aboutToDisappear(): void {
    if (this.pollTimerId >= 0) {
      clearInterval(this.pollTimerId)
      this.pollTimerId = -1
    }
  }

  // ==================== 数据计算 ====================

  // 预计算所有缓存值（避免 build() 中重复计算）
  private recomputeCache(): void {
    // 计算连接状态
    this.cachedConnected = this.wifiState.connectedSsid !== '' && this.wifiState.connectedSsid !== '<unknown ssid>'

    if (this.cachedConnected) {
      // 预计算信号等级信息（使用全局统一阈值）
      const signal: number = this.wifiState.connectedSignal
      if (signal > SIGNAL_THRESHOLD_EXCELLENT) {
        this.cachedSignalLevel = { label: $r('app.string.signal_excellent'), color: COLOR_SIGNAL_EXCELLENT }
        this.cachedSignalLevelBg = COLOR_SIGNAL_EXCELLENT_BG
      } else if (signal > SIGNAL_THRESHOLD_GOOD) {
        this.cachedSignalLevel = { label: $r('app.string.signal_good'), color: COLOR_SIGNAL_GOOD }
        this.cachedSignalLevelBg = COLOR_SIGNAL_GOOD_BG
      } else if (signal > SIGNAL_THRESHOLD_FAIR) {
        this.cachedSignalLevel = { label: $r('app.string.signal_fair'), color: COLOR_SIGNAL_FAIR }
        this.cachedSignalLevelBg = COLOR_SIGNAL_FAIR_BG
      } else {
        this.cachedSignalLevel = { label: $r('app.string.signal_poor'), color: COLOR_SIGNAL_POOR }
        this.cachedSignalLevelBg = COLOR_SIGNAL_POOR_BG
      }

      // 预计算环形图 dashArray（统一公式，根据信号值 + 目标周长计算）
      this.cachedDashArray = this.calcDashArray(signal)
    }
  }

  // 统一计算环形图 dashArray（signal: dBm, targetCircumference: 目标周长）
  private calcDashArray(signal: number): [number, number] {
    const minSignal = -100
    const maxSignal = -30
    const progress = Math.max(0, Math.min(1, (signal - minSignal) / (maxSignal - minSignal)))
    // 使用大号仪表盘周长作为默认（小号仪表盘会按比例缩放）
    const circumference = getSignalGaugeCircumference()
    const filled = Math.round(circumference * progress)
    return [filled, circumference - filled]
  }

  build() {
    Scroll() {
      Column({ space: SPACE_MD }) {
        // 连接状态卡片
        DashboardConnectionCard({
          isDarkMode: false,
          connected: this.cachedConnected,
          ssid: this.wifiState.connectedSsid,
          signalLevel: this.wifiState.connectedSignal,
          signalLevelBg: this.cachedSignalLevelBg,
          isScanning: this.wifiState.isScanning,
          bssid: this.wifiState.connectedBssid,
          freq: this.wifiState.connectedFreq,
          channel: this.wifiState.connectedChannel,
          dashArray: this.cachedDashArray,
          signalColor: this.cachedSignalLevel.color
        })

        // 信号强度卡片
        DashboardSignalCard({
          isDarkMode: false,
          signalLevel: this.wifiState.connectedSignal,
          signalLabel: this.cachedSignalLevel.label,
          signalColor: this.cachedSignalLevel.color,
          signalLevelBg: this.cachedSignalLevelBg,
          cachedDashArray: this.cachedDashArray,
          connected: this.cachedConnected
        })

        // 网络信息卡片
        DashboardNetworkCard({
          isDarkMode: false,
          localIp: this.diagnostics.localIp,
          gateway: this.diagnostics.gateway,
          dns: this.diagnostics.dns,
          publicIp: this.diagnostics.publicIp,
          connected: this.cachedConnected
        })

        // 快速工具网格
        DashboardToolsGrid({
          isDarkMode: false,
          onToolClick: (toolName: string) => {
            // 工具点击回调（可扩展）
          }
        })
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: TAB_BAR_SAFE_BOTTOM })
      .width('100%')
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }
}
