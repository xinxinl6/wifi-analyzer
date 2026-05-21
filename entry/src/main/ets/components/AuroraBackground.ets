// ============================================
// Aurora 极光装饰背景
// ============================================

import {
  COLOR_GLOW_LIGHT_1,
  COLOR_GLOW_LIGHT_2,
  COLOR_GLOW_LIGHT_3
} from '@wifi-analyzer/design-system'

@Component
export struct AuroraBackground {
  build() {
    Stack() {
      // 基础渐变背景已在 Index.ets 设置

      // 极光装饰光晕 1 - 使用更大的透明圆形代替 blur
      Circle()
        .width(300)
        .height(300)
        .fill(COLOR_GLOW_LIGHT_1)
        .position({ x: -80, y: -80 })

      // 极光装饰光晕 2
      Circle()
        .width(200)
        .height(200)
        .fill(COLOR_GLOW_LIGHT_2)
        .position({ x: '70%', y: '55%' })

      // 极光装饰光晕 3
      Circle()
        .width(150)
        .height(150)
        .fill(COLOR_GLOW_LIGHT_3)
        .position({ x: '75%', y: '15%' })
    }
    .width('100%')
    .height('100%')
    .zIndex(-1)
  }
}
