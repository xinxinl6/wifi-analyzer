// ============================================
// AI Analysis Panel - AI 分析面板
// ============================================

import {
  // 文字色（暗色模式）
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  // 文字色（浅色模式）
  COLOR_TEXT_LIGHT_PRIMARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_TEXT_LIGHT_TERTIARY,
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  // 玻璃色彩
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_OVERLAY,
  COLOR_GLASS_AURORA
} from '@wifi-analyzer/design-system'
import { getAIAnalysisUrl, buildNetworkQuery, WifiNetworkInfo } from '../utils/XiaoYiHelper'
import { promptAction } from '@kit.ArkUI'
import web_webview from '@ohos.web.webview'
import { hilog } from '@kit.PerformanceAnalysisKit'

// WiFi 状态回调结果接口
export interface WifiStateCallbackResult {
  ssid: string
  signal: number
  channel: number
  frequency: number
}

// 日志 domain
const DOMAIN = 0x0000

@Component
export struct AIAnalysisPanel {
  @Prop isDarkMode: boolean = false
  @Link showAIAnalysis: boolean

  @State aiWebViewUrl: string = ''
  @State aiLoading: boolean = false

  // AI 分析面板控制器
  private aiAnalysisController: web_webview.WebviewController = new web_webview.WebviewController()

  // 外部获取 wifiState 的回调
  getWifiStateCallback: () => WifiStateCallbackResult = () => {
    const result: WifiStateCallbackResult = { ssid: '', signal: 0, channel: 0, frequency: 0 }
    return result
  }

  // URL 白名单验证（仅允许百度搜索）
  private isUrlAllowed(url: string): boolean {
    try {
      const allowedDomains = ['https://m.baidu.com/', 'https://www.baidu.com/']
      for (let i = 0; i < allowedDomains.length; i++) {
        if (url.startsWith(allowedDomains[i])) {
          return true
        }
      }
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[AIAnalysisPanel] Blocked URL: ' + url)
      return false
    } catch (e) {
      return false
    }
  }

  // 打开 AI 分析面板
  openAIAnalysis(): void {
    // 获取网络状态
    const wifiState = this.getWifiStateCallback()

    // 构建网络分析查询
    const networkInfo: WifiNetworkInfo = {
      ssid: wifiState.ssid,
      signal: wifiState.signal,
      channel: wifiState.channel,
      frequency: wifiState.frequency
    }
    const query = buildNetworkQuery(networkInfo)

    // 直接获取搜索URL
    const url = getAIAnalysisUrl(query)
    // URL 白名单验证
    if (!this.isUrlAllowed(url)) {
      promptAction.showToast({ message: $r('app.string.unsupported_url'), duration: 2000 })
      return
    }
    this.aiWebViewUrl = url
    this.showAIAnalysis = true
    this.aiLoading = true

    promptAction.showToast({
      message: $r('app.string.ai_analyzing'),
      duration: 2000
    })
  }

  // 关闭 AI 分析面板
  closeAIAnalysis(): void {
    this.showAIAnalysis = false
    this.aiWebViewUrl = ''
  }

  build() {
    if (this.showAIAnalysis) {
      Stack({ alignContent: Alignment.Bottom }) {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(COLOR_OVERLAY)
          .onClick(() => {
            this.closeAIAnalysis()
          })

        // WebView 面板内容
        Column({ space: 0 }) {
          // 顶部拖拽指示条
          Column()
            .width(40)
            .height(4)
            .backgroundColor(COLOR_GLASS_SURFACE_LIGHT)
            .borderRadius(2)
            .margin({ top: 12, bottom: 8 })

          // 标题栏
          Row() {
            Text($r('app.string.ai_network_optimization'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY)

            Blank()

            // 关闭按钮
            Image($r('app.media.ic_close'))
              .width(24)
              .height(24)
              .fillColor(this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY)
              .onClick(() => {
                this.closeAIAnalysis()
              })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 12 })

          // 加载指示器
          if (this.aiLoading) {
            Row() {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(COLOR_AURORA_PRIMARY)
              Text($r('app.string.loading'))
                .fontSize(14)
                .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY)
                .margin({ left: 8 })
            }
            .padding(16)
            .width('100%')
          }

          // WebView 内容（安全加固配置）
          Web({ src: this.aiWebViewUrl, controller: this.aiAnalysisController })
            .width('100%')
            .layoutWeight(1)
            .multiWindowAccess(false)
            .fileAccess(false)
            .databaseAccess(false)
            .domStorageAccess(false)
            .geolocationAccess(false)
            .mediaPlayGestureAccess(true)
            .onPageBegin((event: OnPageBeginEvent) => {
              // 二次验证：页面开始加载时再次检查 URL
              if (event && event.url && !this.isUrlAllowed(event.url)) {
                hilog.warn(DOMAIN, 'testTag', '%{public}s', '[AIAnalysisPanel] Blocked WebView loading: ' + event.url)
                promptAction.showToast({ message: $r('app.string.blocked_unsafe_url'), duration: 2000 })
                return
              }
              this.aiLoading = true
            })
            .onPageEnd(() => {
              this.aiLoading = false
            })
            .onErrorReceive((event) => {
              hilog.error(DOMAIN, 'testTag', '%{public}s', 'WebView error: ' + (event?.error?.getErrorInfo() || 'Unknown error'))
              this.aiLoading = false
            })
        }
        .width('100%')
        .height('85%')
        .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_SURFACE)
        .borderRadius({ topLeft: 24, topRight: 24 })
      }
      .zIndex(999)
    }
  }
}
