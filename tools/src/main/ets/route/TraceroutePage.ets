// 路由追踪页面组件 — 天蓝色透明毛玻璃悬浮风格
// 风格：天蓝色渐变背景 + 透明毛玻璃卡片 + 胶囊按钮 + 时间线路径

import { COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_SOLID, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_LINE,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL, GLASS_SHADOW_3XL, SAFE_AREA_BOTTOM } from '@wifi-analyzer/design-system'
import {
  TracerouteEngine, TracerouteHop, TracerouteConfig, TracerouteStats, DnsResolveResult
} from '../traceroute/TracerouteEngine'
import { RouterManager } from '@wifi-analyzer/core'

// ==================== 接口定义 ====================

interface QuickTargetItem {
  name: string
  address: string
}

// ==================== 组件 ====================

@Component
export struct TraceroutePage {
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
  @State pulseOpacity: number = 1.0

  private engine: TracerouteEngine = new TracerouteEngine()
  private pulseTimerId: number = -1

  aboutToAppear(): void {
    this.detectGateway()
  }

  aboutToDisappear(): void {
    this.engine.stopTrace()
    this.stopPulse()
  }

  // ==================== 网关检测 ====================
  private detectGateway(): void {
    this.engine.detectGateway().then((gw: string) => {
      this.detectedGateway = gw
    })
  }

  // ==================== 脉冲动画 ====================
  private startPulse(): void {
    this.pulseTimerId = setInterval((): void => {
      this.pulseOpacity = this.pulseOpacity === 1.0 ? 0.3 : 1.0
    }, 600)
  }

  private stopPulse(): void {
    if (this.pulseTimerId >= 0) {
      clearInterval(this.pulseTimerId)
      this.pulseTimerId = -1
    }
    this.pulseOpacity = 1.0
  }

  // ==================== 业务逻辑 ====================

