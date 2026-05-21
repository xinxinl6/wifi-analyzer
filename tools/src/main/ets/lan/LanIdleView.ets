// LAN 空闲状态 + 操作按钮 — Aurora WiFi V2

import {
  COLOR_PRIMARY, COLOR_DANGER,
  FONT_SIZE_LG, FONT_SIZE_MD, FONT_SIZE_SM,
  FONT_WEIGHT_BOLD, FONT_WEIGHT_MEDIUM,
  SPACE_2XL, SPACE_MD,
  RADIUS_3XL,
  GLASS_SHADOW_SM,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextPrimary, adaptiveTextTertiary
} from '@wifi-analyzer/design-system'

// ==================== 空状态 ====================
@Component
export struct LanIdleState {
  @Prop isDarkMode: boolean = false

  build() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(80)
          .height(80)
          .fill(this.isDarkMode ? 'rgba(16,185,129,0.18)' : 'rgba(16,185,129,0.12)')

        Image($r('app.media.ic_lan'))
          .width(40)
          .height(40)
          .fillColor(COLOR_PRIMARY)
      }

      Text($r('app.string.lan_find_device'))
        .fontSize(FONT_SIZE_LG)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .fontWeight(FONT_WEIGHT_BOLD)

      Text($r('app.string.lan_scan_desc'))
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: SPACE_2XL, bottom: SPACE_2XL })
    .justifyContent(FlexAlign.Center)
  }
}

// ==================== 操作按钮 ====================
@Component
export struct LanActionButtons {
  @Prop isDarkMode: boolean = false
  @Prop viewMode: string = ''
  onStartScan: () => void = () => {}
  onStopScan: () => void = () => {}

  build() {
    if (this.viewMode === 'scanning') {
      Row() {
        Text($r('app.string.lan_stop_scan'))
          .fontSize(FONT_SIZE_MD)
          .fontColor(Color.White)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLOR_DANGER)
      .borderRadius(RADIUS_3XL)
      .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(239,68,68,0.5)' : 'rgba(239,68,68,0.35)', offsetX: 0, offsetY: 4 })
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => this.onStopScan())
    } else if (this.viewMode === 'idle') {
      Row() {
        Text($r('app.string.lan_start_find'))
          .fontSize(FONT_SIZE_MD)
          .fontColor(Color.White)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLOR_PRIMARY)
      .borderRadius(RADIUS_3XL)
      .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(16,185,129,0.5)' : 'rgba(16,185,129,0.35)', offsetX: 0, offsetY: 4 })
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => this.onStartScan())
    } else {
      Row() {
        Text($r('app.string.lan_rescan'))
          .fontSize(FONT_SIZE_MD)
          .fontColor(Color.White)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLOR_PRIMARY)
      .borderRadius(RADIUS_3XL)
      .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(16,185,129,0.5)' : 'rgba(16,185,129,0.35)', offsetX: 0, offsetY: 4 })
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => this.onStartScan())
    }
  }
}
