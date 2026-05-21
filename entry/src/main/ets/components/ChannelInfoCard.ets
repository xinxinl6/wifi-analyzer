/**
 * ChannelInfoCard - 频段信息卡片组件
 */
import {
  FONT_SIZE_XS,
  FONT_SIZE_SM,
  FONT_SIZE_XL,
  FONT_SIZE_XXS,
  FONT_WEIGHT_BOLD,
  FONT_WEIGHT_MEDIUM,
  SPACE_SM,
  SPACE_MD,
  CARD_RADIUS,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_DARK_BORDER,
  COLOR_SHADOW_GLASS,
  adaptiveCardBg,
  adaptiveTextPrimary,
  adaptiveTextTertiary
} from '@wifi-analyzer/design-system'
import {
  getBandShortName,
  getBandNameResource,
  getBandDescriptionResource,
  getBandRange,
  getBandColor,
  getCurrentChannels
} from './ChannelCalculator'

@Component
export struct ChannelInfoCard {
  @Prop isDarkMode: boolean = false
  @Prop currentBand: string = '2.4'
  @Prop totalCount: number = 0

  build() {
    Column() {
      Row() {
        // 频段图标
        Column() {
          Text(getBandShortName(this.currentBand))
            .fontSize(FONT_SIZE_XS)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(getBandColor(this.currentBand))
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(getBandNameResource(this.currentBand))
            .fontSize(FONT_SIZE_SM)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(getBandDescriptionResource(this.currentBand))
            .fontSize(FONT_SIZE_XXS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .margin({ left: SPACE_SM })
        .alignItems(HorizontalAlign.Start)

        // 网络数量
        Column({ space: 0 }) {
          Text(this.totalCount + '')
            .fontSize(FONT_SIZE_XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(getBandColor(this.currentBand))

          Text($r('app.string.unit_network'))
            .fontSize(FONT_SIZE_XXS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)

      // 频段范围
      Row() {
        Text(getBandRange(this.currentBand))
          .fontSize(FONT_SIZE_XXS)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        Text('CH' + getCurrentChannels(this.currentBand)[0] + '-' + getCurrentChannels(this.currentBand)[getCurrentChannels(this.currentBand).length - 1])
          .fontSize(FONT_SIZE_XXS)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height(20)
      .margin({ top: SPACE_SM })
    }
    .width('100%')
    .height(88)
    .padding(SPACE_MD)
    .backgroundColor(adaptiveCardBg(this.isDarkMode))
    .borderRadius(CARD_RADIUS)
    .border({ width: 1, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER_LIGHT })
    .shadow({ radius: 8, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 2 })
    .backdropBlur(10)
  }
}
