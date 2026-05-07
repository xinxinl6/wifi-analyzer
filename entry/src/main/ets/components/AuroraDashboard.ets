// ============================================
// Aurora WiFi V2 — 首页仪表盘组件
// API Level: 23+
// 极光天蓝 + 毛玻璃 + 沉浸光感设计
// ============================================

import {
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_AURORA_GLOW,
  COLOR_AURORA_DEEP,
  // 毛玻璃色彩
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_GLASS_AURORA_BORDER,
  // 暗色模式毛玻璃
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  // 文字色（暗色模式）
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  // 文字色（浅色模式）
  COLOR_TEXT_LIGHT_PRIMARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_TEXT_LIGHT_TERTIARY,
  // 阴影
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_GLASS_STRONG,
  COLOR_SHADOW_AURORA,
  // 信号色
  SIGNAL_COLORS_AURORA,
  SIGNAL_COLORS_AURORA_BG,
  // 动效
  DURATION_FAST,
  DURATION_NORMAL,
  AnimationTapScale,
  // 半径
  RADIUS_CARD,
  RADIUS_BUTTON
} from '@wifi-analyzer/design-system'
import { SharedWifiState, NetworkDiagnosticsResult, defaultDiagnosticsResult, networkDiagnostics, RouterManager, RouteName, WifiDataManager } from '@wifi-analyzer/core'
import { AuroraSignalIndicator } from './AuroraGlassComponents'

// AI 功能相关
import { getAIAnalysisUrl, buildNetworkQuery, WifiNetworkInfo } from '../utils/XiaoYiHelper'
import { promptAction } from '@kit.ArkUI'
import web_webview from '@ohos.web.webview'
import { hilog } from '@kit.PerformanceAnalysisKit'

// 日志 domain
const DOMAIN = 0x0000

// ============================================
// Aurora 连接状态卡片（极光渐变版）
// ============================================

@Component
export struct AuroraConnectionCard {
  @Consume('wifiState') wifiState: SharedWifiState
  @Prop isDarkMode: boolean = false

  @State private connected: boolean = false
  @State private cardScale: number = 1.0
  @State private signalColor: string = SIGNAL_COLORS_AURORA.none

