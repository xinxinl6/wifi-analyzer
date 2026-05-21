// 通用页面背景 — Aurora 天蓝渐变 + 光晕装饰

import {
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium
} from '@wifi-analyzer/design-system'

@Component
export struct CommonPageBackground {
  @Prop isDarkMode: boolean = false

  build() {
    Column() {}
      .width('100%')
      .height('100%')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: adaptiveBackgroundList(this.isDarkMode)
      })

    Circle()
      .width(280)
      .height(280)
      .fill(adaptiveGlowLarge(this.isDarkMode))
      .position({ x: -60, y: -60 })

    Circle()
      .width(180)
      .height(180)
      .fill(adaptiveGlowMedium(this.isDarkMode))
      .position({ x: '68%', y: '45%' })
  }
}
