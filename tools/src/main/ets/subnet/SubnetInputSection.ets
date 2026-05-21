// 子网输入区域组件

import {
  COLOR_WARNING, COLOR_DANGER, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_WEIGHT_BOLD, FONT_WEIGHT_MEDIUM,
  SPACE_XS, SPACE_SM,
  GLASS_BLUR_LG, GLASS_SHADOW_SM, GLASS_SHADOW_XL,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_SHADOW_MED,
  adaptiveTextPrimary, adaptiveTextTertiary,
} from '@wifi-analyzer/design-system'

@Component
export struct SubnetInputSection {
  @Prop isDarkMode: boolean = false
  @Prop inputText: string = ''
  @Prop inputValid: boolean = true
  @Prop inputError: string = ''
  onInputChange: (value: string) => void = () => {}
  onCalculate: () => void = () => {}

  build() {
    Column({ space: SPACE_SM }) {
      Row({ space: SPACE_SM }) {
        Image($r('app.media.ic_subnet')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_WARNING)

        TextInput({ placeholder: $r('app.string.input_ip_subnet_hint'), text: this.inputText })
          .layoutWeight(1)
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode))
          .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => this.onInputChange(value))

        Button($r('app.string.calculate_action'))
          .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
          .backgroundColor(COLOR_WARNING)
          .borderRadius(999)
          .height(36)
          .padding({ left: 18, right: 18 })
          .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.onCalculate())
      }
      .width('100%')
      .padding({ left: 16, right: 12, top: 13, bottom: 13 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.inputValid
        ? (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
        : COLOR_DANGER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })

      // 输入提示/错误
      if (!this.inputValid) {
        Row({ space: SPACE_SM }) {
          Text('!')
            .fontSize(FONT_SIZE_XS).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
            .width(18).height(18).textAlign(TextAlign.Center)
            .backgroundColor(COLOR_DANGER).borderRadius(9)
          Text(this.inputError)
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_DANGER)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ left: 18, right: 14, top: 8, bottom: 8 })
      } else {
        Text($r('app.string.cidr_format_hint'))
          .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          .alignSelf(ItemAlign.Start)
          .padding({ left: 18 })
      }
    }
    .width('100%')
  }
}
