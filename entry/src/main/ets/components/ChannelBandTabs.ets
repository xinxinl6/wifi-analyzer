/**
 * ChannelBandTabs - 频段切换标签栏组件
 */
import {
  FONT_SIZE_MD,
  FONT_WEIGHT_BOLD,
  FONT_WEIGHT_MEDIUM,
  SPACE_SM,
  SPACE_LG,
  COLOR_CARD_SHADOW,
  COLOR_GLASS_AURORA_LIGHT,
  adaptiveTextSecondary,
  adaptiveGlowLarge,
  adaptiveGlowMedium
} from '@wifi-analyzer/design-system'
import { getBandColor, getIndicatorMargin, BANDS } from './ChannelCalculator'

@Component
export struct ChannelBandTabs {
  @Prop isDarkMode: boolean = false
  @Prop currentBand: string = '2.4'
  onBandChange: (band: string) => void = () => {}

  build() {
    Column() {
      Row() {
        this.buildBandTab('2.4GHz', '2.4')
        this.buildBandTab('5.2GHz', '5g1')
        this.buildBandTab('5.8GHz', '5g2')
      }
      .width('100%')
      .height(48)
      .padding({ left: SPACE_SM, right: SPACE_LG })

      // 底部滑动指示器
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('33.33%')
          .height(3)
          .backgroundColor(getBandColor(this.currentBand))
          .borderRadius({ topLeft: 2, topRight: 2 })
          .margin({ left: getIndicatorMargin(this.currentBand) })
          .animation({ duration: 250, curve: Curve.EaseInOut })
      }
      .width('100%')
      .height(3)
      .padding({ left: SPACE_SM, right: SPACE_SM })
    }
    .width('100%')
    .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
    .shadow({ radius: 6, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
  }

  @Builder
  buildBandTab(label: string, band: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(FONT_SIZE_MD)
        .fontWeight(this.currentBand === band ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
        .fontColor(this.currentBand === band ? getBandColor(this.currentBand) : adaptiveTextSecondary(this.isDarkMode))
        .animation({ duration: 200 })

      Circle()
        .width(this.currentBand === band ? 4 : 0)
        .height(4)
        .fill(this.currentBand === band ? getBandColor(this.currentBand) : 'transparent')
        .animation({ duration: 200 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onBandChange(band))
  }
}
