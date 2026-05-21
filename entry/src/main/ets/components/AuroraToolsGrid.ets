// ============================================
// Aurora 快速工具网格
// ============================================

import {
  // 文字色（暗色模式）
  COLOR_TEXT_GLASS_PRIMARY,
  // 文字色（浅色模式）
  COLOR_TEXT_LIGHT_PRIMARY,
  // 暗色模式毛玻璃
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_SURFACE,
  COLOR_GLASS_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  // 功能色
  COLOR_INFO,
  // 半径
  RADIUS_CARD
} from '@wifi-analyzer/design-system'
import { RouterManager, RouteName } from '@wifi-analyzer/core'

@Component
export struct AuroraToolsGrid {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State private toolScale: number = 1.0

  // 根据模式获取文字颜色
  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  // 根据模式获取卡片背景色
  private get cardBg(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_CARD
  }

  // 根据模式获取边框颜色
  private get cardBorder(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER_LIGHT
  }

  // 根据模式获取工具项背景色
  private get toolItemBg(): string {
    return this.isDarkMode ? COLOR_GLASS_DARK_SURFACE : COLOR_GLASS_SURFACE_LIGHT
  }

  // 根据模式获取工具项边框颜色
  private get toolItemBorder(): string {
    return this.isDarkMode ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_BORDER_LIGHT
  }

  // 浅色模式无边框
  private get toolBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  // 浅色模式工具项边框
  private get toolItemBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  @Builder
  ToolCard(title: ResourceStr, icon: Resource, bgColor: string, iconColor: string, index: number, action: string) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        // 图标背景
        Column()
          .width(48)
          .height(48)
          .borderRadius(14)
          .backgroundColor(bgColor)
          .shadow({
            radius: 8,
            color: `${iconColor}25`,
            offsetX: 0,
            offsetY: 2
          })

        // 图标
        Image(icon)
          .width(26)
          .height(26)
          .fillColor(iconColor)
      }

      // 标题
      Text(title)
        .fontSize(10)
        .fontColor(this.textPrimary)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.toolItemBg)
    .borderRadius(14)
    .border({
      width: this.toolItemBorderWidth,
      color: this.isDarkMode ? this.toolItemBorder : 'rgba(0,0,0,0)',
      radius: 14
    })
    .scale({ x: this.toolScale, y: this.toolScale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.getUIContext().animateTo({
          duration: 100,
          curve: Curve.EaseOut
        }, () => {
          this.toolScale = 0.95
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.getUIContext().animateTo({
          duration: 200,
          curve: Curve.EaseOut
        }, () => {
          this.toolScale = 1.0
        })
      }
    })
    .onClick(() => {
      const routeMap: Record<string, RouteName> = {
        'roamtest': 'roamtest',
        'channel': 'channel'
      }
      const tabMap: Record<string, number> = {
        'wifi': 1,
        'channel_tab': 2,
        'speed': 3,
        'tools': 4
      }
      // 先检查是否是 Tab 导航
      const tabIndex = tabMap[action]
      if (tabIndex !== undefined) {
        RouterManager.navigateToTab(tabIndex)
        return
      }
      // 否则检查是否是子页面导航
      const route = routeMap[action]
      if (route) {
        RouterManager.navigate(route)
      }
    })
  }

  build() {
    Column({ space: 12 }) {
      // 标题
      Row() {
        Text($r('app.string.quick_tools'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)

        Blank()

        Text($r('app.string.more'))
          .fontSize(12)
          .fontColor(COLOR_AURORA_PRIMARY)
          .onClick(() => {
            RouterManager.navigateToTab(4) // 跳转到工具 Tab
          })
      }
      .width('100%')

      // 工具网格
      Grid() {
        GridItem() {
          this.ToolCard($r('app.string.roam_test'), $r('app.media.ic_roaming'), COLOR_GLASS_AURORA, COLOR_AURORA_PRIMARY, 0, 'roamtest')
        }
        GridItem() {
          this.ToolCard($r('app.string.surrounding_wifi'), $r('app.media.ic_surround'), COLOR_GLASS_AURORA_LIGHT, COLOR_AURORA_LIGHT, 1, 'wifi')
        }
        GridItem() {
          this.ToolCard($r('app.string.channel_analysis'), $r('app.media.ic_channel'), COLOR_GLASS_AURORA, COLOR_INFO, 2, 'channel_tab')
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .height(110)
    }
    .width('100%')
    .padding(15)
    .backgroundColor(this.cardBg)
    .borderRadius(RADIUS_CARD)
    .border({
      width: this.toolBorderWidth,
      color: this.cardBorder,
      radius: RADIUS_CARD
    })
  }
}
