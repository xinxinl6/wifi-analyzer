// Ping 测试 - 初始视图组件
// 天蓝色毛玻璃风格

import { adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveCardBg, adaptiveDivider,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER, COLOR_SKY_BLUE_GAUGE_BG,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER, COLOR_GLASS_SKY_SHADOW_MED,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_AURORA,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL } from '@wifi-analyzer/design-system'
import { PingResult, QuickAddressItem } from './PingTestPage'
import { PingMode, getDuration } from '../utils/NativePing'

// ==================== Props 接口 ====================
export interface IdleViewProps {
  isDarkMode: boolean
  inputText: string
  gatewayStatus: string
  detectedGateway: string
  detectedDns: string
  quickAddressList: QuickAddressItem[]
  pingMode: PingMode
  nativeSupported: boolean
  onInputChange: (value: string) => void
  onRecommendTap: (index: number) => void
  // 新增：仅填充网关地址（不立即开始Ping）
  onFillGateway: () => void
  onStartPing: () => void
  onToggleMode: () => void
  hasQuickAddresses: () => boolean
  // 点击"历史趋势"功能卡片 → 打开历史记录弹窗
  onShowHistory?: () => void
}

// ==================== 初始视图 ====================
@Component
export struct IdleView {
  @Prop isDarkMode: boolean = false
  @Prop inputText: string = ''
  @Prop gatewayStatus: string = 'loading'
  @Prop detectedGateway: string = ''
  @Prop detectedDns: string = ''
  @Prop quickAddressList: QuickAddressItem[] = []
  @Prop pingMode: PingMode = PingMode.FAST
  @Prop nativeSupported: boolean = true

  onInputChange: (value: string) => void = () => {}
  onRecommendTap: (index: number) => void = () => {}
  onFillGateway: () => void = () => {}
  onStartPing: () => void = () => {}
  onToggleMode: () => void = () => {}
  hasQuickAddresses: () => boolean = () => false
  onShowHistory?: () => void = undefined

  // 获取模式显示标签
  private getModeLabel(): Resource | string {
    return this.pingMode === PingMode.FAST ? $r('app.string.ping_fast_mode') : $r('app.string.ping_accurate_mode')
  }

