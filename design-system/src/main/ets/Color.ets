// ============================================
// WiFi Analyzer — HarmonyOS 7 沉浸光感设计系统
// Immersive Light Sense: 暗色为基 · 材质景深 · 光晕装饰
// 品牌: #0066FF(Light) / #317AF7(Dark)
// 背景: #F2F4F7(Light) / #0A0D14(Dark)
// 详见项目根目录 DESIGN.md
// 兼容 @ComponentV2 架构 · API Level 23+
// ============================================

// ============================================
// 品牌色
// ============================================
export const COLOR_PRIMARY = '#0066FF'
export const COLOR_PRIMARY_LIGHT = '#3388FF'
export const COLOR_PRIMARY_DARK = '#317AF7'
export const COLOR_PRIMARY_DARK_LIGHT = '#5B9AFF'
export const COLOR_PRIMARY_BG = 'rgba(0,102,255,0.07)'
export const COLOR_PRIMARY_BG_DARK = 'rgba(49,122,247,0.12)'

// ============================================
// 功能色（Modern Light）
// ============================================
export const COLOR_SUCCESS = '#059669'
export const COLOR_WARNING = '#D97706'
export const COLOR_DANGER = '#DC2626'
export const COLOR_INFO = '#3B82F6'
export const COLOR_PURPLE = '#8B5CF6'
export const COLOR_PINK = '#EC4899'
export const COLOR_CYAN = '#14B8A6'
export const COLOR_INDIGO = '#5B9AFF'
export const COLOR_ORANGE = '#F97316'
export const COLOR_EMERALD = '#059669'

// ============================================
// 基础色彩变量
// ============================================
export const COLOR_BG = '#F2F4F7'
export const COLOR_CARD = '#FFFFFF'
export const COLOR_BDR = 'rgba(0,0,0,0.05)'
export const COLOR_SHADOW = '0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.03)'
export const COLOR_SHADOW_LG = '0 2px 8px rgba(0,0,0,0.06)'

// 文字色
export const COLOR_TXT_1 = '#1A1D26'
export const COLOR_TXT_2 = '#6B7280'
export const COLOR_TXT_3 = '#9CA3AF'

// 文字色（RGBA 透明度层级，兼容旧版）
export const COLOR_TEXT_PRIMARY = 'rgba(0,0,0,0.95)'
export const COLOR_TEXT_SECONDARY = 'rgba(0,0,0,0.70)'
export const COLOR_TEXT_TERTIARY = 'rgba(0,0,0,0.50)'
export const COLOR_TEXT_DISABLED = 'rgba(0,0,0,0.25)'
export const COLOR_TEXT_ON_COLOR = '#FFFFFF'

// 亮色模式文字（兼容旧版）
export const COLOR_TEXT_LIGHT_PRIMARY = COLOR_TXT_1
export const COLOR_TEXT_LIGHT_SECONDARY = COLOR_TXT_2
export const COLOR_TEXT_LIGHT_TERTIARY = COLOR_TXT_3
export const COLOR_TEXT_LIGHT_DISABLED = 'rgba(0,0,0,0.25)'

// 暗色模式文字（兼容旧版）
export const COLOR_TEXT_DARK_PRIMARY = 'rgba(255,255,255,0.90)'
export const COLOR_TEXT_DARK_SECONDARY = 'rgba(255,255,255,0.60)'
export const COLOR_TEXT_DARK_TERTIARY = 'rgba(255,255,255,0.40)'
export const COLOR_TEXT_GLASS_PRIMARY = 'rgba(255,255,255,0.95)'
export const COLOR_TEXT_GLASS_SECONDARY = 'rgba(255,255,255,0.70)'
export const COLOR_TEXT_GLASS_TERTIARY = 'rgba(255,255,255,0.50)'
export const COLOR_TEXT_GLASS_DISABLED = 'rgba(255,255,255,0.25)'
export const COLOR_TEXT_CYAN_DARK = '#5EA1FF'
export const COLOR_TEXT_AMBER_DARK = '#DB6B42'
export const COLOR_TEXT_GREEN_DARK = '#5BA854'

// 背景/表面
export const COLOR_BACKGROUND = COLOR_BG
export const COLOR_SURFACE = COLOR_CARD
export const COLOR_BORDER = COLOR_BDR
export const COLOR_DIVIDER = COLOR_BDR
export const COLOR_DIVIDER_WEAK = 'rgba(0,0,0,0.04)'
export const COLOR_DIVIDER_STRONG = 'rgba(0,0,0,0.10)'
export const COLOR_CARD_SHADOW = 'rgba(0,0,0,0.04)'
export const COLOR_CARD_SHADOW_STRONG = 'rgba(0,0,0,0.08)'
export const COLOR_MODAL_OVERLAY = 'rgba(0,0,0,0.30)'
export const COLOR_OVERLAY = 'rgba(0,0,0,0.60)'

