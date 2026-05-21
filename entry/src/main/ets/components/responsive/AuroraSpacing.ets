// ============================================
// Aurora WiFi V2 — 响应式间距系统
// ============================================

import { auroraResponsive, getLayoutMode, AuroraLayoutMode } from './AuroraBreakpoints'
import { COLOR_SHADOW_GLASS, COLOR_SHADOW_GLASS_STRONG, COLOR_SHADOW_AURORA } from '@wifi-analyzer/design-system'

// ============================================
// Aurora 间距 Token
// ============================================
export const AuroraSpacing = {
  // 基础间距（4px 基准）
  xs: 4,    // 超紧凑
  sm: 8,    // 紧凑
  md: 16,   // 标准
  lg: 24,   // 宽松
  xl: 32,   // 超宽松
  xxl: 48,  // 极大
  xxxl: 64, // 巨量

  // 页面边距
  pagePhone: 16,
  pageTablet: 24,
  pagePC: 32,

  // 卡片间距
  cardGapPhone: 12,
  cardGapTablet: 16,
  cardGapPC: 20,

  // 组件间距
  componentGapPhone: 8,
  componentGapTablet: 12,
  componentGapPC: 16,
} as const

// ============================================
// Aurora 响应式间距
// ============================================

/**
 * 获取页面水平边距
 */
export function getPagePadding(): number {
  const mode = getLayoutMode()
  switch (mode) {
    case AuroraLayoutMode.FULL:
      return AuroraSpacing.pagePC
    case AuroraLayoutMode.EXPANDED:
      return AuroraSpacing.pageTablet
    default:
      return AuroraSpacing.pagePhone
  }
}

/**
 * 获取卡片间距
 */
export function getCardGap(): number {
  const mode = getLayoutMode()
  switch (mode) {
    case AuroraLayoutMode.FULL:
      return AuroraSpacing.cardGapPC
    case AuroraLayoutMode.EXPANDED:
      return AuroraSpacing.cardGapTablet
    default:
      return AuroraSpacing.cardGapPhone
  }
}

/**
 * 获取组件间距
 */
export function getComponentGap(): number {
  const mode = getLayoutMode()
  switch (mode) {
    case AuroraLayoutMode.FULL:
      return AuroraSpacing.componentGapPC
    case AuroraLayoutMode.EXPANDED:
      return AuroraSpacing.componentGapTablet
    default:
      return AuroraSpacing.componentGapPhone
  }
}

/**
 * 获取垂直间距（响应式）
 */
export function getVerticalSpace(base: number): number {
  return auroraResponsive(base, Math.round(base * 0.75), Math.round(base * 1.5))
}

/**
 * 获取水平间距（响应式）
 */
export function getHorizontalSpace(base: number): number {
  return auroraResponsive(base, Math.round(base * 0.8), Math.round(base * 1.25))
}

// ============================================
// Aurora 间距组件
// ============================================

/**
 * Aurora 间距组件 - 垂直
 */
@Component
export struct AuroraSpacerV {
  @Prop size: number = 16
  build() {
    Column()
      .width('100%')
      .height(this.size)
  }
}

/**
 * Aurora 间距组件 - 水平
 */
@Component
export struct AuroraSpacerH {
  @Prop size: number = 16
  build() {
    Row()
      .height('100%')
      .width(this.size)
  }
}

/**
 * Aurora 安全区域
 */
@Component
export struct AuroraSafeArea {
  @BuilderParam content: () => void = this.defaultContent

  @Builder
  defaultContent() {
    Column()
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .height('100%')
    .padding({
      top: auroraResponsive(20, 12, 32),
      left: auroraResponsive(16, 12, 24),
      right: auroraResponsive(16, 12, 24),
      bottom: auroraResponsive(16, 12, 24)
    })
  }
}

/**
 * Aurora 中心容器
 */
@Component
export struct AuroraCenterContainer {
  @Prop maxWidth: number = 0
  @BuilderParam content: () => void = this.defaultContent

  @Builder
  defaultContent() {
    Column()
  }

  build() {
    Column() {
      Column() {
        this.content()
      }
      .width('100%')
      .height('100%')
      .constraintSize({
        maxWidth: this.maxWidth > 0 ? this.maxWidth : '100%'
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

// ============================================
// Aurora 圆角系统
// ============================================
export const AuroraRadius = {
  // 基础圆角
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32,

  // 组件特定圆角
  button: 12,
  card: 16,
  modal: 20,
  navBar: 24,
  fab: 28,
  sheet: 32,
} as const

/**
 * 获取响应式圆角
 */
export function getResponsiveRadius(base: number): number {
  return auroraResponsive(base, Math.round(base * 0.75), Math.round(base * 1.5))
}

/**
 * 获取卡片圆角
 */
export function getCardRadius(): number {
  return auroraResponsive(AuroraRadius.card, 12, 20)
}

/**
 * 获取按钮圆角
 */
export function getButtonRadius(): number {
  return auroraResponsive(AuroraRadius.button, 8, 16)
}

// ============================================
// Aurora 阴影系统
// ============================================
export const AuroraShadow = {
  // 轻微阴影
  sm: {
    radius: 8,
    color: COLOR_SHADOW_GLASS,
    offsetX: 0,
    offsetY: 2
  },
  // 标准阴影
  md: {
    radius: 16,
    color: COLOR_SHADOW_GLASS_STRONG,
    offsetX: 0,
    offsetY: 4
  },
  // 强阴影
  lg: {
    radius: 24,
    color: COLOR_SHADOW_GLASS_STRONG,
    offsetX: 0,
    offsetY: 8
  },
  // 悬浮阴影（底部导航）
  floating: {
    radius: 32,
    color: COLOR_SHADOW_GLASS_STRONG,
    offsetX: 0,
    offsetY: -8
  },
  // Aurora 光晕阴影
  aurora: {
    radius: 20,
    color: COLOR_SHADOW_AURORA,
    offsetX: 0,
    offsetY: 4
  }
} as const

/**
 * 获取响应式阴影
 */
export function getResponsiveShadow(type: keyof typeof AuroraShadow) {
  const shadow = AuroraShadow[type]
  return {
    radius: auroraResponsive(shadow.radius, Math.round(shadow.radius * 0.75), shadow.radius * 2),
    color: shadow.color,
    offsetX: shadow.offsetX,
    offsetY: auroraResponsive(shadow.offsetY, 1, shadow.offsetY * 2)
  }
}
