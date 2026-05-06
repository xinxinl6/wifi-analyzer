// ============================================
// Aurora WiFi V2 — 悬浮毛玻璃底部导航栏
// API Level: 23+
// ============================================

import {
  Column,
  Image,
  Text,
  FlexAlign,
  Stack,
  Row,
  Circle,
  RelativeContainer,
  LayoutInfo,
  TransitionEffect
} from '@kit.ArkUI'
import {
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_GLOW,
  COLOR_AURORA_LIGHT,
  // 毛玻璃色彩
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_GLASS_STRONG,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  // 预置样式
  GlassTabBarStyle,
  DURATION_FAST,
  DURATION_NORMAL,
  AnimationTapScale
} from '@wifi-analyzer/design-system'

// 导航项配置接口
export interface AuroraTabItem {
  title: string
  icon: Resource
  iconActive: Resource
}

// 导航项组件（带点击动效）
@Component
export struct AuroraTabItem {
  @Prop title: string = ''
  @Prop icon: Resource = $r('app.media.ic_home')
  @Prop iconActive: Resource = $r('app.media.ic_home')
  @Prop isActive: boolean = false
  @Prop index: number = 0

  // 点击状态动画
  @State private scale: number = 1.0

  // 点击按下
  private onPress(): void {
    this.getUIContext().animateTo(AnimationTapScale, () => {
      this.scale = 0.90
    })
  }

  // 点击释放
  private onRelease(): void {
    this.getUIContext().animateTo({
      duration: DURATION_NORMAL,
      curve: Curve.EaseOut
    }, () => {
      this.scale = 1.0
    })
  }

  build() {
    Column() {
      // 顶部选中指示器（发光条）
      Stack() {
        // 发光背景
        if (this.isActive) {
          Circle()
            .width('100%')
            .height(24)
            .fill('rgba(74,144,217,0.25)')
        }
      }
      .width(56)
      .height(24)
      .alignContent(Alignment.Center)

      // 图标
      Stack({ alignContent: Alignment.Center }) {
        // 图标光晕（选中时显示）
        if (this.isActive) {
          Circle()
            .width(40)
            .height(40)
            .fill('rgba(74,144,217,0.15)')
        }

        Image(this.isActive ? this.iconActive : this.icon)
          .width(24)
          .height(24)
          .fillColor(this.isActive ? COLOR_AURORA_PRIMARY : COLOR_TEXT_GLASS_TERTIARY)
      }
      .width(48)
      .height(48)

      // 标题
      Text(this.title)
        .fontSize(11)
        .fontWeight(this.isActive ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.isActive ? COLOR_AURORA_PRIMARY : COLOR_TEXT_GLASS_TERTIARY)
        .margin({ top: 4 })
    }
    .width('100%')
    .height(72)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 8 })
    .scale({ x: this.scale, y: this.scale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.onPress()
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.onRelease()
      }
    })
  }
}

// ============================================
// 主导航栏组件
// ============================================

@Component
export struct AuroraTabBar {
  @Prop tabs: AuroraTabItem[] = []
  @Prop currentIndex: number = 0
  // 回调函数
  private onTabChange: (index: number) => void = () => {}

  build() {
    Row() {
      ForEach(this.tabs, (tab: AuroraTabItem, index: number) => {
        AuroraTabItem({
          title: tab.title,
          icon: tab.icon,
          iconActive: tab.iconActive,
          isActive: this.currentIndex === index,
          index: index
        })
        .onClick(() => {
          if (this.currentIndex !== index) {
            this.onTabChange(index)
          }
        })
        .layoutWeight(1)
      }, (tab: AuroraTabItem, index: number) => index.toString())
    }
    .width('100%')
    .height(72)
    .padding({
      left: 8,
      right: 8,
      top: 10,
      bottom: 10
    })
    // 毛玻璃背景
    .backgroundColor(COLOR_GLASS_SURFACE_MEDIUM)
    .border({
      width: { top: 0.5 },
      color: COLOR_GLASS_BORDER_LIGHT,
      radius: {
        topLeft: 24,
        topRight: 24,
        bottomLeft: 0,
        bottomRight: 0
      }
    })
    // 悬浮阴影
    .shadow({
      radius: 20,
      color: COLOR_SHADOW_GLASS_STRONG,
      offsetX: 0,
      offsetY: -4
    })
    // 安全区域
    .padding({ bottom: 10 })
  }
}

// ============================================
// AI 悬浮助手按钮
// ============================================

@Component
export struct AuroraAIFab {
  @Prop isVisible: boolean = true
  @State private isExpanded: boolean = false
  @State private scale: number = 1.0

  private onClick: () => void = () => {}

  build() {
    if (this.isVisible) {
      Stack({ alignContent: Alignment.Center }) {
        // 外层光晕（静态）
        Circle()
          .width(64)
          .height(64)
          .fill('rgba(74,144,217,0.1)')

        // 主按钮
        Column()
          .width(56)
          .height(56)
          .borderRadius(28)
          .backgroundColor(COLOR_AURORA_PRIMARY)
          .shadow({
            radius: 16,
            color: 'rgba(74,144,217,0.5)',
            offsetX: 0,
            offsetY: 4
          })
          .scale({ x: this.scale, y: this.scale })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.getUIContext().animateTo(AnimationTapScale, () => {
                this.scale = 0.88
              })
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.getUIContext().animateTo({
                duration: DURATION_NORMAL,
                curve: Curve.EaseOut
              }, () => {
                this.scale = 1.0
              })
            }
          })
          .onClick(() => {
            this.onClick()
          }) {
          // AI 图标
          Image($r('app.media.ic_ai_assistant'))
            .width(28)
            .height(28)
            .fillColor('#FFFFFF')
        }
      }
      .width(64)
      .height(64)
    }
  }
}

// ============================================
// 导出配置
// ============================================

export const AuroraTabConfig = {
  height: 72,
  iconSize: 24,
  textSize: 11,
  paddingHorizontal: 8,
  paddingVertical: 10,
  borderRadius: 24
}
