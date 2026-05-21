/**
 * ChannelBarChart - 信道占用柱状图组件
 */
import {
  FONT_SIZE_LG,
  FONT_SIZE_XS,
  FONT_SIZE_MD,
  FONT_SIZE_XXS,
  FONT_WEIGHT_BOLD,
  FONT_WEIGHT_MEDIUM,
  SPACE_MD,
  SPACE_LG,
  SPACE_SM,
  SPACE_XS,
  RADIUS_SM,
  CARD_RADIUS,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_DARK_BORDER,
  COLOR_SHADOW_GLASS,
  COLOR_CHANNEL_IDLE,
  COLOR_CHANNEL_LIGHT,
  COLOR_CHANNEL_MODERATE,
  COLOR_CHANNEL_CROWDED,
  COLOR_CHANNEL_IDLE_TOP,
  COLOR_CHANNEL_LIGHT_TOP,
  COLOR_CHANNEL_MODERATE_TOP,
  COLOR_CHANNEL_CROWDED_TOP,
  COLOR_CHART_GRID,
  COLOR_CHART_GRID_DARK,
  COLOR_SKY_BLUE_BG,
  adaptiveCardBg,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary
} from '@wifi-analyzer/design-system'
import { SharedWifiState } from '@wifi-analyzer/core'
import { ChannelCacheData } from './ChannelCalculator'

@Component
export struct ChannelBarChart {
  @Prop isDarkMode: boolean = false
  @Prop cachedChannelData: ChannelCacheData[] = []
  @Prop currentBand: string = '2.4'
  @Prop cachedTotalCount: number = 0

  // 空状态标题
  @Consume('wifiState') wifiState: SharedWifiState
  private isWifiDataAvailable(): boolean {
    return this.wifiState?.connectedSsid !== '' && (this.wifiState?.wifiList?.length ?? 0) > 0
  }

  private getEmptyTitleResource(): Resource {
    if (!this.isWifiDataAvailable()) return $r('app.string.wifi_not_connected')
    if (this.cachedTotalCount === 0) {
      if (this.currentBand === '2.4') return $r('app.string.no_2_4g_network')
      if (this.currentBand === '5g1') return $r('app.string.no_5g1_network')
      return $r('app.string.no_5g2_network')
    }
    return $r('app.string.no_data')
  }

  private getEmptySubtitleResource(): Resource {
    if (!this.isWifiDataAvailable()) return $r('app.string.connect_wifi_hint_short')
    if (this.cachedTotalCount === 0) {
      if (this.currentBand === '2.4') return $r('app.string.no_2_4g_network_hint')
      if (this.currentBand === '5g1') return $r('app.string.no_5g1_network_hint')
      return $r('app.string.no_5g2_network_hint')
    }
    return $r('app.string.no_data')
  }

  build() {
    Column() {
      // 标题行
      Row() {
        Text($r('app.string.channel_distribution'))
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)

        Blank()

        // 图例
        Row({ space: SPACE_SM }) {
          this.buildLegendDot(COLOR_CHANNEL_IDLE, $r('app.string.idle'))
          this.buildLegendDot(COLOR_CHANNEL_LIGHT, $r('app.string.light'))
          this.buildLegendDot(COLOR_CHANNEL_MODERATE, $r('app.string.moderate'))
          this.buildLegendDot(COLOR_CHANNEL_CROWDED, $r('app.string.crowded'))
        }
      }
      .width('100%')
      .margin({ bottom: SPACE_MD })

      // 柱状图区域
      if (this.cachedChannelData.length === 0 || this.cachedTotalCount === 0) {
        this.buildEmptyChart()
      } else {
        this.buildBarChart()
      }
    }
    .width('100%')
    .padding(SPACE_LG)
    .backgroundColor(adaptiveCardBg(this.isDarkMode))
    .borderRadius(CARD_RADIUS)
    .border({ width: 1, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER_LIGHT })
    .shadow({ radius: 8, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 2 })
    .backdropBlur(10)
  }

  @Builder
  buildEmptyChart() {
    Column() {
      Column() {
        Text('📶')
          .fontSize(32)
      }
      .width(60)
      .height(60)
      .backgroundColor(COLOR_SKY_BLUE_BG)
      .borderRadius(30)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(this.getEmptyTitleResource())
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .margin({ top: SPACE_SM })

      Text(this.getEmptySubtitleResource())
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(110)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildBarChart() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景参考网格
      Column() {
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(this.isDarkMode ? COLOR_CHART_GRID_DARK : COLOR_CHART_GRID)
          .opacity(0.5)
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(this.isDarkMode ? COLOR_CHART_GRID_DARK : COLOR_CHART_GRID)
          .opacity(0.5)
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(this.isDarkMode ? COLOR_CHART_GRID_DARK : COLOR_CHART_GRID)
          .opacity(0.5)
        Blank()
      }
      .width('100%')
      .height(100)

      // 柱状图主体 - 使用 Scroll 防止溢出
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.cachedChannelData, (item: ChannelCacheData) => {
            Column() {
              // 数量标签
              if (item.count > 0) {
                Text(item.count.toString())
                  .fontSize(13)
                  .fontWeight(FONT_WEIGHT_MEDIUM)
                  .fontColor(item.color)
                  .margin({ bottom: 2 })
              }

              // 柱体（固定宽度）
              Column()
                .width(24)
                .height(item.height)
                .linearGradient({
                  angle: 180,
                  colors: [[item.gradientTop, 0], [item.gradientBottom, 1]]
                })
                .borderRadius(RADIUS_SM)
                .shadow({
                  radius: 3,
                  color: item.color + '30',
                  offsetX: 0,
                  offsetY: 1
                })

              // 信道号
              Text(item.channel.toString())
                .fontSize(13)
                .fontColor(adaptiveTextTertiary(this.isDarkMode))
                .margin({ top: 4 })
            }
            .justifyContent(FlexAlign.End)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .height(100)
        .alignItems(VerticalAlign.Bottom)
        .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .height(100)
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Horizontal)
    }
    .width('100%')
    .height(110)
  }

  @Builder
  buildLegendDot(color: string, label: Resource) {
    Row({ space: SPACE_XS }) {
      Circle()
        .width(6)
        .height(6)
        .fill(color)
      Text(label)
        .fontSize(FONT_SIZE_XXS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
  }
}
