// ============================================
// Aurora WiFi V2 — 毛玻璃组件库
// API Level: 23+
// ============================================

import {
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_AURORA_GLOW,
  // 毛玻璃色彩
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_GLASS_AURORA_BORDER,
  // 文字色
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  // 阴影
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_GLASS_STRONG,
  COLOR_SHADOW_AURORA,
  // 光晕
  COLOR_GLOW_PRIMARY,
  COLOR_GLOW_INNER,
  // 信号色
  SIGNAL_COLORS_AURORA,
  SIGNAL_COLORS_AURORA_BG,
  // 动效
  DURATION_FAST,
  DURATION_NORMAL,
  AnimationTapScale,
  // 半径
  RADIUS_CARD,
  RADIUS_BUTTON
} from '@wifi-analyzer/design-system'

// ============================================
// 颜色工具函数
// ============================================

/**
 * 将十六进制颜色转换为 RGBA 字符串
 * @param hex 十六进制颜色，如 #00D97E
 * @param alpha 透明度 0-1
 */
function hexToRgba(hex: string, alpha: number): string {
  // 处理已有的 rgba 格式
  if (hex.startsWith('rgba') || hex.startsWith('rgb')) {
    return hex.replace(/[\d.]+\)$/, `${alpha})`)
  }
  // 处理十六进制格式
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  if (result) {
    const r = parseInt(result[1], 16)
    const g = parseInt(result[2], 16)
    const b = parseInt(result[3], 16)
    return `rgba(${r},${g},${b},${alpha})`
  }
  // 降级处理
  return hex
}

// ============================================
// 基础毛玻璃卡片
// ============================================

@Component
export struct AuroraGlassCard {
  @Prop cardPadding: number = 20
  @Prop glowEnabled: boolean = false

  build() {
    Column() {
      // 内容插槽
    }
    .width('100%')
    .padding(this.cardPadding)
    .backgroundColor(COLOR_GLASS_CARD)
    .border({
      width: 1,
      color: this.glowEnabled ? COLOR_GLASS_AURORA_BORDER : COLOR_GLASS_BORDER_LIGHT,
      radius: RADIUS_CARD
    })
    .shadow({
      radius: this.glowEnabled ? 20 : 16,
      color: this.glowEnabled ? COLOR_SHADOW_AURORA : COLOR_SHADOW_GLASS,
      offsetX: 0,
      offsetY: 4
    })
  }
}

// ============================================
// Aurora 强调卡片（用于重要信息展示）
// ============================================

@Component
export struct AuroraEmphasisCard {
  @Prop title: string = ''
  @Prop subtitle: string = ''
  @Prop value: string = ''
  @Prop icon: Resource = $r('app.media.ic_wifi')
  @Prop statusColor: string = SIGNAL_COLORS_AURORA.excellent

  @State private cardScale: number = 1.0

  build() {
    Column() {
      Row({ space: 16 }) {
        // 左侧图标区
        Stack({ alignContent: Alignment.Center }) {
          // 图标光晕 - 适配十六进制颜色
          Circle()
            .width(56)
            .height(56)
            .fill(hexToRgba(this.statusColor, 0.15))
          // 图标
          Image(this.icon)
            .width(28)
            .height(28)
            .fillColor(this.statusColor)
        }
        .width(56)
        .height(56)

        // 右侧文字区
        Column({ space: 4 }) {
          // 状态标签
          Row({ space: 6 }) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor(COLOR_TEXT_GLASS_SECONDARY)

            Circle()
              .width(6)
              .height(6)
              .fill(this.statusColor)
          }

          // 主标题
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT_GLASS_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 数值
          Text(this.value)
            .fontSize(14)
            .fontColor(COLOR_TEXT_GLASS_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(COLOR_GLASS_CARD)
    .border({
      width: 1,
      color: COLOR_GLASS_BORDER_MEDIUM,
      radius: RADIUS_CARD
    })
    .shadow({
      radius: 16,
      color: COLOR_SHADOW_GLASS,
      offsetX: 0,
      offsetY: 4
    })
    .scale({ x: this.cardScale, y: this.cardScale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        animateTo(AnimationTapScale, () => {
          this.cardScale = 0.98
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.cardScale = 1.0
        })
      }
    })
  }
}

// ============================================
// 毛玻璃列表项
// ============================================

@Component
export struct AuroraListItem {
  @Prop itemTitle: string = ''
  @Prop itemSubtitle: string = ''
  @Prop itemValue: string = ''
  @Prop itemIcon: Resource = $r('app.media.ic_wifi')
  @Prop iconColor: string = COLOR_AURORA_PRIMARY
  @Prop showArrow: boolean = true
  @Prop badge: string = ''

  @State private itemScale: number = 1.0
  @State private itemOpacity: number = 1.0

  build() {
    Row({ space: 16 }) {
      // 图标
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(44)
          .height(44)
          .fill(`${this.iconColor}20`)

        Image(this.itemIcon)
          .width(22)
          .height(22)
          .fillColor(this.iconColor)
      }
      .width(44)
      .height(44)

      // 文字区
      Column({ space: 2 }) {
        Row({ space: 8 }) {
          Text(this.itemTitle)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLOR_TEXT_GLASS_PRIMARY)

          if (this.badge !== '') {
            Text(this.badge)
              .fontSize(10)
              .fontColor(COLOR_AURORA_PRIMARY)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor('rgba(74,144,217,0.2)')
              .borderRadius(10)
          }
        }

        Text(this.itemSubtitle)
          .fontSize(13)
          .fontColor(COLOR_TEXT_GLASS_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .constraintSize({ minWidth: 0 })

      // 右侧值
      if (this.itemValue !== '') {
        Text(this.itemValue)
          .fontSize(14)
          .fontColor(COLOR_TEXT_GLASS_SECONDARY)
      }

      // 箭头
      if (this.showArrow) {
        Image($r('app.media.ic_arrow_right'))
          .width(20)
          .height(20)
          .fillColor(COLOR_TEXT_GLASS_TERTIARY)
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 16, right: 16 })
    .backgroundColor(COLOR_GLASS_SURFACE)
    .borderRadius(RADIUS_BUTTON)
    .scale({ x: this.itemScale, y: this.itemScale })
    .opacity(this.itemOpacity)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        animateTo(AnimationTapScale, () => {
          this.itemScale = 0.98
          this.itemOpacity = 0.85
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.itemScale = 1.0
          this.itemOpacity = 1.0
        })
      }
    })
  }
}

