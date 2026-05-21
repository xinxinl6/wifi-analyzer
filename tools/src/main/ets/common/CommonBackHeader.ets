// 通用返回头部 — BackButtonGlass + 标题

import {
  SPACE_LG,
  SAFE_AREA_TOP,
  FONT_SIZE_LG, FONT_WEIGHT_BOLD,
  adaptiveTextPrimary
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'

@Component
export struct CommonBackHeader {
  @Prop isDarkMode: boolean = false
  @Prop title: string = ''
  onBack: () => void = () => {}

  build() {
    Row() {
      BackButtonGlass({ onBack: () => this.onBack() })
      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
          .margin({ left: SPACE_LG })
      }
      Blank()
    }
    .width('100%')
    .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
    .alignItems(VerticalAlign.Center)
  }
}
