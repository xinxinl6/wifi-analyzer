/**
 * ChannelDetailList - 信道详情列表组件
 */
import {
  FONT_SIZE_LG,
  FONT_SIZE_XS,
  FONT_SIZE_XXS,
  FONT_WEIGHT_BOLD,
  FONT_WEIGHT_MEDIUM,
  SPACE_SM,
  SPACE_MD,
  SPACE_LG,
  RADIUS_SM,
  CARD_RADIUS,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_DARK_BORDER,
  COLOR_SHADOW_GLASS,
  COLOR_CHART_GRID,
  COLOR_CHART_GRID_DARK,
  adaptiveCardBg,
  adaptiveTextPrimary,
  adaptiveTextTertiary,
  adaptiveDivider
} from '@wifi-analyzer/design-system'
import { ChannelCacheData } from './ChannelCalculator'

@Component
export struct ChannelDetailList {
  @Prop isDarkMode: boolean = false
  @Prop cachedChannels: number[] = []
  @Prop cachedChannelData: ChannelCacheData[] = []

  build() {
    Column() {
      Row() {
        Text($r('app.string.channel_detail'))
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)

        Blank()

        Row({ space: 0 }) {
          Text(String(this.cachedChannels.length))
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
            .margin({ top: 4 })
          Text($r('app.string.channels_count_suffix'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
      }
      .width('100%')
      .margin({ bottom: SPACE_MD })

      // 列表内容
      ForEach(this.cachedChannelData, (item: ChannelCacheData) => {
        this.buildChannelRow(item)
      })
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
  buildChannelRow(item: ChannelCacheData) {
    Column() {
      Row({ space: SPACE_SM }) {
        // 信道号 + 状态指示
        Row({ space: 4 }) {
          Circle()
            .width(6)
            .height(6)
            .fill(item.color)

          Text('CH' + item.channel)
            .fontSize(FONT_SIZE_XS)
            .fontWeight(FONT_WEIGHT_MEDIUM)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
        }
        .width(50)

        // 占用条
        Row() {
          Row()
            .width(item.barWidth)
            .height(6)
            .linearGradient({
              angle: 90,
              colors: [[item.gradientTop, 0], [item.gradientBottom, 1]]
            })
            .borderRadius(3)
        }
        .backgroundColor(this.isDarkMode ? COLOR_CHART_GRID_DARK : COLOR_CHART_GRID)
        .borderRadius(3)
        .layoutWeight(1)

        // AP 数量
        Row({ space: 2 }) {
          Text(item.count + '')
            .fontSize(FONT_SIZE_XS)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(item.color)

          Text($r('app.string.unit_count'))
            .fontSize(9)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .width(36)
        .justifyContent(FlexAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分隔线（最后一项不显示）
      if (item.channel !== this.cachedChannels[this.cachedChannels.length - 1]) {
        Divider()
          .color(adaptiveDivider(this.isDarkMode))
          .strokeWidth(0.6)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}
