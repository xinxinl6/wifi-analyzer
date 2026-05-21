// 路由追踪 — 初始空闲视图组件
// 包含：搜索栏 + 推荐标签 + 功能说明卡片

import { COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY, COLOR_SHADOW_DARK,
  COLOR_SKY_BLUE,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_2XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_LG, SPACE_MD,
  GLASS_BLUR_LG, GLASS_SHADOW_LG, GLASS_SHADOW_XL, GLASS_SHADOW_SM,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider } from '@wifi-analyzer/design-system'

@Component
export struct TracerouteIdleView {
  @Prop isDarkMode: boolean = false
  @Prop inputText: string = ''
  @Prop detectedGateway: string = ''
  @Prop detectedDns: string = ''
  private recommendItems: Resource[] = [$r('app.string.gateway'), $r('app.string.dns'), $r('app.string.baidu')]
  onInputChange: (value: string) => void = () => {}
  onSubmit: () => void = () => {}
  onFillGateway: () => void = () => {}
  onFillDns: () => void = () => {}
  onRecommendTap: (index: number) => void = () => {}

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 大标题区
        Column({ space: 6 }) {
          Text($r('app.string.route_trace'))
            .fontSize(FONT_SIZE_2XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
          Text($r('app.string.path_desc'))
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

  // 搜索栏 - 毛玻璃风格
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_route'))
        .width(20).height(20)
        .fillColor(COLOR_SKY_BLUE)

      TextInput({ placeholder: $r('app.string.input_ip_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => this.onInputChange(value))
        .onSubmit(() => this.onSubmit())

      // 追踪按钮 — 胶囊
      Row() {
        Text($r('app.string.trace'))
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
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 推荐标签
  @Builder RecommendTagsSection() {
    Column({ space: 8 }) {
      Text($r('app.string.recommended_target'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        ForEach(this.recommendItems, (item: Resource, index: number) => {
          Row({ space: 5 }) {
            Text(index === 0 ? '\u{1F6E1}' : index === 1 ? '\u{1F50D}' : '\u{1F310}')
              .fontSize(14)
            Text(item)
              .fontSize(FONT_SIZE_MD)
              .fontColor(COLOR_SKY_BLUE)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_SKY_LIGHT : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(this.isDarkMode ? COLOR_GLASS_BORDER : COLOR_GLASS_SKY_TAG_BORDER)
          .onClick(() => this.onRecommendTap(index))
        }, (item: Resource, index: number): string => String(index))
      }
      .alignSelf(ItemAlign.Start)
    }
    .alignSelf(ItemAlign.Start)
    .width('100%')
  }

  // 功能说明卡片 - 毛玻璃
  @Builder FeatureCardsSection() {
    Column({ space: 0 }) {
      // 标题
      Row() {
        Text($r('app.string.feature_intro'))
          .fontSize(FONT_SIZE_SM)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .width('100%')
      .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem($r('app.media.ic_route'), $r('app.string.path_detection'), $r('app.string.path_desc'), '\u{1F6F0}')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem($r('app.media.ic_device'), $r('app.string.latency_analysis'), $r('app.string.latency_analysis_desc'), '\u26A1')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem($r('app.media.ic_dns'), $r('app.string.statistics_report'), $r('app.string.statistics_report_desc'), '\u{1F4CA}')
      }
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(icon: Resource, title: Resource, desc: Resource, emoji: string) {
    Row({ space: 14 }) {
      // 图标容器
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? COLOR_GLASS_SKY_LIGHT : COLOR_GLASS_SKY_ACTIVE)
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

      Text('\u203A').fontSize(18).fontColor('rgba(14,165,233,0.5)')
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
  }
}
