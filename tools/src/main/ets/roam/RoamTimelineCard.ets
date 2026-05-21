// 漫游测试 — BSSID 时间线卡片 — Aurora WiFi V2

import {
  COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER, COLOR_INFO,
  FONT_SIZE_XXS, FONT_SIZE_XS, FONT_SIZE_MD,
  FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD, SPACE_LG,
  RADIUS_2XL,
  GLASS_BLUR_LG,
  adaptiveTextPrimary, adaptiveTextTertiary,
  adaptiveCardBg, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BssidRecord } from '../roamtest/RoamTestEngine'
import { RssiLevel } from './RoamTestingView'

// ==================== BSSID 时间线卡片 ====================
@Component
export struct RoamTimelineCard {
  @Prop isDarkMode: boolean = false
  @Prop bssidHistory: BssidRecord[] = []
  getRssiLevel: (rssi: number) => RssiLevel = (): RssiLevel => ({ label: '', color: COLOR_SUCCESS })

  build() {
    if (this.bssidHistory.length > 0) {
      Column({ space: SPACE_SM }) {
        Row() {
          Text($r('app.string.bssid_history'))
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          Blank()
          Text() {
            Span($r('app.string.recent_records'))
            Span(' ' + String(this.bssidHistory.length) + ' ')
            Span($r('app.string.records_suffix'))
          }
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .width('100%')

        // 信号强度可视化（用水平色条表示）
        Scroll() {
          Row({ space: 2 }) {
            ForEach(this.bssidHistory, (record: BssidRecord) => {
              Column() {
                Stack() {
                  Row()
                    .width(4)
                    .height(record.rssi > -40 ? 40 : record.rssi > -60 ? 32 : record.rssi > -70 ? 24 : 16)
                    .backgroundColor(this.getRssiLevel(record.rssi).color)
                    .borderRadius(2)
                }
              }
            }, (record: BssidRecord, index: number): string => String(index))
          }
          .width('100%')
          .padding({ top: SPACE_SM, bottom: SPACE_SM })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        // 图例
        Row({ space: SPACE_LG }) {
          Row({ space: SPACE_SM }) {
            Circle().width(8).height(8).fill(COLOR_SUCCESS)
            Text($r('app.string.signal_ge_neg50')).fontSize(FONT_SIZE_XXS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
          Row({ space: SPACE_SM }) {
            Circle().width(8).height(8).fill(COLOR_INFO)
            Text($r('app.string.signal_ge_neg60')).fontSize(FONT_SIZE_XXS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
          Row({ space: SPACE_SM }) {
            Circle().width(8).height(8).fill(COLOR_WARNING)
            Text($r('app.string.signal_ge_neg70')).fontSize(FONT_SIZE_XXS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
          Row({ space: SPACE_SM }) {
            Circle().width(8).height(8).fill(COLOR_DANGER)
            Text($r('app.string.signal_lt_neg70')).fontSize(FONT_SIZE_XXS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
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
