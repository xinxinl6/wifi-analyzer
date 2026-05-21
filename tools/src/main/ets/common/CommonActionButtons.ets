// 通用操作按钮栏 — 返回 + 主操作

import {
  FONT_SIZE_MD,
  FONT_WEIGHT_BOLD,
  SPACE_MD,
  GLASS_SHADOW_SM,
  COLOR_GLASS_SKY_SHADOW_MED,
  adaptiveTextPrimary
} from '@wifi-analyzer/design-system'
import { BackButtonCapsule } from '@wifi-analyzer/design-system'

@Component
export struct CommonActionButtons {
  @Prop accentColor: string = '#4A90D9'
  @Prop actionLabel: string | Resource = ''
  onAction: () => void = () => {}
  onBack: () => void = () => {}

  build() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => this.onBack() })

      Row() {
        Text(this.actionLabel)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(this.accentColor)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
      .onClick(() => this.onAction())
    }
    .width('100%')
  }
}
