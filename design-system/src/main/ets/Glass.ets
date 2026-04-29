// ============================================
// Aurora WiFi V2 — 毛玻璃效果组件库
// API Level: 23+
// ============================================

import {
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_BORDER_STRONG,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_GLASS_AURORA_BORDER,
  COLOR_GLASS_DARK_SURFACE,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLOW_PRIMARY,
  COLOR_GLOW_INNER,
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_GLASS_STRONG,
  COLOR_SHADOW_AURORA,
  SHADOW_GLASS_BLUR,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_GLOW,
  GRADIENT_AURORA_START,
  GRADIENT_AURORA_END
} from './Color'

// ============================================
// 显式接口类型定义（ArkTS禁止交集类型）
// ============================================

// 阴影配置
interface GlassShadowStyle {
  radius: number
  color: string
  offsetX: number
  offsetY: number
}

// TabBar + 边框 + 阴影
interface GlassTabBarStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
  shadow: GlassShadowStyle
}

// 卡片 + 边框 + 阴影
interface GlassCardStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
  shadow: GlassShadowStyle
}

// 强调卡片 + 边框 + 阴影
interface GlassAuroraCardStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
  shadow: GlassShadowStyle
}

// 按钮 + 边框
interface GlassButtonStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
}

// FAB + 阴影
interface GlassFabStyleType {
  backgroundColor: string
  borderRadius: number
  shadow: GlassShadowStyle
}

// 对话气泡 + 边框
interface GlassBubbleStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
}

// 输入框 + 边框
interface GlassInputStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
}

// 动效曲线类型
interface AnimationConfigType {
  duration: number
  curve: Curve
}

// 信号颜色类型
interface SignalColorMap {
  excellent: string
  good: string
  fair: string
  poor: string
  none: string
}

// AuroraStyleConfig 内嵌对象接口
interface AuroraGlassColors {
  surface: string
  surfaceLight: string
  surfaceMedium: string
  surfaceHigh: string
  card: string
  aurora: string
  auroraLight: string
  darkSurface: string
  darkCard: string
}

interface AuroraBorderColors {
  light: string
  medium: string
  strong: string
  aurora: string
  dark: string
}

interface AuroraShadowColors {
  glass: string
  glassStrong: string
  aurora: string
}

interface AuroraGlowColors {
  primary: string
  inner: string
}

interface AuroraTextColors {
  primary: string
  secondary: string
  tertiary: string
}

interface AuroraAccentColors {
  primary: string
  glow: string
}

interface AuroraRadiusValues {
  tabBar: number
  card: number
  button: number
  modal: number
}

// AuroraStyleConfig 类型（使用分离的接口引用）
interface AuroraStyleConfigType {
  glass: AuroraGlassColors
  border: AuroraBorderColors
  shadow: AuroraShadowColors
  glow: AuroraGlowColors
  text: AuroraTextColors
  aurora: AuroraAccentColors
  radius: AuroraRadiusValues
}

// 毛玻璃模糊半径常量
export const BLUR_RADIUS_LIGHT = 12
export const BLUR_RADIUS_MEDIUM = 20
export const BLUR_RADIUS_HIGH = 30

// 圆角常量
export const RADIUS_TAB_BAR = 24
export const RADIUS_CARD = 20
export const RADIUS_BUTTON = 16
export const RADIUS_MODAL = 28

// ============================================
// 基础毛玻璃样式构建器
// ============================================

/**
 * 获取毛玻璃背景色彩（根据主题）
 */
export function getGlassBackground(isDark: boolean, level: 'light' | 'medium' | 'high' = 'medium'): string {
  if (isDark) {
    switch (level) {
      case 'light': return COLOR_GLASS_DARK_SURFACE
      case 'medium': return 'rgba(26,39,68,0.80)'
      case 'high': return COLOR_GLASS_DARK_CARD
    }
  }
  switch (level) {
    case 'light': return COLOR_GLASS_SURFACE_LIGHT
    case 'medium': return COLOR_GLASS_SURFACE_MEDIUM
    case 'high': return COLOR_GLASS_SURFACE_HIGH
  }
}

