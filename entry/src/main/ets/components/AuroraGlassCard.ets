// ============================================
// Aurora WiFi V2 — 毛玻璃基础卡片
// ============================================

import {
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_AURORA_BORDER,
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_AURORA,
  RADIUS_CARD
} from '@wifi-analyzer/design-system'

/**
 * 将十六进制颜色转换为 RGBA 字符串
 * @param hex 十六进制颜色，如 #00D97E
 * @param alpha 透明度 0-1
 */
export function hexToRgba(hex: string, alpha: number): string {
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
