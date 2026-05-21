// PoE 标准选择器 — Aurora WiFi V2

import {
  COLOR_WARNING, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextPrimary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'

// ==================== 类型定义 ====================

export interface StandardDisplayItem {
  name: string
  type: string
  powerPse: string
  powerPd: string
  description: string
}

// ==================== PoE 标准选择器 ====================
@Component
export struct PoeStandardSelector {
  @Prop isDarkMode: boolean = false
  @Prop standardItems: StandardDisplayItem[] = []
  @Prop selectedStandard: number = 0
  onStandardTap: (index: number) => void = () => {}

  build() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.poe_standard'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Column({ space: SPACE_SM }) {
        ForEach(this.standardItems, (item: StandardDisplayItem, index: number) => {
          this.StandardRow(item, index)
        }, (item: StandardDisplayItem, index: number): string => String(index))
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder StandardRow(item: StandardDisplayItem, index: number) {
    Column({ space: SPACE_XS }) {
      Row({ space: SPACE_MD }) {
        // 选中指示器
        Circle()
          .width(20).height(20)
          .fill(this.selectedStandard === index ? COLOR_WARNING : Color.Transparent)
          .border({ width: 2, color: this.selectedStandard === index ? COLOR_WARNING : adaptiveDivider(this.isDarkMode) })

        Column({ space: 2 }) {
          Row({ space: SPACE_SM }) {
            Text(item.name)
              .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_MEDIUM)
            Text(item.type)
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_WARNING)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor(this.isDarkMode ? 'rgba(245,158,11,0.15)' : '#FEF3C7')
              .borderRadius(999)
          }
          Text(item.description)
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 功率
        Column({ space: 2 }) {
          Text(item.powerPd)
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_WARNING).fontWeight(FONT_WEIGHT_BOLD)
          Text($r('app.string.poe_available'))
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.End)
      }
    }
    .width('100%')
    .padding(SPACE_MD)
    .backgroundColor(this.selectedStandard === index
      ? (this.isDarkMode ? 'rgba(245,158,11,0.12)' : 'rgba(245,158,11,0.08)')
      : (this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE))
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.selectedStandard === index ? COLOR_WARNING : (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER))
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({
      radius: GLASS_SHADOW_LG,
      color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .stateStyles({ pressed: { opacity: 0.8 } })
    .clip(true)
    .onClick(() => this.onStandardTap(index))
  }
}
