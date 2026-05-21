// SpeedHistoryList.ets - 测速历史记录组件
// 提取自 SpeedTestSection.ets

import {
  COLOR_SUCCESS,
  COLOR_WARNING,
  COLOR_DANGER,
  COLOR_SKY_BLUE,
  COLOR_SKY_BLUE_LIGHT,
  COLOR_SKY_BLUE_GAUGE_BG,
  COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS,
  FONT_SIZE_SM,
  FONT_SIZE_LG,
  FONT_SIZE_2XL,
  FONT_SIZE_3XL,
  FONT_SIZE_4XL,
  SPACE_SM,
  SPACE_MD,
  SPACE_LG,
  GLASS_BLUR_XL,
  GLASS_SHADOW_XL,
  GLASS_SHADOW_2XL,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_WHITE,
  COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_SKY_TAG_BG,
  COLOR_GLASS_SKY_ACTIVE
} from '@wifi-analyzer/design-system'
import { SpeedTestResult } from '@wifi-analyzer/core'

// 历史记录卡片 - 天蓝色毛玻璃（支持展开/收起）
@Component
export struct SpeedHistoryList {
  @Prop historyList: Array<SpeedTestResult> = []
  @Prop showAllHistory: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onToggleHistory: () => void = () => {}
  onHistoryItemClick: (item: SpeedTestResult) => void = () => {}

  build() {
    Column({ space: 14 }) {
      Row() {
        Text($r('app.string.speed_history'))
          .fontSize(FONT_SIZE_3XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))

        Blank()

        // 展开/收起按钮
        if (this.historyList.length > 5) {
          Row({ space: 4 }) {
            Text(this.showAllHistory ? $r('app.string.collapse') : $r('app.string.expand_all'))
              .fontSize(FONT_SIZE_SM)
              .fontColor(COLOR_SKY_BLUE)
            Text(this.showAllHistory ? '∧' : '∨')
              .fontSize(FONT_SIZE_SM)
              .fontColor(COLOR_SKY_BLUE)
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(8)
          .onClick(() => {
            this.onToggleHistory()
          })
        }
      }.width('100%')
      .margin({ bottom: SPACE_MD })

      if (this.historyList.length > 0) {
        // 可滚动的历史记录列表
        Column() {
          Scroll() {
            Column({ space: 12 }) {
              ForEach(this.showAllHistory ? this.historyList : this.historyList.slice(0, 5),
                (item: SpeedTestResult) => {
                  this.buildHistoryRow(item)
                }, (item: SpeedTestResult): string => item.timestamp + '_' + item.downloadSpeed)
            }
          }
          .scrollBar(BarState.Off)
          .height(this.showAllHistory ? 300 : undefined)
        }

        // 底部提示（仅展开时显示）
        if (this.showAllHistory && this.historyList.length > 5) {
          Text() {
            Span($r('app.string.total_roam_events'))
            Span(String(this.historyList.length))
            Span($r('app.string.records_count'))
          }
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
          .margin({ top: 8 })
        }
      } else {
        Column({ space: 12 }) {
          Text('📈').fontSize(42)
          Text($r('app.string.no_test_record')).fontSize(FONT_SIZE_3XL).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .width('100%')
        .padding({ top: 28, bottom: 28 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(20)
    .backdropBlur(GLASS_BLUR_XL)
    .borderWidth(1)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_LIGHT)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_SKY_BLUE_GAUGE_BG, offsetX: 0, offsetY: 3 })
  }

  @Builder
  buildHistoryRow(item: SpeedTestResult) {
    Row({ space: 12 }) {
      Column().width(3).height(44).borderRadius(2)
        .linearGradient({ angle: 180, colors: [[COLOR_SKY_BLUE, 0.0], [COLOR_SKY_BLUE_LIGHT, 1.0]] })

      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Row({ space: 3 }) {
            Text('↓').fontSize(FONT_SIZE_SM).fontColor(COLOR_SKY_BLUE).fontWeight(FontWeight.Bold)
            Text(item.downloadSpeed.toFixed(1)).fontSize(FONT_SIZE_LG).fontWeight(FontWeight.Medium).fontColor(this.isDarkMode ? '#FFFFFF' : '#1E293B')
            Text('Mbps').fontSize(10).fontColor(this.isDarkMode ? 'rgba(255,255,255,0.6)' : 'rgba(100,116,139,0.7)')
          }
          Row({ space: 3 }) {
            Text('↑').fontSize(FONT_SIZE_SM).fontColor(COLOR_SUCCESS).fontWeight(FontWeight.Bold)
            Text(item.uploadSpeed.toFixed(1)).fontSize(FONT_SIZE_LG).fontWeight(FontWeight.Medium).fontColor(this.isDarkMode ? '#FFFFFF' : '#1E293B')
            Text('Mbps').fontSize(10).fontColor(this.isDarkMode ? 'rgba(255,255,255,0.6)' : 'rgba(100,116,139,0.7)')
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text(item.timeLabel || $r('app.string.unknown')).fontSize(FONT_SIZE_XS).fontColor(this.isDarkMode ? 'rgba(255,255,255,0.5)' : 'rgba(100,116,139,0.7)')
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column({ space: 1 }) {
        Text(item.pingMs.toFixed(0))
          .fontSize(FONT_SIZE_2XL)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('ms').fontSize(10).fontColor('#FFFFFF')
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 10, right: 10, top: 8, bottom: 8 })
      .backgroundColor(
        this.isDarkMode ?
          (item.pingMs < 30 ? COLOR_SUCCESS : (item.pingMs < 80 ? COLOR_WARNING : COLOR_DANGER)) :
          (item.pingMs < 30 ? COLOR_SUCCESS : (item.pingMs < 80 ? COLOR_WARNING : COLOR_DANGER))
      )
      .borderRadius(12)
    }
    .width('100%')
    .onClick(() => {
      this.onHistoryItemClick(item)
    })
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor(
      this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_SKY_LIGHT
    )
    .borderRadius(12)
  }
}