// ============================================
// 信号强度色
// ============================================
export const COLOR_SIGNAL_EXCELLENT = '#059669'
export const COLOR_SIGNAL_GOOD = '#3B82F6'
export const COLOR_SIGNAL_FAIR = '#D97706'
export const COLOR_SIGNAL_POOR = '#DC2626'

export const COLOR_SIGNAL_EXCELLENT_BG = 'rgba(5,150,105,0.10)'
export const COLOR_SIGNAL_GOOD_BG = 'rgba(59,130,246,0.10)'
export const COLOR_SIGNAL_FAIR_BG = 'rgba(217,119,6,0.10)'
export const COLOR_SIGNAL_POOR_BG = 'rgba(220,38,38,0.10)'
export const COLOR_SIGNAL_TEXT_ON_BG = '#FFFFFF'

export const COLOR_SIGNAL_EXCELLENT_BG_LIGHT = 'rgba(5,150,105,0.08)'
export const COLOR_SIGNAL_POOR_BG_LIGHT = 'rgba(220,38,38,0.08)'

export const SIGNAL_THRESHOLD_EXCELLENT = -50
export const SIGNAL_THRESHOLD_GOOD = -65
export const SIGNAL_THRESHOLD_FAIR = -80

// ============================================
// 信道色标
// ============================================
export const COLOR_CHANNEL_IDLE = '#059669'
export const COLOR_CHANNEL_LIGHT = '#3B82F6'
export const COLOR_CHANNEL_MODERATE = '#D97706'
export const COLOR_CHANNEL_CROWDED = '#DC2626'

export const COLOR_CHANNEL_IDLE_TOP = '#34D399'
export const COLOR_CHANNEL_LIGHT_TOP = '#60A5FA'
export const COLOR_CHANNEL_MODERATE_TOP = '#FBBF24'
export const COLOR_CHANNEL_CROWDED_TOP = '#F87171'

export const COLOR_CHANNEL_RECOMMEND_BG = 'rgba(5,150,105,0.08)'
export const COLOR_CHANNEL_RECOMMEND_BORDER = 'rgba(5,150,105,0.20)'
export const COLOR_CHART_GRID = 'rgba(0,0,0,0.06)'

// ============================================
// 渐变遮罩色
// ============================================
export const COLOR_FADE_TOP = 'rgba(242,244,247,0.60)'
export const COLOR_FADE_BOTTOM = 'rgba(242,244,247,0.60)'
export const COLOR_FADE_LIGHT = 'rgba(242,244,247,0.40)'

// ============================================
// Tab Bar
// ============================================
export const COLOR_TAB_BAR_BG = 'rgba(255,255,255,0.92)'
export const COLOR_TAB_BAR_BORDER = 'rgba(0,0,0,0.05)'
export const COLOR_TAB_BAR_ACTIVE = COLOR_PRIMARY
export const COLOR_TAB_BAR_INACTIVE = COLOR_TXT_3

// ============================================
// Sky Blue 主题色（测速/路由追踪页）
// ============================================
export const COLOR_SKY_BLUE = '#0066FF'
export const COLOR_SKY_BLUE_LIGHT = '#3388FF'
export const COLOR_SKY_BLUE_BG = 'rgba(0,102,255,0.07)'
export const COLOR_SKY_BLUE_GAUGE_BG = 'rgba(0,102,255,0.05)'
export const COLOR_SKY_BLUE_DIVIDER = 'rgba(0,102,255,0.12)'

// Blue 主题色（Ping 页专用）
export const COLOR_BLUE_THEME = '#0066FF'

// ============================================
// 玻璃效果（HM7 材质系统兼容）
// ============================================
export const COLOR_GLASS_WHITE = 'rgba(255,255,255,0.10)'
export const COLOR_GLASS_WHITE_SOLID = 'rgba(255,255,255,0.16)'
export const COLOR_GLASS_SKY = 'rgba(0,102,255,0.08)'
export const COLOR_GLASS_SKY_SOLID = 'rgba(0,102,255,0.12)'
export const COLOR_GLASS_BORDER = 'rgba(0,102,255,0.15)'
export const COLOR_GLASS_SKY_LIGHT = 'rgba(0,102,255,0.06)'
export const COLOR_GLASS_SKY_ACTIVE = 'rgba(0,102,255,0.10)'
export const COLOR_GLASS_SKY_TAG_BG = 'rgba(0,102,255,0.07)'
export const COLOR_GLASS_SKY_TAG_BORDER = 'rgba(0,102,255,0.12)'

