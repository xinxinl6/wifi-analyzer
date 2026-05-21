/**
 * ChannelRecommend - 推荐信道组件
 */
import {
  FONT_SIZE_LG,
  FONT_SIZE_XS,
  FONT_SIZE_SM,
  FONT_SIZE_XXS,
  FONT_WEIGHT_BOLD,
  SPACE_MD,
  SPACE_LG,
  SPACE_SM,
  RADIUS_LG,
  RADIUS_SM,
  CARD_RADIUS,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_DARK_BORDER,
  COLOR_SHADOW_GLASS,
  COLOR_CHANNEL_RECOMMEND_BG,
  COLOR_CHANNEL_RECOMMEND_BORDER,
  COLOR_SUCCESS,
  COLOR_CHANNEL_IDLE,
  COLOR_CHANNEL_IDLE_TOP,
  COLOR_CHANNEL_MODERATE,
  COLOR_CHANNEL_MODERATE_TOP,
  adaptiveCardBg,
  adaptiveTextPrimary,
  adaptiveTextTertiary
} from '@wifi-analyzer/design-system'
import { ChannelCountPair } from './ChannelCalculator'

@Component
export struct ChannelRecommend {
  @Prop isDarkMode: boolean = false
  @Prop recommendedChannels: ChannelCountPair[] = []
  @Prop cachedTotalCount: number = 0

  build() {
    Column() {
      Row() {
        Text($r('app.string.recommend_channels'))
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)

        Blank()

        if (this.cachedTotalCount > 0) {
          Text($r('app.string.least_interference'))
            .fontSize(FONT_SIZE_XXS)
            .fontColor(this.isDarkMode ? COLOR_CHANNEL_IDLE_TOP : COLOR_CHANNEL_IDLE)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: 2, bottom: 2 })
            .backgroundColor(this.isDarkMode ? COLOR_CHANNEL_MODERATE : COLOR_CHANNEL_RECOMMEND_BG)
            .borderRadius(RADIUS_SM)
        }
      }
      .width('100%')
      .margin({ bottom: SPACE_MD })

      if (this.recommendedChannels.length > 0) {
        Row({ space: SPACE_MD }) {
          ForEach(this.recommendedChannels, (item: ChannelCountPair) => {
            this.buildRecommendChip(item)
          })
        }
        .width('100%')
      } else {
        Row() {
          Text($r('app.string.no_recommend'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: SPACE_MD, bottom: SPACE_MD })
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
  buildRecommendChip(item: ChannelCountPair) {
    Column() {
      // 信道号
      Text('CH' + item.channel)
        .fontSize(FONT_SIZE_LG)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(COLOR_SUCCESS)

      if (item.count === 0) {
        Text($r('app.string.best'))
          .fontSize(FONT_SIZE_XXS)
          .fontColor(this.isDarkMode ? COLOR_CHANNEL_IDLE_TOP : COLOR_CHANNEL_IDLE)
          .margin({ top: 2 })
      } else {
        Text() {
          Span($r('app.string.networks_found'))
          Span(' ' + item.count + ' ')
          Span($r('app.string.networks_unit'))
        }
          .fontSize(FONT_SIZE_XXS)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
          .margin({ top: 2 })
      }
    }
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: SPACE_MD, bottom: SPACE_MD })
    .backgroundColor(this.isDarkMode ? COLOR_CHANNEL_MODERATE : COLOR_CHANNEL_RECOMMEND_BG)
    .borderRadius(RADIUS_LG)
    .border({
      width: 1,
      color: this.isDarkMode ? COLOR_CHANNEL_MODERATE_TOP : COLOR_CHANNEL_RECOMMEND_BORDER,
      radius: RADIUS_LG
    })
  }
}
