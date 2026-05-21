// 通用搜索栏组件 — 图标 + TextInput + 提交按钮

import {
  FONT_SIZE_SM, FONT_SIZE_MD,
  FONT_WEIGHT_BOLD,
  SPACE_SM,
  GLASS_BLUR_LG, GLASS_SHADOW_XL, GLASS_SHADOW_SM,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_SHADOW_MED,
  adaptiveTextPrimary, adaptiveTextTertiary
} from '@wifi-analyzer/design-system'

@Component
export struct CommonSearchBar {
  @Prop isDarkMode: boolean = false
  @Prop accentColor: string = '#4A90D9'
  @Prop icon: Resource = $r('app.media.ic_search')
  @Prop placeholder: Resource = $r('app.string.search_hint')
  @Prop inputText: string = ''
  @Prop actionLabel: string | Resource = ''
  onInputChange: (value: string) => void = () => {}
  onSubmit: () => void = () => {}

  build() {
    Row({ space: SPACE_SM }) {
      Image(this.icon).width(20).height(20).fillColor(this.accentColor)

      TextInput({ placeholder: this.placeholder, text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .type(InputType.Normal)
        .onChange((value: string) => { this.onInputChange(value) })

      Row() {
        Text(this.actionLabel).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(this.accentColor)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.onSubmit())
    }
    .width('100%').padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }
}
