// ============================================
// 华为标准返回按钮组件
// 根据 HarmonyOS 设计规范，返回按钮只显示箭头图标，不显示文字
// ============================================

import {
  COLOR_TEXT_SECONDARY,
  COLOR_SURFACE,
  COLOR_BORDER,
  COLOR_SKY_BLUE,
  COLOR_GLASS_SKY_TAG_BG,
  COLOR_GLASS_BORDER,
  FONT_SIZE_MD,
  FONT_SIZE_LG,
  FONT_WEIGHT_MEDIUM,
  SAFE_AREA_TOP,
  SPACE_LG,
  SPACE_MD,
  RADIUS_3XL,
  BUTTON_HEIGHT_SM,
} from '@wifi-analyzer/design-system'

// 底部胶囊返回按钮（用于 ActionButtons）
@Component
export struct BackButtonCapsule {
  private onBack: () => void = () => {}

  build() {
    Row() {
      Text('←')
        .fontSize(FONT_SIZE_MD)
        .fontColor(COLOR_TEXT_SECONDARY)
        .fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .width(44)
    .height(BUTTON_HEIGHT_SM)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_3XL)
    .borderWidth(1)
    .borderColor(COLOR_BORDER)
    .onClick(() => this.onBack())
  }
}

// 毛玻璃风格返回按钮（用于毛玻璃主题页面如 TraceroutePage）
@Component
export struct BackButtonGlass {
  private onBack: () => void = () => {}

  build() {
    Row() {
      Text('←')
        .fontSize(20)
        .fontColor(COLOR_SKY_BLUE)
        .fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .borderRadius(20)
    .backgroundColor(COLOR_GLASS_SKY_TAG_BG)
    .borderWidth(1)
    .borderColor(COLOR_GLASS_BORDER)
    .onClick(() => this.onBack())
  }
}

// 顶部返回按钮栏（用于 TraceroutePage 等自定义导航栏页面）
@Component
export struct TopBackBar {
  private onBack: () => void = () => {}

  build() {
    Row() {
      BackButtonGlass({ onBack: this.onBack })
      Blank()
    }
    .width('100%')
    .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
    .alignItems(VerticalAlign.Center)
  }
}