/**
 * 获取毛玻璃边框色彩（根据主题）
 */
export function getGlassBorder(isDark: boolean): string {
  return isDark ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER_MEDIUM
}

/**
 * 获取毛玻璃阴影（根据主题）
 */
export function getGlassShadow(isDark: boolean): string {
  if (isDark) {
    return `0 8px 32px ${COLOR_SHADOW_GLASS_STRONG}, 0 2px 8px ${COLOR_SHADOW_GLASS}`
  }
  return `0 8px 32px ${COLOR_SHADOW_GLASS}, 0 2px 8px rgba(0,0,0,0.05)`
}

// ============================================
// 预置毛玻璃样式对象
// ============================================

/**
 * TabBar 毛玻璃样式
 * 悬浮高度 + 圆角 + 光晕边框
 */
export const GlassTabBarStyle: GlassTabBarStyleType = {
  backgroundColor: COLOR_GLASS_SURFACE_MEDIUM,
  borderColor: COLOR_GLASS_BORDER_LIGHT,
  borderWidth: 1,
  borderRadius: RADIUS_TAB_BAR,
  shadow: {
    radius: 20,
    color: COLOR_SHADOW_GLASS_STRONG,
    offsetX: 0,
    offsetY: -4
  }
}

/**
 * 卡片毛玻璃样式
 */
export const GlassCardStyle: GlassCardStyleType = {
  backgroundColor: COLOR_GLASS_CARD,
  borderColor: COLOR_GLASS_BORDER_MEDIUM,
  borderWidth: 1,
  borderRadius: RADIUS_CARD,
  shadow: {
    radius: SHADOW_GLASS_BLUR,
    color: COLOR_SHADOW_GLASS,
    offsetX: 0,
    offsetY: 4
  }
}

/**
 * Aurora 强调卡片样式
 */
export const GlassAuroraCardStyle: GlassAuroraCardStyleType = {
  backgroundColor: COLOR_GLASS_AURORA,
  borderColor: COLOR_GLASS_AURORA_BORDER,
  borderWidth: 1,
  borderRadius: RADIUS_CARD,
  shadow: {
    radius: 16,
    color: COLOR_SHADOW_AURORA,
    offsetX: 0,
    offsetY: 4
  }
}

/**
 * 按钮毛玻璃样式
 */
export const GlassButtonStyle: GlassButtonStyleType = {
  backgroundColor: COLOR_GLASS_SURFACE,
  borderColor: COLOR_GLASS_BORDER_LIGHT,
  borderWidth: 1,
  borderRadius: RADIUS_BUTTON
}

/**
 * 悬浮按钮（FAB）样式
 */
export const GlassFabStyle: GlassFabStyleType = {
  backgroundColor: COLOR_AURORA_PRIMARY,
  borderRadius: 28,
  shadow: {
    radius: 16,
    color: COLOR_GLOW_PRIMARY,
    offsetX: 0,
    offsetY: 4
  }
}

// ============================================
// AI 助手按钮样式
// ============================================

/**
 * AI助手悬浮按钮样式
 * 渐变背景 + 脉冲光晕动画
 */
export const GlassAIStyle: GlassFabStyleType = {
  backgroundColor: COLOR_AURORA_PRIMARY,
  borderRadius: 28,
  shadow: {
    radius: 20,
    color: COLOR_GLOW_PRIMARY,
    offsetX: 0,
    offsetY: 4
  }
}

/**
 * AI对话气泡样式
 */
export const GlassBubbleStyle: GlassBubbleStyleType = {
  backgroundColor: COLOR_GLASS_SURFACE_MEDIUM,
  borderColor: COLOR_GLASS_BORDER_LIGHT,
  borderWidth: 1,
  borderRadius: 20
}

/**
 * AI输入框样式
 */
