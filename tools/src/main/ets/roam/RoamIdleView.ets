// 漫游测试 — 空闲状态 + 时长选择 + 功能说明 — Aurora WiFi V2

import {
  COLOR_ORANGE,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_WEIGHT_BOLD, FONT_WEIGHT_MEDIUM,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_2XL,
  RADIUS_3XL, RADIUS_2XL,
  GLASS_BLUR_LG,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveCardBg, adaptiveDivider
} from '@wifi-analyzer/design-system'

// ==================== 空状态 ====================
@Component
export struct RoamIdleState {
  @Prop isDarkMode: boolean = false

  build() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(80).height(80)
          .fill(this.isDarkMode ? 'rgba(251,146,60,0.18)' : 'rgba(251,146,60,0.13)')
        Image($r('app.media.ic_roaming')).width(40).height(40)
      }
      Text($r('app.string.wifi_roam_test'))
        .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
      Text($r('app.string.roam_test_desc'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%').padding({ top: SPACE_2XL, bottom: SPACE_2XL }).justifyContent(FlexAlign.Center)
  }
}

// ==================== 测试时长选择 ====================
@Component
export struct RoamDurationSelector {
  @Prop isDarkMode: boolean = false
  @Prop testDuration: number = 60
  onDurationChange: (sec: number) => void = () => {}

  build() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.test_duration'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        Text('30s')
          .fontSize(FONT_SIZE_XS).fontColor(this.testDuration === 30 ? Color.White : COLOR_ORANGE)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.testDuration === 30 ? COLOR_ORANGE : (this.isDarkMode ? 'rgba(251,146,60,0.18)' : 'rgba(251,146,60,0.13)'))
          .borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.onDurationChange(30) })
        Text('60s')
          .fontSize(FONT_SIZE_XS).fontColor(this.testDuration === 60 ? Color.White : COLOR_ORANGE)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.testDuration === 60 ? COLOR_ORANGE : (this.isDarkMode ? 'rgba(251,146,60,0.18)' : 'rgba(251,146,60,0.13)'))
          .borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.onDurationChange(60) })
        Text('120s')
          .fontSize(FONT_SIZE_XS).fontColor(this.testDuration === 120 ? Color.White : COLOR_ORANGE)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.testDuration === 120 ? COLOR_ORANGE : (this.isDarkMode ? 'rgba(251,146,60,0.18)' : 'rgba(251,146,60,0.13)'))
          .borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.onDurationChange(120) })
        Text('300s')
          .fontSize(FONT_SIZE_XS).fontColor(this.testDuration === 300 ? Color.White : COLOR_ORANGE)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.testDuration === 300 ? COLOR_ORANGE : (this.isDarkMode ? 'rgba(251,146,60,0.18)' : 'rgba(251,146,60,0.13)'))
          .borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.onDurationChange(300) })
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }
}

// ==================== 功能说明卡片 ====================
@Component
export struct RoamFeatureCard {
  @Prop isDarkMode: boolean = false

  build() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36)
            .fill(this.isDarkMode ? 'rgba(251,146,60,0.18)' : 'rgba(251,146,60,0.13)')
          Image($r('app.media.ic_route')).width(18).height(18).fillColor(COLOR_ORANGE)
        }
        Column({ space: 2 }) {
          Text($r('app.string.roam_test_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.roam_test_intro_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD)
    .backgroundColor(adaptiveCardBg(this.isDarkMode))
    .borderRadius(RADIUS_2XL)
    .border({ width: 1, color: adaptiveDivider(this.isDarkMode) })
    .backdropBlur(GLASS_BLUR_LG)
  }
}