export const COLOR_GLASS_BLUE_TAG_BG = 'rgba(0,102,255,0.07)'
export const COLOR_GLASS_BLUE_ACTIVE = 'rgba(0,102,255,0.08)'
export const COLOR_GLASS_BLUE_BORDER = 'rgba(0,102,255,0.10)'
export const COLOR_GLASS_BLUE_TAG_BORDER = 'rgba(0,102,255,0.12)'

export const COLOR_GLASS_SKY_SHADOW_MED = 'rgba(0,102,255,0.15)'
export const COLOR_GLASS_SKY_LINE = 'rgba(0,102,255,0.15)'

// ============================================
// Aurora 旧版兼容
// ============================================
export const COLOR_AURORA_AMBER = '#D97706'
export const COLOR_AURORA_BLUE = '#0066FF'
export const COLOR_AURORA_CYAN = '#3B82F6'
export const COLOR_AURORA_GLOW_AMBER = 'rgba(217,119,6,0.06)'
export const COLOR_AURORA_GLOW_BLUE = 'rgba(0,102,255,0.04)'

export const COLOR_AURORA_PRIMARY = '#0066FF'
export const COLOR_AURORA_LIGHT = '#3388FF'
export const COLOR_AURORA_DEEP = '#0052CC'
export const COLOR_AURORA_GLOW = '#3388FF'
export const COLOR_AURORA_PASTEL = 'rgba(0,102,255,0.07)'

export const GRADIENT_AURORA_START = '#0066FF'
export const GRADIENT_AURORA_MID = '#3388FF'
export const GRADIENT_AURORA_END = '#A8D4F5'
export const GRADIENT_AURORA_BLEND = '#F2F4F7'

// ============================================
// 5 级材质系统（兼容）
// ============================================
export const GLASS_OPACITY_LIGHT = 0.04
export const GLASS_OPACITY_MEDIUM = 0.06
export const GLASS_OPACITY_HIGH = 0.10
export const GLASS_OPACITY_SOLID = 0.16

export const COLOR_GLASS_SURFACE = 'rgba(0,0,0,0.03)'
export const COLOR_GLASS_SURFACE_LIGHT = 'rgba(0,0,0,0.02)'
export const COLOR_GLASS_SURFACE_MEDIUM = 'rgba(0,0,0,0.04)'
export const COLOR_GLASS_SURFACE_HIGH = 'rgba(0,0,0,0.06)'
export const COLOR_GLASS_CARD = 'rgba(0,0,0,0.03)'

export const COLOR_GLASS_BORDER_LIGHT = 'rgba(0,0,0,0.04)'
export const COLOR_GLASS_BORDER_MEDIUM = 'rgba(0,0,0,0.06)'
export const COLOR_GLASS_BORDER_STRONG = 'rgba(0,0,0,0.08)'

export const COLOR_GLASS_AURORA = 'rgba(0,102,255,0.07)'
export const COLOR_GLASS_AURORA_LIGHT = 'rgba(0,102,255,0.05)'
export const COLOR_GLASS_AURORA_BORDER = 'rgba(0,102,255,0.10)'

// ============================================
// 光晕效果
// ============================================
export const COLOR_GLOW_PRIMARY = 'rgba(0,102,255,0.10)'
export const COLOR_GLOW_SECONDARY = 'rgba(51,136,255,0.08)'
export const COLOR_GLOW_INNER = 'rgba(255,255,255,0.80)'
export const COLOR_GLOW_OUTER = 'rgba(0,102,255,0.06)'

// ============================================
// 暗色主题兼容
// ============================================
export const COLOR_GLASS_DARK_SURFACE = 'rgba(255,255,255,0.06)'
export const COLOR_GLASS_DARK_CARD = 'rgba(255,255,255,0.14)'
export const COLOR_GLASS_DARK_BORDER = 'rgba(255,255,255,0.08)'

export const COLOR_BG_TOP = '#0A0D14'
export const COLOR_BG_MID = '#080A10'
export const COLOR_BG_BOTTOM = '#090C13'
export const COLOR_BG_AURORA = 'rgba(49,122,247,0.04)'

