// ============================================
// Aurora WiFi V2 — Aurora 强调卡片
// ============================================

import {
  COLOR_AURORA_PRIMARY,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_SHADOW_GLASS,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  SIGNAL_COLORS_AURORA,
  DURATION_NORMAL,
  AnimationTapScale,
  RADIUS_CARD
} from '@wifi-analyzer/design-system'
import { hexToRgba } from './AuroraGlassCard'

@Component
export struct AuroraEmphasisCard {
  @Prop title: string = ''
  @Prop subtitle: string = ''
  @Prop value: string = ''
  @Prop icon: Resource = $r('app.media.ic_wifi')
  @Prop statusColor: string = SIGNAL_COLORS_AURORA.excellent

  @State private cardScale: number = 1.0

  build() {
    Column() {
      Row({ space: 16 }) {
        // 左侧图标区
        Stack({ alignContent: Alignment.Center }) {
          // 图标光晕 - 适配十六进制颜色
          Circle()
            .width(56)
            .height(56)
            .fill(hexToRgba(this.statusColor, 0.15))
          // 图标
          Image(this.icon)
            .width(28)
            .height(28)
            .fillColor(this.statusColor)
        }
        .width(56)
        .height(56)

        // 右侧文字区
        Column({ space: 4 }) {
          // 状态标签
          Row({ space: 6 }) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor(COLOR_TEXT_GLASS_SECONDARY)

            Circle()
              .width(6)
              .height(6)
              .fill(this.statusColor)
          }

          // 主标题
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT_GLASS_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 数值
          Text(this.value)
            .fontSize(14)
            .fontColor(COLOR_TEXT_GLASS_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(COLOR_GLASS_CARD)
    .border({
      width: 1,
      color: COLOR_GLASS_BORDER_MEDIUM,
      radius: RADIUS_CARD
    })
    .shadow({
      radius: 16,
      color: COLOR_SHADOW_GLASS,
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
