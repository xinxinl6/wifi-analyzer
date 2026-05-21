// 路由追踪 — 加载中状态组件

import { TracerouteHop } from '../traceroute/TracerouteEngine'
import { COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_DIVIDER, COLOR_SHADOW_DARK,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_ACTIVE,
  FONT_SIZE_XS, FONT_SIZE_MD,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  adaptiveTextSecondary, adaptiveTextTertiary } from '@wifi-analyzer/design-system'

@Component
export struct TracerouteLoadingState {
  @Prop isDarkMode: boolean = false
  @Prop hopList: TracerouteHop[] = []
  @Prop pulserOpacity: number = 1.0

  build() {
    Column({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(72).height(72)
          .fill(COLOR_GLASS_SKY_ACTIVE)
          .opacity(this.pulserOpacity)
        Circle().width(52).height(52)
          .fill(COLOR_SKY_BLUE_DIVIDER)
          .opacity(this.pulserOpacity)
        Image($r('app.media.ic_route')).width(26).height(26).fillColor(COLOR_SKY_BLUE)
      }
      Text($r('app.string.tracing_path'))
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
      Text($r('app.string.trace_duration_hint'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_ACTIVE, offsetX: 0, offsetY: 4 })
  }
}
