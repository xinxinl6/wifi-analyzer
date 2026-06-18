// ============================================
// AuroraAIFabButton — AI 助手悬浮按钮
// Aurora WiFi V2 设计系统
// 使用 @ComponentV2 架构
// ============================================

import {
  COLOR_AURORA_PRIMARY,
  COLOR_TEXT_ON_COLOR,
  COLOR_GLOW_PRIMARY,
  COLOR_GLOW_OUTER
} from '../Color'

@ComponentV2
export struct AuroraAIFabButton {
  @Param onClickAction: () => void = this.defaultOnClick

  @Builder
  defaultOnClick(): void {
  }

  build() {
    Column() {
      Text('AI')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT_ON_COLOR)
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor(COLOR_AURORA_PRIMARY)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({
      radius: 16,
      color: COLOR_GLOW_PRIMARY,
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.onClickAction()
    })
  }
}
