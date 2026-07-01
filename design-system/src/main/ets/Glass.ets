// ============================================
// HM7 沉浸光感 — 5级材质组件库（systemMaterial 就绪）
// API Level: 23+ (systemMaterial 需 API 26)
// 暗色材质：rgba(255,255,255,X) 光从下方透上
// 亮色材质：rgba(0,0,0,X) 反相逻辑
// 暗色模式不用阴影，靠材质 blur 景深
// 详见项目根目录 DESIGN.md
// ⚠️ systemMaterial 会接管 backgroundColor/borderColor，注意 Blend Conflict
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
// 显式接口类型定义
// ============================================

export class Shadow {
  radius: number = 0
  color: string = 'rgba(0,0,0,0.06)'
  offsetX: number = 0
  offsetY: number = 2

  constructor(radius: number, color: string, offsetX: number, offsetY: number) {
    this.radius = radius
    this.color = color
    this.offsetX = offsetX
    this.offsetY = offsetY
  }
}

interface GlassShadowStyle {
  radius: number
  color: string
  offsetX: number
  offsetY: number
}

interface GlassTabBarStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
  shadow: GlassShadowStyle
}

interface GlassCardStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
  shadow: GlassShadowStyle
}

interface GlassAuroraCardStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
  shadow: GlassShadowStyle
}

interface GlassButtonStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
}

interface GlassFabStyleType {
  backgroundColor: string
  borderRadius: number
  shadow: GlassShadowStyle
}

interface GlassBubbleStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
}

interface GlassInputStyleType {
  backgroundColor: string
  borderColor: string
  borderWidth: number
  borderRadius: number
}

interface AnimationConfigType {
  duration: number
  curve: Curve
}

interface SignalColorMap {
  excellent: string
  good: string
  fair: string
  poor: string
  none: string
}

// AuroraStyleConfig 内嵌接口
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

interface AuroraStyleConfigType {
  glass: AuroraGlassColors
  border: AuroraBorderColors
  shadow: AuroraShadowColors
  glow: AuroraGlowColors
  text: AuroraTextColors
  aurora: AuroraAccentColors
  radius: AuroraRadiusValues
}

// ============================================
// HM7 5级材质 blur 半径
// ============================================
// Level 0: 4px (Ultra Thin)  — StatusBar, NavigationBar
// Level 1: 8px (Thin)        — TabBar, WiFi list items, tool cards
// Level 2: 16px (Medium)     — Metric cards, search bar, channel cards
// Level 3: 24px (Thick)      — Dialogs, settings cards
// Level 4: 32px (Ultra Thick) — Connection card, semi-modal panels

export const BLUR_RADIUS_LIGHT = 8
export const BLUR_RADIUS_MEDIUM = 16
export const BLUR_RADIUS_HIGH = 24

// ============================================
// 圆角常量（HM7 规范）
// ============================================
export const RADIUS_TAB_BAR = 24
export const RADIUS_CARD = 16
export const RADIUS_BUTTON = 24
export const RADIUS_MODAL = 20

// ============================================
// 基础材质样式构建器
// ============================================

/**
 * 获取材质背景色（根据主题 + 级别）
 * 暗色：rgba(255,255,255,X)
 * 亮色：rgba(0,0,0,X)
 */
export function getGlassBackground(isDark: boolean, level: 'light' | 'medium' | 'high' = 'medium'): string {
  if (isDark) {
    switch (level) {
      case 'light': return 'rgba(255,255,255,0.06)'   // Level 1 Thin
      case 'medium': return 'rgba(255,255,255,0.10)'   // Level 2 Medium
      case 'high': return 'rgba(255,255,255,0.16)'     // Level 3 Thick
    }
  }
  // 亮色
  switch (level) {
    case 'light': return 'rgba(0,0,0,0.04)'
    case 'medium': return 'rgba(0,0,0,0.06)'
    case 'high': return 'rgba(0,0,0,0.10)'
  }
}

/**
 * 获取材质边框色（根据主题）
 */
export function getGlassBorder(isDark: boolean): string {
  return isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.10)'
}

/**
 * 获取材质阴影（HM7 暗色不用阴影）
 */
export function getGlassShadow(isDark: boolean): string {
  if (isDark) {
    return 'none'
  }
  return `0 1px 4px rgba(0,0,0,0.04)`
}

// ============================================
// 预置材质样式对象（HM7）
// ============================================

/**
 * TabBar 材质样式 — Level 0 Ultra Thin
 * 底部悬浮 + 全圆角 + 极淡边框
 */
export const GlassTabBarStyle: GlassTabBarStyleType = {
  backgroundColor: 'rgba(255,255,255,0.02)',
  borderColor: 'rgba(255,255,255,0.04)',
  borderWidth: 1,
  borderRadius: RADIUS_TAB_BAR,
  shadow: {
    radius: 0,
    color: 'transparent',
    offsetX: 0,
    offsetY: 0
  }
}

/**
 * 卡片材质样式 — Level 2 Medium
 * 16px 圆角 + 材质模糊 + 不投影
 */
export const GlassCardStyle: GlassCardStyleType = {
  backgroundColor: 'rgba(255,255,255,0.10)',
  borderColor: 'rgba(255,255,255,0.08)',
  borderWidth: 1,
  borderRadius: RADIUS_CARD,
  shadow: {
    radius: 0,
    color: 'transparent',
    offsetX: 0,
    offsetY: 0
  }
}

