// Ping 操作按钮组件

import {
  COLOR_SKY_BLUE, COLOR_DANGER, COLOR_GLASS_SKY_SHADOW_MED,
  FONT_SIZE_MD, FONT_WEIGHT_BOLD,
  SPACE_MD,
  GLASS_SHADOW_SM,
  BackButtonCapsule
} from '@wifi-analyzer/design-system'
import { RouterManager } from '@wifi-analyzer/core'

@Component
export struct PingActionButtons {
  @Prop isRunning: boolean = false

  onStop: () => void = () => {}
  onRestart: () => void = () => {}

  build() {
    Row({ space: SPACE_MD }) {
      // 返回按钮
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      // 停止/重新 Ping 按钮
      if (this.isRunning) {
        Row() {
          Text($r('app.string.stop_action_btn')).fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
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
          Text($r('app.string.ping_re_ping_btn')).fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor(COLOR_SKY_BLUE)
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
        .onClick(() => this.onRestart())
      }
    }
    .width('100%')
  }
}
