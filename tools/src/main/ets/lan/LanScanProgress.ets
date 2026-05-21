// 扫描进度卡片 — Aurora WiFi V2

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_MD,
  FONT_WEIGHT_BOLD, FONT_WEIGHT_MEDIUM,
  SPACE_MD, SPACE_SM,
  GLASS_SHADOW_SM,
  GLASS_BLUR_LG,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextPrimary, adaptiveTextTertiary
} from '@wifi-analyzer/design-system'

// ==================== 类型定义 ====================

export interface ScanProgressState {
  progress: number
  total: number
  currentIp: string
  startTime: number
  duration: number
}

export interface ScanStats {
  onlineCount: number
  errorMessage: string
}

// ==================== 扫描进度卡片 ====================
@Component
export struct LanScanProgress {
  @Prop isDarkMode: boolean = false
  @Prop scanProgress: ScanProgressState = {
    progress: 0, total: 254, currentIp: '', startTime: 0, duration: 0
  }
  @Prop scanStats: ScanStats = {
    onlineCount: 0, errorMessage: ''
  }
  @Prop progressPercent: number = 0

  build() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.lan_scanning'))
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_MEDIUM)
        Blank()
        Text(String(this.progressPercent) + '%')
          .fontSize(FONT_SIZE_MD)
          .fontColor(COLOR_PRIMARY)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')

      // 进度条
      Row() {
        Column()
          .height(6)
          .borderRadius(3)
          .backgroundColor(COLOR_PRIMARY)
          .width(String(this.progressPercent) + '%')
        Blank()
      }
      .width('100%')
      .height(6)
      .borderRadius(3)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)

      Row({ space: SPACE_SM }) {
        Text() {
          Span($r('app.string.lan_scanned'))
          Span(' ')
          Span(String(this.scanProgress.progress) + '/' + String(this.scanProgress.total))
        }
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))

        Blank()

        Text() {
          Span($r('app.string.lan_current'))
          Span(' ')
          Span(this.scanProgress.currentIp)
        }
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))

        Blank()

        Text() {
          Span($r('app.string.lan_discover'))
          Span(' ')
          Span(String(this.scanStats.onlineCount))
          Span(' ')
          Span($r('app.string.lan_unit'))
        }
        .fontSize(FONT_SIZE_XS)
        .fontColor(COLOR_SUCCESS)
        .fontWeight(FONT_WEIGHT_MEDIUM)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }
}
