// Ping 测试 - 初始视图组件
// 天蓝色毛玻璃风格

import { COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER, COLOR_GLASS_SKY_SHADOW_MED,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL } from '@wifi-analyzer/design-system'
import { PingResult, QuickAddressItem } from './PingTestPage'

// ==================== Props 接口 ====================
export interface IdleViewProps {
  inputText: string
  gatewayStatus: string
  detectedGateway: string
  detectedDns: string
  quickAddressList: QuickAddressItem[]
  onInputChange: (value: string) => void
  onRecommendTap: (index: number) => void
  // 新增：仅填充网关地址（不立即开始Ping）
  onFillGateway: () => void
  onStartPing: () => void
  hasQuickAddresses: () => boolean
}

// ==================== 初始视图 ====================
@Component
export struct IdleView {
  @Prop inputText: string = ''
  @Prop gatewayStatus: string = 'loading'
  @Prop detectedGateway: string = ''
  @Prop detectedDns: string = ''
  @Prop quickAddressList: QuickAddressItem[] = []

  onInputChange: (value: string) => void = () => {}
  onRecommendTap: (index: number) => void = () => {}
  onFillGateway: () => void = () => {}
  onStartPing: () => void = () => {}
  hasQuickAddresses: () => boolean = () => false

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 大标题区
        Column({ space: 6 }) {
          Text($r('app.string.ping_test'))
            .fontSize(FONT_SIZE_3XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(COLOR_TEXT_PRIMARY)
          Text($r('app.string.ping_desc'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(COLOR_TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: SPACE_SM })

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

  // ==================== 搜索栏 - 毛玻璃风格 ====================
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_ping'))
        .width(20).height(20)
        .fillColor(COLOR_SKY_BLUE)

      TextInput({ placeholder: $r('app.string.input_ip_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD)
        .fontColor(COLOR_TEXT_PRIMARY)
        .placeholderColor(COLOR_TEXT_TERTIARY)
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.onInputChange(value) })
        .onSubmit(() => this.onStartPing())

      // Ping 按钮 — 胶囊
      Row() {
        Text($r('app.string.ping_action'))
          .fontSize(FONT_SIZE_SM)
          .fontColor('#FFFFFF')
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_SKY_BLUE)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.onStartPing())
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(COLOR_GLASS_SKY_LIGHT)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 推荐标签 ====================
  @Builder RecommendTagsSection() {
    Column({ space: 8 }) {
      Text($r('app.string.recommended_target'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(COLOR_TEXT_TERTIARY)
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        // 网关标签
        Row({ space: 5 }) {
          if (this.gatewayStatus === 'loading') {
            LoadingProgress()
              .width(12).height(12)
              .color(COLOR_SKY_BLUE)
          } else if (this.gatewayStatus === 'ready') {
            Circle().width(7).height(7).fill(COLOR_SUCCESS)
          } else {
            Circle().width(7).height(7).fill(COLOR_WARNING)
          }
          Text($r('app.string.gateway'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(
              this.gatewayStatus === 'loading' ? COLOR_TEXT_TERTIARY :
                (this.gatewayStatus === 'ready' ? COLOR_SKY_BLUE : COLOR_WARNING)
            )
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .backgroundColor(
          this.gatewayStatus === 'ready' ? COLOR_GLASS_SKY_TAG_BG : 'rgba(148,163,184,0.08)'
        )
        .borderRadius(999)
        .borderWidth(1)
        .borderColor(
          this.gatewayStatus === 'ready' ? COLOR_GLASS_SKY_TAG_BORDER : 'rgba(148,163,184,0.2)'
        )
        .onClick(() => this.onFillGateway())

        // DNS 标签
        Row({ space: 5 }) {
          Circle().width(7).height(7)
            .fill(this.detectedDns !== '' ? COLOR_SUCCESS : COLOR_TEXT_TERTIARY)
          Text($r('app.string.dns'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(COLOR_SKY_BLUE)
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .backgroundColor(COLOR_GLASS_SKY_TAG_BG)
        .borderRadius(999)
        .borderWidth(1)
        .borderColor(COLOR_GLASS_SKY_TAG_BORDER)
        .onClick(() => this.onRecommendTap(1))

        // 百度标签
        Row({ space: 5 }) {
          Text('🌐').fontSize(14)
          Text($r('app.string.baidu'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(COLOR_SKY_BLUE)
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .backgroundColor(COLOR_GLASS_SKY_TAG_BG)
        .borderRadius(999)
        .borderWidth(1)
        .borderColor(COLOR_GLASS_SKY_TAG_BORDER)
        .onClick(() => this.onRecommendTap(2))
      }
      .alignSelf(ItemAlign.Start)
    }
    .alignSelf(ItemAlign.Start)
    .width('100%')
  }

  // ==================== 功能说明卡片 - 毛玻璃 ====================
  @Builder FeatureCardsSection() {
    Column({ space: 0 }) {
      // 标题
      Row() {
        Text($r('app.string.feature_intro'))
          .fontSize(FONT_SIZE_SM)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(COLOR_TEXT_SECONDARY)
      }
      .width('100%')
      .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem($r('app.media.ic_ping'), $r('app.string.latency_detection'), $r('app.string.latency_detection_desc'), '⚡')
        Column().width('100%').height(0.5).backgroundColor(COLOR_SKY_BLUE_DIVIDER)
        this.FeatureItem($r('app.media.ic_stability'), $r('app.string.stability_analysis'), $r('app.string.stability_analysis_desc'), '📊')
        Column().width('100%').height(0.5).backgroundColor(COLOR_SKY_BLUE_DIVIDER)
        this.FeatureItem($r('app.media.ic_chart'), $r('app.string.history_trend'), $r('app.string.history_trend_desc'), '📈')
      }
      .backgroundColor(COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(COLOR_GLASS_SKY_LIGHT)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(icon: Resource, title: Resource, desc: Resource, emoji: string) {
    Row({ space: 14 }) {
      // 图标容器
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(COLOR_GLASS_SKY_ACTIVE)
        Text(emoji).fontSize(16)
      }

      Column({ space: 3 }) {
        Text(title)
          .fontSize(FONT_SIZE_MD)
          .fontColor(COLOR_TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›').fontSize(18).fontColor('rgba(14,165,233,0.5)')
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
  }
}
