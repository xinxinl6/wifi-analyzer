// Ping 测试 - 测试视图组件
// 天蓝色毛玻璃风格

import { adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveCardBg, adaptiveDivider,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER, COLOR_GLASS_SKY_SHADOW_MED,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_SKY_BLUE_GAUGE_BG, COLOR_SIGNAL_TEXT_ON_BG,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL } from '@wifi-analyzer/design-system'
import { PingResult, PingStats, PingSessionSummary } from './PingTestPage'
import { PingMode, getDuration } from '../utils/NativePing'
import { PingStatsCard } from './PingStatsCard'
import { PingLiveChart } from './PingLiveChart'
import { PingTrendChart } from './PingTrendChart'

// ==================== Props 接口 ====================
export interface TestingViewProps {
  isDarkMode: boolean
  pingHistory: PingResult[]
  sessionStats: PingStats
  sessionSummaries: PingSessionSummary[]
  targetHost: string
  resolvedIp: string
  isTesting: boolean
  isPaused: boolean
  chartMode: string
  chartData: PingResult[]
  chartMaxY: number
  chartAvgMs: number
  chartMinMs: number
  chartMaxMs: number
  lastPingResult: PingResult | null
  pingMode: PingMode
  isChartBest: (item: PingResult) => boolean
  isChartWorst: (item: PingResult) => boolean
  onEndTest: () => void
  onTogglePause: () => void
  onToggleMode: () => void
  onChartModeChange: (mode: string) => void
}

// ==================== 测试视图 ====================
@Component
export struct TestingView {
  @Prop isDarkMode: boolean = false
  @Prop pingHistory: PingResult[] = []
  @Prop sessionStats: PingStats = {
    sentCount: 0, receivedCount: 0, lossRate: 0,
    minTime: 0, maxTime: 0, avgTime: 0, jitter: 0, stabilityScore: 0
  }
  @Prop sessionSummaries: PingSessionSummary[] = []
  @Prop targetHost: string = ''
  @Prop resolvedIp: string = ''
  @Prop isTesting: boolean = false
  @Prop isPaused: boolean = false
  @Prop chartMode: string = 'live'
  @Prop chartData: PingResult[] = []
  @Prop chartMaxY: number = 100
  @Prop chartAvgMs: number = 0
  @Prop chartMinMs: number = 0
  @Prop chartMaxMs: number = 0
  @Prop lastPingResult: PingResult | null = null
  @Prop pingMode: PingMode = PingMode.FAST

  isChartBest: (item: PingResult) => boolean = () => false
  isChartWorst: (item: PingResult) => boolean = () => false
  onEndTest: () => void = () => {}
  onTogglePause: () => void = () => {}
  onToggleMode: () => void = () => {}
  onChartModeChange: (mode: string) => void = () => {}

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 目标信息卡片
        this.TargetInfoCard()

        // 最新单条 ping 结果
        if (this.lastPingResult !== null) {
          this.LatestPingCard()
        }

        // 统计概览
        if (this.pingHistory.length > 0) {
          PingStatsCard({
            sentCount: this.sessionStats.sentCount,
            receivedCount: this.sessionStats.receivedCount,
            lossRate: this.sessionStats.lossRate,
            maxTime: this.sessionStats.maxTime,
            minTime: this.sessionStats.minTime,
            avgTime: this.sessionStats.avgTime,
            jitter: this.sessionStats.jitter,
            stabilityScore: this.sessionStats.stabilityScore
          })
        }

        // 图表卡片
        if (this.pingHistory.length > 0) {
          this.ChartCard()
        }

