// 路由追踪 — 操作按钮组件

import { COLOR_SKY_BLUE, COLOR_DANGER,
  COLOR_GLASS_SKY_SHADOW_MED,
  FONT_SIZE_MD,
  FONT_WEIGHT_BOLD,
  SPACE_MD,
  GLASS_SHADOW_SM,
  adaptiveTextPrimary } from '@wifi-analyzer/design-system'
import { BackButtonCapsule } from '@wifi-analyzer/design-system'

@Component
export struct TracerouteActionButtons {
  @Prop isDarkMode: boolean = false
  @Prop isRunning: boolean = false
  @Prop canStart: boolean = true
  onStart: () => void = () => {}
  onStop: () => void = () => {}
  onBack: () => void = () => {}

  build() {
    Row({ space: SPACE_MD }) {
      // 返回按钮（返回空闲页，不退出）
      BackButtonCapsule({
        onBack: () => this.onBack()
      })

      // 停止/重新追踪按钮
      if (this.isRunning) {
        Row() {
          Text($r('app.string.stop_trace')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor(COLOR_DANGER)
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_DANGER, offsetX: 0, offsetY: 5 })
        .onClick(() => this.onStop())
      } else {
        Row() {
          Text($r('app.string.re_trace')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor(COLOR_SKY_BLUE)
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
        .onClick(() => this.onStart())
      }
    }
    .width('100%')
  }
}
