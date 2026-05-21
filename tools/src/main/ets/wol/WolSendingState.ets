// WOL 发送状态 + 错误提示 — Aurora WiFi V2

import {
  COLOR_CYAN, COLOR_DANGER,
  FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_WEIGHT_BOLD,
  SPACE_MD, SPACE_SM,
  GLASS_BLUR_LG,
} from '@wifi-analyzer/design-system'
import { PulseIndicator } from '@wifi-analyzer/design-system'

// ==================== 发送中状态 ====================
@Component
export struct WolSendingState {
  @Prop isDarkMode: boolean = false
  @Prop sendingDeviceName: string = ''

  private pulser: PulseIndicator = new PulseIndicator()

  aboutToAppear(): void {
    this.pulser.start(800)
  }

  aboutToDisappear(): void {
    this.pulser.stop()
  }

  build() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(40).height(40).fill(COLOR_CYAN).opacity(this.pulser.opacity)
        Image($r('app.media.ic_wol')).width(20).height(20).fillColor(Color.White)
      }
      Text() {
        Span($r('app.string.sending_wake_packet'))
        Span(' ' + this.sendingDeviceName + ' ')
        Span($r('app.string.sending_wake_packet_suffix'))
      }
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_CYAN)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? 'rgba(34,211,238,0.12)' : '#E0F7FE')
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? 'rgba(34,211,238,0.3)' : COLOR_CYAN)
    .clip(true)
  }
}

// ==================== 错误提示 ====================
@Component
export struct WolErrorTip {
  @Prop isDarkMode: boolean = false
  @Prop errorMessage: string | Resource = ''

  build() {
    Row({ space: SPACE_SM }) {
      Text('!')
        .fontSize(FONT_SIZE_SM).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
        .width(24).height(24).textAlign(TextAlign.Center)
        .backgroundColor(COLOR_DANGER).borderRadius(12)
      Text(this.errorMessage).fontSize(FONT_SIZE_SM).fontColor(COLOR_DANGER)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? 'rgba(239,68,68,0.12)' : '#FEF2F2')
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? 'rgba(239,68,68,0.3)' : COLOR_DANGER)
    .clip(true)
  }
}
