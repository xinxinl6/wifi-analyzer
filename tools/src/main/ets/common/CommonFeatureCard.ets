// 通用功能特性卡片 — 天蓝色透明毛玻璃悬浮风格
// 消除 11 个 Page 中重复的 FeatureCard + FeatureItem 模式

import {
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD,
  FONT_WEIGHT_BOLD,
  SPACE_SM,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'

// 功能项数据
export interface FeatureItemData {
  emoji: string
  title: string | Resource
  desc: string | Resource
}

@Component
export struct CommonFeatureCard {
  @Prop isDarkMode: boolean = false
  @Prop sectionTitle: Resource | string = ''
  @Prop items: FeatureItemData[] = []
  @Prop accentColor: string = COLOR_GLASS_SKY_ACTIVE

  build() {
    Column({ space: 0 }) {
      // 标题
      if (this.sectionTitle !== '') {
        Text(this.sectionTitle)
          .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
          .width('100%')
          .padding({ bottom: 12 })
      }

      // 功能列表
      Column({ space: 0 }) {
        ForEach(this.items, (item: FeatureItemData, index: number) => {
          Row({ space: 14 }) {
            Stack({ alignContent: Alignment.Center }) {
              Circle().width(38).height(38)
                .fill(this.isDarkMode ? this.accentColor.replace(')', ',0.15)').replace('rgb', 'rgba') : COLOR_GLASS_SKY_ACTIVE)
              Text(item.emoji).fontSize(16)
            }

            Column({ space: 3 }) {
              Text(item.title)
                .fontSize(FONT_SIZE_MD)
                .fontColor(adaptiveTextPrimary(this.isDarkMode))
                .fontWeight(FONT_WEIGHT_BOLD)
              Text(item.desc)
                .fontSize(FONT_SIZE_XS)
                .fontColor(adaptiveTextSecondary(this.isDarkMode))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 14, bottom: 14 })

          if (index < this.items.length - 1) {
            Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
          }
        }, (item: FeatureItemData, index: number): string => String(index))
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }
}
