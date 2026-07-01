// 悬浮毛玻璃 TabBar 组件 — 从旧项目移植，供 API 17-22 降级使用
// 接收动画状态和回调，独立管理 UI 渲染

import {
  COLOR_AURORA_PRIMARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_GLASS_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER,
  COLOR_SHADOW_GLASS,
} from '@wifi-analyzer/design-system'

interface TabItem {
  title: ResourceStr
  icon: Resource
}

const TAB_ITEMS: Array<TabItem> = [
  { title: $r('app.string.tab_home'), icon: $r('app.media.ic_home') },
  { title: $r('app.string.tab_wifi'), icon: $r('app.media.ic_wifi') },
  { title: $r('app.string.tab_channel'), icon: $r('app.media.ic_chart') },
  { title: $r('app.string.tab_speed'), icon: $r('app.media.ic_speed') },
  { title: $r('app.string.tab_tools'), icon: $r('app.media.ic_tool') },
]

@Component
export struct AuroraTabBar {
  @Prop currentIndex: number = 0
  @Prop isDarkMode: boolean = false
  @Prop tabScales: number[] = []
  @Prop tabGlows: number[] = []
  @Prop tabOffsetY: number[] = []
  @Prop tabDotOpacity: number[] = []
  onTabSelected: (index: number) => void = () => {}

  build() {
    Column() {
      Column() {}
        .layoutWeight(1)
        .hitTestBehavior(HitTestMode.None)

      Column() {
        Row() {
          ForEach(TAB_ITEMS, (item: TabItem, index: number) => {
            Column() {
              Stack() {
                Column()
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,0.35)' : '#007AFF')
                  .opacity(this.tabGlows[index] * (this.isDarkMode ? 0.20 : 0.12) + (this.currentIndex === index ? (this.isDarkMode ? 0.15 : 0.10) : 0))
                  .blur(8)

                Image(item.icon)
                  .width(26)
                  .height(26)
                  .fillColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : (this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_SECONDARY))
                  .scale({ x: this.tabScales[index], y: this.tabScales[index] })
                  .translate({ x: 0, y: this.tabOffsetY[index] })
              }
              .width(44)
              .height(44)

              Text(item.title)
                .fontSize(11)
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : (this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_SECONDARY))
                .margin({ top: 2 })
                .scale({ x: this.tabScales[index], y: this.tabScales[index] })

              Column()
                .width(4)
                .height(4)
                .borderRadius(2)
                .backgroundColor(COLOR_AURORA_PRIMARY)
                .margin({ top: 3 })
                .opacity(this.tabDotOpacity[index])
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.onTabSelected(index)
            })
          }, (item: TabItem, index: number) => index.toString())
        }
        .width('85%')
        .height(80)
        .padding({ top: 10, bottom: 12 })
        .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_SURFACE_LIGHT)
        .backdropBlur(18)
        .linearGradient(this.isDarkMode
          ? { direction: GradientDirection.Top, colors: [['rgba(30,41,59,0.45)', 0], ['rgba(30,41,59,0.14)', 0.5], ['rgba(30,41,59,0.08)', 1]] }
          : { direction: GradientDirection.Top, colors: [['rgba(255,255,255,0.45)', 0], ['rgba(255,255,255,0.14)', 0.5], ['rgba(255,255,255,0.08)', 1]] })
        .borderRadius(28)
        .border({
          width: { top: 0.5, bottom: 0 },
          color: {
            top: this.isDarkMode ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_CARD,
            bottom: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER
          }
        })
        .shadow({
          radius: 24,
          color: COLOR_SHADOW_GLASS,
          offsetX: 0,
          offsetY: 6
        })
      }
    }
    .width('100%')
    .height(104)
    .padding({ bottom: 24 })
    .backgroundColor(Color.Transparent)
  }
}