  // 获取模式描述
  private getModeDesc(): Resource | string {
    return this.pingMode === PingMode.FAST ? $r('app.string.ping_interval_fast') : $r('app.string.ping_interval_accurate')
  }

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 大标题区
        Column({ space: 6 }) {
          Text($r('app.string.ping_test'))
            .fontSize(FONT_SIZE_3XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
          Text($r('app.string.ping_desc'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: SPACE_SM })

        // 搜索栏
        this.SearchBarSection()

        // Ping 模式切换
        this.PingModeSwitcher()

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
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
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
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== Ping 模式切换器 ====================
  @Builder PingModeSwitcher() {
    Row({ space: 10 }) {
      // 左侧标签
      Text($r('app.string.ping_mode_label'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))

      Blank()

      // 快速模式按钮
      Row({ space: 4 }) {
        if (this.pingMode === PingMode.FAST) {
          Circle().width(6).height(6).fill(COLOR_SKY_BLUE)
        }
        Text($r('app.string.ping_fast_mode')).fontSize(FONT_SIZE_XS).fontColor(
          this.pingMode === PingMode.FAST ? COLOR_SKY_BLUE : adaptiveTextTertiary(this.isDarkMode))
        .fontWeight(this.pingMode === PingMode.FAST ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
        Text($r('app.string.ping_interval_fast')).fontSize(FONT_SIZE_XS).fontColor(
          this.pingMode === PingMode.FAST ? COLOR_SKY_BLUE : adaptiveTextTertiary(this.isDarkMode))
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.pingMode === PingMode.FAST
        ? (this.isDarkMode ? COLOR_SKY_BLUE_GAUGE_BG : COLOR_SKY_BLUE_GAUGE_BG)
        : Color.Transparent)
      .borderRadius(999)
      .onClick(() => { if (this.pingMode !== PingMode.FAST) this.onToggleMode() })

      // 分隔
      Text('|').fontSize(FONT_SIZE_XS).fontColor(adaptiveDivider(this.isDarkMode))

      // 准确模式按钮
      Row({ space: 4 }) {
        if (this.pingMode === PingMode.ACCURATE) {
          Circle().width(6).height(6).fill(COLOR_SKY_BLUE)
        }
        Text($r('app.string.ping_accurate_mode')).fontSize(FONT_SIZE_XS).fontColor(
          this.pingMode === PingMode.ACCURATE ? COLOR_SKY_BLUE : adaptiveTextTertiary(this.isDarkMode))
        .fontWeight(this.pingMode === PingMode.ACCURATE ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
        Text($r('app.string.ping_interval_accurate')).fontSize(FONT_SIZE_XS).fontColor(
          this.pingMode === PingMode.ACCURATE ? COLOR_SKY_BLUE : adaptiveTextTertiary(this.isDarkMode))
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.pingMode === PingMode.ACCURATE
        ? (this.isDarkMode ? COLOR_SKY_BLUE_GAUGE_BG : COLOR_SKY_BLUE_GAUGE_BG)
        : Color.Transparent)
      .borderRadius(999)
      .onClick(() => { if (this.pingMode !== PingMode.ACCURATE) this.onToggleMode() })
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
  }

  // ==================== 推荐标签 ====================
  @Builder RecommendTagsSection() {
    Column({ space: 8 }) {
      Text($r('app.string.recommended_target'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
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
              this.gatewayStatus === 'loading' ? adaptiveTextTertiary(this.isDarkMode) :
                (this.gatewayStatus === 'ready' ? COLOR_SKY_BLUE : COLOR_WARNING)
            )
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .backgroundColor(
          this.gatewayStatus === 'ready'
            ? (this.isDarkMode ? COLOR_SKY_BLUE_GAUGE_BG : COLOR_GLASS_SKY_TAG_BG)
            : (this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_TAG_BG)
        )
        .borderRadius(999)
        .borderWidth(1)
        .borderColor(
          this.gatewayStatus === 'ready'
            ? (this.isDarkMode ? COLOR_SKY_BLUE_DIVIDER : COLOR_GLASS_SKY_TAG_BORDER)
            : (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_TAG_BORDER)
        )
        .onClick(() => this.onFillGateway())

        // DNS 标签
        Row({ space: 5 }) {
          Circle().width(7).height(7)
            .fill(this.detectedDns !== '' ? COLOR_SUCCESS : adaptiveTextTertiary(this.isDarkMode))
          Text($r('app.string.dns'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(COLOR_SKY_BLUE)
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .backgroundColor(this.isDarkMode ? COLOR_SKY_BLUE_GAUGE_BG : COLOR_GLASS_SKY_TAG_BG)
        .borderRadius(999)
        .borderWidth(1)
        .borderColor(this.isDarkMode ? COLOR_SKY_BLUE_DIVIDER : COLOR_GLASS_SKY_TAG_BORDER)
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
        .backgroundColor(this.isDarkMode ? COLOR_SKY_BLUE_GAUGE_BG : COLOR_GLASS_SKY_TAG_BG)
        .borderRadius(999)
        .borderWidth(1)
        .borderColor(this.isDarkMode ? COLOR_SKY_BLUE_DIVIDER : COLOR_GLASS_SKY_TAG_BORDER)
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
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .width('100%')
      .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem($r('app.media.ic_ping'), $r('app.string.latency_detection'), $r('app.string.latency_detection_desc'), '⚡')
        Column().width('100%').height(0.5).backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER)
        this.FeatureItem($r('app.media.ic_stability'), $r('app.string.stability_analysis'), $r('app.string.stability_analysis_desc'), '📊')
        Column().width('100%').height(0.5).backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER)
        // 历史趋势卡片 — 可点击，弹出历史记录
        this.FeatureItemClickable($r('app.media.ic_chart'), $r('app.string.history_trend'), $r('app.string.history_trend_desc'), '📈')
      }
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
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
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›').fontSize(18).fontColor(COLOR_SKY_BLUE)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
  }

  /** 可点击的功能项（用于"历史趋势"卡片） */
  @Builder FeatureItemClickable(icon: Resource, title: Resource, desc: Resource, emoji: string) {
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
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›').fontSize(18).fontColor(COLOR_SKY_BLUE)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .onClick(() => { this.onShowHistory?.() })
    .stateStyles({ pressed: { backgroundColor: this.isDarkMode ? COLOR_GLASS_SKY_ACTIVE : COLOR_GLASS_SKY_TAG_BG } })
  }
}
