// ============================================
// HM7 返回按钮组件 — 沉浸光感风格
// 品牌色实心胶囊（暗色） / 毛玻璃风格（亮色）
// 详见项目根目录 DESIGN.md
// ============================================

import {
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  adaptivePrimary,
  adaptivePrimaryBg,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveBtnBg,
  adaptiveBtnBorder,
} from './Color'
import {
  SAFE_AREA_TOP,
  SPACE_LG,
  RADIUS_3XL,
  BUTTON_HEIGHT_SM,
} from './Size'
import {
  FONT_SIZE_MD,
  FONT_WEIGHT_MEDIUM,
} from './Typography'

// 底部胶囊返回按钮（暗色模式用品牌色，亮色用材质）
@ComponentV2
export struct BackButtonCapsule {
  @Param isDark: boolean = true
  @Param onBack: () => void = () => {}

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(20)
        .fontColor([adaptivePrimary(this.isDark)])
    }
    .width(40)
    .height(BUTTON_HEIGHT_SM)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(adaptiveBtnBg(this.isDark))
    .borderRadius(RADIUS_3XL)
    .borderWidth(1)
    .borderColor(adaptiveBtnBorder(this.isDark))
    .onClick(() => this.onBack())
  }
}

// HM7 品牌色返回按钮（主色调实心胶囊）
@ComponentV2
export struct BackButtonGlass {
  @Param isDark: boolean = true
  @Param onBack: () => void = () => {}

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(18)
        .fontColor([Color.White])
    }
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .borderRadius(24)
    .backgroundColor(adaptivePrimary(this.isDark))
    .onClick(() => this.onBack())
  }
}

// 材质透明返回按钮（适合暗色背景场景）
@ComponentV2
export struct BackButtonGlassTransparent {
  @Param isDark: boolean = true
  @Param onBack: () => void = () => {}

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.arrow_left'))
        .fontSize(18)
        .fontColor([adaptiveTextPrimary(this.isDark)])
    }
    .width(32)
    .height(32)
    .justifyContent(FlexAlign.Center)
    .borderRadius(10)
    .backgroundColor(adaptiveBtnBg(this.isDark))
    .borderWidth(1)
    .borderColor(adaptiveBtnBorder(this.isDark))
    .onClick(() => this.onBack())
  }
}

// 顶部返回按钮栏
@ComponentV2
export struct TopBackBar {
  @Param isDark: boolean = true
  @Param onBack: () => void = () => {}

  build() {
    Row() {
      BackButtonGlassTransparent({ isDark: this.isDark, onBack: this.onBack })
      Blank()
    }
    .width('100%')
    .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
    .alignItems(VerticalAlign.Center)
  }
}