export const GlassInputStyle: GlassInputStyleType = {
  backgroundColor: COLOR_GLASS_SURFACE_LIGHT,
  borderColor: COLOR_GLASS_BORDER_LIGHT,
  borderWidth: 1,
  borderRadius: 24
}

// ============================================
// 动效配置
// ============================================

// 动效时长常量（毫秒）
export const DURATION_FAST = 150
export const DURATION_NORMAL = 300
export const DURATION_SLOW = 400

// 缓动曲线
export const CURVE_EASE_OUT = Curve.EaseOut
export const CURVE_EASE_IN_OUT = Curve.EaseInOut
export const CURVE_SPRING = Curve.FastOutSlowIn

// 点击反馈动画配置
export const AnimationTapScale: AnimationConfigType = {
  duration: DURATION_FAST,
  curve: CURVE_EASE_OUT
}

export const AnimationPressIn: AnimationConfigType = {
  duration: DURATION_FAST,
  curve: Curve.FastOutSlowIn
}

export const AnimationPressOut: AnimationConfigType = {
  duration: DURATION_NORMAL,
  curve: Curve.FastOutLinearIn
}

// ============================================
// 信号强度颜色（适配 Aurora 主题）
// ============================================

export const SIGNAL_COLORS_AURORA: SignalColorMap = {
  excellent: '#00D97E',
  good: '#4ADE80',
  fair: '#FBBF24',
  poor: '#F87171',
  none: '#94A3B8'
}

export const SIGNAL_COLORS_AURORA_BG: SignalColorMap = {
  excellent: 'rgba(0,217,126,0.15)',
  good: 'rgba(74,222,128,0.15)',
  fair: 'rgba(251,191,36,0.15)',
  poor: 'rgba(248,113,113,0.15)',
  none: 'rgba(148,163,184,0.15)'
}

// ============================================
// 导出完整样式配置对象
// ============================================

export const AuroraStyleConfig: AuroraStyleConfigType = {
  // 毛玻璃
  glass: {
    surface: COLOR_GLASS_SURFACE,
    surfaceLight: COLOR_GLASS_SURFACE_LIGHT,
    surfaceMedium: COLOR_GLASS_SURFACE_MEDIUM,
    surfaceHigh: COLOR_GLASS_SURFACE_HIGH,
    card: COLOR_GLASS_CARD,
    aurora: COLOR_GLASS_AURORA,
    auroraLight: COLOR_GLASS_AURORA_LIGHT,
    darkSurface: COLOR_GLASS_DARK_SURFACE,
    darkCard: COLOR_GLASS_DARK_CARD
  } as AuroraGlassColors,
  // 边框
  border: {
    light: COLOR_GLASS_BORDER_LIGHT,
    medium: COLOR_GLASS_BORDER_MEDIUM,
    strong: COLOR_GLASS_BORDER_STRONG,
    aurora: COLOR_GLASS_AURORA_BORDER,
    dark: COLOR_GLASS_DARK_BORDER
  } as AuroraBorderColors,
  // 阴影
  shadow: {
    glass: COLOR_SHADOW_GLASS,
    glassStrong: COLOR_SHADOW_GLASS_STRONG,
    aurora: COLOR_SHADOW_AURORA
  } as AuroraShadowColors,
  // 光晕
  glow: {
    primary: COLOR_GLOW_PRIMARY,
    inner: COLOR_GLOW_INNER
  } as AuroraGlowColors,
  // 文字
  text: {
    primary: COLOR_TEXT_GLASS_PRIMARY,
    secondary: COLOR_TEXT_GLASS_SECONDARY,
    tertiary: COLOR_TEXT_GLASS_TERTIARY
  } as AuroraTextColors,
  // Aurora主色
  aurora: {
    primary: COLOR_AURORA_PRIMARY,
    glow: COLOR_AURORA_GLOW
  } as AuroraAccentColors,
  // 半径
  radius: {
    tabBar: RADIUS_TAB_BAR,
    card: RADIUS_CARD,
    button: RADIUS_BUTTON,
    modal: RADIUS_MODAL
  } as AuroraRadiusValues
} as AuroraStyleConfigType
