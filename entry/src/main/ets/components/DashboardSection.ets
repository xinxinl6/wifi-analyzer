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


  // ==================== 连接状态卡片 ====================
  @Builder ConnectionCard() {
    Row({ space: SPACE_XL }) {
      // 左侧：WiFi 图标 + 状态信息
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(52).height(52).fill(COLOR_DIVIDER)
        Image($r('app.media.ic_wifi'))
          .width(26).height(26)
          .fillColor(this.cachedConnected ? COLOR_PRIMARY : COLOR_TEXT_DISABLED)
      }.width(52).height(52)

      Column({ space: 6 }) {
        // 状态标签行
        Row({ space: 6 }) {
          Text(this.wifiState.isScanning ? $r('app.string.scanning') : (this.cachedConnected ? $r('app.string.connected') : $r('app.string.not_connected')))
            .fontSize(FONT_SIZE_SM)
            .fontColor(this.cachedConnected ? COLOR_SUCCESS : COLOR_TEXT_TERTIARY)
            .fontWeight(FONT_WEIGHT_MEDIUM)

          // 已连接时显示绿色圆点
          if (this.cachedConnected) {
            Circle().width(6).height(6).fill(COLOR_SUCCESS)
          }
        }

        // SSID 名称（主标题）
        Text(this.cachedConnected ? this.wifiState.connectedSsid : $r('app.string.no_network'))
          .fontSize(FONT_SIZE_3XL)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(this.cachedConnected ? COLOR_TEXT_PRIMARY : COLOR_TEXT_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 副信息行：BSSID · 频率 · 信道（仅已连接时显示）
        // 对比度要求 > 4.5:1，使用 #64748B
        if (this.cachedConnected) {
          Text(`${this.wifiState.connectedBssid || '--'} · ${this.wifiState.connectedFreq > 0 ? this.wifiState.connectedFreq + 'GHz' : '--'} · CH ${this.wifiState.connectedChannel > 0 ? String(this.wifiState.connectedChannel) : '--'}`)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_TEXT_SECONDARY)
            .margin({ top: 1 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .constraintSize({ minWidth: 0 })

      // 右侧：信号强度环形图（仅已连接时显示）
      if (this.cachedConnected) {
        Stack({ alignContent: Alignment.Center }) {
          // 背景轨道
          Circle().width(getSmallGaugeSize()).height(getSmallGaugeSize())
            .stroke(COLOR_CHART_GRID).strokeWidth(getSmallGaugeStrokeWidth()).fillOpacity(0)

          // 进度弧
          Circle().width(getSmallGaugeSize()).height(getSmallGaugeSize())
            .stroke(this.cachedSignalLevel.color)
            .strokeWidth(getSmallGaugeStrokeWidth())
            .fillOpacity(0)
            .strokeDashArray(this.cachedDashArray)
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ angle: -90 })
        }.width(getSmallGaugeSize()).height(getSmallGaugeSize())
      }
    }
    .width('100%')
    .padding(SPACE_XL)
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(CARD_RADIUS + 4)
    .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
  }

  // ==================== 信号强度卡片 ====================
  @Builder SignalCard() {
    Column({ space: SPACE_LG }) {
      // 标题栏
      Row() {
        Text($r('app.string.signal_strength'))
          .fontSize(FONT_SIZE_XL)
          .fontColor(COLOR_TEXT_SECONDARY)
          .fontWeight(FONT_WEIGHT_MEDIUM)

        Blank()

        // 信号等级标签（带背景）— 未连接时显示"无信号"灰色标签
        Text(this.cachedConnected ? this.cachedSignalLevel.label : $r('app.string.no_signal'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(this.cachedConnected ? this.cachedSignalLevel.color : COLOR_TEXT_TERTIARY)
          .fontWeight(FONT_WEIGHT_BOLD)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(RADIUS_FULL)
          .backgroundColor(this.cachedConnected ? this.cachedSignalLevelBg : COLOR_DIVIDER)
      }
      .width('100%')

      // 仪表盘 + 信号等级列表
      Row({ space: SPACE_XL }) {
        // 左侧：大号环形仪表（响应式尺寸）
        Stack({ alignContent: Alignment.Center }) {
          // 外圈轨道
          Circle().width(getSignalGaugeSize()).height(getSignalGaugeSize())
            .stroke(COLOR_CHART_GRID).strokeWidth(getSignalGaugeStrokeWidth()).fillOpacity(0)

          // 进度弧（未连接时为空环）
          Circle().width(getSignalGaugeSize()).height(getSignalGaugeSize())
            .stroke(this.cachedConnected ? this.cachedSignalLevel.color : COLOR_TEXT_TERTIARY)
            .strokeWidth(getSignalGaugeStrokeWidth())
            .fillOpacity(0)
            .strokeDashArray(this.cachedConnected ? this.cachedDashArray : [0, getSignalGaugeCircumference()])
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ angle: -90 })

          // 中心数值 — 未连接时显示"--"
          // 对比度要求 > 4.5:1，使用 #64748B
          Column({ space: 2 }) {
            Text(this.cachedConnected ? String(this.wifiState.connectedSignal) : '--')
              .fontSize(FONT_SIZE_4XL)
              .fontWeight(FONT_WEIGHT_BOLD)
              .fontColor(this.cachedConnected ? COLOR_TEXT_PRIMARY : COLOR_TEXT_TERTIARY)
            Text('dBm')
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_TEXT_SECONDARY)
          }
        }
        .width(getSignalGaugeSize())
        .height(getSignalGaugeSize())

        // 右侧：信号等级指示器
        Column({ space: 14 }) {
          this.SignalIndicator($r('app.string.signal_excellent'), COLOR_SIGNAL_EXCELLENT, COLOR_SIGNAL_EXCELLENT_BG, this.cachedConnected && this.wifiState.connectedSignal > SIGNAL_THRESHOLD_EXCELLENT)
          this.SignalIndicator($r('app.string.signal_good'), COLOR_SIGNAL_GOOD, COLOR_SIGNAL_GOOD_BG, this.cachedConnected && this.wifiState.connectedSignal > SIGNAL_THRESHOLD_GOOD && this.wifiState.connectedSignal <= SIGNAL_THRESHOLD_EXCELLENT)
          this.SignalIndicator($r('app.string.signal_fair'), COLOR_SIGNAL_FAIR, COLOR_SIGNAL_FAIR_BG, this.cachedConnected && this.wifiState.connectedSignal > SIGNAL_THRESHOLD_FAIR && this.wifiState.connectedSignal <= SIGNAL_THRESHOLD_GOOD)
          this.SignalIndicator($r('app.string.signal_poor'), COLOR_SIGNAL_POOR, COLOR_SIGNAL_POOR_BG, this.cachedConnected && this.wifiState.connectedSignal <= SIGNAL_THRESHOLD_FAIR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.End)
        .justifyContent(FlexAlign.Center)
        .constraintSize({ minWidth: 0 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(SPACE_XL)
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(CARD_RADIUS + 4)
    .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
  }

  // 信号等级指示器项（带背景色的圆点+文字）
  // 对比度要求：正文文字与背景 > 4.5:1
  @Builder SignalIndicator(label: Resource, dotColor: string, bgColor: string, active: boolean) {
    Row({ space: 8 }) {
      Circle()
        .width(10).height(10)
        .fill(active ? dotColor : COLOR_TEXT_DISABLED)

      Text(label)
        .fontSize(FONT_SIZE_LG)
        .fontColor(active ? COLOR_TEXT_PRIMARY : COLOR_TEXT_SECONDARY)
        .fontWeight(active ? FONT_WEIGHT_MEDIUM : FONT_WEIGHT_NORMAL)
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(RADIUS_FULL)
    .backgroundColor(active ? bgColor : 'transparent')
    .justifyContent(FlexAlign.End)
  }

  // ==================== 网络信息卡片 ====================
  @Builder NetworkCard() {
    Column({ space: SPACE_MD }) {
      // 标题栏
      Row() {
        Text($r('app.string.network_info'))
          .fontSize(FONT_SIZE_XL)
          .fontColor(COLOR_TEXT_SECONDARY)
          .fontWeight(FONT_WEIGHT_MEDIUM)
      }
      .width('100%')

      // 未连接时显示占位提示，已连接时显示网格
      if (this.cachedConnected) {
        // 信息网格（大屏4列单行，普通屏幕2列2行）
        Grid() {
          GridItem() { this.InfoItem($r('app.string.local_ip'), this.diagnostics.localIp !== '--' ? this.diagnostics.localIp : $r('app.string.not_obtained'), $r('app.media.ic_device')) }
          GridItem() { this.InfoItem($r('app.string.public_ip'), this.diagnostics.publicIp !== '--' ? this.diagnostics.publicIp : $r('app.string.not_obtained'), $r('app.media.ic_route')) }
          GridItem() { this.InfoItem($r('app.string.gateway'), this.diagnostics.gateway !== '--' ? this.diagnostics.gateway : $r('app.string.not_obtained'), $r('app.media.ic_route')) }
          GridItem() { this.InfoItem($r('app.string.dns_server'), this.diagnostics.dns !== '--' ? this.diagnostics.dns : $r('app.string.not_obtained'), $r('app.media.ic_dns')) }
        }
        .columnsTemplate(isMediumOrLarger() ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
        .rowsTemplate(isMediumOrLarger() ? '1fr' : '1fr 1fr')
        .columnsGap(SPACE_MD).rowsGap(SPACE_SM)
        .width('100%').height(isMediumOrLarger() ? 80 : 140)
      } else {
        // 未连接时显示占位提示
        // 对比度要求 > 4.5:1
        Column({ space: 8 }) {
          Text($r('app.string.connect_wifi_hint'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(COLOR_TEXT_TERTIARY)
            .fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.network_info_auto_show'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: SPACE_LG, bottom: SPACE_LG })
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding(SPACE_XL)
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(CARD_RADIUS + 4)
    .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
  }

  // 单个网络信息条目
  @Builder InfoItem(label: Resource, value: Resource | string, icon: Resource) {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Image(icon).width(14).height(14).fillColor(COLOR_TEXT_SECONDARY)
        Text(label).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_SECONDARY)
      }
      .alignItems(VerticalAlign.Center)
      .alignSelf(ItemAlign.Start)

      Text(value)
        .fontSize(FONT_SIZE_LG)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(COLOR_TEXT_PRIMARY)
        .textAlign(TextAlign.Start)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .alignSelf(ItemAlign.Start)
    }
    .padding({ left: SPACE_MD, right: SPACE_MD, top: SPACE_MD, bottom: SPACE_MD })
    .backgroundColor(COLOR_BACKGROUND)
    .borderRadius(RADIUS_MD)
    .width('100%')
    .height('100%')
  }

  // ==================== 快速工具网格 ====================
  @Builder ToolsGrid() {
    Column({ space: SPACE_MD }) {
      // 标题栏
      Row() {
        Text($r('app.string.quick_tools'))
          .fontSize(FONT_SIZE_XL)
          .fontColor(COLOR_TEXT_SECONDARY)
          .fontWeight(FONT_WEIGHT_MEDIUM)
        Blank()
      }
      .width('100%')

      // 工具网格（大屏4列单行，普通屏幕2列2行）
      Grid() {
        GridItem() { this.ToolItem($r('app.string.roam_test'), $r('app.media.ic_roaming'), '#EEF2FF', COLOR_PRIMARY, false, -1, 'roamtest') }
        GridItem() { this.ToolItem($r('app.string.find_device'), $r('app.media.ic_device'), '#E0F7FE', '#06B6D4', false, -1, 'finddevice') }
        GridItem() { this.ToolItem($r('app.string.tab_wifi'), $r('app.media.ic_surround'), '#ECFDF5', COLOR_SUCCESS, false, 1) }
        GridItem() { this.ToolItem($r('app.string.channel_analysis'), $r('app.media.ic_channel'), '#F0EBFF', COLOR_INFO, true) }
      }
      .columnsTemplate(isMediumOrLarger() ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
      .rowsTemplate(isMediumOrLarger() ? '1fr' : '1fr 1fr')
      .columnsGap(SPACE_MD).rowsGap(SPACE_MD)
      .width('100%').height(isMediumOrLarger() ? 100 : 180)
      .padding(SPACE_XL)
      .backgroundColor(COLOR_SURFACE)
      .borderRadius(CARD_RADIUS + 4)
      .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
    }
  }

  // 工具项（毛玻璃图标：渐变 PNG 自身作背景，白色图案，无需 fillColor）
  @Builder ToolItem(name: Resource, icon: Resource, bgColor: string, iconColor: string, isChannelTool: boolean = false, targetTab: number = -1, toolAction: string = '') {
    Column({ space: SPACE_SM }) {
      Stack({ alignContent: Alignment.Center }) {
        // 毛玻璃图标：图标自身是渐变背景+白色图案，无需 Circle 和 fillColor
        Image(icon).width(44).height(44)
      }
      .width(54)
      .height(54)

      Text(name)
        .fontSize(FONT_SIZE_MD)
        .fontColor(COLOR_TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .padding({ top: SPACE_SM, bottom: 4 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .stateStyles({
      pressed: { opacity: 0.75 }
    })
    .onClick(() => {
      // 工具子页面：统一通过 RouterManager 导航
      if (toolAction === 'roamtest') {
        RouterManager.navigate('roamtest')
      } else if (toolAction === 'finddevice') {
        RouterManager.navigate('finddevice')
      } else if (isChannelTool) {
        AppStorage.set('currentTab', 2)
      } else if (targetTab >= 0) {
        AppStorage.set('currentTab', targetTab)
      }
    })
  }

  build() {
    Scroll() {
      Column({ space: SPACE_MD }) {
        this.ConnectionCard()
        this.SignalCard()
        this.NetworkCard()
        this.ToolsGrid()
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
