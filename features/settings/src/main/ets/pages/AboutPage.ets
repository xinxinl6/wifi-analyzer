// ============================================
// AboutPage — 关于页面
// WiFi分析仪 v2 设置模块
// 使用 @ComponentV2 + AuroraGlassCard 布局
// ============================================

import { hilog } from '@kit.PerformanceAnalysisKit'
import { AuroraGlassCard } from '@wifi-analyzer/design-system'
import {
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  COLOR_PRIMARY,
  COLOR_BACKGROUND
} from '@wifi-analyzer/design-system'
import {
  SPACE_LG,
  SPACE_XL,
  SPACE_2XL,
  SPACE_4XL,
  SPACE_6XL
} from '@wifi-analyzer/design-system'
import {
  FONT_SIZE_3XL,
  FONT_SIZE_MD,
  FONT_SIZE_SM,
  FONT_SIZE_LG,
  FONT_WEIGHT_BOLD,
  FONT_WEIGHT_MEDIUM,
  FONT_WEIGHT_NORMAL
} from '@wifi-analyzer/design-system'
import { Logger } from '@wifi-analyzer/wifi-base'

const TAG = 'AboutPage'

@ComponentV2
export struct AboutPage {
  @Builder
  featureItem(text: ResourceStr): void {
    Row() {
      Text('•')
        .fontSize(FONT_SIZE_MD)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(COLOR_PRIMARY)
        .margin({ right: SPACE_LG })

      Text(text)
        .fontSize(FONT_SIZE_MD)
        .fontWeight(FONT_WEIGHT_NORMAL)
        .fontColor(adaptiveTextPrimary(false))
    }
    .width('100%')
    .padding({ top: SPACE_LG / 2, bottom: SPACE_LG / 2 })
  }

  aboutResumed(): void {
    hilog.info(0x0000, TAG, 'AboutPage aboutToAppear')
    Logger.info(TAG, 'AboutPage aboutToAppear')
  }

  @Builder
  appHeader(): void {
    Column({ space: SPACE_LG }) {
      Text($r('app.string.app_name'))
        .fontSize(FONT_SIZE_3XL)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextPrimary(false))
        .textAlign(TextAlign.Center)

      Text($r('app.string.app_version'))
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FONT_WEIGHT_NORMAL)
        .fontColor(adaptiveTextSecondary(false))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: SPACE_6XL, bottom: SPACE_2XL })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  descriptionCard(): void {
    AuroraGlassCard({
      content: this.descriptionContent
    })
  }

  @Builder
  descriptionContent(): void {
    Column({ space: SPACE_LG }) {
      Text($r('app.string.app_description'))
        .fontSize(FONT_SIZE_MD)
        .fontWeight(FONT_WEIGHT_NORMAL)
        .fontColor(adaptiveTextSecondary(false))
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
  }

  @Builder
  featuresCard(): void {
    AuroraGlassCard({
      content: this.featuresContent
    })
  }

  @Builder
  featuresContent(): void {
    Column({ space: SPACE_LG }) {
      Text($r('app.string.app_features'))
        .fontSize(FONT_SIZE_LG)
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .fontColor(adaptiveTextPrimary(false))
        .width('100%')

      this.featureItem($r('app.string.feature_wifi_scan'))
      this.featureItem($r('app.string.feature_channel'))
      this.featureItem($r('app.string.feature_speed'))
      this.featureItem($r('app.string.feature_tools'))
    }
    .width('100%')
  }

  @Builder
  footerSection(): void {
    Column() {
      Text($r('app.string.app_copyright'))
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FONT_WEIGHT_NORMAL)
        .fontColor(adaptiveTextTertiary(false))
        .textAlign(TextAlign.Center)
        .padding({ top: SPACE_4XL, bottom: SPACE_4XL })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Scroll() {
      Column({ space: SPACE_XL }) {
        this.appHeader()

        Column({ space: SPACE_XL }) {
          this.descriptionCard()
          this.featuresCard()
        }
        .width('100%')
        .padding({ left: SPACE_XL, right: SPACE_XL })

        this.footerSection()
      }
      .width('100%')
      .backgroundColor(COLOR_BACKGROUND)
    }
  }
}