  // 根据模式获取文字颜色
  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  private get textSecondary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY
  }

  private get textTertiary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
  }

  // 根据模式获取卡片背景色
  private get cardBg(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_CARD
  }

  // 根据模式获取边框颜色
  private get cardBorder(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_BORDER : 'rgba(255,255,255,0)'
  }

  // 浅色模式无边框
  private get cardBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  aboutToAppear(): void {
    this.updateState()
  }

  private updateState(): void {
    this.connected = this.wifiState.connectedSsid !== '' && this.wifiState.connectedSsid !== '<unknown ssid>'

    const signal = this.wifiState.connectedSignal
    if (signal > -50) {
      this.signalColor = SIGNAL_COLORS_AURORA.excellent
    } else if (signal > -65) {
      this.signalColor = SIGNAL_COLORS_AURORA.good
    } else if (signal > -80) {
      this.signalColor = SIGNAL_COLORS_AURORA.fair
    } else {
      this.signalColor = SIGNAL_COLORS_AURORA.poor
    }
  }

  private getSignalLevel(): string {
    const signal = this.wifiState.connectedSignal
    if (signal > -50) return 'excellent'
    if (signal > -65) return 'good'
    if (signal > -80) return 'fair'
    return 'poor'
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        // 左侧：WiFi 图标 + 状态
        Stack({ alignContent: Alignment.Center }) {
          // 外层光晕
          Circle()
            .width(64)
            .height(64)
            .fill(this.connected ? `${this.signalColor}30` : 'rgba(148,163,184,0.15)')

          // 内层光晕
          Circle()
            .width(52)
            .height(52)
            .fill(this.connected ? `${this.signalColor}20` : 'rgba(148,163,184,0.1)')

          // WiFi 图标
          Image($r('app.media.ic_wifi'))
            .width(28)
            .height(28)
            .fillColor(this.connected ? this.signalColor : '#64748B')
        }
        .width(64)
        .height(64)

        // 文字信息
        Column({ space: 6 }) {
          // 状态标签
          Row({ space: 6 }) {
            Text(this.wifiState.isScanning ? $r('app.string.scanning') : (this.connected ? $r('app.string.connected') : $r('app.string.not_connected')))
              .fontSize(12)
              .fontColor(this.connected ? this.textSecondary : this.textTertiary)

            if (this.connected) {
              Circle()
                .width(6)
                .height(6)
                .fill('#00D97E')
            }
          }

          // SSID 名称
          Text(this.connected ? this.wifiState.connectedSsid : $r('app.string.no_network'))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 详细信息
          if (this.connected) {
            Row({ space: 8 }) {
              Text(`${this.wifiState.connectedFreq}GHz`)
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text('·')
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text(`CH ${this.wifiState.connectedChannel}`)
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text('·')
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text(`${this.wifiState.connectedSignal} dBm`)
                .fontSize(12)
                .fontColor(this.textTertiary)
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .constraintSize({ minWidth: 0 })

        // 右侧：信号强度指示器
        if (this.connected) {
          Column({ space: 4 }) {
            AuroraSignalIndicator({
              signalLevel: this.getSignalLevel(),
              signalLabel: '',
              showLabel: false,
              indicatorSize: 'large'
            })

            Text(`${this.wifiState.connectedSignal}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.signalColor)
              .margin({ top: 4 })

            Text($r('app.string.dbm_unit'))
              .fontSize(10)
              .fontColor(this.textTertiary)
          }
        }
      }
    }
    .width('100%')
    .padding(20)
    // Aurora 极光渐变背景
    .backgroundColor(this.cardBg)
    .border({
      width: this.cardBorderWidth,
      color: this.cardBorder,
      radius: RADIUS_CARD
    })
    .shadow({
      radius: 20,
      color: COLOR_SHADOW_AURORA,
      offsetX: 0,
      offsetY: 4
    })
    .scale({ x: this.cardScale, y: this.cardScale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.getUIContext().animateTo(AnimationTapScale, () => {
          this.cardScale = 0.98
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.getUIContext().animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.cardScale = 1.0
        })
      }
    })
  }
}

// ============================================
// Aurora 网络信息网格
// ============================================

@Component
export struct AuroraNetworkGrid {
  @Consume('wifiState') wifiState: SharedWifiState
  @Prop isDarkMode: boolean = false
  @State diagnostics: NetworkDiagnosticsResult = defaultDiagnosticsResult

  // AI 分析点击回调（不使用 @Prop 装饰器，直接作为普通属性传递）
  onAIAnalysisClick: () => void = () => {}

  // 根据模式获取文字颜色
  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  private get textTertiary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
  }

  // 根据模式获取卡片背景色
  private get cardBg(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_CARD
  }

  // 根据模式获取边框颜色
  private get cardBorder(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER_LIGHT
  }

  // 根据模式获取网格项背景色
  private get gridItemBg(): string {
    return this.isDarkMode ? 'rgba(255,255,255,0.08)' : COLOR_GLASS_SURFACE_MEDIUM
  }

  // 根据模式获取网格项边框颜色
  private get gridItemBorder(): string {
    return this.isDarkMode ? 'rgba(255,255,255,0.06)' : COLOR_GLASS_BORDER_LIGHT
  }

  // 浅色模式无边框
  private get gridBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  // 浅色模式网格项边框
  private get gridItemBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  // 轮询定时器ID
  private pollingTimerId: number = -1

  aboutToAppear(): void {
    // 获取初始状态
    const initialResult = networkDiagnostics.getCurrentResult()
    this.diagnostics.localIp = initialResult.localIp
    this.diagnostics.publicIp = initialResult.publicIp
    this.diagnostics.gateway = initialResult.gateway
    this.diagnostics.dns = initialResult.dns
    this.diagnostics.isTesting = initialResult.isTesting
    
    // 发起诊断
    networkDiagnostics.startDiagnostics((result: NetworkDiagnosticsResult) => {
      // 诊断完成，更新UI
      this.diagnostics.localIp = result.localIp
      this.diagnostics.publicIp = result.publicIp
      this.diagnostics.gateway = result.gateway
      this.diagnostics.dns = result.dns
      this.diagnostics.isTesting = result.isTesting
      
      // 停止轮询
      if (this.pollingTimerId !== -1) {
        clearInterval(this.pollingTimerId)
        this.pollingTimerId = -1
      }
    })
    
    // 启动轮询，确保UI能更新
    this.pollingTimerId = setInterval(() => {
      const result = networkDiagnostics.getCurrentResult()
      this.diagnostics.localIp = result.localIp
      this.diagnostics.publicIp = result.publicIp
      this.diagnostics.gateway = result.gateway
      this.diagnostics.dns = result.dns
      this.diagnostics.isTesting = result.isTesting
      
      // 如果诊断完成，停止轮询
      if (!result.isTesting && this.pollingTimerId !== -1) {
        clearInterval(this.pollingTimerId)
        this.pollingTimerId = -1
      }
    }, 300)
  }
  
  aboutToDisappear(): void {
    if (this.pollingTimerId !== -1) {
      clearInterval(this.pollingTimerId)
      this.pollingTimerId = -1
    }
  }

  @Builder
  InfoGridItem(label: ResourceStr, value: string, icon: Resource) {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Image(icon)
          .width(14)
          .height(14)
          .fillColor(COLOR_AURORA_PRIMARY)
        Text(label)
          .fontSize(11)
          .fontColor(this.textTertiary)
      }
      .alignItems(VerticalAlign.Center)

      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.gridItemBg)
    .borderRadius(12)
    .border({
      width: this.gridItemBorderWidth,
      color: this.isDarkMode ? this.gridItemBorder : 'rgba(0,0,0,0)',
      radius: 12
    })
  }

  build() {
    Column({ space: 12 }) {
      // 标题
      Row() {
        Text($r('app.string.network_info'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)

        Blank()

        // AI 分析入口（点击调用小艺助手，降级为浏览器搜索）
        Row({ space: 4 }) {
          Image($r('app.media.ic_ai_assistant'))
            .width(14)
            .height(14)
            .fillColor(COLOR_AURORA_PRIMARY)
          Text($r('app.string.ai_analysis_home'))
            .fontSize(12)
            .fontColor(COLOR_AURORA_PRIMARY)
        }
        .padding(6)
        .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
        .borderRadius(8)
        .onClick(() => {
          // 调用 AI 分析回调
          if (this.onAIAnalysisClick) {
            this.onAIAnalysisClick()
          }
        })
      }
      .width('100%')

      // 信息网格
      Grid() {
        GridItem() {
          this.InfoGridItem($r('app.string.local_ip'), this.diagnostics.localIp || '--', $r('app.media.ic_device'))
        }
        GridItem() {
          this.InfoGridItem($r('app.string.public_ip'), this.diagnostics.publicIp || '--', $r('app.media.ic_route'))
        }
        GridItem() {
          this.InfoGridItem($r('app.string.gateway'), this.diagnostics.gateway || '--', $r('app.media.ic_route'))
        }
        GridItem() {
          this.InfoGridItem($r('app.string.dns'), this.diagnostics.dns || '--', $r('app.media.ic_dns'))
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .height(160)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .borderRadius(RADIUS_CARD)
    .border({
      width: this.gridBorderWidth,
      color: this.cardBorder,
      radius: RADIUS_CARD
    })
  }
}

// ============================================
// Aurora 快速工具网格
// ============================================

@Component
export struct AuroraToolsGrid {
  @Prop isDarkMode: boolean = false
  @State private toolScale: number = 1.0

  // 根据模式获取文字颜色
  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  // 根据模式获取卡片背景色
  private get cardBg(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_CARD
  }

  // 根据模式获取边框颜色
  private get cardBorder(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER_LIGHT
  }

  // 根据模式获取工具项背景色
  private get toolItemBg(): string {
    return this.isDarkMode ? 'rgba(255,255,255,0.06)' : COLOR_GLASS_SURFACE
  }

  // 根据模式获取工具项边框颜色
  private get toolItemBorder(): string {
    return this.isDarkMode ? 'rgba(255,255,255,0.05)' : COLOR_GLASS_BORDER_LIGHT
  }

  // 浅色模式无边框
  private get toolBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  // 浅色模式工具项边框
  private get toolItemBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  @Builder
  ToolCard(title: ResourceStr, icon: Resource, bgColor: string, iconColor: string, index: number, action: string) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        // 图标背景
        Column()
          .width(48)
          .height(48)
          .borderRadius(14)
          .backgroundColor(bgColor)
          .shadow({
            radius: 8,
            color: `${iconColor}25`,
            offsetX: 0,
            offsetY: 2
          })

        // 图标
        Image(icon)
          .width(26)
          .height(26)
          .fillColor(iconColor)
      }

      // 标题
      Text(title)
        .fontSize(10)
        .fontColor(this.textPrimary)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.toolItemBg)
    .borderRadius(14)
    .border({
      width: this.toolItemBorderWidth,
      color: this.isDarkMode ? this.toolItemBorder : 'rgba(0,0,0,0)',
      radius: 14
    })
    .scale({ x: this.toolScale, y: this.toolScale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        // 按下：缩小到 0.95
        this.getUIContext().animateTo({
          duration: 100,
          curve: Curve.EaseOut
        }, () => {
          this.toolScale = 0.95
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        // 松开：恢复 1.0
        this.getUIContext().animateTo({
          duration: 200,
          curve: Curve.EaseOut
        }, () => {
          this.toolScale = 1.0
        })
      }
    })
    .onClick(() => {
      const routeMap: Record<string, RouteName> = {
        'roamtest': 'roamtest',
        'channel': 'channel'
      }
      const tabMap: Record<string, number> = {
        'wifi': 1,
        'channel_tab': 2,
        'speed': 3,
        'tools': 4
      }
      // 先检查是否是 Tab 导航
      const tabIndex = tabMap[action]
      if (tabIndex !== undefined) {
        RouterManager.navigateToTab(tabIndex)
        return
      }
      // 否则检查是否是子页面导航
      const route = routeMap[action]
      if (route) {
        RouterManager.navigate(route)
      }
    })
  }

  build() {
    Column({ space: 12 }) {
      // 标题
      Row() {
        Text($r('app.string.quick_tools'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)

        Blank()

        Text($r('app.string.more'))
          .fontSize(12)
          .fontColor(COLOR_AURORA_PRIMARY)
          .onClick(() => {
            RouterManager.navigateToTab(4) // 跳转到工具 Tab
          })
      }
      .width('100%')

      // 工具网格
      Grid() {
        GridItem() {
          this.ToolCard($r('app.string.roam_test'), $r('app.media.ic_roaming'), 'rgba(74,144,217,0.15)', COLOR_AURORA_PRIMARY, 0, 'roamtest')
        }
        GridItem() {
          this.ToolCard($r('app.string.surrounding_wifi'), $r('app.media.ic_surround'), 'rgba(135,206,235,0.15)', COLOR_AURORA_LIGHT, 1, 'wifi')
        }
        GridItem() {
          this.ToolCard($r('app.string.channel_analysis'), $r('app.media.ic_channel'), 'rgba(139,92,246,0.15)', '#8B5CF6', 2, 'channel_tab')
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .height(110)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(this.cardBg)
    .borderRadius(RADIUS_CARD)
    .border({
      width: this.toolBorderWidth,
      color: this.cardBorder,
      radius: RADIUS_CARD
    })
  }
}

// ============================================
// Aurora 极光装饰背景
// ============================================

@Component
export struct AuroraBackground {
  build() {
    Stack() {
      // 基础渐变背景已在 Index.ets 设置

      // 极光装饰光晕 1 - 使用更大的透明圆形代替 blur
      Circle()
        .width(300)
        .height(300)
        .fill('rgba(74,144,217,0.06)')
        .position({ x: -80, y: -80 })

      // 极光装饰光晕 2
      Circle()
        .width(200)
        .height(200)
        .fill('rgba(135,206,235,0.05)')
        .position({ x: '70%', y: '55%' })

      // 极光装饰光晕 3
      Circle()
        .width(150)
        .height(150)
        .fill('rgba(74,144,217,0.04)')
        .position({ x: '75%', y: '15%' })
    }
    .width('100%')
    .height('100%')
    .zIndex(-1)
  }
}

// ============================================
// Aurora 首页主组件
// ============================================

@Component
export struct AuroraDashboard {
  @Consume('wifiState') wifiState: SharedWifiState
  @Prop isDarkMode: boolean = false

  // 下拉刷新状态
  @State isRefreshing: boolean = false
  @State private refreshOffset: number = 0

  // WiFi 数据管理器
  private dataManager: WifiDataManager = WifiDataManager.getInstance()

  // AI 分析面板状态
  @State private showAIAnalysis: boolean = false
  @State private aiWebViewUrl: string = ''
  @State private aiLoading: boolean = false

  // AI 分析面板控制器
  private aiAnalysisController: web_webview.WebviewController = new web_webview.WebviewController()

  // 下拉刷新回调
  private async onRefresh(): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[AuroraDashboard] Refreshing WiFi data...')
    
    // 触发 WiFi 扫描
    this.dataManager.scanAndUpdate(
      this.wifiState,
      (newState: SharedWifiState) => {
        this.wifiState = newState
        AppStorage.setOrCreate('wifiState', newState)
        // 刷新完成
        this.isRefreshing = false
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[AuroraDashboard] Refresh completed')
      }
    )
  }

  // 打开 AI 分析面板
  private openAIAnalysis(): void {
    // 构建网络分析查询
    const networkInfo: WifiNetworkInfo = {
      ssid: this.wifiState.connectedSsid,
      signal: this.wifiState.connectedSignal,
      channel: this.wifiState.connectedChannel,
      frequency: this.wifiState.connectedFreq
    }
    const query = buildNetworkQuery(networkInfo)

    // 直接获取搜索URL，不尝试启动小艺（避免系统弹窗）
    const url = getAIAnalysisUrl(query)
    this.aiWebViewUrl = url
    this.showAIAnalysis = true
    this.aiLoading = true

    promptAction.showToast({
      message: '正在为您分析网络...',
      duration: 2000
    })
  }

  // 关闭 AI 分析面板
  private closeAIAnalysis(): void {
    this.showAIAnalysis = false
    this.aiWebViewUrl = ''
  }

  @Builder
  AIAnalysisWebViewPanel() {
    if (this.showAIAnalysis) {
      Stack({ alignContent: Alignment.Bottom }) {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.6)')
          .onClick(() => {
            this.closeAIAnalysis()
          })

        // WebView 面板内容
        Column({ space: 0 }) {
          // 顶部拖拽指示条
          Column()
            .width(40)
            .height(4)
            .backgroundColor('rgba(148,163,184,0.4)')
            .borderRadius(2)
            .margin({ top: 12, bottom: 8 })

          // 标题栏
          Row() {
            Text('网络优化分析')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY)

            Blank()

            // 关闭按钮
            Image($r('app.media.ic_close'))
              .width(24)
              .height(24)
              .fillColor(this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY)
              .onClick(() => {
                this.closeAIAnalysis()
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 12 })

          // 加载指示器
          if (this.aiLoading) {
            Row() {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(COLOR_AURORA_PRIMARY)
              Text('正在加载...')
                .fontSize(14)
                .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY)
                .margin({ left: 8 })
            }
            .padding(16)
            .width('100%')
          }

          // WebView 内容
          Web({ src: this.aiWebViewUrl, controller: this.aiAnalysisController })
            .width('100%')
            .layoutWeight(1)
            .onPageBegin(() => {
              this.aiLoading = true
            })
            .onPageEnd(() => {
              this.aiLoading = false
            })
            .onErrorReceive((event) => {
              console.error('WebView error: ' + (event?.error?.getErrorInfo() || 'Unknown error'))
              this.aiLoading = false
            })
        }
        .width('100%')
        .height('85%')
        .backgroundColor(this.isDarkMode ? 'rgba(20,38,72,0.98)' : 'rgba(248,250,252,0.98)')
        .borderRadius({ topLeft: 24, topRight: 24 })
      }
      .zIndex(999)
    }
  }

  build() {
    Stack() {
      Column() {
        // 下拉刷新容器
        Refresh({
          refreshing: this.isRefreshing
        }) {
          Scroll() {
            Column({ space: 16 }) {
              // 连接状态卡片
              AuroraConnectionCard({ isDarkMode: this.isDarkMode })

              // 网络信息网格
              AuroraNetworkGrid({
                isDarkMode: this.isDarkMode,
                onAIAnalysisClick: () => this.openAIAnalysis()
              })

              // 快速工具网格
              AuroraToolsGrid({ isDarkMode: this.isDarkMode })

              // 底部安全区
              Row()
                .height(100)
            }
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .width('100%')
          .layoutWeight(1)
        }
        .onRefreshing(() => {
          this.onRefresh()
        })
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')

      // AI 分析 WebView 面板
      this.AIAnalysisWebViewPanel()
    }
    .width('100%')
    .height('100%')
  }
}