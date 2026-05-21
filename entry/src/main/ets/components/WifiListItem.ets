// WifiListItem.ets - WiFi列表项组件
// 提取自 WifiListSection.ets

import {
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_SURFACE_LIGHT,
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

// 获取信号颜色
function getSignalColor(signal: number): string {
  if (signal > SIGNAL_THRESHOLD_EXCELLENT) return SIGNAL_COLORS_AURORA.excellent
  if (signal > SIGNAL_THRESHOLD_GOOD) return SIGNAL_COLORS_AURORA.good
  if (signal > SIGNAL_THRESHOLD_FAIR) return SIGNAL_COLORS_AURORA.fair
  return SIGNAL_COLORS_AURORA.poor
}

// 信号强度 Aurora 指示器
@Component
export struct WifiSignalBars {
  @Prop signal: number = -100
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Row({ space: 2 }) {
      // 4 格信号条，渐进高度
      Column()
        .width(3).height(5).borderRadius(2)
        .backgroundColor(this.signal > SIGNAL_THRESHOLD_FAIR ? getSignalColor(this.signal) : COLOR_GLASS_AURORA)

      Column()
        .width(3).height(8).borderRadius(2)
        .backgroundColor(this.signal > SIGNAL_THRESHOLD_GOOD ? getSignalColor(this.signal) : COLOR_GLASS_AURORA)

      Column()
        .width(3).height(12).borderRadius(2)
        .backgroundColor(this.signal > -62 ? getSignalColor(this.signal) : COLOR_GLASS_AURORA)

      Column()
        .width(3).height(16).borderRadius(2)
        .backgroundColor(this.signal > SIGNAL_THRESHOLD_EXCELLENT ? getSignalColor(this.signal) : COLOR_GLASS_AURORA)
    }
    .alignItems(VerticalAlign.Bottom)
  }
}

// 单个WiFi卡片
@Component
export struct WifiListItemComponent {
  @Prop item: WifiItem = { ssid: '', bssid: '', signal: -100, freq: 0, channel: 0, security: '', isConnected: false, bandwidth: '' }
  @Prop index: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onItemClick: (item: WifiItem) => void = () => {}

  build() {
    Row({ space: SPACE_MD }) {
      // 信号图标区（Aurora 发光效果）
      Stack({ alignContent: Alignment.Center }) {
        // 发光底圆（已连接时）
        if (this.item.isConnected) {
          Circle()
            .width(44)
            .height(44)
            .fill(COLOR_GLASS_AURORA)
        }

        // 信号条
        Column({ space: 2 }) {
          WifiSignalBars({ signal: this.item.signal })
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(44)
      .height(44)

      // 中间信息区
      Column() {
        Row({ space: SPACE_SM }) {
          Text(this.item.ssid || $r('app.string.hidden_network'))
            .fontSize(FONT_SIZE_LG)
            .fontWeight(FONT_WEIGHT_MEDIUM)
            .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.item.isConnected) {
            Text($r('app.string.connected'))
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_AURORA_PRIMARY)
              .fontWeight(FONT_WEIGHT_MEDIUM)
              .padding({ left: SPACE_SM, right: SPACE_SM, top: 2, bottom: 2 })
              .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
              .borderRadius(RADIUS_SM)
              .border({ width: 1, color: COLOR_GLASS_AURORA_BORDER })
          }
        }
        .width('100%')

        Text((this.item.bssid || '') + ' · ' + (this.item.freq >= 4.0 ? '5GHz' : '2.4GHz') + ' · CH ' + this.item.channel + ' · ' + (this.item.bandwidth || '--MHz'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY)
          .margin({ top: 3 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧信号数值
      Column({ space: 4 }) {
        Text(this.item.signal + ' dBm')
          .fontSize(FONT_SIZE_MD)
          .fontWeight(FONT_WEIGHT_MEDIUM)
          .fontColor(getSignalColor(this.item.signal))

        Text(this.item.security || 'Open')
          .fontSize(FONT_SIZE_XS)
          .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
          .borderRadius(RADIUS_SM)
          .border({ width: 1, color: COLOR_GLASS_AURORA })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: SPACE_LG, right: SPACE_MD, top: SPACE_MD, bottom: SPACE_MD })
    // Aurora 毛玻璃卡片
    .backgroundColor(this.item.isConnected ? COLOR_GLASS_AURORA : COLOR_GLASS_SURFACE_LIGHT)
    .borderRadius(RADIUS_CARD)
    .border({
      width: 1,
      color: this.item.isConnected ? COLOR_GLASS_AURORA_BORDER : COLOR_GLASS_BORDER_LIGHT
    })
    .shadow({
      radius: this.item.isConnected ? 16 : 8,
      color: this.item.isConnected ? COLOR_SHADOW_AURORA : COLOR_SHADOW_GLASS,
      offsetX: 0,
      offsetY: this.item.isConnected ? 4 : 2
    })
    .backdropBlur(10)
    // 点击时半透明反馈
    .stateStyles({
      pressed: { .opacity(0.65) },
      normal: { .opacity(1) }
    })
    .animation({ duration: DURATION_FAST, curve: Curve.EaseOut })
    .onClick(() => {
      this.onItemClick(this.item)
    })
  }
}

export { getSignalColor }
