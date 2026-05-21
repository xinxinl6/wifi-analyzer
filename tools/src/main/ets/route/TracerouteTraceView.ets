// 路由追踪 — 追踪结果视图组件
// 包含：目标信息卡片 + 统计概览卡片

import { COLOR_TEXT_TERTIARY,
  COLOR_SUCCESS, COLOR_DANGER,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_ACTIVE,
  FONT_SIZE_XS, FONT_SIZE_LG, FONT_SIZE_2XL,
  FONT_WEIGHT_BOLD,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  adaptiveTextPrimary, adaptiveTextTertiary, adaptiveDivider } from '@wifi-analyzer/design-system'
import { TracerouteStats } from '../traceroute/TracerouteEngine'

@Component
export struct TracerouteTraceView {
  @Prop isDarkMode: boolean = false
  @Prop targetHost: string = ''
  @Prop resolvedIp: string = ''
  @Prop isRunning: boolean = false
  @Prop viewMode: string = 'tracing'
  @Prop pulserOpacity: number = 1.0
  @Prop traceStats: TracerouteStats = {
    totalHops: 0, successHops: 0, failedHops: 0,
    avgLatency: 0, maxLatency: 0, minLatency: 0, totalLatency: -1
  }
  onSearchTap: () => void = () => {}

  build() {
    Column({ space: 0 }) {
      // 目标信息卡片
      this.TargetInfoCard()

      // 统计概览
      this.StatsOverviewCard()
    }
    .width('100%')
  }

  // 目标信息卡片
  @Builder TargetInfoCard() {
    Row({ space: 14 }) {
      // 脉冲图标
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? COLOR_GLASS_SKY_ACTIVE : COLOR_GLASS_SKY_LIGHT)
          .opacity(this.isRunning ? this.pulserOpacity : 1.0)
        Circle().width(36).height(36)
          .fill(this.isRunning ? COLOR_SKY_BLUE : (this.viewMode === 'completed' ? COLOR_SUCCESS : COLOR_SKY_BLUE))
        Image($r('app.media.ic_route')).width(18).height(18).fillColor(adaptiveTextPrimary(this.isDarkMode))
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
                .opacity(this.pulserOpacity)
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
        Text('\u{1F50D}').fontSize(14)
      }
      .width(34).height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_SKY_ACTIVE : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(10)
      .onClick(() => this.onSearchTap())
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
}
