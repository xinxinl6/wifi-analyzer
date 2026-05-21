// 漫游测试 — 测试进行中卡片 — Aurora WiFi V2

import {
  COLOR_WARNING, COLOR_SUCCESS, COLOR_ORANGE,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_2XL,
  FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_2XL,
  GLASS_BLUR_LG,
  adaptiveTextPrimary, adaptiveTextTertiary,
  adaptiveCardBg, adaptiveDivider
} from '@wifi-analyzer/design-system'

// ==================== 类型定义 ====================

export interface RssiLevel {
  label: string
  color: ResourceColor
}

// ==================== 测试进行中卡片 ====================
@Component
export struct RoamTestingCard {
  @Prop isDarkMode: boolean = false
  @Prop currentRssi: number = 0
  @Prop elapsedSec: number = 0
  @Prop totalSec: number = 60
  @Prop roamCount: number = 0
  @Prop avgRssi: number = 0
  formatDuration: (sec: number) => string = (sec: number) => String(sec) + 's'
  getRssiLevel: (rssi: number) => RssiLevel = (): RssiLevel => ({ label: '', color: COLOR_SUCCESS })

  // 获取资源字符串的辅助方法
  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
      return ''
    }
  }

  build() {
    Column({ space: SPACE_MD }) {
      // 环形进度 + 信号强度
      Row({ space: SPACE_XL }) {
        // 倒计时
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(80).height(80)
            .fill(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(255,255,255,0.5)')
          Text(this.formatDuration(this.totalSec - this.elapsedSec))
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_ORANGE).fontWeight(FONT_WEIGHT_BOLD)
        }
        .width(80).height(80)

        // 实时数据
        Column({ space: SPACE_SM }) {
          Row({ space: SPACE_XL }) {
            Column({ space: SPACE_XS }) {
              Text($r('app.string.signal_label')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
              Text(String(this.currentRssi) + ' dBm')
                .fontSize(FONT_SIZE_MD).fontColor(this.getRssiLevel(this.currentRssi).color)
                .fontWeight(FONT_WEIGHT_BOLD)
            }
            .alignItems(HorizontalAlign.Start)

            Column({ space: SPACE_XS }) {
              Text($r('app.string.avg_signal')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
              Text(String(this.avgRssi) + ' dBm')
                .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
            }
            .alignItems(HorizontalAlign.Start)

            Column({ space: SPACE_XS }) {
              Text($r('app.string.roam_label')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
              Text() {
                Span(String(this.roamCount))
                Span(' ')
                Span($r('app.string.times_suffix'))
              }
                .fontSize(FONT_SIZE_MD)
                .fontColor(this.roamCount === 0 ? COLOR_SUCCESS : COLOR_WARNING)
                .fontWeight(FONT_WEIGHT_BOLD)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 进度条
      Row() {
        Row()
          .width(this.elapsedSec > 0 && this.totalSec > 0
            ? Math.min(100, Math.round(this.elapsedSec / this.totalSec * 100)) + '%' : '0%')
          .height(4).backgroundColor(COLOR_ORANGE).borderRadius(2)
      }
      .width('100%').height(4)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)')
      .borderRadius(2)

      Row({ space: SPACE_SM }) {
        Text() {
          Span($r('app.string.tested'))
          Span(' ' + this.formatDuration(this.elapsedSec))
        }
          .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        Blank()
        Text() {
          Span($r('app.string.total_duration'))
          Span(' ' + this.formatDuration(this.totalSec))
        }
          .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
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
