// ============================================
// Aurora WiFi V2 — 协议弹窗组件
// API Level: 23+
// ============================================

import {
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  FONT_SIZE_LG, FONT_SIZE_MD, FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD, SPACE_LG,
  RADIUS_LG,
  GLASS_BLUR_LG, GLASS_SHADOW_XL,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider,
  COLOR_SHADOW_GLASS
} from '@wifi-analyzer/design-system'

// ============================================
// 通用协议弹窗组件
// ============================================

@CustomDialog
export struct AgreementDialog {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  controller: CustomDialogController = new CustomDialogController({ builder: '' })
  dialogTitle: ResourceStr = ''
  plainTextContent: string = ''

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.dialogTitle)
          .fontSize(FONT_SIZE_LG)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
        Blank()
        Text('×')
          .fontSize(28)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
          .onClick(() => { this.controller.close() })
      }
      .width('100%')
      .padding({ left: SPACE_LG, right: SPACE_SM, top: SPACE_LG, bottom: SPACE_MD })

      Divider()
        .color(adaptiveDivider(this.isDarkMode))
        .strokeWidth(0.5)

      // 内容区域 - 使用 Text 组件显示纯文本
      Scroll() {
        Text(this.plainTextContent)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
          .width('100%')
          .lineHeight(24)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(SPACE_LG)
    }
    .width('90%')
    .height('70%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(RADIUS_LG)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 8 })
    .clip(true)
  }
}