// ============================================
// Aurora 工具图标网格项
// ============================================

@Component
export struct AuroraToolItem {
  @Prop toolTitle: string = ''
  @Prop toolIcon: Resource = $r('app.media.ic_tool')
  @Prop iconBgColor: string = 'rgba(74,144,217,0.15)'
  @Prop iconColor: string = COLOR_AURORA_PRIMARY
  @Prop itemIndex: number = 0

  @State private itemScale: number = 1.0
  @State private itemY: number = 0

  aboutToAppear(): void {
    // 入场动画：轻微上浮
    animateTo({
      duration: 400 + this.itemIndex * 50,
      curve: Curve.EaseOut
    }, () => {
      this.itemY = 0
    })
    this.itemY = 20
  }

  build() {
    Column({ space: 8 }) {
      // 图标容器
      Stack({ alignContent: Alignment.Center }) {
        // 图标背景
        Column()
          .width(52)
          .height(52)
          .borderRadius(16)
          .backgroundColor(this.iconBgColor)
          .shadow({
            radius: 8,
            color: `${this.iconColor}30`,
            offsetX: 0,
            offsetY: 2
          })

        // 图标
        Image(this.toolIcon)
          .width(26)
          .height(26)
          .fillColor(this.iconColor)
      }

      // 标题
      Text(this.toolTitle)
        .fontSize(12)
        .fontColor(COLOR_TEXT_GLASS_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(12)
    .scale({ x: this.itemScale, y: this.itemScale })
    .translate({ y: this.itemY })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        animateTo(AnimationTapScale, () => {
          this.itemScale = 0.92
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.itemScale = 1.0
        })
      }
    })
  }
}

// ============================================
// Aurora 信号强度指示器
// ============================================

@Component
export struct AuroraSignalIndicator {
  @Prop signalLevel: string = 'none'
  @Prop signalLabel: string = ''
  @Prop showLabel: boolean = true
  @Prop indicatorSize: string = 'medium'

  private getBarColor(): string {
    const level = this.signalLevel
    if (level === 'excellent') return SIGNAL_COLORS_AURORA.excellent
    if (level === 'good') return SIGNAL_COLORS_AURORA.good
    if (level === 'fair') return SIGNAL_COLORS_AURORA.fair
    if (level === 'poor') return SIGNAL_COLORS_AURORA.poor
    return SIGNAL_COLORS_AURORA.none
  }

  private getBarCount(): number {
    switch (this.signalLevel) {
      case 'excellent': return 4
      case 'good': return 3
      case 'fair': return 2
      case 'poor': return 1
      default: return 0
    }
  }

  private getBarWidth(): number {
    switch (this.indicatorSize) {
      case 'small': return 4
      case 'medium': return 6
      case 'large': return 8
      default: return 6
    }
  }

  build() {
    Row({ space: 4 }) {
      // 信号条
      Row({ space: 2 }) {
        ForEach([1, 2, 3, 4], (barIndex: number) => {
          Column()
            .width(this.getBarWidth())
            .height(6 + barIndex * 3)
            .borderRadius(2)
            .backgroundColor(barIndex <= this.getBarCount()
              ? this.getBarColor()
              : 'rgba(255,255,255,0.2)')
        })
      }

      // 标签
      if (this.showLabel && this.signalLabel !== '') {
        Text(this.signalLabel)
          .fontSize(11)
          .fontColor(this.getBarColor())
          .margin({ left: 6 })
      }
    }
  }
}

// ============================================
// 导出组件列表
// ============================================

interface AuroraComponentMap {
  GlassCard: object
  EmphasisCard: object
  ListItem: object
  ToolItem: object
  SignalIndicator: object
}

export const AuroraComponents: AuroraComponentMap = {
  GlassCard: AuroraGlassCard,
  EmphasisCard: AuroraEmphasisCard,
  ListItem: AuroraListItem,
  ToolItem: AuroraToolItem,
  SignalIndicator: AuroraSignalIndicator
}
