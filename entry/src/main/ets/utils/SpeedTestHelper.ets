// SpeedTestHelper.ets - 测速工具函数
// 提取自 SpeedTestSection.ets

import {
  COLOR_SUCCESS,
  COLOR_WARNING,
  COLOR_DANGER,
  COLOR_SKY_BLUE,
  COLOR_SKY_BLUE_LIGHT,
  COLOR_SKY_BLUE_GAUGE_BG,
  COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_PRIMARY,
  COLOR_TEXT_SECONDARY,
  COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS,
  FONT_SIZE_SM,
  FONT_SIZE_LG,
  FONT_SIZE_XL,
  FONT_SIZE_2XL,
  FONT_SIZE_3XL,
  FONT_SIZE_4XL,
  GAUGE_SIZE_XL,
  STROKE_WIDTH_3XL,
  GLASS_SHADOW_MD,
  SPACE_SM,
  SPACE_LG,
  SPACE_2XL,
  adaptiveTextTertiary,
  adaptiveTextSecondary,
  adaptiveTextPrimary
} from '@wifi-analyzer/design-system'

// 格式化显示速度
export function formatDisplaySpeed(displaySpeed: number, currentPhase: string, isTesting: boolean): string {
  if (currentPhase === 'idle' || (displaySpeed <= 0 && !isTesting)) {
    return '0.0'
  }
  return displaySpeed.toFixed(1)
}

// 获取 Ping 颜色
export function getPingColor(displayPing: number): string {
  if (displayPing < 30) return COLOR_SUCCESS
  if (displayPing < 80) return COLOR_WARNING
  return COLOR_DANGER
}

// 获取仪表盘阴影颜色
export function getGaugeShadowColor(currentPhase: string): string {
  switch (currentPhase) {
    case 'ping': return 'rgba(251,191,36,0.5)'
    case 'download': return 'rgba(14,165,233,0.5)'
    case 'upload': return 'rgba(52,211,153,0.5)'
    case 'done': return 'rgba(52,211,153,0.5)'
    case 'error': return 'rgba(248,113,113,0.5)'
    default: return 'rgba(14,165,233,0.3)'
  }
}

// 获取仪表盘颜色
export function getGaugeColor(currentPhase: string): string {
  switch (currentPhase) {
    case 'selecting': return COLOR_SKY_BLUE_LIGHT
    case 'ping': return COLOR_WARNING
    case 'download': return COLOR_SKY_BLUE
    case 'upload': return COLOR_SUCCESS
    case 'done': return COLOR_SUCCESS
    case 'error': return COLOR_DANGER
    case 'idle': return COLOR_SKY_BLUE
    default: return COLOR_SKY_BLUE
  }
}

// 获取仪表盘弧长
export function getGaugeArcLength(gaugeProgress: number): number {
  const diameter: number = GAUGE_SIZE_XL - 16
  const circumference: number = Math.round(Math.PI * diameter)
  return Math.max(circumference * gaugeProgress, 0)
}

// 获取速度标签资源
export function getSpeedLabelResource(currentPhase: string): Resource {
  if (currentPhase === 'done') return $r('app.string.download_speed')
  if (currentPhase === 'selecting') return $r('app.string.node_selecting')
  if (currentPhase === 'download') return $r('app.string.download_in_progress')
  if (currentPhase === 'upload') return $r('app.string.upload_in_progress')
  if (currentPhase === 'ping') return $r('app.string.latency_testing')
  return $r('app.string.tap_to_start')
}

// 导出常量供子组件使用
export {
  COLOR_SUCCESS,
  COLOR_WARNING,
  COLOR_DANGER,
  COLOR_SKY_BLUE,
  COLOR_SKY_BLUE_LIGHT,
  COLOR_SKY_BLUE_GAUGE_BG,
  COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_PRIMARY,
  COLOR_TEXT_SECONDARY,
  COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS,
  FONT_SIZE_SM,
  FONT_SIZE_LG,
  FONT_SIZE_XL,
  FONT_SIZE_2XL,
  FONT_SIZE_3XL,
  FONT_SIZE_4XL,
  GAUGE_SIZE_XL,
  STROKE_WIDTH_3XL,
  GLASS_SHADOW_MD,
  SPACE_SM,
  SPACE_LG,
  SPACE_2XL,
  adaptiveTextTertiary,
  adaptiveTextSecondary,
  adaptiveTextPrimary
}
