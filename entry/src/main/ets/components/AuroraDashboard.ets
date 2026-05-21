// ============================================
// Aurora WiFi V2 — 首页仪表盘组件（容器）
// API Level: 23+
// 极光天蓝 + 毛玻璃 + 沉浸光感设计
// ============================================

import { SharedWifiState, WifiDataManager } from '@wifi-analyzer/core'
import { AuroraConnectionCard } from './AuroraConnectionCard'
import { AuroraNetworkGrid } from './AuroraNetworkGrid'
import { AuroraToolsGrid } from './AuroraToolsGrid'
import { AuroraBackground } from './AuroraBackground'
import { AIAnalysisPanel, WifiStateCallbackResult } from './AIAnalysisPanel'
import { isEmulatorDevice } from '../utils/DeviceUtils'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { COLOR_WARNING } from '@wifi-analyzer/design-system'

// 日志 domain
const DOMAIN = 0x0000

// ============================================
// Aurora 首页主组件
// ============================================

@Component
export struct AuroraDashboard {
  @Consume('wifiState') wifiState: SharedWifiState
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  // 下拉刷新状态
  @State isRefreshing: boolean = false
  @State private refreshOffset: number = 0

  // WiFi 数据管理器
  private dataManager: WifiDataManager = WifiDataManager.getInstance()

  // AI 分析面板显示状态
  @State private showAIAnalysis: boolean = false

  // AI 分析面板控制器引用
  @Builder
  AIAnalysisPanelBuilder() {
    AIAnalysisPanel({
      isDarkMode: this.isDarkMode,
      showAIAnalysis: $showAIAnalysis,
      getWifiStateCallback: () => {
        const result: WifiStateCallbackResult = {
          ssid: this.wifiState.connectedSsid,
          signal: this.wifiState.connectedSignal,
          channel: this.wifiState.connectedChannel,
          frequency: this.wifiState.connectedFreq
        }
        return result
      }
    })
  }

  // 打开 AI 分析面板
  private openAIAnalysis(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[AuroraDashboard] Opening AI Analysis')
    this.showAIAnalysis = true
  }

  // 下拉刷新回调
  private async onRefresh(): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[AuroraDashboard] Refreshing WiFi data...')

    // 触发 WiFi 扫描
    this.dataManager.scanAndUpdate(
      this.wifiState,
      (newState: SharedWifiState) => {
        this.wifiState = newState
        AppStorage.setOrCreate('wifiState', newState)
        // 刷新完成
        this.isRefreshing = false
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[AuroraDashboard] Refresh completed')
      }
    )
  }

  build() {
    Stack() {
      // 极光装饰背景
      AuroraBackground()

      Column() {
        // 下拉刷新容器
        Refresh({
          refreshing: this.isRefreshing
        }) {
          Scroll() {
            Column({ space: 16 }) {
              // 连接状态卡片
              AuroraConnectionCard()

              // Fallback 数据提示（仅模拟器显示）
              if (this.wifiState.usingFallbackData && isEmulatorDevice()) {
                Row({ space: 8 }) {
                  Image($r('app.media.ic_warning'))
                    .width(16)
                    .height(16)
                  Text($r('app.string.simulator_data_warning'))
                    .fontSize(12)
                    .fontColor(COLOR_WARNING)
                }
                .padding({ left: 16, right: 16 })
              }

              // 网络信息网格
              AuroraNetworkGrid({
                onAIAnalysisClick: () => this.openAIAnalysis()
              })

              // 快速工具网格
              AuroraToolsGrid()

              // 底部安全区
              Row()
                .height(100)
            }
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .width('100%')
          .layoutWeight(1)
        }
        .onRefreshing(() => {
          this.onRefresh()
        })
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')

      // AI 分析面板（覆盖层）
      this.AIAnalysisPanelBuilder()
    }
    .width('100%')
    .height('100%')
  }
}
