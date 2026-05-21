// ============================================
// Aurora 网络信息网格
// ============================================

import {
  // 文字色（暗色模式）
  COLOR_TEXT_GLASS_PRIMARY,
  // 文字色（浅色模式）
  COLOR_TEXT_LIGHT_PRIMARY,
  // 暗色模式毛玻璃
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER_LIGHT,
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_GLASS_AURORA_LIGHT,
  // 半径
  RADIUS_CARD
} from '@wifi-analyzer/design-system'
import { PublicIpView } from './PublicIpView'
import { LocalIpView } from './LocalIpView'
import { GatewayView } from './GatewayView'
import { DnsView } from './DnsView'

@Component
export struct AuroraNetworkGrid {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  // AI 分析点击回调
  onAIAnalysisClick: () => void = () => {}

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

  // 浅色模式无边框
  private get gridBorderWidth(): number {
    return this.isDarkMode ? 1 : 0
  }

  build() {
    Column({ space: 12 }) {
      // 标题
      Row() {
        Text($r('app.string.network_info'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)

        Blank()

        // AI 分析入口
        Row({ space: 4 }) {
          Image($r('app.media.ic_ai_assistant'))
            .width(14)
            .height(14)
            .fillColor(COLOR_AURORA_PRIMARY)
          Text($r('app.string.ai_analysis_home'))
            .fontSize(12)
            .fontColor(COLOR_AURORA_PRIMARY)
        }
        .padding(6)
        .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
        .borderRadius(8)
        .onClick(() => {
          if (this.onAIAnalysisClick) {
            this.onAIAnalysisClick()
          }
        })
      }
      .width('100%')

      // 信息网格
      Grid() {
        GridItem() {
          LocalIpView({ isDarkMode: this.isDarkMode })
        }
        GridItem() {
          PublicIpView({ isDarkMode: this.isDarkMode })
        }
        GridItem() {
          GatewayView({ isDarkMode: this.isDarkMode })
        }
        GridItem() {
          DnsView({ isDarkMode: this.isDarkMode })
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .height(160)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.cardBg)
    .borderRadius(RADIUS_CARD)
    .border({
      width: this.gridBorderWidth,
      color: this.cardBorder,
      radius: RADIUS_CARD
    })
  }
}
