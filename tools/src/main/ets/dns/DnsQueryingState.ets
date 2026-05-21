// DNS 查询中状态与错误状态组件

import {
  COLOR_DANGER,
  FONT_SIZE_MD, FONT_SIZE_3XL,
  SPACE_MD,
  GLASS_BLUR_LG,
  GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  adaptiveTextTertiary
} from '@wifi-analyzer/design-system'

// ==================== 组件 ====================

@Component
export struct DnsQueryingState {
  @Prop isDarkMode: boolean = false
  @Prop isQuerying: boolean = false
  @Prop errorMessage: string = ''

  build() {
    Column({ space: SPACE_MD }) {
      if (this.isQuerying) {
        this.QueryingState()
      } else if (this.errorMessage !== '') {
        this.ErrorState()
      }
    }
    .width('100%')
  }

  // 查询中状态
  @Builder QueryingState() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.querying_dns')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%').height(180).justifyContent(FlexAlign.Center)
  }

  // 错误状态
  @Builder ErrorState() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(64).height(64).fill(this.isDarkMode ? 'rgba(239,68,68,0.15)' : '#FEF2F2')
        Text('!').fontSize(FONT_SIZE_3XL).fontColor(COLOR_DANGER).fontWeight(FONT_WEIGHT_BOLD)
      }
      Text(this.errorMessage || $r('app.string.query_failed'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_DANGER)
    }
    .width('100%').height(200).justifyContent(FlexAlign.Center)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
  }
}
