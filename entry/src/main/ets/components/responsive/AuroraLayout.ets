// ============================================
// Aurora WiFi V2 — 自适应布局组件
// ============================================

import {
  AuroraBreakpoints,
  auroraResponsive,
  useSideNav,
  isPC,
  isTablet
} from './AuroraBreakpoints'
import {
  COLOR_AURORA_PRIMARY,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_TERTIARY
} from '@wifi-analyzer/design-system'

// Tab 配置项
export interface AuroraTabConfig {
  title: string
  titleZh: string
  icon: Resource
  iconActive: Resource
  badge?: number
}

// ============================================
// Aurora 底部导航栏 (手机模式)
// ============================================
@Component
export struct AuroraBottomNav {
  @Prop items: AuroraTabConfig[] = []
  @Prop currentIndex: number = 0
  onSelect: (index: number) => void = () => {}

  @State private tabScales: number[] = []

  aboutToAppear(): void {
    this.tabScales = this.items.map(() => 1)
  }

  build() {
    Row() {
      ForEach(this.items, (item: AuroraTabConfig, index: number) => {
        this.buildTabItem(item, index)
      }, (item: AuroraTabConfig, index: number) => index.toString())
    }
    .width('100%')
    .height(auroraResponsive(64, 56, 72))
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
    .backgroundColor('rgba(10,22,40,0.92)')
    .border({
      width: { top: 0.5 },
      color: 'rgba(255,255,255,0.08)',
      radius: { topLeft: 24, topRight: 24 }
    })
    .shadow({
      radius: 24,
      color: 'rgba(0,0,0,0.25)',
      offsetX: 0,
      offsetY: -6
    })
  }

  @Builder
  buildTabItem(item: AuroraTabConfig, index: number) {
    Column() {
      // 顶部光晕
      Stack({ alignContent: Alignment.Top }) {
        if (this.currentIndex === index) {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(COLOR_AURORA_PRIMARY)
        }
        // 图标
        Stack({ alignContent: Alignment.Center }) {
          if (this.currentIndex === index) {
            Circle()
              .width(auroraResponsive(40, 36, 44))
              .height(auroraResponsive(40, 36, 44))
              .fill('rgba(74,144,217,0.15)')
          }
          Image(this.currentIndex === index ? item.iconActive : item.icon)
            .width(auroraResponsive(24, 22, 26))
            .height(auroraResponsive(24, 22, 26))
            .fillColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : COLOR_TEXT_GLASS_TERTIARY)
        }
        .width(auroraResponsive(44, 40, 48))
        .height(auroraResponsive(44, 40, 48))
      }
      .width('100%')
      .height(auroraResponsive(28, 24, 30))

      // 标签
      Text(item.title)
        .fontSize(auroraResponsive(11, 10, 12))
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : COLOR_TEXT_GLASS_TERTIARY)
        .maxLines(1)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .scale({ x: this.tabScales[index] || 1, y: this.tabScales[index] || 1 })
    .onClick(() => {
      animateTo({ duration: 80 }, () => { this.tabScales[index] = 0.88 })
      setTimeout(() => {
        animateTo({ duration: 150 }, () => { this.tabScales[index] = 1 })
      }, 80)
      this.onSelect(index)
    })
  }
}

// ============================================
// Aurora 侧边导航栏 (平板/PC模式)
// ============================================
@Component
export struct AuroraSideNav {
  @Prop items: AuroraTabConfig[] = []
  @Prop currentIndex: number = 0
  @Prop collapsed: boolean = false
  onSelect: (index: number) => void = () => {}
  onToggleCollapse: () => void = () => {}

  @State private hoveredIndex: number = -1

  build() {
    Column() {
      // Logo 区域
      this.buildHeader()

      Divider().width('80%').color('rgba(255,255,255,0.08)').margin({ top: 16, bottom: 16 })

      // 导航列表
      Column() {
        ForEach(this.items, (item: AuroraTabConfig, index: number) => {
          this.buildNavItem(item, index)
        }, (item: AuroraTabConfig, index: number) => index.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 8, right: 8 })

      Divider().width('80%').color('rgba(255,255,255,0.08)').margin({ top: 16, bottom: 16 })

      // 折叠按钮
      Row() {
        Image($r('app.media.ic_arrow_right'))
          .width(20).height(20).fillColor(COLOR_TEXT_GLASS_TERTIARY)
          .rotate({ z: 1, angle: this.collapsed ? 0 : 180 })
          .animation({ duration: 200, curve: Curve.EaseInOut })
      }
      .width(40).height(40).borderRadius(20)
      .backgroundColor('rgba(255,255,255,0.05)')
      .justifyContent(FlexAlign.Center)
      .onClick(() => this.onToggleCollapse())
    }
    .width('100%').height('100%')
    .padding({ top: 16, bottom: 16 })
    .backgroundColor('rgba(10,22,40,0.95)')
    .border({
      width: { right: 0.5 },
      color: 'rgba(255,255,255,0.08)',
      radius: { topRight: 20, bottomRight: 20 }
    })
  }

