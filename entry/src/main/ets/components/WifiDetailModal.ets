// WifiDetailModal.ets - WiFi详情弹窗组件
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
  COLOR_CARD_DARK_SOLID,
  COLOR_OVERLAY,
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
import { WifiItem } from '@wifi-analyzer/core'
import { WifiSignalBars, getSignalColor } from './WifiListItem'

// WiFi详情弹窗
@Component
export struct WifiDetailModal {
  @Prop selectedItem: WifiItem = { ssid: '', bssid: '', signal: -100, freq: 0, channel: 0, security: '', isConnected: false, bandwidth: '' }
  @Prop modalOpacity: number = 0
  @Prop modalTranslateY: number = 60
  @Prop overlayOpacity: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onClose: () => void = () => {}

  build() {
    Stack() {
      // 详情弹窗背景遮罩（带动画）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.isDarkMode ? COLOR_OVERLAY : COLOR_GLASS_AURORA)
        .backdropBlur(4)
        .opacity(this.overlayOpacity)
        .onClick(() => { this.onClose() })
        .zIndex(998)

      // 详情弹窗（带线性动画）
      Column() {
        // 顶部拖拽指示条
        Column()
          .width(36)
          .height(4)
          .borderRadius(2)
          .backgroundColor(COLOR_GLASS_AURORA_BORDER)
          .margin({ top: SPACE_SM, bottom: SPACE_SM })

        // 标题栏
        Row() {
          Column() {
            Text($r('app.string.wifi_detail'))
              .fontSize(FONT_SIZE_LG)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY)

            if (this.selectedItem.isConnected) {
              Text($r('app.string.connected'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_AURORA_PRIMARY)
                .margin({ top: 2 })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 关闭按钮
          Column() {
            Text('×')
              .fontSize(20)
              .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY)
          }
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.onClose() })
        }
        .padding({ left: SPACE_LG, right: SPACE_LG, bottom: SPACE_MD })
        .width('100%')

        // 分割线（Aurora 发光）
        Column()
          .width('100%')
          .height(1)
          .backgroundColor(COLOR_GLASS_AURORA)
          .margin({ bottom: SPACE_MD })

        // 详情内容
        Column({ space: SPACE_SM }) {
          this.DetailRow($r('app.string.network_name'), this.selectedItem.ssid)
          this.DetailRow($r('app.string.bssid'), this.selectedItem.bssid)
          this.DetailRow($r('app.string.signal_strength'), this.selectedItem.signal + ' dBm')
          this.DetailRow($r('app.string.band'), this.selectedItem.freq >= 4.0 ? $r('app.string.filter_5g') : $r('app.string.filter_2g'))
          this.DetailRow($r('app.string.channel_ch'), 'CH ' + this.selectedItem.channel)
          this.DetailRow($r('app.string.bandwidth_mhz'), this.selectedItem.bandwidth || '--MHz')
          this.DetailRow($r('app.string.encryption'), this.selectedItem.security)
          this.DetailRow($r('app.string.status'), this.selectedItem.isConnected ? $r('app.string.connected') : $r('app.string.not_connected'))
        }
        .padding({ left: SPACE_LG, right: SPACE_LG, bottom: SPACE_LG })
        .width('100%')
      }
      .width('88%')
      // Aurora 毛玻璃底板
      .backgroundColor(this.isDarkMode ? COLOR_CARD_DARK_SOLID : COLOR_GLASS_CARD)
      .borderRadius(RADIUS_CARD)
      .border({ width: 1, color: COLOR_GLASS_AURORA_BORDER })
      .backdropBlur(20)
      .shadow({ radius: 32, color: COLOR_SHADOW_AURORA, offsetX: 0, offsetY: 8 })
      .position({ x: '6%', y: '15%' })
      .zIndex(999)
      // 线性动画属性
      .opacity(this.modalOpacity)
      .translate({ y: this.modalTranslateY })
    }
    .width('100%')
    .height('100%')
  }

  // 详情行
  @Builder DetailRow(label: Resource, value: Resource | string) {
    Row({ space: SPACE_MD }) {
      Text(label)
        .fontSize(FONT_SIZE_SM)
        .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY)
        .width('35%')

      Text(value)
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ top: SPACE_XS, bottom: SPACE_XS })
    .border({ width: { bottom: 1 }, color: COLOR_GLASS_AURORA_LIGHT })
  }
}