// 阴影
export const COLOR_SHADOW_GLASS = 'rgba(0,0,0,0.02)'
export const COLOR_SHADOW_GLASS_STRONG = 'rgba(0,0,0,0.04)'
export const COLOR_SHADOW_AURORA = 'rgba(0,102,255,0.06)'
export const COLOR_SHADOW_DARK = 'rgba(0,0,0,0.08)'
export const SHADOW_GLASS_BLUR = 16
export const SHADOW_GLASS_SPREAD = 0

// 暗色主题兼容
export const COLOR_CARD_DARK = 'rgba(255,255,255,0.14)'
export const COLOR_CARD_DARK_SOLID = 'rgba(255,255,255,0.24)'
export const COLOR_CARD_DARK_ALT = 'rgba(255,255,255,0.06)'
export const COLOR_CARD_LIGHT = 'rgba(0,0,0,0.03)'
export const COLOR_CARD_LIGHT_SOLID = '#FFFFFF'
export const COLOR_BORDER_CYAN = 'rgba(0,102,255,0.10)'
export const COLOR_BORDER_AMBER = 'rgba(217,119,6,0.10)'
export const COLOR_BTN_DARK = 'rgba(255,255,255,0.06)'
export const COLOR_INPUT_DARK = 'rgba(255,255,255,0.08)'
export const COLOR_DIVIDER_DARK = 'rgba(255,255,255,0.06)'
export const COLOR_TAB_BAR_BG_DARK = 'rgba(255,255,255,0.02)'
export const COLOR_TAB_BAR_BORDER_DARK = 'rgba(255,255,255,0.04)'
export const COLOR_TAB_BAR_ACTIVE_BG_DARK = 'rgba(49,122,247,0.15)'
export const COLOR_TAB_BAR_INACTIVE_DARK = 'rgba(255,255,255,0.40)'
export const COLOR_TAB_BAR_TEXT_DARK = 'rgba(255,255,255,0.90)'

// 暗色模式图表
export const COLOR_CHART_GRID_DARK = 'rgba(255,255,255,0.06)'
export const COLOR_FADE_DARK_TOP = 'rgba(10,13,20,0.60)'
export const COLOR_FADE_DARK_BOTTOM = 'rgba(10,13,20,0.60)'

// 云朵装饰
export const COLOR_CLOUD_1 = 'rgba(255,255,255,0.10)'
export const COLOR_CLOUD_2 = 'rgba(255,255,255,0.06)'

// ============================================
// 背景渐变色值数组
// ============================================
export const COLOR_BG_DARK_LIST: Array<[ResourceColor, number]> = [
  ['#0A0D14', 0],
  ['#080A10', 0.5],
  ['#090C13', 1]
]

export const COLOR_BG_LIGHT_LIST: Array<[ResourceColor, number]> = [
  ['#F2F4F7', 0],
  ['#F0F2F5', 0.4],
  ['#F8FAFC', 0.75],
  ['#FDFDFE', 1]
]

// 暗色光晕装饰
export const COLOR_GLOW_DARK_1 = 'rgba(49,122,247,0.06)'
export const COLOR_GLOW_DARK_2 = 'rgba(91,154,255,0.04)'
export const COLOR_GLOW_DARK_3 = 'rgba(49,122,247,0.03)'

// 亮色光晕装饰
export const COLOR_GLOW_LIGHT_1 = 'rgba(0,102,255,0.04)'
export const COLOR_GLOW_LIGHT_2 = 'rgba(51,136,255,0.03)'
export const COLOR_GLOW_LIGHT_3 = 'rgba(0,102,255,0.02)'

// ============================================
// 自适应函数 — 根据 isDark 返回对应颜色
// ============================================

export function adaptiveBackgroundList(isDark: boolean): Array<[ResourceColor, number]> {
  return isDark ? COLOR_BG_DARK_LIST : COLOR_BG_LIGHT_LIST
}

export function adaptiveGlowLarge(isDark: boolean): string {
  return isDark ? COLOR_GLOW_DARK_1 : COLOR_GLOW_LIGHT_1
}

export function adaptiveGlowMedium(isDark: boolean): string {
  return isDark ? COLOR_GLOW_DARK_2 : COLOR_GLOW_LIGHT_2
}

export function adaptiveGlowSmall(isDark: boolean): string {
  return isDark ? COLOR_GLOW_DARK_3 : COLOR_GLOW_LIGHT_3
}

export function adaptiveTextPrimary(isDark: boolean): string {
  return isDark ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
}

export function adaptiveTextSecondary(isDark: boolean): string {
  return isDark ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY
}

export function adaptiveTextTertiary(isDark: boolean): string {
  return isDark ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
}

