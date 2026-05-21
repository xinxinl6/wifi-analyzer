// SpeedGauge.ets - 测速仪表盘组件
// 提取自 SpeedTestSection.ets

import {
  COLOR_SUCCESS,
  COLOR_SKY_BLUE,
  COLOR_SKY_BLUE_LIGHT,
  COLOR_SKY_BLUE_GAUGE_BG,
  COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_TERTIARY,
  FONT_SIZE_SM,
  FONT_SIZE_LG,
  FONT_SIZE_XL,
  FONT_SIZE_2XL,
  FONT_SIZE_3XL,
  GAUGE_SIZE_XL,
  STROKE_WIDTH_3XL,
  SPACE_SM,
  SPACE_LG,
  SPACE_2XL,
  GLASS_BLUR_LG,
  GLASS_SHADOW_2XL,
  GLASS_SHADOW_3XL,
  adaptiveTextTertiary,
  adaptiveTextSecondary,
  adaptiveTextPrimary,
  adaptiveGlowLarge,
  adaptiveGlowMedium,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_WHITE,
  COLOR_GLASS_WHITE_SOLID,
  COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_AURORA,
  FONT_SIZE_XS
} from '@wifi-analyzer/design-system'
import {
  formatDisplaySpeed,
  getGaugeShadowColor,
  getGaugeColor,
  getGaugeArcLength,
  getSpeedLabelResource
} from '../utils/SpeedTestHelper'

@Component
export struct SpeedGauge {
  @Prop isTesting: boolean = false
  @Prop currentPhase: string = 'idle'
  @Prop displaySpeed: number = 0
  @Prop displayPing: number = 0
  @Prop displayDownloadSpeed: number = 0
  @Prop displayUploadSpeed: number = 0
  @Prop phaseLabel: string = ''
  @Prop gaugeProgress: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column({ space: 0 }) {
      Column({ space: 0 }) {
        // 顶部状态标签
        Row() {
          if (this.isTesting && this.phaseLabel.length > 0) {
            Row({ space: 6 }) {
              Circle().width(6).height(6).fill(getGaugeColor(this.currentPhase))
              Text(getSpeedLabelResource(this.currentPhase)).fontSize(FONT_SIZE_LG).fontColor(COLOR_SKY_BLUE)
            }
          } else if (this.currentPhase === 'done') {
            Row({ space: 6 }) {
              Circle().width(6).height(6).fill(COLOR_SUCCESS)
              Text($r('app.string.speed_test_complete')).fontSize(FONT_SIZE_LG).fontColor(COLOR_SKY_BLUE)
            }
          } else {
            Text($r('app.string.speed_test_title')).fontSize(FONT_SIZE_LG).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 24, bottom: 16 })

        // 仪表盘主体
        Stack() {
          // 外圈渐变背景
          Circle().width(GAUGE_SIZE_XL).height(GAUGE_SIZE_XL)
            .fill(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_SKY_BLUE_GAUGE_BG)

          // 背景轨道
          Circle().width(GAUGE_SIZE_XL - 16).height(GAUGE_SIZE_XL - 16)
            .fill(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE_SOLID)
            .strokeWidth(1)
            .stroke(COLOR_SKY_BLUE_DIVIDER)

          // 进度弧
          Circle().width(GAUGE_SIZE_XL - 16).height(GAUGE_SIZE_XL - 16)
            .fillOpacity(0)
            .stroke(getGaugeColor(this.currentPhase))
            .strokeWidth(STROKE_WIDTH_3XL)
            .strokeDashArray([getGaugeArcLength(this.gaugeProgress), 400])
            .rotate({ angle: -90 })
            .shadow({ radius: GLASS_SHADOW_2XL, color: getGaugeShadowColor(this.currentPhase), offsetX: 0, offsetY: 0 })

          // 中心数值
          Column({ space: 4 }) {
            Text(this.currentPhase === 'ping' ? 'ms' : 'Mbps')
              .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).letterSpacing(3)
            Text(formatDisplaySpeed(this.displaySpeed, this.currentPhase, this.isTesting))
              .fontSize(58).fontWeight(FontWeight.Bold).fontColor(COLOR_SKY_BLUE).letterSpacing(-2)
            Text(getSpeedLabelResource(this.currentPhase))
              .fontSize(FONT_SIZE_XL).fontColor(adaptiveTextSecondary(this.isDarkMode))
          }
        }
        .width(GAUGE_SIZE_XL).height(GAUGE_SIZE_XL).margin({ top: 10, bottom: 10 })

        // 下方实时数据（测速中或完成时显示）
        if (this.isTesting || this.currentPhase === 'done') {
          Row() {
            // 下载速度
            Column({ space: SPACE_SM }) {
              Text(this.displayDownloadSpeed > 0 ? this.displayDownloadSpeed.toFixed(1) : '--')
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.currentPhase === 'download' ? COLOR_SKY_BLUE : adaptiveTextPrimary(this.isDarkMode))
              Row({ space: 3 }) {
                Text('↓').fontSize(FONT_SIZE_SM).fontColor(COLOR_SKY_BLUE)
                Text('Mbps').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
                Text($r('app.string.speed_estimate')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDarkMode)).opacity(0.6)
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)

            Column().width(1).height(44).backgroundColor(COLOR_SKY_BLUE_DIVIDER)

            // 延迟
            Column({ space: SPACE_SM }) {
              Text(this.displayPing > 0 ? this.displayPing.toFixed(0) : '--')
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.currentPhase === 'ping' ? COLOR_SUCCESS : adaptiveTextPrimary(this.isDarkMode))
              Row({ space: 3 }) {
                Text('⊙').fontSize(FONT_SIZE_SM).fontColor(COLOR_SUCCESS)
                Text('ms').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)

            Column().width(1).height(44).backgroundColor(COLOR_SKY_BLUE_DIVIDER)

            // 上传速度
            Column({ space: SPACE_SM }) {
              Text(this.displayUploadSpeed > 0 ? this.displayUploadSpeed.toFixed(1) : '--')
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.currentPhase === 'upload' ? COLOR_SUCCESS : adaptiveTextPrimary(this.isDarkMode))
              Row({ space: 3 }) {
                Text('↑').fontSize(FONT_SIZE_SM).fontColor(COLOR_SUCCESS)
                Text('Mbps').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
                Text($r('app.string.speed_simulated')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDarkMode)).opacity(0.6)
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ left: SPACE_2XL, right: SPACE_2XL, top: SPACE_LG, bottom: SPACE_LG })
        }
      }
      .width('100%')
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE_SOLID)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .shadow({ radius: GLASS_SHADOW_2XL, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_ACTIVE, offsetX: 0, offsetY: 8 })
    }
    .width('100%')
    .borderRadius(24)
    .shadow({ radius: GLASS_SHADOW_3XL, color: COLOR_SKY_BLUE_DIVIDER, offsetX: 0, offsetY: 8 })
    .clip(true)
  }
}