  @Builder
  buildHeader() {
    Column() {
      if (!this.collapsed) {
        Row({ space: 8 }) {
          Text('🌊').fontSize(28)
          Column() {
            Text('Aurora').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT_GLASS_PRIMARY)
            Text('WiFi').fontSize(12).fontColor(COLOR_TEXT_GLASS_TERTIARY)
          }.alignItems(HorizontalAlign.Start)
        }.width('100%').justifyContent(FlexAlign.Center)
      } else {
        Text('🌊').fontSize(28)
      }
    }
    .width('100%')
    .height(auroraResponsive(56, 48, 64))
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildNavItem(item: AuroraTabConfig, index: number) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        // 选中背景
        if (this.currentIndex === index) {
          Column()
            .width('100%')
            .height(auroraResponsive(48, 44, 52))
            .borderRadius(12)
            .backgroundColor('rgba(74,144,217,0.15)')
            .border({ width: 1, color: 'rgba(74,144,217,0.25)', radius: 12 })
            .clip(true)
        }
        // 悬停效果
        if (this.hoveredIndex === index && this.currentIndex !== index) {
          Column()
            .width('100%')
            .height(auroraResponsive(48, 44, 52))
            .borderRadius(12)
            .backgroundColor('rgba(255,255,255,0.05)')
            .clip(true)
        }
        // 内容
        Row({ space: 12 }) {
          Image(this.currentIndex === index ? item.iconActive : item.icon)
            .width(auroraResponsive(22, 20, 24))
            .height(auroraResponsive(22, 20, 24))
            .fillColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : COLOR_TEXT_GLASS_TERTIARY)
          if (!this.collapsed) {
            Text(item.title)
              .fontSize(auroraResponsive(14, 13, 15))
              .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(this.currentIndex === index ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_GLASS_TERTIARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .height(auroraResponsive(48, 44, 52))
        .padding({ left: 12, right: 12 })
        .width(this.collapsed ? '100%' : 'calc(100% - 16px)')
        .justifyContent(this.collapsed ? FlexAlign.Center : FlexAlign.Start)
      }
      .width('100%')
      .onHover((isHover: boolean) => { this.hoveredIndex = isHover ? index : -1 })
      .onClick(() => this.onSelect(index))
    }
    .width('100%')
    .margin({ bottom: 4 })
  }
}

// ============================================
// Aurora 主布局组件
// ============================================
@Component
export struct AuroraMainLayout {
  @Prop currentIndex: number = 0
  @State sidebarCollapsed: boolean = false
  @Prop tabItems: AuroraTabConfig[] = []
  onTabChange: (index: number) => void = () => {}

  @BuilderParam contentBuilder: () => void = this.defaultContent

  @Builder defaultContent() {
    Text('Content').fontColor(COLOR_TEXT_GLASS_PRIMARY)
  }

  build() {
    if (useSideNav()) {
      // 大屏：侧边栏 + 内容
      Row() {
        AuroraSideNav({
          items: this.tabItems,
          currentIndex: this.currentIndex,
          collapsed: this.sidebarCollapsed,
          onSelect: this.onTabChange,
          onToggleCollapse: () => {
            animateTo({ duration: 200 }, () => { this.sidebarCollapsed = !this.sidebarCollapsed })
          }
        })
        .width(this.sidebarCollapsed ? AuroraBreakpoints.SIDEBAR_WIDTH_COMPACT : AuroraBreakpoints.SIDEBAR_WIDTH_EXPANDED)
        Column() { this.contentBuilder() }.layoutWeight(1).height('100%').clip(true)
      }.width('100%').height('100%').backgroundColor('#0A1628')
    } else {
      // 手机：底部Tab + 内容
      Column() {
        Column() { this.contentBuilder() }.layoutWeight(1).width('100%')
        AuroraBottomNav({ items: this.tabItems, currentIndex: this.currentIndex, onSelect: this.onTabChange })
      }.width('100%').height('100%').backgroundColor('#0A1628')
    }
  }
}

// ============================================
// Aurora 设备特定布局
// ============================================
@Component
export struct AuroraDeviceLayout {
  @BuilderParam phoneBuilder: () => void = this.defaultBuilder
  @BuilderParam tabletBuilder: () => void = this.defaultBuilder
  @BuilderParam pcBuilder: () => void = this.defaultBuilder

  @Builder defaultBuilder() { Text('Default') }

  build() {
    Column() {
      if (isPC()) { this.pcBuilder() }
      else if (isTablet()) { this.tabletBuilder() }
      else { this.phoneBuilder() }
    }.width('100%').height('100%')
  }
}
