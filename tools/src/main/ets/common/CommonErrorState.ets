// 通用错误状态展示

import {
  COLOR_DANGER,
  FONT_SIZE_MD, FONT_SIZE_3XL,
  FONT_WEIGHT_BOLD,
  SPACE_MD,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER,
  GLASS_BLUR_LG,
  adaptiveTextTertiary
} from '@wifi-analyzer/design-system'

@Component
export struct CommonErrorState {
  @Prop isDarkMode: boolean = false
  @Prop errorMessage: string | Resource = ''

  build() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(64).height(64).fill(this.isDarkMode ? 'rgba(239,68,68,0.15)' : '#FEF2F2')
        Text('!').fontSize(FONT_SIZE_3XL).fontColor(COLOR_DANGER).fontWeight(FONT_WEIGHT_BOLD)
      }
      Text(this.errorMessage)
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_DANGER)
    }
    .width('100%').height(200).justifyContent(FlexAlign.Center)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
  }
}
