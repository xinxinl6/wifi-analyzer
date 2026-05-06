// 路由追踪页面组件 — 天蓝色透明毛玻璃悬浮风格
// 风格：天蓝色渐变背景 + 透明毛玻璃卡片 + 胶囊按钮 + 时间线路径

import promptAction from '@ohos.promptAction'
import { COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_SOLID, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_LINE,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL, GLASS_SHADOW_3XL, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider } from '@wifi-analyzer/design-system'
import {
  TracerouteEngine, TracerouteHop, TracerouteConfig, TracerouteStats, DnsResolveResult
} from '../traceroute/TracerouteEngine'
import { RouterManager, ValidationPatterns, DnsConfig, DiagnosticsConfig } from '@wifi-analyzer/core'
import { BackButtonGlass, BackButtonCapsule, PulseIndicator } from '@wifi-analyzer/design-system'

// ==================== 接口定义 ====================

interface QuickTargetItem {
  name: string
  address: string
}

// ==================== 组件 ====================

@Component
export struct TraceroutePage {
  @Consume isDarkMode: boolean = false
  @State detectedGateway: string = ''
  @State inputText: string = ''
  @State viewMode: string = 'idle'

  // 推荐目标（使用 $r 引用，用于 i18n）
  private recommendItems: Resource[] = [$r('app.string.gateway'), $r('app.string.dns'), $r('app.string.baidu')]

  @State hopList: TracerouteHop[] = []
  @State traceStats: TracerouteStats = {
    totalHops: 0, successHops: 0, failedHops: 0,
    avgLatency: 0, maxLatency: 0, minLatency: 0, totalLatency: -1
  }

  @State targetHost: string = ''
  @State resolvedIp: string = ''
  @State isRunning: boolean = false
  private pulser: PulseIndicator = new PulseIndicator()

  private engine: TracerouteEngine = new TracerouteEngine()

