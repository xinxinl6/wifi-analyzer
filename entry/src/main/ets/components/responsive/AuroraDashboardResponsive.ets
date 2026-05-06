// ============================================
// Aurora WiFi V2 — 响应式首页仪表盘
// 注意：当前未在任何文件中引用，保留以备后续响应式布局使用
// ============================================

import {
  Column,
  Row,
  Scroll,
  Blank
} from '@kit.ArkUI'
import {
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_AURORA_PRIMARY,
  COLOR_TEXT_GLASS_PRIMARY,
  RADIUS_CARD
} from '@wifi-analyzer/design-system'
import {
  AuroraConnectionCard,
  AuroraNetworkGrid,
  AuroraToolsGrid,
  AuroraBackground
} from '../AuroraDashboard'
import {
  auroraResponsive,
  isTablet,
  isPC
} from './AuroraBreakpoints'

// ============================================
// Aurora 响应式首页
// ============================================
@Component
export struct AuroraDashboardResponsive {
  @Builder
  buildPhoneLayout() {
    Scroll() {
      Column({ space: auroraResponsive(16, 12, 20) }) {
        AuroraBackground()
        AuroraConnectionCard()
        AuroraNetworkGrid()
        AuroraToolsGrid()
        Row().height(auroraResponsive(80, 60, 100))
      }
      .padding({
        left: auroraResponsive(16, 12, 24),
        right: auroraResponsive(16, 12, 24),
        top: auroraResponsive(16, 12, 24)
      })
      .width('100%')
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTabletLayout() {
    // 平板：双栏布局
    Row() {
      // 左栏
      Column({ space: auroraResponsive(16, 12, 20) }) {
        AuroraConnectionCard()
        AuroraToolsGrid()
      }
      .layoutWeight(1)
      .padding({
        left: auroraResponsive(20, 16, 32),
        right: auroraResponsive(12, 8, 16),
        top: auroraResponsive(20, 16, 32)
      })

      // 右栏
      Column({ space: auroraResponsive(16, 12, 20) }) {
        AuroraNetworkGrid()
      }
      .width(auroraResponsive(340, 300, 400))
      .padding({
        left: auroraResponsive(12, 8, 16),
        right: auroraResponsive(20, 16, 32),
        top: auroraResponsive(20, 16, 32)
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildPCLayout() {
    // PC：三栏布局
    Row() {
      // 左栏
      Column({ space: auroraResponsive(16, 12, 20) }) {
        AuroraConnectionCard()
      }
      .width(auroraResponsive(360, 320, 400))
      .padding({
        left: auroraResponsive(24, 20, 40),
        right: auroraResponsive(16, 12, 24),
        top: auroraResponsive(24, 20, 40)
      })

      // 中栏
      Column({ space: auroraResponsive(16, 12, 20) }) {
        AuroraToolsGrid()
      }
      .layoutWeight(1)
      .padding({
        left: auroraResponsive(16, 12, 24),
        right: auroraResponsive(16, 12, 24),
        top: auroraResponsive(24, 20, 40)
      })

      // 右栏
      Column({ space: auroraResponsive(16, 12, 20) }) {
        AuroraNetworkGrid()
      }
      .width(auroraResponsive(360, 320, 420))
      .padding({
        left: auroraResponsive(16, 12, 24),
        right: auroraResponsive(24, 20, 40),
        top: auroraResponsive(24, 20, 40)
      })
    }
    .width('100%')
    .height('100%')
  }

  build() {
    if (isPC()) {
      this.buildPCLayout()
    } else if (isTablet()) {
      this.buildTabletLayout()
    } else {
      this.buildPhoneLayout()
    }
  }
}
