// Ping 测试 - 测试视图组件
// 天蓝色毛玻璃风格

import { adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveCardBg, adaptiveDivider,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER, COLOR_GLASS_SKY_SHADOW_MED,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL } from '@wifi-analyzer/design-system'
import { PingResult, PingStats, PingSessionSummary } from './PingTestPage'

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
  isChartBest: (item: PingResult) => boolean
  isChartWorst: (item: PingResult) => boolean
  onEndTest: () => void
  onTogglePause: () => void
  onChartModeChange: (mode: string) => void
}

// ==================== 测试视图 ====================
@Component
export struct TestingView {
  @Prop isDarkMode: boolean = false
  @State pingHistory: PingResult[] = []
  @State sessionStats: PingStats = {
    sentCount: 0, receivedCount: 0, lossRate: 0,
    minTime: 0, maxTime: 0, avgTime: 0, jitter: 0, stabilityScore: 0
  }
  @State sessionSummaries: PingSessionSummary[] = []
  @State targetHost: string = ''
  @State resolvedIp: string = ''
  @State isTesting: boolean = false
  @State isPaused: boolean = false
  @State chartMode: string = 'live'
  @State chartData: PingResult[] = []
  @State chartMaxY: number = 100
  @State chartAvgMs: number = 0
  @State chartMinMs: number = 0
  @State chartMaxMs: number = 0
  @State lastPingResult: PingResult | null = null