        // 操作按钮
        this.ActionButtons()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: 0, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // ==================== 目标信息卡片 ====================
  @Builder TargetInfoCard() {
    Row({ space: 14 }) {
      // 图标容器
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44).fill(this.isDarkMode ? COLOR_GLASS_SKY_ACTIVE : COLOR_GLASS_SKY_LIGHT)
        Circle().width(36).height(36)
          .fill(this.isTesting ? (this.isPaused ? COLOR_WARNING : COLOR_SKY_BLUE) : COLOR_SUCCESS)
        Image($r('app.media.ic_ping')).width(18).height(18).fillColor(adaptiveTextPrimary(this.isDarkMode))
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
          // 当前 Ping 模式标签
          Text(this.pingMode === PingMode.FAST ? $r('app.string.ping_fast_mode') : $r('app.string.ping_accurate_mode'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_SKY_BLUE)
            .fontWeight(FONT_WEIGHT_MEDIUM)
          if (this.isTesting) {
            Row({ space: 4 }) {
              Circle().width(5).height(5)
                .fill(this.isPaused ? COLOR_WARNING : COLOR_SKY_BLUE)
              Text(this.isPaused ? $r('app.string.paused') : $r('app.string.testing'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(this.isPaused ? COLOR_WARNING : COLOR_SKY_BLUE)
            }
          } else {
            Row({ space: 4 }) {
              Circle().width(5).height(5).fill(COLOR_SUCCESS)
              Text($r('app.string.test_complete'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SUCCESS)
            }
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 最新单条 ping 结果 ====================
  @Builder LatestPingCard() {
    Row({ space: 14 }) {
      // 序号
      Column({ space: 4 }) {
        Text('#' + String(this.pingHistory.length))
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
        Text(this.lastPingResult?.status === 'success' ? '✓' : '✗')
          .fontSize(FONT_SIZE_2XL)
          .fontColor(this.lastPingResult?.status === 'success' ? COLOR_SUCCESS : COLOR_DANGER)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .alignItems(HorizontalAlign.Center)
      .width(44)

      Column({ space: 2 }) {
        if (this.lastPingResult?.status === 'success') {
          Text(String(this.lastPingResult?.timeMs) + ' ms')
            .fontSize(48)
            .fontColor(COLOR_SKY_BLUE)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontStyle(FontStyle.Normal)
          Text($r('app.string.response_time'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        } else {
          Text(this.lastPingResult?.status === 'timeout' ? '--' : 'ERR')
            .fontSize(48)
            .fontColor(COLOR_DANGER)
            .fontWeight(FONT_WEIGHT_BOLD)
          Text(this.lastPingResult?.status === 'timeout' ? $r('app.string.ping_timeout') : $r('app.string.ping_error'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 图表卡片 ====================
  @Builder ChartCard() {
    Column({ space: SPACE_SM }) {
      // 顶部栏：选项卡 + 图例 + 当前值 一行搞定
      Row({ space: SPACE_SM }) {
        // 选项卡
        Row({ space: SPACE_SM }) {
          Text($r('app.string.live_chart'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(this.chartMode === 'live' ? adaptiveTextPrimary(this.isDarkMode) : COLOR_SKY_BLUE)
            .fontWeight(this.chartMode === 'live' ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.chartMode === 'live' ? COLOR_SKY_BLUE : COLOR_SKY_BLUE_GAUGE_BG)
            .borderRadius(999)
            .onClick(() => { this.onChartModeChange('live') })

          Text($r('app.string.history_trend'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(this.chartMode === 'trend' ? adaptiveTextPrimary(this.isDarkMode) : COLOR_SKY_BLUE)
            .fontWeight(this.chartMode === 'trend' ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.chartMode === 'trend' ? COLOR_SKY_BLUE : COLOR_GLASS_SKY_TAG_BG)
            .borderRadius(999)
            .onClick(() => { this.onChartModeChange('trend') })
        }

        Blank()

        // 图例（紧凑内联）
        if (this.chartMode === 'live') {
          Row({ space: 10 }) {
            Row({ space: 3 }) { Circle().width(6).height(6).fill(COLOR_SUCCESS); Text($r('app.string.best')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDarkMode)) }
            Row({ space: 3 }) { Circle().width(6).height(6).fill(COLOR_DANGER); Text($r('app.string.worst')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDarkMode)) }
          }
        }

        // 实时数值高亮
        if (this.chartMode === 'live' && this.lastPingResult?.status === 'success') {
          Text(String(this.lastPingResult.timeMs) + 'ms')
            .fontSize(13).fontColor(COLOR_SKY_BLUE).fontWeight(FONT_WEIGHT_BOLD)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 图表绘制区 - 使用独立组件
      if (this.chartMode === 'live') {
        PingLiveChart({
          isDarkMode: this.isDarkMode,
          chartData: this.chartData,
          chartMaxY: this.chartMaxY,
          chartAvgMs: this.chartAvgMs,
          chartMinMs: this.chartMinMs,
          chartMaxMs: this.chartMaxMs,
          lastPingResult: this.lastPingResult,
          isChartBest: this.isChartBest,
          isChartWorst: this.isChartWorst
        })
      } else {
        PingTrendChart({
          isDarkMode: this.isDarkMode,
          sessionSummaries: this.sessionSummaries
        })
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 操作按钮 ====================
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      // 结束按钮
      Row() {
        Text($r('app.string.end_test')).fontSize(FONT_SIZE_MD).fontColor(COLOR_SKY_BLUE).fontWeight(FONT_WEIGHT_MEDIUM)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(this.isDarkMode ? COLOR_SKY_BLUE_GAUGE_BG : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(999)
      .borderWidth(1)
      .borderColor(this.isDarkMode ? COLOR_SKY_BLUE_DIVIDER : COLOR_GLASS_SKY_TAG_BORDER)
      .onClick(() => this.onEndTest())

      // 暂停/继续按钮
      Row() {
        Text(this.isPaused ? $r('app.string.continue_action') : $r('app.string.pause_action'))
          .fontSize(FONT_SIZE_MD)
          .fontColor(COLOR_SIGNAL_TEXT_ON_BG)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(this.isPaused ? COLOR_SUCCESS : COLOR_SKY_BLUE)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
      .onClick(() => this.onTogglePause())
    }
    .width('100%')
  }
}
