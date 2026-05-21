// 漫游测试 — 漫游事件列表 — Aurora WiFi V2

import {
  COLOR_ORANGE, COLOR_SUCCESS,
  FONT_SIZE_XS, FONT_SIZE_MD,
  FONT_WEIGHT_BOLD, FONT_WEIGHT_MEDIUM,
  SPACE_SM, SPACE_MD, SPACE_LG,
  RADIUS_2XL,
  GLASS_BLUR_LG,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveCardBg, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { RoamEvent, RoamTestSummary, RoamTestEngine } from '../roamtest/RoamTestEngine'
import { RssiLevel } from './RoamTestingView'

// ==================== 漫游事件列表 ====================
@Component
export struct RoamEventsList {
  @Prop isDarkMode: boolean = false
  @Prop showEvents: boolean = false
  @Prop summary: RoamTestSummary = {
    stabilityScore: 0, roamCount: 0, bssidCount: 0,
    avgRssi: 0, minRssi: 0, maxRssi: 0, totalDuration: 0, roamEvents: []
  }
  onToggleEvents: () => void = () => {}
  getRssiLevel: (rssi: number) => RssiLevel = (): RssiLevel => ({ label: '', color: COLOR_SUCCESS })

  build() {
    if (this.summary && this.summary.roamEvents.length > 0) {
      Column({ space: SPACE_SM }) {
        Row() {
          Text($r('app.string.roam_events_detail'))
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          Blank()
          Text(this.showEvents ? $r('app.string.collapse') : $r('app.string.expand'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_ORANGE)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => { this.onToggleEvents() })
        }
        .width('100%')

        if (this.showEvents) {
          ForEach(this.summary.roamEvents, (event: RoamEvent, index: number) => {
            this.RoamEventRow(event, index)
          }, (event: RoamEvent, index: number): string => String(index))
        } else {
          Text() {
            Span($r('app.string.total_roam_events'))
            Span(' ' + String(this.summary.roamEvents.length) + ' ')
            Span($r('app.string.roam_event_hint'))
          }
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
      }
      .width('100%').padding(SPACE_LG)
      .backgroundColor(adaptiveCardBg(this.isDarkMode))
      .borderRadius(RADIUS_2XL)
      .border({ width: 1, color: adaptiveDivider(this.isDarkMode) })
      .backdropBlur(GLASS_BLUR_LG)
    }
  }

  @Builder RoamEventRow(event: RoamEvent, index: number) {
    Row({ space: SPACE_MD }) {
      // 序号
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(24).height(24)
          .fill(this.isDarkMode ? 'rgba(251,146,60,0.18)' : 'rgba(251,146,60,0.13)')
        Text('#' + String(index + 1))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_ORANGE).fontWeight(FONT_WEIGHT_BOLD)
      }

      // 事件详情
      Column({ space: SPACE_SM }) {
        Row({ space: SPACE_SM }) {
          Text(RoamTestEngine.formatBssid(event.fromBssid))
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
          Text(' → ')
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_ORANGE).fontWeight(FONT_WEIGHT_BOLD)
          Text(RoamTestEngine.formatBssid(event.toBssid))
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        Row({ space: SPACE_SM }) {
          Text(String(event.rssiBefore) + 'dBm')
            .fontSize(FONT_SIZE_XS).fontColor(this.getRssiLevel(event.rssiBefore).color)
          Text('→')
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text(String(event.rssiAfter) + 'dBm')
            .fontSize(FONT_SIZE_XS).fontColor(this.getRssiLevel(event.rssiAfter).color)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(adaptiveDivider(this.isDarkMode))
          Text(String(event.duration) + 'ms')
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding({ top: SPACE_SM, bottom: SPACE_SM })
  }
}