  isChartBest: (item: PingResult) => boolean = () => false
  isChartWorst: (item: PingResult) => boolean = () => false
  onEndTest: () => void = () => {}
  onTogglePause: () => void = () => {}
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
          this.StatsOverviewCard()
        }

        // 图表卡片
        if (this.pingHistory.length > 0) {
          this.ChartCard()
        }

        // 操作按钮
        this.ActionButtons()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
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
        Circle().width(44).height(44).fill(this.isDarkMode ? 'rgba(14,165,233,0.12)' : COLOR_GLASS_SKY_LIGHT)
        Circle().width(36).height(36)
          .fill(this.isTesting ? (this.isPaused ? COLOR_WARNING : COLOR_SKY_BLUE) : COLOR_SUCCESS)
        Image($r('app.media.ic_ping')).width(18).height(18).fillColor('#FFFFFF')
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
    .padding({ left: 16, right: 16, top: 20, bottom: 20 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(20)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 统计概览 — 4 格毛玻璃卡片 ====================
  @Builder StatsOverviewCard() {
    Column({ space: 0 }) {
      // 第一行：发送 / 接收 / 丢包
      Row() {
        this.StatCell($r('app.string.ping_count'), String(this.sessionStats.sentCount), COLOR_SKY_BLUE)
        this.StatDivider()
        this.StatCell($r('app.string.ping_received'), String(this.sessionStats.receivedCount), COLOR_SUCCESS)
        this.StatDivider()
        this.StatCell($r('app.string.ping_loss'), String(this.sessionStats.lossRate) + '%', COLOR_DANGER)
      }
      .width('100%')

      Column().width('100%').height(0.5).backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER)

      // 第二行：最大 / 最小 / 平均
      Row() {
        this.StatCell($r('app.string.ping_max'), this.sessionStats.maxTime > 0 ? String(this.sessionStats.maxTime) + 'ms' : '--', COLOR_SKY_BLUE_LIGHT)
        this.StatDivider()
        this.StatCell($r('app.string.ping_min'), this.sessionStats.minTime > 0 ? String(this.sessionStats.minTime) + 'ms' : '--', COLOR_SUCCESS)
        this.StatDivider()
        this.StatCell($r('app.string.ping_avg'), this.sessionStats.avgTime > 0 ? String(this.sessionStats.avgTime) + 'ms' : '--', COLOR_SKY_BLUE)
      }
      .width('100%')

      Column().width('100%').height(0.5).backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER)

      // 第三行：抖动 / 稳定性
      Row() {
        this.StatCell($r('app.string.jitter'), this.sessionStats.jitter > 0 ? String(this.sessionStats.jitter) + 'ms' : '--', COLOR_WARNING)
        this.StatDivider()
        this.StatCell($r('app.string.stability'), String(this.sessionStats.stabilityScore), this.getStabilityColor(this.sessionStats.stabilityScore))
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
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
    .padding({ top: 14, bottom: 14 })
  }

  @Builder StatDivider() {
    Column()
      .width(1).height(36)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER)
  }

  getStabilityColor(score: number): string {
    if (score >= 80) return COLOR_SUCCESS
    if (score >= 60) return COLOR_SKY_BLUE
    if (score >= 40) return COLOR_WARNING
    return COLOR_DANGER
  }

  // ==================== 图表卡片 ====================
  @Builder ChartCard() {
    Column({ space: SPACE_SM }) {
      // 选项卡选择器
      Row({ space: SPACE_SM }) {
        Text($r('app.string.live_chart'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(this.chartMode === 'live' ? '#FFFFFF' : COLOR_SKY_BLUE)
          .fontWeight(this.chartMode === 'live' ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.chartMode === 'live' ? COLOR_SKY_BLUE : 'rgba(14,165,233,0.1)')
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(this.chartMode === 'live' ? COLOR_SKY_BLUE : COLOR_GLASS_SKY_TAG_BORDER)
          .onClick(() => { this.onChartModeChange('live') })
          .layoutWeight(1)

        Text($r('app.string.history_trend'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(this.chartMode === 'trend' ? '#FFFFFF' : COLOR_SKY_BLUE)
          .fontWeight(this.chartMode === 'trend' ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.chartMode === 'trend' ? COLOR_SKY_BLUE : 'rgba(14,165,233,0.1)')
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(this.chartMode === 'trend' ? COLOR_SKY_BLUE : COLOR_GLASS_SKY_TAG_BORDER)
          .onClick(() => { this.onChartModeChange('trend') })
          .layoutWeight(1)
      }
      .width('100%')

      // 图例
      if (this.chartMode === 'live') {
        Row({ space: SPACE_LG }) {
          Row({ space: 4 }) {
            Circle().width(8).height(8).fill(COLOR_SUCCESS)
            Text($r('app.string.best')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
          }
          Row({ space: 4 }) {
            Circle().width(8).height(8).fill(COLOR_DANGER)
            Text($r('app.string.worst')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
          }
          Row({ space: 4 }) {
            Circle().width(8).height(8).fill(COLOR_SKY_BLUE)
            Text($r('app.string.avg')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
          }
        }
        .width('100%')
        .padding({ top: SPACE_XS })
      }

      // 图表区域
      if (this.chartMode === 'live') {
        this.BarChartWithData()
      } else {
        this.TrendChartBody()
      }
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

  // ==================== 柱状图数据 ====================
  @Builder BarChartWithData() {
    Column() {
      Row({ space: SPACE_XS }) {
        // Y 轴刻度列
        Column({ space: 0 }) {
          Text(String(Math.round(this.chartMaxY))).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(20).textAlign(TextAlign.End)
          Text(String(Math.round(this.chartMaxY * 0.5))).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(20).textAlign(TextAlign.End)
          Text('0').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(20).textAlign(TextAlign.End)
        }
        .height(160).justifyContent(FlexAlign.SpaceBetween).alignItems(HorizontalAlign.End)

        // 图表区域（使用 Stack 叠加）
        Column() {
          // 背景网格
          Column() {
            Row().width('100%').height(80).backgroundColor('rgba(14,165,233,0.03)')
            Row().width('100%').height(80).backgroundColor(Color.Transparent)
          }
          .width('100%').height(160)

          // 平均值参考线
          if (this.chartAvgMs > 0) {
            Row() {
              Text() {
                Span($r('app.string.avg_colon'))
                Span(' ' + String(Math.round(this.chartAvgMs * 10) / 10) + 'ms')
              }
                .fontSize(FONT_SIZE_XS).fontColor(COLOR_SKY_BLUE).opacity(0.8)
            }
            .width('100%')
            .height(160)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Top)
            .margin({ top: Math.max(0, (1 - this.chartAvgMs / this.chartMaxY) * 160) })
          }

          // 柱子容器
          Row() {
            ForEach(this.chartData, (item: PingResult, index: number) => {
              Column() {
                // 柱子上部分（透明占位，让柱子底部对齐）
                Blank()
                  .height(
                    item.status === 'success'
                      ? Math.max(0, 160 - (item.timeMs / this.chartMaxY) * 160)
                      : 160 - 4
                  )
                // 柱子
                Column()
                  .width(8)
                  .height(
                    item.status === 'success'
                      ? Math.max(2, (item.timeMs / this.chartMaxY) * 160)
                      : 4
                  )
                  .borderRadius({ topLeft: 2, topRight: 2 })
                  .backgroundColor(
                    this.isChartBest(item) ? COLOR_SUCCESS :
                      (this.isChartWorst(item) ? COLOR_DANGER :
                        (item.status === 'success' ? COLOR_SKY_BLUE : COLOR_SKY_BLUE_DIVIDER)))
                // 底部标签
                Text(String(index + 1))
                  .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
              }
              .alignItems(HorizontalAlign.Center)
            }, (item: PingResult, index: number): string => String(index + '_' + item.timestamp))
          }
          .width('100%')
          .padding({ left: 2, right: 2 })
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
    }.width('100%')
  }

  // ==================== 历史趋势图表 ====================
  @Builder TrendChartBody() {
    if (this.sessionSummaries.length === 0) {
      Column({ space: SPACE_MD }) {
        Text($r('app.string.no_history_data'))
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextTertiary(this.isDarkMode))
        Text($r('app.string.chart_hint'))
          .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .width('100%').height(180).justifyContent(FlexAlign.Center)
    } else {
      Column() {
        Row({ space: SPACE_XS }) {
          // Y 轴刻度列
          Column({ space: 0 }) {
            Text('100').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(24).textAlign(TextAlign.End)
            Text('50').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(24).textAlign(TextAlign.End)
            Text('0').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(24).textAlign(TextAlign.End)
          }
          .height(160).justifyContent(FlexAlign.SpaceBetween)

          // 折线图绘制区
          Stack({ alignContent: Alignment.Bottom }) {
            Column() {
              Row().width('100%').height(80).border({ width: { bottom: 0.5 }, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER })
              Row().width('100%').height(80)
            }.width('100%').height(160)

            Row() {
              ForEach(this.sessionSummaries, (summary: PingSessionSummary, index: number) => {
                Column() {
                  Circle()
                    .width(8).height(8)
                    .fill(this.getStabilityColor(summary.stabilityScore))
                    .margin({ bottom: (summary.stabilityScore / 100) * 160 - 4 })

                  Text(this.formatTime(summary.timestamp))
                    .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
                    .margin({ top: 4 })
                }.alignItems(HorizontalAlign.Center)
              }, (summary: PingSessionSummary, index: number): string => String(index + '_' + summary.timestamp))
            }.width('100%').padding({ left: 4, right: 4 }).position({ x: 0, y: 0 })
          }
          .width('100%').constraintSize({ maxHeight: 160 })
        }
        .width('100%')
      }.width('100%')
    }
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${hours}:${minutes}`
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
      .backgroundColor(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(999)
      .borderWidth(1)
      .borderColor(this.isDarkMode ? 'rgba(14,165,233,0.25)' : COLOR_GLASS_SKY_TAG_BORDER)
      .onClick(() => this.onEndTest())

      // 暂停/继续按钮
      Row() {
        Text(this.isPaused ? $r('app.string.continue_action') : $r('app.string.pause_action'))
          .fontSize(FONT_SIZE_MD)
          .fontColor('#FFFFFF')
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
