// Ping 统计卡片 - 独立组件
// 天蓝色毛玻璃风格，3×3 统计网格，值变化带弹跳动画

import {
  adaptiveTextTertiary,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_XL,
  FONT_WEIGHT_BOLD,
  GLASS_BLUR_LG,
  GLASS_SHADOW_LG
} from '@wifi-analyzer/design-system'

// ==================== Props 接口 ====================
export interface PingStatsCardProps {
  sentCount: number
  receivedCount: number
  lossRate: number
  maxTime: number
  minTime: number
  avgTime: number
  jitter: number
  stabilityScore: number
}

// ==================== 统计卡片 ====================
@Component
export struct PingStatsCard {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  // 统计数值输入（简单类型 @Prop，ArkTS 同步可靠）
  @Watch('onSentChanged')
  @Prop sentCount: number = 0
  @Watch('onReceivedChanged')
  @Prop receivedCount: number = 0
  @Watch('onLossChanged')
  @Prop lossRate: number = 0
  @Watch('onMaxChanged')
  @Prop maxTime: number = 0
  @Watch('onMinChanged')
  @Prop minTime: number = 0
  @Watch('onAvgChanged')
  @Prop avgTime: number = 0
  @Watch('onJitterChanged')
  @Prop jitter: number = 0
  @Watch('onStabilityChanged')
  @Prop stabilityScore: number = 0

  // 动画缩放值
  @State pulseSent: number = 1
  @State pulseReceived: number = 1
  @State pulseLoss: number = 1
  @State pulseMax: number = 1
  @State pulseMin: number = 1
  @State pulseAvg: number = 1
  @State pulseJitter: number = 1
  @State pulseStability: number = 1

  // ==================== 动画回调 ====================
  private triggerPulse(setter: (v: number) => void): void {
    try {
      this.getUIContext().animateTo({ duration: 120, curve: Curve.EaseOut }, (): void => { setter(1.2) })
      setTimeout((): void => {
        try {
          this.getUIContext().animateTo({ duration: 180, curve: Curve.FastOutSlowIn }, (): void => { setter(1) })
        } catch (_) {
        }
      }, 120)
    } catch (_) {
      setter(1)
    }
  }

  onSentChanged(): void {
    this.triggerPulse((v: number): void => { this.pulseSent = v })
  }

  onReceivedChanged(): void {
    this.triggerPulse((v: number): void => { this.pulseReceived = v })
  }

  onLossChanged(): void {
    this.triggerPulse((v: number): void => { this.pulseLoss = v })
  }

  onMaxChanged(): void {
    this.triggerPulse((v: number): void => { this.pulseMax = v })
  }

  onMinChanged(): void {
    this.triggerPulse((v: number): void => { this.pulseMin = v })
  }

  onAvgChanged(): void {
    this.triggerPulse((v: number): void => { this.pulseAvg = v })
  }

  onJitterChanged(): void {
    this.triggerPulse((v: number): void => { this.pulseJitter = v })
  }

  onStabilityChanged(): void {
    this.triggerPulse((v: number): void => { this.pulseStability = v })
  }

  build() {
    Column({ space: 0 }) {
      // 第一行：发送 / 接收 / 丢包率
      Row() {
        this.AnimatedStatCell($r('app.string.ping_count'), String(this.sentCount), '', COLOR_SKY_BLUE, false, this.pulseSent)
        this.StatDivider()
        this.AnimatedStatCell($r('app.string.ping_received'), String(this.receivedCount), '/' + String(this.sentCount), COLOR_SUCCESS, false, this.pulseReceived)
        this.StatDivider()
        this.AnimatedStatCell($r('app.string.ping_loss'), String(this.lossRate) + '%', '',
          this.lossRate === 0 ? COLOR_SUCCESS : (this.lossRate > 10 ? COLOR_DANGER : COLOR_WARNING),
          this.lossRate > 0, this.pulseLoss)
      }
      .width('100%')

      Column().width('100%').height(0.5)
        .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER)

      // 第二行：最大 / 最小 / 平均
      Row() {
        this.AnimatedStatCell($r('app.string.ping_max'), this.maxTime > 0 ? String(this.maxTime) + 'ms' : '--', '', COLOR_SKY_BLUE_LIGHT, false, this.pulseMax)
        this.StatDivider()
        this.AnimatedStatCell($r('app.string.ping_min'), this.minTime > 0 ? String(this.minTime) + 'ms' : '--', '', COLOR_SUCCESS, false, this.pulseMin)
        this.StatDivider()
        this.AnimatedStatCell($r('app.string.ping_avg'), this.avgTime > 0 ? String(this.avgTime) + 'ms' : '--', '', COLOR_SKY_BLUE, false, this.pulseAvg)
      }
      .width('100%')

      Column().width('100%').height(0.5)
        .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER)

      // 第三行：抖动 / 稳定性
      Row() {
        this.AnimatedStatCell($r('app.string.jitter'), this.jitter > 0 ? String(this.jitter) + 'ms' : '--', '',
          this.jitter === 0 ? COLOR_SUCCESS : (this.jitter > 5 ? COLOR_DANGER : COLOR_WARNING),
          this.jitter > 2, this.pulseJitter)
        this.StatDivider()
        this.AnimatedStatCell($r('app.string.stability'), String(this.stabilityScore), '/100',
          this.getStabilityColor(this.stabilityScore), this.stabilityScore < 80, this.pulseStability)
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  @Builder AnimatedStatCell(label: Resource | string, mainValue: string, subValue: string, valueColor: string, isAlert: boolean, scaleVal: number = 1) {
    Column({ space: 3 }) {
      // 数值行：主数值 + 副标签（带弹跳缩放）
      Row({ space: subValue.length > 0 ? 3 : 0 }) {
        Text(mainValue)
          .fontSize(FONT_SIZE_XL)
          .fontColor(valueColor)
          .fontWeight(FONT_WEIGHT_BOLD)
          .scale({ x: scaleVal, y: scaleVal })
        if (subValue.length > 0) {
          Text(subValue)
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
            .margin({ top: 3 })
        }
      }
      // 标签行
      Text(label)
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FontWeight.Bold)
        .fontColor(isAlert ? '#FFFFFF' : adaptiveTextTertiary(this.isDarkMode))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 12, bottom: 12 })
    .backgroundColor(isAlert ? (this.isDarkMode ? COLOR_DANGER : COLOR_DANGER) : Color.Transparent)
    .borderRadius(8)
    .scale({ x: scaleVal, y: scaleVal })
  }

  @Builder StatDivider() {
    Column()
      .width(1).height(36)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_DIVIDER)
  }

  getStabilityColor(score: number): string {
    if (score >= 80) return COLOR_SUCCESS
    if (score >= 60) return COLOR_SKY_BLUE
    if (score >= 40) return COLOR_WARNING
    return COLOR_DANGER
  }
}
