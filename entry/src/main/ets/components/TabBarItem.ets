// Tab栏项目组件
import { Column, Image, Text, FlexAlign } from '@kit.ArkUI'
import { COLOR_PRIMARY, COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS, FONT_WEIGHT_NORMAL,
  SPACE_XS, SPACE_SM, SPACE_LG, ICON_SIZE_MD, TAB_BAR_HEIGHT } from '@wifi-analyzer/design-system'

@Component
export struct TabBarItem {
  private title: string = ''
  private icon: Resource = $r('app.media.ic_home')
  private index: number = 0
  private currentTab: number = 0

  build() {
    Column() {
      Image(this.icon)
        .width(ICON_SIZE_MD)
        .height(ICON_SIZE_MD)
        .fillColor(this.currentTab === this.index ? COLOR_PRIMARY : COLOR_TEXT_TERTIARY)
      Text(this.title)
        .fontSize(FONT_SIZE_XS)
        .margin({ top: SPACE_XS })
        .fontColor(this.currentTab === this.index ? COLOR_PRIMARY : COLOR_TEXT_TERTIARY)
    }
    .height(TAB_BAR_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .padding({ top: SPACE_SM, bottom: SPACE_SM })
  }
}
