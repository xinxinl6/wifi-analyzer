// Ping 历史趋势图表组件

import { adaptiveTextTertiary, adaptiveDivider,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_DARK_BORDER } from '@wifi-analyzer/design-system'
import { PingSessionSummary } from './PingTestPage'
import { PingStatsHelper } from '../utils/PingStatsHelper'
import { SPACE_XS, SPACE_MD } from '@wifi-analyzer/design-system'
import { FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD } from '@wifi-analyzer/design-system'

/**
 * PingTrendChart - 历史趋势图表组件
 * 显示历史 Ping 会话的稳定性趋势
 */
@Component
export struct PingTrendChart {
  @Prop isDarkMode: boolean = false
  @Prop sessionSummaries: PingSessionSummary[] = []

  build() {
    if (this.sessionSummaries.length === 0) {
      this.EmptyState()
    } else {
      this.TrendChartBody()
    }
  }

  @Builder
  EmptyState() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.no_history_data_trend'))
        .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextTertiary(this.isDarkMode))
      Text($r('app.string.trend_hint'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%').height(120).justifyContent(FlexAlign.Center)
  }

  @Builder
  TrendChartBody() {
    Column() {
      Row({ space: SPACE_XS }) {
        // Y 轴刻度列
        Column({ space: 0 }) {
          Text('100').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(24).textAlign(TextAlign.End)
          Text('50').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(24).textAlign(TextAlign.End)
          Text('0').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(24).textAlign(TextAlign.End)
        }
        .height(100).justifyContent(FlexAlign.SpaceBetween)

        // 折线图绘制区
        Stack({ alignContent: Alignment.Bottom }) {
          Column() {
            Row().width('100%').height(50).border({
              width: { bottom: 0.5 },
              color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER
            })
            Row().width('100%').height(50)
          }.width('100%').height(100)

          Row() {
            ForEach(this.sessionSummaries, (summary: PingSessionSummary, index: number) => {
              Column() {
                Circle()
                  .width(6).height(6)
                  .fill(PingStatsHelper.getStabilityColor(summary.stabilityScore, this.isDarkMode))
                  .margin({ bottom: (summary.stabilityScore / 100) * 100 - 4 })

                Text(PingStatsHelper.formatTime(summary.timestamp))
                  .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
                  .margin({ top: 4 })
              }.alignItems(HorizontalAlign.Center)
            }, (summary: PingSessionSummary, index: number): string => String(index + '_' + summary.timestamp))
          }.width('100%').padding({ left: 4, right: 4 }).position({ x: 0, y: 0 })
        }
        .width('100%').constraintSize({ maxHeight: 100 })
      }
      .width('100%')
    }.width('100%')
  }
}