/**
 * Aurora 强调卡片 — Level 3 Thick + 品牌调
 */
export const GlassAuroraCardStyle: GlassAuroraCardStyleType = {
  backgroundColor: 'rgba(49,122,247,0.12)',
  borderColor: 'rgba(49,122,247,0.18)',
  borderWidth: 1,
  borderRadius: RADIUS_CARD,
  shadow: {
    radius: 0,
    color: 'transparent',
    offsetX: 0,
    offsetY: 0
  }
}

/**
 * 按钮材质样式 — Level 1 Thin
 */
export const GlassButtonStyle: GlassButtonStyleType = {
  backgroundColor: 'rgba(255,255,255,0.06)',
  borderColor: 'rgba(255,255,255,0.06)',
  borderWidth: 1,
  borderRadius: RADIUS_BUTTON
}

/**
 * 悬浮按钮（FAB）样式
 * 品牌色实色 + 微光晕
 */
export const GlassFabStyle: GlassFabStyleType = {
  backgroundColor: COLOR_AURORA_PRIMARY,
  borderRadius: 28,
  shadow: {
    radius: 12,
    color: 'rgba(49,122,247,0.20)',
    offsetX: 0,
    offsetY: 4
  }
}

// ============================================
// AI 助手按钮样式
// ============================================

export const GlassAIStyle: GlassFabStyleType = {
  backgroundColor: COLOR_AURORA_PRIMARY,
  borderRadius: 28,
  shadow: {
    radius: 16,
    color: 'rgba(49,122,247,0.25)',
    offsetX: 0,
    offsetY: 4
  }
}

export const GlassBubbleStyle: GlassBubbleStyleType = {
  backgroundColor: 'rgba(255,255,255,0.10)',
  borderColor: 'rgba(255,255,255,0.06)',
  borderWidth: 1,
  borderRadius: 20
}

export const GlassInputStyle: GlassInputStyleType = {
  backgroundColor: 'rgba(255,255,255,0.08)',
  borderColor: 'rgba(255,255,255,0.08)',
  borderWidth: 1,
  borderRadius: RADIUS_BUTTON
}

// ============================================
// 动效配置 — 与 Animations.ets 保持同步
// ============================================

export const DURATION_FAST = 150
export const DURATION_NORMAL = 300
export const DURATION_SLOW = 400

export const CURVE_EASE_OUT: Curve = Curve.EaseOut
export const CURVE_EASE_IN_OUT: Curve = Curve.EaseInOut
export const CURVE_SPRING: Curve = Curve.FastOutSlowIn

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
// 信号强度颜色（HM7 降饱和）
// ============================================

export const SIGNAL_COLORS_AURORA: SignalColorMap = {
  excellent: '#5BA854',
  good: '#5EA1FF',
  fair: '#DB6B42',
  poor: '#D94838',
  none: 'rgba(255,255,255,0.40)'
}

export const SIGNAL_COLORS_AURORA_BG: SignalColorMap = {
  excellent: 'rgba(91,168,84,0.15)',
  good: 'rgba(94,161,255,0.15)',
  fair: 'rgba(219,107,66,0.15)',
  poor: 'rgba(217,72,56,0.15)',
  none: 'rgba(255,255,255,0.06)'
}

// ============================================
// 导出完整样式配置对象（HM7 映射）
// ============================================

export const AuroraStyleConfig: AuroraStyleConfigType = {
  glass: {
    surface: 'rgba(255,255,255,0.06)',
    surfaceLight: 'rgba(255,255,255,0.04)',
    surfaceMedium: 'rgba(255,255,255,0.10)',
    surfaceHigh: 'rgba(255,255,255,0.16)',
    card: 'rgba(255,255,255,0.10)',
    aurora: 'rgba(49,122,247,0.10)',
    auroraLight: 'rgba(49,122,247,0.06)',
    darkSurface: COLOR_GLASS_DARK_SURFACE,
    darkCard: COLOR_GLASS_DARK_CARD
  } as AuroraGlassColors,
  border: {
    light: 'rgba(255,255,255,0.06)',
    medium: 'rgba(255,255,255,0.08)',
    strong: 'rgba(255,255,255,0.12)',
    aurora: 'rgba(49,122,247,0.15)',
    dark: COLOR_GLASS_DARK_BORDER
  } as AuroraBorderColors,
  shadow: {
    glass: 'rgba(0,0,0,0.02)',
    glassStrong: 'rgba(0,0,0,0.04)',
    aurora: 'rgba(49,122,247,0.08)'
  } as AuroraShadowColors,
  glow: {
    primary: 'rgba(49,122,247,0.15)',
    inner: 'rgba(255,255,255,0.08)'
  } as AuroraGlowColors,
  text: {
    primary: 'rgba(255,255,255,0.90)',
    secondary: 'rgba(255,255,255,0.60)',
    tertiary: 'rgba(255,255,255,0.40)'
  } as AuroraTextColors,
  aurora: {
    primary: COLOR_AURORA_PRIMARY,
    glow: COLOR_AURORA_GLOW
  } as AuroraAccentColors,
  radius: {
    tabBar: RADIUS_TAB_BAR,
    card: RADIUS_CARD,
    button: RADIUS_BUTTON,
    modal: RADIUS_MODAL
  } as AuroraRadiusValues
} as AuroraStyleConfigType
