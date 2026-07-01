// ============================================
// AuroraAIFabButton — HM7 AI 助手悬浮按钮
// 沉浸光感设计：品牌色实色 + 极光光晕投影
// 使用 @ComponentV2 架构
// ============================================

import {
  COLOR_GLOW_PRIMARY,
  adaptivePrimary,
} from '../Color'

@ComponentV2
export struct AuroraAIFabButton {
  @Param isDark: boolean = true
  @Param onClickAction: () => void = this.defaultOnClick

  @Builder
  defaultOnClick(): void {
  }

  build() {
    Column() {
      Text('AI')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor(adaptivePrimary(this.isDark))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({
      radius: this.isDark ? 16 : 12,
      color: this.isDark ? 'rgba(49,122,247,0.25)' : COLOR_GLOW_PRIMARY,
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.onClickAction()
    })
  }
}
