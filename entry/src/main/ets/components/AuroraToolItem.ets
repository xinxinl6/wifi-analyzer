// ============================================
// Aurora WiFi V2 — Aurora 工具图标网格项
// ============================================

import {
  COLOR_AURORA_PRIMARY,
  COLOR_GLASS_AURORA,
  COLOR_TEXT_GLASS_PRIMARY,
  DURATION_NORMAL,
  AnimationTapScale
} from '@wifi-analyzer/design-system'

@Component
export struct AuroraToolItem {
  @Prop toolTitle: string = ''
  @Prop toolIcon: Resource = $r('app.media.ic_tool')
  @Prop iconBgColor: string = COLOR_GLASS_AURORA
  @Prop iconColor: string = COLOR_AURORA_PRIMARY
  @Prop itemIndex: number = 0

  @State private itemScale: number = 1.0
  @State private itemY: number = 0

  aboutToAppear(): void {
    // 入场动画：轻微上浮
    this.getUIContext().animateTo({
      duration: 400 + this.itemIndex * 50,
      curve: Curve.EaseOut
    }, () => {
      this.itemY = 0
    })
    this.itemY = 20
  }

  build() {
    Column({ space: 8 }) {
      // 图标容器
      Stack({ alignContent: Alignment.Center }) {
        // 图标背景
        Column()
          .width(52)
          .height(52)
          .borderRadius(16)
          .backgroundColor(this.iconBgColor)
          .shadow({
            radius: 8,
            color: `${this.iconColor}30`,
            offsetX: 0,
            offsetY: 2
          })

        // 图标
        Image(this.toolIcon)
          .width(26)
          .height(26)
          .fillColor(this.iconColor)
      }

      // 标题
      Text(this.toolTitle)
        .fontSize(12)
        .fontColor(COLOR_TEXT_GLASS_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(12)
    .scale({ x: this.itemScale, y: this.itemScale })
    .translate({ y: this.itemY })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.getUIContext().animateTo(AnimationTapScale, () => {
          this.itemScale = 0.92
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.getUIContext().animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.itemScale = 1.0
        })
      }
    })
  }
}
