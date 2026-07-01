// ============================================
// HM7 GlassCard — 可复用材质卡片组件
// 沉浸光感设计系统：5级材质 + backdrop-filter 景深
// 支持暗/亮双主题自适应 + 交互状态
// 使用 @ComponentV2 架构
// ============================================

import {
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_GLASS_STRONG,
  COLOR_CARD_LIGHT,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
} from '../Color'
import {
  GLASS_BLUR_LG,
  GLASS_BLUR_MD,
  GLASS_BLUR_SM
} from '../Size'

export enum MaterialLevel {
  THIN = 1,      // 轻材质：工具卡片、列表项
  MEDIUM = 2,    // 中材质：普通卡片
  THICK = 3,     // 厚材质：重点卡片
  SOLID = 4      // 实心材质：焦点卡片
}

export enum InteractionState {
  NORMAL = 'normal',
  HOVER = 'hover',
  ACTIVE = 'active',
  DISABLED = 'disabled'
}

interface InteractiveStyle {
  backgroundColor?: string
  borderColor?: string
  shadowRadius?: number
  shadowColor?: string
  shadowOffsetX?: number
  shadowOffsetY?: number
}

@ComponentV2
export struct AuroraGlassCard {
  @Param radius: number = 16
  @Param cardPadding: Padding | undefined = undefined
  @Param glassBlur: number = GLASS_BLUR_LG
  @Param isDark: boolean = false
  @Param materialLevel: MaterialLevel = MaterialLevel.MEDIUM
  @Param interactive: boolean = false
  @Param isPressed: boolean = false
  @BuilderParam content: () => void = this.defaultContent

  @Builder
  defaultContent(): void {
  }

  // 根据材质级别获取背景色
  private getBackgroundColor(): string {
    if (this.isDark) {
      switch (this.materialLevel) {
        case MaterialLevel.THIN: return COLOR_GLASS_SURFACE_LIGHT
        case MaterialLevel.MEDIUM: return COLOR_GLASS_SURFACE_MEDIUM
        case MaterialLevel.THICK: return COLOR_GLASS_SURFACE_HIGH
        case MaterialLevel.SOLID: return COLOR_GLASS_DARK_CARD
        default: return COLOR_GLASS_SURFACE_MEDIUM
      }
    } else {
      switch (this.materialLevel) {
        case MaterialLevel.THIN: return 'rgba(0,0,0,0.02)'
        case MaterialLevel.MEDIUM: return 'rgba(0,0,0,0.04)'
        case MaterialLevel.THICK: return 'rgba(0,0,0,0.06)'
        case MaterialLevel.SOLID: return COLOR_CARD_LIGHT
        default: return 'rgba(0,0,0,0.04)'
      }
    }
  }

  // 根据材质级别获取边框色
  private getBorderColor(): string {
    if (this.isDark) {
      switch (this.materialLevel) {
        case MaterialLevel.THIN: return 'rgba(255,255,255,0.04)'
        case MaterialLevel.MEDIUM: return 'rgba(255,255,255,0.08)'
        case MaterialLevel.THICK: return 'rgba(255,255,255,0.12)'
        case MaterialLevel.SOLID: return COLOR_GLASS_DARK_BORDER
        default: return 'rgba(255,255,255,0.08)'
      }
    } else {
      switch (this.materialLevel) {
        case MaterialLevel.THIN: return 'rgba(0,0,0,0.04)'
        case MaterialLevel.MEDIUM: return 'rgba(0,0,0,0.06)'
        case MaterialLevel.THICK: return 'rgba(0,0,0,0.08)'
        case MaterialLevel.SOLID: return 'rgba(0,0,0,0.08)'
        default: return 'rgba(0,0,0,0.06)'
      }
    }
  }

  // 根据材质级别获取模糊度
  private getGlassBlur(): number {
    switch (this.materialLevel) {
      case MaterialLevel.THIN: return GLASS_BLUR_SM
      case MaterialLevel.MEDIUM: return GLASS_BLUR_MD
      case MaterialLevel.THICK: return GLASS_BLUR_LG
      case MaterialLevel.SOLID: return 0
      default: return GLASS_BLUR_MD
    }
  }

  // 交互状态处理
  private getInteractiveStyle(): InteractiveStyle {
    if (!this.interactive) return {}
    
    let backgroundColor = this.getBackgroundColor()
    let borderColor = this.getBorderColor()
    let shadowRadius = this.isDark ? 0 : 8
    let shadowColor = this.isDark ? 'transparent' : COLOR_SHADOW_GLASS
    
    if (this.isPressed) {
      // 按下状态
      backgroundColor = this.isDark 
        ? 'rgba(49,122,247,0.12)' 
        : 'rgba(10,89,247,0.08)'
      borderColor = this.isDark 
        ? 'rgba(49,122,247,0.20)' 
        : 'rgba(10,89,247,0.15)'
      shadowRadius = 4
      shadowColor = this.isDark 
        ? 'rgba(49,122,247,0.15)' 
        : 'rgba(10,89,247,0.10)'
    } else {
      // 悬停状态效果
      shadowRadius = this.isDark ? 0 : 12
      shadowColor = this.isDark 
        ? 'transparent' 
        : COLOR_SHADOW_GLASS_STRONG
    }
    
    return {
      backgroundColor,
      borderColor,
      shadowRadius,
      shadowColor,
      shadowOffsetX: 0,
      shadowOffsetY: this.isDark ? 0 : 3
    }
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(this.cardPadding ?? 16)
    .borderRadius(this.radius)
    .backgroundColor(this.getInteractiveStyle().backgroundColor ?? this.getBackgroundColor())
    .blur(this.getGlassBlur())
    .borderWidth(1)
    .borderColor(this.getInteractiveStyle().borderColor ?? this.getBorderColor())
    .borderStyle(BorderStyle.Solid)
    .shadow({
      radius: this.getInteractiveStyle().shadowRadius ?? (this.isDark ? 0 : 8),
      color: this.getInteractiveStyle().shadowColor ?? (this.isDark ? 'transparent' : COLOR_SHADOW_GLASS),
      offsetX: this.getInteractiveStyle().shadowOffsetX ?? 0,
      offsetY: this.getInteractiveStyle().shadowOffsetY ?? (this.isDark ? 0 : 2)
    })
    .onClick(() => {
      if (this.interactive) {
        // 可以在这里添加点击动画
      }
    })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
  }
}