export function adaptiveCardBg(isDark: boolean): string {
  return isDark ? COLOR_CARD_DARK : COLOR_CARD_LIGHT
}

export function adaptiveFadeColor(isDark: boolean): string {
  return isDark ? COLOR_FADE_DARK_BOTTOM : COLOR_FADE_BOTTOM
}

export function adaptiveChartGrid(isDark: boolean): string {
  return isDark ? COLOR_CHART_GRID_DARK : COLOR_CHART_GRID
}

export function adaptiveDivider(isDark: boolean): string {
  return isDark ? COLOR_DIVIDER_DARK : COLOR_DIVIDER_WEAK
}

export function adaptiveSkyBlue(isDark: boolean): string {
  return isDark ? COLOR_SKY_BLUE_LIGHT : COLOR_SKY_BLUE
}

export function adaptiveAuroraPrimary(isDark: boolean): string {
  return isDark ? COLOR_AURORA_LIGHT : COLOR_AURORA_PRIMARY
}

export function adaptiveTextCyan(isDark: boolean): string {
  return isDark ? COLOR_TEXT_CYAN_DARK : COLOR_SKY_BLUE
}

export function adaptiveTextAmber(isDark: boolean): string {
  return isDark ? COLOR_TEXT_AMBER_DARK : COLOR_WARNING
}

export function adaptiveTextGreen(isDark: boolean): string {
  return isDark ? COLOR_TEXT_GREEN_DARK : COLOR_SUCCESS
}

export function adaptiveCardDarkGlass(isDark: boolean): string {
  return isDark ? COLOR_CARD_DARK : COLOR_GLASS_CARD
}

export function adaptiveBorderCyan(isDark: boolean): string {
  return isDark ? COLOR_BORDER_CYAN : COLOR_GLASS_AURORA_BORDER
}

export function adaptivePrimary(isDark: boolean): string {
  return isDark ? COLOR_PRIMARY_DARK : COLOR_PRIMARY
}

export function adaptivePrimaryLight(isDark: boolean): string {
  return isDark ? COLOR_PRIMARY_DARK_LIGHT : COLOR_PRIMARY_LIGHT
}

export function adaptivePrimaryBg(isDark: boolean): string {
  return isDark ? COLOR_PRIMARY_BG_DARK : COLOR_PRIMARY_BG
}

export function adaptiveTabActiveBg(isDark: boolean): string {
  return isDark ? 'rgba(49,122,247,0.12)' : 'rgba(10,89,247,0.08)'
}

export function adaptiveSuccess(isDark: boolean): string {
  return isDark ? '#5BA854' : COLOR_SUCCESS
}

export function adaptiveDanger(isDark: boolean): string {
  return isDark ? '#D94838' : COLOR_DANGER
}

export function adaptiveWarning(isDark: boolean): string {
  return isDark ? '#DB6B42' : COLOR_WARNING
}

export function adaptiveInfo(isDark: boolean): string {
  return isDark ? '#5EA1FF' : COLOR_INFO
}

export function adaptiveInputBg(isDark: boolean): string {
  return isDark ? COLOR_INPUT_DARK : 'rgba(0,0,0,0.04)'
}

export function adaptiveInputBorder(isDark: boolean): string {
  return isDark ? 'rgba(49,122,247,0.12)' : 'rgba(0,102,255,0.10)'
}

export function adaptiveBtnBg(isDark: boolean): string {
  return isDark ? COLOR_BTN_DARK : 'rgba(0,0,0,0.04)'
}

export function adaptiveBtnBorder(isDark: boolean): string {
  return isDark ? 'rgba(49,122,247,0.10)' : 'rgba(0,102,255,0.08)'
}

// ============================================
// 工具函数
// ============================================

export function withOpacity(color: string, opacity: number): string {
  return color + Math.round(opacity * 255).toString(16).padStart(2, '0')
}

export function glassColor(opacity: number): string {
  return `rgba(255,255,255,${opacity})`
}

export function auroraGradient(): string {
  return `linear-gradient(135deg, ${GRADIENT_AURORA_START} 0%, ${GRADIENT_AURORA_MID} 50%, ${GRADIENT_AURORA_END} 100%)`
}

export function backgroundGradient(isDark: boolean): string {
  if (isDark) {
    return `linear-gradient(180deg, ${COLOR_BG_TOP} 0%, ${COLOR_BG_BOTTOM} 100%)`
  }
  return `linear-gradient(180deg, ${GRADIENT_AURORA_BLEND} 0%, #EBF0F5 100%)`
}
