// WifiFilterChips.ets - WiFi筛选胶囊组件
// 提取自 WifiListSection.ets

import {
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_GLASS_AURORA_BORDER,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_TEXT_LIGHT_PRIMARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_TEXT_LIGHT_TERTIARY,
  COLOR_SHADOW_AURORA,
  COLOR_SHADOW_GLASS,
  COLOR_GLASS_SURFACE_LIGHT,
  SIGNAL_COLORS_AURORA,
  SIGNAL_THRESHOLD_EXCELLENT,
  SIGNAL_THRESHOLD_GOOD,
  SIGNAL_THRESHOLD_FAIR,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_2XL, FONT_WEIGHT_MEDIUM,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_CARD, RADIUS_BUTTON,
  DURATION_FAST, DURATION_NORMAL, AnimationTapScale,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary
} from '@wifi-analyzer/design-system'

// 筛选按钮配置接口
export interface WifiFilterChipConfig {
  label: Resource | string
  isSelected: boolean
  onClick: () => void
}

// 筛选胶囊（Aurora 风格）
@Component
export struct WifiFilterChip {
  @Prop config: WifiFilterChipConfig = { label: '', isSelected: false, onClick: () => {} }

  build() {
    Column() {
      Text(this.config.label)
        .fontSize(FONT_SIZE_SM)
        .fontWeight(this.config.isSelected ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.config.isSelected ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY)
    }
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    .backgroundColor(this.config.isSelected ? COLOR_AURORA_PRIMARY : COLOR_GLASS_SURFACE_MEDIUM)
    .borderRadius(20)
    .border({
      width: 1,
      color: this.config.isSelected ? COLOR_GLASS_BORDER_MEDIUM : COLOR_GLASS_AURORA_BORDER
    })
    .shadow({
      radius: this.config.isSelected ? 12 : 6,
      color: this.config.isSelected ? COLOR_SHADOW_AURORA : COLOR_SHADOW_GLASS,
      offsetX: 0,
      offsetY: this.config.isSelected ? 4 : 2
    })
    .backdropBlur(this.config.isSelected ? 8 : 4)
    .animation({ duration: DURATION_NORMAL, curve: Curve.EaseOut })
    .onClick(this.config.onClick)
  }
}

// 扫描按钮（Aurora 风格）
@Component
export struct WifiScanButton {
  @Prop isScanning: boolean = false
  onTap: () => void = () => {}

  build() {
    Row({ space: SPACE_SM }) {
      if (this.isScanning) {
        LoadingProgress()
          .width(14)
          .height(14)
          .color(COLOR_TEXT_GLASS_PRIMARY)
      } else {
        Text('↺')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT_GLASS_PRIMARY)
      }
      Text(this.isScanning ? $r('app.string.scanning') : $r('app.string.refresh'))
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLOR_TEXT_GLASS_PRIMARY)
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .backgroundColor(this.isScanning ? COLOR_GLASS_AURORA : COLOR_AURORA_PRIMARY)
    .borderRadius(RADIUS_BUTTON)
    .border({
      width: 1,
      color: this.isScanning ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_BORDER_MEDIUM
    })
    .shadow({
      radius: 12,
      color: this.isScanning ? COLOR_SHADOW_GLASS : COLOR_SHADOW_AURORA,
      offsetX: 0,
      offsetY: 4
    })
    .backdropBlur(8)
    .animation({ duration: DURATION_NORMAL, curve: Curve.EaseOut })
    .onClick(() => { this.onTap() })
  }
}