  onRecommendTap(index: number): void {
    switch (index) {
      case 0: // 网关
        this.inputText = this.detectedGateway || '192.168.1.1'
        break
      case 1: // DNS
        this.inputText = '223.5.5.5'
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
    if (addr.length === 0) return

    this.targetHost = addr
    this.resolvedIp = addr
    this.hopList = []
    this.traceStats = {
      totalHops: 0, successHops: 0, failedHops: 0,
      avgLatency: 0, maxLatency: 0, minLatency: 0, totalLatency: -1
    }
    this.isRunning = true
    this.viewMode = 'tracing'
    this.startPulse()

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
        this.stopPulse()
        this.viewMode = 'completed'
      },
      onError: (message: string): void => {
        console.error('[TraceroutePage] Error:', message)
        this.isRunning = false
        this.stopPulse()
        this.viewMode = 'completed'
      }
    })
  }

  stopTrace(): void {
    this.engine.stopTrace()
    this.isRunning = false
    this.stopPulse()
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
    if (latency <= 10) return $r('app.string.latency_very_fast').toString()
    if (latency <= 50) return $r('app.string.latency_good').toString()
    if (latency <= 100) return $r('app.string.rssi_average').toString()
    return $r('app.string.latency_slow').toString()
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
      // 天蓝渐变背景
      Column() {
        Column()
          .width('100%')
          .height(220)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [[COLOR_SKY_BLUE_LIGHT, 0], ['rgba(186,230,253,0.55)', 0.55], ['rgba(224,242,254,0.15)', 1]]
          })
        Blank()
      }
      .width('100%').height('100%')
      .backgroundColor(COLOR_BACKGROUND)

      // 主内容
      Column() {
        if (this.viewMode === 'idle') {
          this.IdleView()
        } else {
          this.TraceView()
        }
      }
      .width('100%').height('100%')
      .padding({ top: SPACE_LG })
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
            .fontSize(FONT_SIZE_3XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(COLOR_TEXT_PRIMARY)
          Text($r('app.string.path_desc'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(COLOR_TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: SPACE_SM })

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
        .width(18).height(18)
        .fillColor(COLOR_SKY_BLUE)

      TextInput({ placeholder: $r('app.string.input_ip_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD)
        .fontColor(COLOR_TEXT_PRIMARY)
        .placeholderColor(COLOR_TEXT_TERTIARY)
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
    .backgroundColor(COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 推荐标签
  @Builder RecommendTagsSection() {
    Column({ space: 8 }) {
      Text($r('app.string.recommended_target'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(COLOR_TEXT_TERTIARY)
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        ForEach(this.recommendItems, (item: Resource, index: number) => {
          Row({ space: 5 }) {
            Text(index === 0 ? '🛡' : index === 1 ? '🔍' : '🌐')
              .fontSize(12)
            Text(item)
              .fontSize(FONT_SIZE_SM)
              .fontColor(COLOR_SKY_BLUE)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(COLOR_GLASS_SKY_TAG_BORDER)
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
          .fontColor(COLOR_TEXT_SECONDARY)
      }
      .width('100%')
      .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem($r('app.media.ic_route'), $r('app.string.path_detection'), $r('app.string.path_desc'), '🛰')
        Column().width('100%').height(0.5).backgroundColor(COLOR_GLASS_SKY_LIGHT)
        this.FeatureItem($r('app.media.ic_device'), $r('app.string.latency_analysis'), $r('app.string.latency_analysis_desc'), '⚡')
        Column().width('100%').height(0.5).backgroundColor(COLOR_GLASS_SKY_LIGHT)
        this.FeatureItem($r('app.media.ic_dns'), $r('app.string.statistics_report'), $r('app.string.statistics_report_desc'), '📊')
      }
      .backgroundColor(COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(icon: Resource, title: Resource, desc: Resource, emoji: string) {
    Row({ space: 14 }) {
      // 图标容器
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(COLOR_GLASS_SKY_ACTIVE)
        Text(emoji).fontSize(16)
      }

      Column({ space: 3 }) {
        Text(title)
          .fontSize(FONT_SIZE_MD)
          .fontColor(COLOR_TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›').fontSize(18).fontColor('rgba(14,165,233,0.5)')
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
          .fill(COLOR_GLASS_SKY_LIGHT)
          .opacity(this.isRunning ? this.pulseOpacity : 1.0)
        Circle().width(36).height(36)
          .fill(this.isRunning ? COLOR_SKY_BLUE : (this.viewMode === 'completed' ? COLOR_SUCCESS : COLOR_SKY_BLUE))
        Image($r('app.media.ic_route')).width(18).height(18).fillColor('#FFFFFF')
      }

      Column({ space: 4 }) {
        Text(this.targetHost)
          .fontSize(FONT_SIZE_LG)
          .fontColor(COLOR_TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          if (this.resolvedIp !== this.targetHost && this.resolvedIp.length > 0) {
            Text(this.resolvedIp)
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_TEXT_TERTIARY)
          }
          if (this.isRunning) {
            Row({ space: 4 }) {
              Circle().width(5).height(5)
                .fill(COLOR_SKY_BLUE)
                .opacity(this.pulseOpacity)
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
      .backgroundColor(COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(10)
      .onClick(() => {
        this.viewMode = 'idle'
        this.inputText = this.targetHost
      })
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
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
    .backgroundColor(COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  @Builder StatCell(label: Resource | string, value: string, valueColor: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(FONT_SIZE_2XL)
        .fontColor(valueColor)
        .fontWeight(FONT_WEIGHT_BOLD)
      Text(label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(COLOR_TEXT_TERTIARY)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder StatDivider() {
    Column()
      .width(1).height(36)
      .backgroundColor(COLOR_SKY_BLUE_DIVIDER)
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
            .fontColor(COLOR_TEXT_PRIMARY)
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
          .backgroundColor(COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      // 分割线
      Column().width('100%').height(0.5).backgroundColor(COLOR_SKY_BLUE_DIVIDER)

      // 时间线列表
      Column({ space: 0 }) {
        ForEach(this.hopList, (hop: TracerouteHop, index: number) => {
          this.PathNode(hop, index)
        }, (hop: TracerouteHop, index: number): string => String(index + '_' + hop.hopIndex))
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
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
              : COLOR_TEXT_TERTIARY)
            .fontWeight(FONT_WEIGHT_BOLD)
        }

        // 连接竖线
        if (!this.isLastHop(index) || this.isRunning) {
          Column()
            .width(1.5)
            .layoutWeight(1)
            .backgroundColor(hop.status === 'success' ? COLOR_GLASS_SKY_LINE : 'rgba(148,163,184,0.25)')
            .margin({ top: 3, bottom: 3 })
        } else {
          Column().height(SPACE_SM)
        }
      }
      .width(30)
      .alignItems(HorizontalAlign.Center)

      // 右侧节点信息
      Column({ space: SPACE_XS }) {
        Row({ space: SPACE_SM }) {
          Text(hop.address === '*' ? $r('app.string.no_response') : hop.address)
            .fontSize(FONT_SIZE_SM)
            .fontColor(hop.address === '*' ? COLOR_TEXT_TERTIARY : COLOR_TEXT_PRIMARY)
            .fontWeight(hop.address === '*' ? FontWeight.Normal : FONT_WEIGHT_BOLD)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (hop.latency > 0) {
            Text(hop.latency + 'ms')
              .fontSize(FONT_SIZE_XS)
              .fontColor(this.getLatencyColor(hop.latency))
              .fontWeight(FONT_WEIGHT_BOLD)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(this.getLatencyColor(hop.latency) + '18')
              .borderRadius(999)
          } else {
            Text($r('app.string.timeout'))
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_TEXT_TERTIARY)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor('rgba(148,163,184,0.2)')
              .borderRadius(999)
          }
        }
        .width('100%')

        // 主机名
        if (hop.hostname !== '' && hop.hostname !== '*') {
          Text(hop.hostname)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_TEXT_TERTIARY)
            .width('100%')
        }

        // 标签行
        Row({ space: 6 }) {
          if (hop.hopIndex === 1) {
            Text($r('app.string.gateway_tag'))
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_SKY_BLUE)
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
              .backgroundColor(COLOR_GLASS_SKY_TAG_BG)
              .borderRadius(999)
          }
          if (this.isLastHop(index) && hop.address !== '*') {
            Text($r('app.string.target_tag'))
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_SUCCESS)
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
              .backgroundColor(COLOR_SUCCESS + '18')
              .borderRadius(999)
          }
          if (hop.latency > 0) {
            Text(this.getLatencyLabelResource(hop.latency))
              .fontSize(FONT_SIZE_XS)
              .fontColor(this.getLatencyColor(hop.latency))
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
              .backgroundColor(this.getLatencyColor(hop.latency) + '15')
              .borderRadius(999)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 12, top: 4, bottom: 8 })
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
          .opacity(this.pulseOpacity)
        Circle().width(52).height(52)
          .fill(COLOR_SKY_BLUE_DIVIDER)
          .opacity(this.pulseOpacity)
        Image($r('app.media.ic_route')).width(26).height(26).fillColor(COLOR_SKY_BLUE)
      }
      Text($r('app.string.tracing_path'))
        .fontSize(FONT_SIZE_MD)
        .fontColor(COLOR_TEXT_SECONDARY)
      Text($r('app.string.trace_duration_hint'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(COLOR_TEXT_TERTIARY)
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      // 返回按钮
      Row() {
        Text($r('app.string.back')).fontSize(FONT_SIZE_MD).fontColor(COLOR_SKY_BLUE).fontWeight(FONT_WEIGHT_MEDIUM)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(999)
      .borderWidth(1)
      .borderColor(COLOR_GLASS_BORDER)
      .onClick(() => RouterManager.goBack())

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
        .shadow({ radius: GLASS_SHADOW_SM, color: 'rgba(239,68,68,0.35)', offsetX: 0, offsetY: 5 })
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
