// 状态栏组件
import { Row, Text } from '@kit.ArkUI'
import { COLOR_TEXT_PRIMARY, COLOR_SURFACE,
  FONT_SIZE_4XL, FONT_WEIGHT_BOLD,
  SPACE_XL, SPACE_MD } from '@wifi-analyzer/design-system'

@Component
export struct StatusBar {
  build() {
    Row() {
      Text($r('app.string.app_name_wifi_analyzer'))
        .fontSize(FONT_SIZE_4XL)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(COLOR_TEXT_PRIMARY)
    }
    .padding({ left: SPACE_XL, right: SPACE_XL, top: SPACE_MD, bottom: SPACE_MD })
    .backgroundColor(COLOR_SURFACE)
  }
}