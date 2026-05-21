// WOL 最近唤醒结果 — Aurora WiFi V2

import {
  COLOR_SUCCESS, COLOR_DANGER, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_WEIGHT_MEDIUM,
  SPACE_MD,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextTertiary
} from '@wifi-analyzer/design-system'
import { WolResult } from '../wol/WolEngine'

// ==================== 最近唤醒结果 ====================
@Component
export struct WolLastResult {
  @Prop isDarkMode: boolean = false
  @Prop lastResult: WolResult | null = null

  build() {
    if (this.lastResult) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(40).height(40)
            .fill(this.lastResult.success
              ? COLOR_SUCCESS
              : COLOR_DANGER)
          Text(this.lastResult.success ? '✓' : '!').fontSize(FONT_SIZE_LG)
            .fontColor(this.lastResult.success ? COLOR_SUCCESS : COLOR_DANGER)
        }
        Column({ space: 4 }) {
          Text(this.lastResult.success ? $r('app.string.wake_success') : $r('app.string.wake_failed'))
            .fontSize(FONT_SIZE_MD).fontColor(this.lastResult.success ? COLOR_SUCCESS : COLOR_DANGER)
            .fontWeight(FONT_WEIGHT_MEDIUM)
          Text(this.lastResult.deviceName + ' (' + this.lastResult.mac + ')')
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.lastResult.success ? COLOR_SUCCESS : COLOR_DANGER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({
        radius: GLASS_SHADOW_LG,
        color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
        offsetX: 0,
        offsetY: 4
      })
      .clip(true)
    }
  }
}
