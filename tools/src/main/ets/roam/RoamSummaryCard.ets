// 漫游测试 — 测试摘要卡片 — Aurora WiFi V2

import {
  COLOR_SUCCESS, COLOR_WARNING, COLOR_INFO,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_2XL,
  GLASS_BLUR_LG,
  adaptiveTextPrimary, adaptiveTextTertiary,
  adaptiveCardBg, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { RoamTestSummary } from '../roamtest/RoamTestEngine'

// ==================== 测试摘要卡片 ====================
@Component
export struct RoamSummaryCard {
  @Prop isDarkMode: boolean = false
  @Prop summary: RoamTestSummary = {
    stabilityScore: 0, roamCount: 0, bssidCount: 0,
    avgRssi: 0, minRssi: 0, maxRssi: 0, totalDuration: 0, roamEvents: []
  }
  formatDuration: (sec: number) => string = (sec: number) => String(sec) + 's'
  getStabilityColor: (score: number) => ResourceColor = (): ResourceColor => COLOR_SUCCESS
  getStabilityLabel: (score: number) => string = (): string => ''

  build() {
    if (this.summary) {
      Column({ space: SPACE_LG }) {
        // 稳定性评分
        Row({ space: SPACE_XL }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle().width(80).height(80).fill(this.getStabilityColor(this.summary.stabilityScore) + '20')
            Text(String(this.summary.stabilityScore))
              .fontSize(FONT_SIZE_3XL).fontColor(this.getStabilityColor(this.summary.stabilityScore))
              .fontWeight(FONT_WEIGHT_BOLD)
          }
          .width(80).height(80)

          Column({ space: SPACE_SM }) {
            Text($r('app.string.stability_score'))
              .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
            Text(this.getStabilityLabel(this.summary.stabilityScore))
              .fontSize(FONT_SIZE_SM).fontColor(this.getStabilityColor(this.summary.stabilityScore))
            Text() {
              Span($r('app.string.test_duration'))
              Span(': ' + this.formatDuration(Math.round(this.summary.totalDuration / 1000)))
            }
              .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        .width('100%')

        // 分割线
        Row()
          .width('100%').height(1)
          .backgroundColor(adaptiveDivider(this.isDarkMode))

        // 详细数据
        Row({ space: SPACE_XL }) {
          Column({ space: SPACE_XS }) {
            Text($r('app.string.roam_count')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
            Text() {
              Span(String(this.summary.roamCount))
              Span(' ')
              Span($r('app.string.times_suffix'))
            }
              .fontSize(FONT_SIZE_2XL)
              .fontColor(this.summary.roamCount === 0 ? COLOR_SUCCESS : COLOR_WARNING)
              .fontWeight(FONT_WEIGHT_BOLD)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)

          Column({ space: SPACE_XS }) {
            Text($r('app.string.roaming_ap')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
            Text() {
              Span(String(this.summary.bssidCount))
              Span(' ')
              Span($r('app.string.count_suffix'))
            }
              .fontSize(FONT_SIZE_2XL).fontColor(COLOR_INFO).fontWeight(FONT_WEIGHT_BOLD)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)

          Column({ space: SPACE_XS }) {
            Text($r('app.string.signal_range')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
            Text(String(this.summary.minRssi) + '~' + String(this.summary.maxRssi))
              .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%').padding(SPACE_LG)
      .backgroundColor(adaptiveCardBg(this.isDarkMode))
      .borderRadius(RADIUS_2XL)
      .border({ width: 1, color: adaptiveDivider(this.isDarkMode) })
      .backdropBlur(GLASS_BLUR_LG)
    }
  }
}
