// ============================================
// Aurora 连接状态卡片（极光渐变版）
// ============================================

import {
  // 文字色（暗色模式）
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  // 文字色（浅色模式）
  COLOR_TEXT_LIGHT_PRIMARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_TEXT_LIGHT_TERTIARY,
  // 暗色模式毛玻璃
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_SURFACE_LIGHT,
  // 功能色
  COLOR_SUCCESS,
  COLOR_TEXT_DISABLED,
  // 信号色
  SIGNAL_COLORS_AURORA,
  // 动效
  AnimationTapScale,
  DURATION_NORMAL,

  // 阴影
  COLOR_SHADOW_AURORA,
  // 半径
  RADIUS_CARD
} from '@wifi-analyzer/design-system'
import { SharedWifiState } from '@wifi-analyzer/core'
import { AuroraSignalIndicator } from './AuroraGlassComponents'

@Component
export struct AuroraConnectionCard {
  @Watch('onWifiStateChange')
  @Consume('wifiState') wifiState: SharedWifiState
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  @State private connected: boolean = false
  @State private cardScale: number = 1.0
  @State private signalColor: string = SIGNAL_COLORS_AURORA.none

  /** wifiState 变化时自动重新计算连接状态 */
  onWifiStateChange(): void {
    this.updateState()
  }

  // 根据模式获取文字颜色
  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  private get textSecondary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY
  }

  private get textTertiary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
  }

  // 根据模式获取卡片背景色
  private get cardBg(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_CARD
  }

  // 根据模式获取边框颜色
  private get cardBorder(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_BORDER : 'rgba(255,255,255,0)'
  }

  // 浅色模式无边框
  private get cardBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  aboutToAppear(): void {
    this.updateState()
  }

  private updateState(): void {
    this.connected = this.wifiState.connectedSsid !== '' && this.wifiState.connectedSsid !== '<unknown ssid>'

    const signal = this.wifiState.connectedSignal
    if (signal > -50) {
      this.signalColor = SIGNAL_COLORS_AURORA.excellent
    } else if (signal > -65) {
      this.signalColor = SIGNAL_COLORS_AURORA.good
    } else if (signal > -80) {
      this.signalColor = SIGNAL_COLORS_AURORA.fair
    } else {
      this.signalColor = SIGNAL_COLORS_AURORA.poor
    }
  }

  private getSignalLevel(): string {
    const signal = this.wifiState.connectedSignal
    if (signal > -50) return 'excellent'
    if (signal > -65) return 'good'
    if (signal > -80) return 'fair'
    return 'poor'
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        // 左侧：WiFi 图标 + 状态
        Stack({ alignContent: Alignment.Center }) {
          // 外层光晕
          Circle()
            .width(64)
            .height(64)
            .fill(this.connected ? `${this.signalColor}30` : 'rgba(148,163,184,0.15)')

          // 内层光晕
          Circle()
            .width(52)
            .height(52)
            .fill(this.connected ? `${this.signalColor}20` : 'rgba(148,163,184,0.1)')

          // WiFi 图标
          Image($r('app.media.ic_wifi'))
            .width(28)
            .height(28)
            .fillColor(this.connected ? this.signalColor : COLOR_TEXT_DISABLED)
        }
        .width(64)
        .height(64)

        // 文字信息
        Column({ space: 6 }) {
          // 状态标签
          Row({ space: 6 }) {
            Text(this.wifiState.isScanning ? $r('app.string.scanning') : (this.connected ? $r('app.string.connected') : $r('app.string.not_connected')))
              .fontSize(12)
              .fontColor(this.connected ? this.textSecondary : this.textTertiary)

            if (this.connected) {
              Circle()
                .width(6)
                .height(6)
                .fill(COLOR_SUCCESS)
            }
          }

          // SSID 名称
          Text(this.connected ? this.wifiState.connectedSsid : $r('app.string.no_network'))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 详细信息
          if (this.connected) {
            Row({ space: 8 }) {
              Text(`${this.wifiState.connectedFreq}GHz`)
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text('·')
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text(`CH ${this.wifiState.connectedChannel}`)
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text('·')
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text(`${this.wifiState.connectedSignal} dBm`)
                .fontSize(12)
                .fontColor(this.textTertiary)
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .constraintSize({ minWidth: 0 })

        // 右侧：信号强度指示器
        if (this.connected) {
          Column({ space: 4 }) {
            AuroraSignalIndicator({
              signalLevel: this.getSignalLevel(),
              signalLabel: '',
              showLabel: false,
              indicatorSize: 'large'
            })

            Text(`${this.wifiState.connectedSignal}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.signalColor)
              .margin({ top: 4 })

            Text($r('app.string.dbm_unit'))
              .fontSize(10)
              .fontColor(this.textTertiary)
          }
        }
      }
    }
    .width('100%')
    .padding(20)
    // Aurora 极光渐变背景
    .backgroundColor(this.cardBg)
    .border({
      width: this.cardBorderWidth,
      color: this.cardBorder,
      radius: RADIUS_CARD
    })
    .shadow({
      radius: 20,
      color: COLOR_SHADOW_AURORA,
      offsetX: 0,
      offsetY: 4
    })
    .scale({ x: this.cardScale, y: this.cardScale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.getUIContext().animateTo(AnimationTapScale, () => {
          this.cardScale = 0.98
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.getUIContext().animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.cardScale = 1.0
        })
      }
    })
  }
}
