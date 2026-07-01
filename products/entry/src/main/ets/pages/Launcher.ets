// ============================================
// Launcher — HM7 沉浸光感启动页 v2.0
// 暗/亮模式自适应：深空渐变 ↔ 浅色光感
// ============================================

import { router } from '@kit.ArkUI'
import { GlobalInfoModel } from 'wifi-base'
import { NetworkTimeout } from '@wifi-analyzer/core'
import {
  COLOR_BG_TOP,
  COLOR_BG_MID,
  COLOR_BG_BOTTOM,
  COLOR_PRIMARY_DARK,
  COLOR_PRIMARY_DARK_LIGHT,
  COLOR_PRIMARY,
  COLOR_PRIMARY_LIGHT,
  COLOR_BG,
  COLOR_CARD,
  COLOR_TEXT_PRIMARY,
  COLOR_TEXT_TERTIARY,
  COLOR_TEXT_DARK_PRIMARY,
  COLOR_TEXT_DARK_TERTIARY,
} from '@wifi-analyzer/design-system'

@Entry
@ComponentV2
struct Launcher {
  @Local model: GlobalInfoModel = GlobalInfoModel.getInstance()
  private launchTimer: number = -1

  private get isDark(): boolean { return this.model.isDarkMode }

  aboutToAppear(): void {
    this.launchTimer = setTimeout(() => {
      router.replaceUrl({ url: 'pages/Index' })
    }, NetworkTimeout.LAUNCHER_DELAY_MS)
  }

  aboutToDisappear(): void {
    if (this.launchTimer !== -1) {
      clearTimeout(this.launchTimer)
      this.launchTimer = -1
    }
  }

  build() {
    Stack() {
      // ── 自适应背景渐变 ──
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.isDark
            ? [[COLOR_BG_TOP, 0], [COLOR_BG_MID, 0.5], [COLOR_BG_BOTTOM, 1]]
            : [[COLOR_BG, 0], [COLOR_CARD, 0.5], [COLOR_BG, 1]]
        })

      // ── 品牌光晕装饰 ──
      Circle({ width: 320, height: 320 })
        .position({ x: '-20%', y: '-25%' })
        .fill(this.isDark ? 'rgba(91,154,255,0.08)' : 'rgba(51,136,255,0.04)')
        .hitTestBehavior(HitTestMode.None)

      Circle({ width: 240, height: 240 })
        .position({ x: '60%', y: '50%' })
        .fill(this.isDark ? 'rgba(49,122,247,0.06)' : 'rgba(51,136,255,0.03)')
        .hitTestBehavior(HitTestMode.None)

      // ── 中心内容 ──
      Column({ space: 20 }) {
        // App 图标
        Column() {
          Text('W')
            .fontSize(36).fontWeight(800)
            .fontColor(this.isDark ? COLOR_PRIMARY_DARK_LIGHT : COLOR_PRIMARY)
        }
        .width(88)
        .height(88)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.isDark ? 'rgba(49,122,247,0.10)' : 'rgba(0,102,255,0.06)')
        .borderRadius(22)
        .borderWidth(1)
        .borderColor(this.isDark ? 'rgba(49,122,247,0.15)' : 'rgba(0,102,255,0.10)')

        // 应用名称
        Text('WlAN')
          .fontSize(32)
          .fontWeight(800)
          .fontColor(this.isDark ? COLOR_TEXT_DARK_PRIMARY : COLOR_TEXT_PRIMARY)
          .letterSpacing(-0.5)

        Text($r('app.string.network_analyzer'))
          .fontSize(14)
          .fontWeight(400)
          .fontColor(this.isDark ? COLOR_TEXT_DARK_TERTIARY : COLOR_TEXT_TERTIARY)
          .letterSpacing(0.5)

        // 品牌 Loading 条
        Column()
          .width(40)
          .height(2)
          .backgroundColor(this.isDark ? COLOR_PRIMARY_DARK : COLOR_PRIMARY)
          .borderRadius(1)
          .margin({ top: 24 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
