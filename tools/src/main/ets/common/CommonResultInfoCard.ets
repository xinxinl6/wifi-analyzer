// 通用结果信息卡 — icon + 标题行 + 键值对

import {
  FONT_SIZE_XS, FONT_SIZE_LG,
  FONT_WEIGHT_BOLD,
  SPACE_MD, SPACE_SM,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_AURORA,
  adaptiveTextPrimary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'

@Component
export struct CommonResultInfoCard {
  @Prop isDarkMode: boolean = false
  @Prop icon: Resource = $r('app.media.ic_ip')
  @Prop accentColor: string = '#4A90D9'
  @Prop titleText: string | Resource = ''
  @Prop subtitleText: string | Resource = ''
  @Prop queryTime: string = ''
  onEdit: () => void = () => {}

  build() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_LIGHT)
        Image(this.icon).width(22).height(22).fillColor(this.accentColor)
      }

      Column({ space: 4 }) {
        Text(this.titleText)
          .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: SPACE_SM }) {
          Text(this.subtitleText).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          if (this.queryTime.length > 0) {
            Text(' | ').fontSize(FONT_SIZE_XS).fontColor(adaptiveDivider(this.isDarkMode))
            Text(this.queryTime + 'ms').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row() {
        Text('🔍').fontSize(14)
      }
      .width(34).height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(10)
      .onClick(() => this.onEdit())
    }
    .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }
}
