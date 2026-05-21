// 子网计算错误提示组件

import {
  COLOR_DANGER,
  FONT_SIZE_XS, FONT_SIZE_MD, FONT_SIZE_SM,
  FONT_WEIGHT_BOLD,
  SPACE_SM,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  adaptiveTextTertiary,
} from '@wifi-analyzer/design-system'

@Component
export struct SubnetErrorTip {
  @Prop isDarkMode: boolean = false
  @Prop errorMessage: string = ''

  build() {
    Row({ space: SPACE_SM }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(36).height(36).fill(this.isDarkMode ? 'rgba(239,68,68,0.15)' : '#FEF2F2')
        Text('!').fontSize(FONT_SIZE_MD).fontColor(COLOR_DANGER).fontWeight(FONT_WEIGHT_BOLD)
      }
      Column({ space: 2 }) {
        Text($r('app.string.input_error'))
          .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        Text(this.errorMessage)
          .fontSize(FONT_SIZE_SM).fontColor(COLOR_DANGER)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : 'rgba(239,68,68,0.3)')
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(239,68,68,0.2)', offsetX: 0, offsetY: 4 })
  }
}
