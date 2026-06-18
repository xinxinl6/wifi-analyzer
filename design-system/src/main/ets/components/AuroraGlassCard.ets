// ============================================
// AuroraGlassCard — 可复用毛玻璃卡片组件
// Aurora WiFi V2 设计系统
// 使用 @ComponentV2 架构，支持暗色/亮色模式
// ============================================

import {
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_GLASS_STRONG
} from '../Color'
import {
  GLASS_BLUR_LG
} from '../Size'

@ComponentV2
export struct AuroraGlassCard {
  @Param radius: number = 16
  @Param padding: Padding | undefined = undefined
  @Param blur: number = GLASS_BLUR_LG
  @Param isDark: boolean = false
  @BuilderParam content: () => void = this.defaultContent

  @Builder
  defaultContent(): void {
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.padding ?? 16)
    .borderRadius(this.radius)
    .backgroundColor(this.isDark ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_SURFACE)
    .blur(this.blur)
    .borderWidth(1)
    .borderColor(this.isDark ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER_MEDIUM)
    .shadow({
      radius: 24,
      color: this.isDark ? COLOR_SHADOW_GLASS_STRONG : COLOR_SHADOW_GLASS,
      offsetX: 0,
      offsetY: 4
    })
  }
}
