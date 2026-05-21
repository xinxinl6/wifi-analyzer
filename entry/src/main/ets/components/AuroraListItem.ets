// ============================================
// Aurora WiFi V2 — 毛玻璃列表项
// ============================================

import {
  COLOR_AURORA_PRIMARY,
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_AURORA,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  DURATION_NORMAL,
  AnimationTapScale,
  RADIUS_BUTTON
} from '@wifi-analyzer/design-system'

@Component
export struct AuroraListItem {
  @Prop itemTitle: string = ''
  @Prop itemSubtitle: string = ''
  @Prop itemValue: string = ''
  @Prop itemIcon: Resource = $r('app.media.ic_wifi')
  @Prop iconColor: string = COLOR_AURORA_PRIMARY
  @Prop showArrow: boolean = true
  @Prop badge: string = ''

  @State private itemScale: number = 1.0
  @State private itemOpacity: number = 1.0

  build() {
    Row({ space: 16 }) {
      // 图标
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(44)
          .height(44)
          .fill(`${this.iconColor}20`)

        Image(this.itemIcon)
          .width(22)
          .height(22)
          .fillColor(this.iconColor)
      }
      .width(44)
      .height(44)

      // 文字区
      Column({ space: 2 }) {
        Row({ space: 8 }) {
          Text(this.itemTitle)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLOR_TEXT_GLASS_PRIMARY)

          if (this.badge !== '') {
            Text(this.badge)
              .fontSize(10)
              .fontColor(COLOR_AURORA_PRIMARY)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(COLOR_GLASS_AURORA)
              .borderRadius(10)
          }
        }

        Text(this.itemSubtitle)
          .fontSize(13)
          .fontColor(COLOR_TEXT_GLASS_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .constraintSize({ minWidth: 0 })

      // 右侧值
      if (this.itemValue !== '') {
        Text(this.itemValue)
          .fontSize(14)
          .fontColor(COLOR_TEXT_GLASS_SECONDARY)
      }

      // 箭头
      if (this.showArrow) {
        Image($r('app.media.ic_arrow_right'))
          .width(20)
          .height(20)
          .fillColor(COLOR_TEXT_GLASS_TERTIARY)
      }
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 16, right: 16 })
    .backgroundColor(COLOR_GLASS_SURFACE)
    .borderRadius(RADIUS_BUTTON)
    .scale({ x: this.itemScale, y: this.itemScale })
    .opacity(this.itemOpacity)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.getUIContext().animateTo(AnimationTapScale, () => {
          this.itemScale = 0.98
          this.itemOpacity = 0.85
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.getUIContext().animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.itemScale = 1.0
          this.itemOpacity = 1.0
        })
      }
    })
  }
}
