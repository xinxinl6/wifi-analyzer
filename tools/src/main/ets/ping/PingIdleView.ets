// Ping 测试空闲视图组件

import {
  COLOR_SKY_BLUE, COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_SKY_SHADOW_MED,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_2XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'

interface QuickTargetItem {
  name: string | Resource
  address: string
}

@Component
export struct PingIdleView {
  @Prop isDarkMode: boolean = false
  @Prop inputText: string = ''
  @Prop detectedGateway: string = ''
  @Prop recommendItems: QuickTargetItem[] = []

  onInputChange: (value: string) => void = () => {}
  onSubmit: () => void = () => {}
  onRecommendTap: (index: number) => void = () => {}

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 大标题区
        Column({ space: 6 }) {
          Text($r('app.string.ping_test'))
            .fontSize(FONT_SIZE_2XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
          Text($r('app.string.ping_test_desc'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        // 搜索栏
        this.SearchBarSection()

        // 推荐标签
        this.RecommendTagsSection()

        // 功能说明卡片
        this.FeatureCardsSection()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_device'))
        .width(20).height(20)
        .fillColor(COLOR_SKY_BLUE)

      TextInput({ placeholder: $r('app.string.ping_input_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.onInputChange(value) })
        .onSubmit(() => this.onSubmit())

      // Ping 按钮
      Row() {
        Text($r('app.string.ping_action'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_SKY_BLUE)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.onSubmit())
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 推荐标签
  @Builder RecommendTagsSection() {
    Column({ space: 8 }) {
      Text($r('app.string.ping_quick_test'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        ForEach(this.recommendItems, (item: QuickTargetItem, index: number) => {
          Row({ space: 5 }) {
            Text(index === 0 ? '🛡' : index === 1 ? '🔍' : '🌐')
              .fontSize(14)
            Text(item.name)
              .fontSize(FONT_SIZE_MD)
              .fontColor(COLOR_SKY_BLUE)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_SKY_ACTIVE : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(this.isDarkMode ? COLOR_GLASS_BORDER : COLOR_GLASS_SKY_TAG_BORDER)
          .onClick(() => this.onRecommendTap(index))
        }, (item: QuickTargetItem, index: number): string => String(index))
      }
      .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  // 功能说明卡片
  @Builder FeatureCardsSection() {
    Column({ space: 0 }) {
      Text($r('app.string.feature_intro'))
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('⏱', $r('app.string.ping_latency_test'), $r('app.string.ping_latency_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', $r('app.string.ping_connectivity'), $r('app.string.ping_connectivity_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📈', $r('app.string.ping_stats_report'), $r('app.string.ping_stats_desc'))
      }
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

  @Builder FeatureItem(emoji: string, title: string | Resource, desc: string | Resource) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? COLOR_GLASS_SKY_ACTIVE : COLOR_GLASS_SKY_ACTIVE)
        Text(emoji).fontSize(16)
      }

      Column({ space: 3 }) {
        Text(title)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
  }
}