  // 获取资源字符串的辅助方法
  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch {
      return ''
    }
  }

  aboutToAppear(): void {
    this.detectGateway()
  }

  aboutToDisappear(): void {
    this.engine.stopTrace()
    this.pulser.stop()
  }

  // ==================== 网关检测 ====================
  private detectGateway(): void {
    this.engine.detectGateway().then((gw: string) => {
      this.detectedGateway = gw
    })
  }

  // ==================== 业务逻辑 ====================

  // 验证目标地址输入
  private validateTarget(addr: string): string {
    const trimmed: string = addr.trim()

    // 检查是否为空
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }

    // 检查长度限制
    if (trimmed.length > 255) {
      return this.getString($r('app.string.err_input_too_long'))
    }

    // 验证IP或域名格式
    if (!ValidationPatterns.isValidIpOrDomain(trimmed)) {
      return this.getString($r('app.string.err_invalid_ip_or_domain'))
    }

    return ''
  }

  onRecommendTap(index: number): void {
    switch (index) {
      case 0: // 网关
        this.inputText = this.detectedGateway || DiagnosticsConfig.DEFAULT_GATEWAY
        break
      case 1: // DNS
        this.inputText = DnsConfig.ALI_DNS
        break
      case 2: // 百度
        this.inputText = 'baidu.com'
        break
      default:
        break
    }
  }

  startTrace(): void {
    const addr: string = this.inputText.trim()

    // 输入验证
    const errorMsg: string = this.validateTarget(addr)
    if (errorMsg !== '') {
      promptAction.showToast({
        message: errorMsg,
        duration: 2000
      })
      return
    }

    this.targetHost = addr
    this.resolvedIp = addr
    this.hopList = []
    this.traceStats = {
      totalHops: 0, successHops: 0, failedHops: 0,
      avgLatency: 0, maxLatency: 0, minLatency: 0, totalLatency: -1
    }
    this.isRunning = true
    this.viewMode = 'tracing'
    this.pulser.start(600)

    this.engine.resolveHost(addr).then((result: DnsResolveResult) => {
      this.resolvedIp = result.address
    })

    const config: TracerouteConfig = TracerouteEngine.getDefaultConfig(addr)
    this.engine.startTrace(config, {
      onHopUpdate: (hops: TracerouteHop[]): void => {
        this.hopList = hops
        this.traceStats = TracerouteEngine.calcStats(hops)
      },
      onComplete: (hops: TracerouteHop[]): void => {
        this.hopList = hops
        this.traceStats = TracerouteEngine.calcStats(hops)
        this.isRunning = false
        this.pulser.stop()
        this.viewMode = 'completed'
      },
      onError: (message: string): void => {
        console.error('[TraceroutePage] Error:', message)
        this.isRunning = false
        this.pulser.stop()
        this.viewMode = 'completed'
      }
    })
  }

  stopTrace(): void {
    this.engine.stopTrace()
    this.isRunning = false
    this.pulser.stop()
    if (this.hopList.length > 0) {
      this.viewMode = 'completed'
    } else {
      this.viewMode = 'idle'
    }
  }

  // aboutToDisappear 已处理引擎清理

  getLatencyColor(latency: number): string {
    if (latency < 0) return COLOR_TEXT_TERTIARY
    if (latency <= 10) return COLOR_SUCCESS
    if (latency <= 50) return COLOR_SKY_BLUE
    if (latency <= 100) return COLOR_WARNING
    return COLOR_DANGER
  }

  // 获取时延标签（Resource 类型，用于 i18n）
  getLatencyLabelResource(latency: number): Resource | string {
    if (latency < 0) return ''
    if (latency <= 10) return $r('app.string.very_fast')
    if (latency <= 50) return $r('app.string.good_speed')
    if (latency <= 100) return $r('app.string.normal_speed')
    return $r('app.string.slow_speed')
  }

  // 获取时延标签（兼容字符串）
  getLatencyLabel(latency: number): string {
    if (latency < 0) return ''
    if (latency <= 10) return this.getString($r('app.string.latency_very_fast'))
    if (latency <= 50) return this.getString($r('app.string.latency_good'))
    if (latency <= 100) return this.getString($r('app.string.rssi_average'))
    return this.getString($r('app.string.latency_slow'))
  }

  isLastHop(index: number): boolean {
    return index === this.hopList.length - 1 && !this.isRunning
  }

  getStatusIcon(status: string): string {
    if (status === 'success') return '✓'
    if (status === 'timeout') return '⏳'
    return '✗'
  }

  // ==================== 页面入口 ====================
  build() {
    Stack() {
      // ===== Aurora 天蓝渐变背景 =====
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

      // 主内容
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          this.IdleView()
        } else {
          this.TraceView()
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

  // ==================== 初始视图 ====================
  @Builder IdleView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 大标题区
        Column({ space: 6 }) {
          Text($r('app.string.route_trace'))
            .fontSize(FONT_SIZE_2XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
          Text($r('app.string.path_desc'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        // 搜索栏
        this.SearchBarSection()

        // 推荐标签
        this.RecommendTagsSection()

        // 功能说明卡片
        this.FeatureCardsSection()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 搜索栏 - 毛玻璃风格
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_route'))
        .width(20).height(20)
        .fillColor(COLOR_SKY_BLUE)

      TextInput({ placeholder: $r('app.string.input_ip_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.inputText = value })
        .onSubmit(() => this.startTrace())

      // 追踪按钮 — 胶囊
      Row() {
        Text($r('app.string.trace'))
          .fontSize(FONT_SIZE_SM)
          .fontColor('#FFFFFF')
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_SKY_BLUE)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.startTrace())
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 推荐标签
  @Builder RecommendTagsSection() {
    Column({ space: 8 }) {
      Text($r('app.string.recommended_target'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        ForEach(this.recommendItems, (item: Resource, index: number) => {
          Row({ space: 5 }) {
            Text(index === 0 ? '🛡' : index === 1 ? '🔍' : '🌐')
              .fontSize(14)
            Text(item)
              .fontSize(FONT_SIZE_MD)
              .fontColor(COLOR_SKY_BLUE)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(this.isDarkMode ? 'rgba(14,165,233,0.25)' : COLOR_GLASS_SKY_TAG_BORDER)
          .onClick(() => this.onRecommendTap(index))
        }, (item: Resource, index: number): string => String(index))
      }
      .alignSelf(ItemAlign.Start)
    }
    .alignSelf(ItemAlign.Start)
    .width('100%')
  }

  // 功能说明卡片 - 毛玻璃
  @Builder FeatureCardsSection() {
    Column({ space: 0 }) {
      // 标题
      Row() {
        Text($r('app.string.feature_intro'))
          .fontSize(FONT_SIZE_SM)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .width('100%')
      .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem($r('app.media.ic_route'), $r('app.string.path_detection'), $r('app.string.path_desc'), '🛰')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem($r('app.media.ic_device'), $r('app.string.latency_analysis'), $r('app.string.latency_analysis_desc'), '⚡')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem($r('app.media.ic_dns'), $r('app.string.statistics_report'), $r('app.string.statistics_report_desc'), '📊')
      }
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(icon: Resource, title: Resource, desc: Resource, emoji: string) {
    Row({ space: 14 }) {
      // 图标容器
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_ACTIVE)
        Text(emoji).fontSize(16)
      }

      Column({ space: 3 }) {
        Text(title)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›').fontSize(18).fontColor(this.isDarkMode ? 'rgba(14,165,233,0.5)' : 'rgba(14,165,233,0.5)')
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
  }

  // ==================== 追踪结果视图 ====================
  @Builder TraceView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 目标信息卡片
        this.TargetInfoCard()

        // 统计概览
        if (this.hopList.length > 0) {
          this.StatsOverviewCard()
        }

        // 路径可视化
        if (this.hopList.length > 0) {
          this.PathVisualizationCard()
        }

        // 加载中空状态
        if (this.isRunning && this.hopList.length === 0) {
          this.LoadingState()
        }

        // 操作按钮
        if (this.viewMode !== 'idle') {
          this.ActionButtons()
        }
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 目标信息卡片
  @Builder TargetInfoCard() {
    Row({ space: 14 }) {
      // 脉冲图标
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_LIGHT)
          .opacity(this.isRunning ? this.pulser.opacity : 1.0)
        Circle().width(36).height(36)
          .fill(this.isRunning ? COLOR_SKY_BLUE : (this.viewMode === 'completed' ? COLOR_SUCCESS : COLOR_SKY_BLUE))
        Image($r('app.media.ic_route')).width(18).height(18).fillColor('#FFFFFF')
      }

      Column({ space: 4 }) {
        Text(this.targetHost)
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          if (this.resolvedIp !== this.targetHost && this.resolvedIp.length > 0) {
            Text(this.resolvedIp)
              .fontSize(FONT_SIZE_XS)
              .fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
          if (this.isRunning) {
            Row({ space: 4 }) {
              Circle().width(5).height(5)
                .fill(COLOR_SKY_BLUE)
                .opacity(this.pulser.opacity)
              Text($r('app.string.tracing'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SKY_BLUE)
            }
          } else if (this.viewMode === 'completed') {
            Row({ space: 4 }) {
              Circle().width(5).height(5).fill(COLOR_SUCCESS)
              Text($r('app.string.trace_complete'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SUCCESS)
            }
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

        // 搜索入口
      Row() {
        Text('🔍').fontSize(14)
      }
      .width(34).height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(10)
      .onClick(() => {
        this.viewMode = 'idle'
        this.inputText = this.targetHost
      })
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 统计概览 — 4 格毛玻璃卡片
  @Builder StatsOverviewCard() {
    Row() {
      this.StatCell($r('app.string.total_hops'), String(this.traceStats.totalHops), COLOR_SKY_BLUE)
      this.StatDivider()
      this.StatCell($r('app.string.hop_success'), String(this.traceStats.successHops), COLOR_SUCCESS)
      this.StatDivider()
      this.StatCell($r('app.string.hop_failed'), String(this.traceStats.failedHops), COLOR_DANGER)
      this.StatDivider()
      this.StatCell($r('app.string.end_to_end'), this.traceStats.totalLatency > 0 ? String(this.traceStats.totalLatency) + 'ms' : '--', COLOR_SKY_BLUE_LIGHT)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  @Builder StatCell(label: Resource | string, value: string, valueColor: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(FONT_SIZE_2XL)
        .fontColor(valueColor)
        .fontWeight(FONT_WEIGHT_BOLD)
      Text(label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder StatDivider() {
    Column()
      .width(1).height(36)
      .backgroundColor(adaptiveDivider(this.isDarkMode))
  }

  // 路径可视化卡片 — 时间线
  @Builder PathVisualizationCard() {
    Column({ space: 0 }) {
      // 卡片标题
      Row() {
        Row({ space: 6 }) {
          Text('🛰').fontSize(14)
          Text($r('app.string.route_path'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        Text() {
          Span(String(this.hopList.length))
          Span(' ')
          Span($r('app.string.hops_count'))
        }
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_SKY_BLUE)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      // 分割线
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      // 时间线列表
      Column({ space: 0 }) {
        ForEach(this.hopList, (hop: TracerouteHop, index: number) => {
          this.PathNode(hop, index)
        }, (hop: TracerouteHop, index: number): string => String(index + '_' + hop.hopIndex))
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  // 路径节点
  @Builder PathNode(hop: TracerouteHop, index: number) {
    Row() {
      // 左侧时间线
      Column() {
        // 节点圆点
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(26).height(26)
            .fill(hop.status === 'success'
              ? (this.isLastHop(index) ? COLOR_SKY_BLUE : COLOR_GLASS_SKY_LIGHT)
              : 'rgba(148,163,184,0.2)')
            .borderWidth(1.5)
            .borderColor(hop.status === 'success' ? COLOR_SKY_BLUE : 'rgba(148,163,184,0.4)')

          Text(String(hop.hopIndex))
            .fontSize(FONT_SIZE_XS)
            .fontColor(hop.status === 'success'
              ? (this.isLastHop(index) ? '#FFFFFF' : COLOR_SKY_BLUE)
              : adaptiveTextTertiary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }

        // 连接竖线
        if (!this.isLastHop(index) || this.isRunning) {
          Column()
            .width(1.5)
            .layoutWeight(1)
            .backgroundColor(hop.status === 'success' ? COLOR_GLASS_SKY_LINE : (this.isDarkMode ? 'rgba(148,163,184,0.15)' : 'rgba(148,163,184,0.25)'))
            .margin({ top: 3, bottom: 3 })
        } else {
          Column().height(SPACE_SM)
        }
      }
      .width(32)
      .alignItems(HorizontalAlign.Center)

      // 右侧节点信息 — 使用 Stack + 绝对定位确保不溢出
      Stack({ alignContent: Alignment.Start }) {
        Column({ space: SPACE_XS }) {
          // IP地址行 (第一层)
          Row({ space: SPACE_SM }) {
            Text(hop.address === '*' ? $r('app.string.no_response') : hop.address)
              .fontSize(FONT_SIZE_SM)
              .fontColor(hop.address === '*' ? adaptiveTextTertiary(this.isDarkMode) : adaptiveTextPrimary(this.isDarkMode))
              .fontWeight(hop.address === '*' ? FontWeight.Normal : FONT_WEIGHT_BOLD)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1) // IP占据剩余空间，可收缩

            if (hop.latency > 0) {
              Text(hop.latency + 'ms')
                .fontSize(FONT_SIZE_XS)
                .fontColor(this.getLatencyColor(hop.latency))
                .fontWeight(FONT_WEIGHT_BOLD)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(this.getLatencyColor(hop.latency) + '18')
                .borderRadius(999)
                .flexShrink(0) // 延迟标签不收缩
            } else {
              Text($r('app.string.timeout'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(adaptiveTextTertiary(this.isDarkMode))
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(this.isDarkMode ? 'rgba(148,163,184,0.15)' : 'rgba(148,163,184,0.2)')
                .borderRadius(999)
                .flexShrink(0)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 多次探测 RTT 详情行（来自真实 ICMP 探测）
          if (hop.allRtt !== undefined && hop.allRtt.length > 1) {
            Row({ space: 4 }) {
              ForEach(hop.allRtt, (rtt: number, rttIdx: number) => {
                Text(rtt + 'ms')
                  .fontSize(10)
                  .fontColor(this.getLatencyColor(rtt))
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)')
                  .borderRadius(4)
              }, (rtt: number, rttIdx: number): string => String(rttIdx))
            }
            .width('100%')
          }

          // 主机名
          if (hop.hostname !== '' && hop.hostname !== '*') {
            Text(hop.hostname)
              .fontSize(FONT_SIZE_XS)
              .fontColor(adaptiveTextTertiary(this.isDarkMode))
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          // 标签行
          Row({ space: 6 }) {
            if (hop.hopIndex === 1) {
              Text($r('app.string.gateway_tag'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SKY_BLUE)
                .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                .backgroundColor(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_TAG_BG)
                .borderRadius(999)
            }
            if (this.isLastHop(index) && hop.address !== '*') {
              Text($r('app.string.target_tag'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SUCCESS)
                .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                .backgroundColor(this.isDarkMode ? 'rgba(16,185,129,0.15)' : (COLOR_SUCCESS + '18'))
                .borderRadius(999)
            }
            if (hop.latency > 0) {
              Text(this.getLatencyLabelResource(hop.latency))
                .fontSize(FONT_SIZE_XS)
                .fontColor(this.getLatencyColor(hop.latency))
                .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                .backgroundColor(this.isDarkMode ? this.getLatencyColor(hop.latency) + '20' : this.getLatencyColor(hop.latency) + '15')
                .borderRadius(999)
            }
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .constraintSize({ minWidth: 0 })
        .layoutWeight(1)
        .padding({ left: 12, top: 4, bottom: 8 })
      }
      .alignContent(Alignment.Start)
      .constraintSize({ minWidth: 0 })
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  // 加载状态
  @Builder LoadingState() {
    Column({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(72).height(72)
          .fill(COLOR_GLASS_SKY_ACTIVE)
          .opacity(this.pulser.opacity)
        Circle().width(52).height(52)
          .fill(COLOR_SKY_BLUE_DIVIDER)
          .opacity(this.pulser.opacity)
        Image($r('app.media.ic_route')).width(26).height(26).fillColor(COLOR_SKY_BLUE)
      }
      Text($r('app.string.tracing_path'))
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
      Text($r('app.string.trace_duration_hint'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      // 返回按钮（华为标准：只显示箭头，不显示文字）
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      // 停止/重新追踪按钮
      if (this.isRunning) {
        Row() {
          Text($r('app.string.stop_trace')).fontSize(FONT_SIZE_MD).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor('rgba(239,68,68,0.85)')
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(239,68,68,0.5)' : 'rgba(239,68,68,0.35)', offsetX: 0, offsetY: 5 })
        .onClick(() => this.stopTrace())
      } else {
        Row() {
          Text($r('app.string.re_trace')).fontSize(FONT_SIZE_MD).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor(COLOR_SKY_BLUE)
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
        .onClick(() => this.startTrace())
      }
    }
    .width('100%')
  }
}
