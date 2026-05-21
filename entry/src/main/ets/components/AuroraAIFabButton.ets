// ============================================
// Aurora WiFi V2 — AI 悬浮按钮组件
// API Level: 23+
// ============================================

import {
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_AURORA_GLOW,
  // 文字色
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_GLASS_DARK_CARD,
  COLOR_SHADOW_AURORA,
  COLOR_GLASS_AURORA,
  COLOR_OVERLAY,
  // 动效
  DURATION_NORMAL,
  AnimationTapScale
} from '@wifi-analyzer/design-system'
import { getAIAnalysisUrl, buildNetworkQuery, WifiNetworkInfo } from '../utils/XiaoYiHelper'
import web_webview from '@ohos.web.webview'
import { promptAction } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

// ============================================
// AI 助手悬浮按钮（FAB）
// ============================================

@Component
export struct AuroraAIFabButton {
  @Prop fabVisible: boolean = true
  // 可选的 WiFi 信息，用于构建小艺查询
  @Prop wifiSsid: string = ''
  @Prop wifiSignal: number = 0
  @Prop wifiChannel: number = 0

  @State private fabScale: number = 1.0
  @State private glowScale: number = 1.0
  @State private glowOpacity: number = 0.4
  @State private fabMessage: string = ''

  // AI 分析面板状态
  @State private showAIAnalysis: boolean = false
  @State private aiWebViewUrl: string = ''
  @State private aiLoading: boolean = false

  // AI 分析面板控制器
  private aiAnalysisController: web_webview.WebviewController = new web_webview.WebviewController()

  aboutToAppear(): void {
    // 脉冲光晕动画
    this.getUIContext().animateTo({
      duration: 2000,
      curve: Curve.EaseInOut,
      iterations: -1
    }, () => {
      this.glowOpacity = this.glowOpacity === 0.4 ? 0.8 : 0.4
      this.glowScale = this.glowScale === 1.0 ? 1.15 : 1.0
    })
  }

  // 打开 AI 分析面板（使用 WebView 避免系统弹窗）
  private openAIAnalysis(): void {
    // 构建网络分析查询
    const networkInfo: WifiNetworkInfo = {
      ssid: this.wifiSsid,
      signal: this.wifiSignal,
      channel: this.wifiChannel,
      frequency: 0
    }
    const query = buildNetworkQuery(networkInfo)

    // 直接获取搜索URL，不尝试启动小艺（避免系统弹窗）
    const url = getAIAnalysisUrl(query)
    this.aiWebViewUrl = url
    this.showAIAnalysis = true
    this.aiLoading = true

    // 显示加载提示
    promptAction.showToast({
      message: $r('app.string.ai_analyzing'),
      duration: 2000
    })

  }

  // 关闭 AI 分析面板
  private closeAIAnalysis(): void {
    this.showAIAnalysis = false
    this.aiWebViewUrl = ''
  }

  @Builder
  AIAnalysisWebViewPanel() {
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
            .backgroundColor(COLOR_GLASS_AURORA)
            .borderRadius(2)
            .margin({ top: 12, bottom: 8 })

          // 标题栏
          Row() {
            Text($r('app.string.ai_network_optimization'))
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(COLOR_TEXT_GLASS_PRIMARY)

            Blank()

            // 关闭按钮
            Image($r('app.media.ic_close'))
              .width(24)
              .height(24)
              .fillColor(COLOR_TEXT_GLASS_TERTIARY)
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
              Text($r('app.string.ai_analyzing'))
                .fontSize(14)
                .fontColor(COLOR_TEXT_GLASS_SECONDARY)
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
            .onPageBegin(() => {
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
        .backgroundColor(COLOR_GLASS_DARK_CARD)
        .borderRadius({ topLeft: 24, topRight: 24 })
      }
      .zIndex(999)
    }
  }

  build() {
    Stack() {
      // FAB 按钮
      if (this.fabVisible) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          // 外层呼吸光晕
          Circle()
            .width(72)
            .height(72)
            .fill(`rgba(74,144,217,${this.glowOpacity * 0.3})`)
            .scale({ x: this.glowScale, y: this.glowScale })

          // 内层光晕
          Circle()
            .width(64)
            .height(64)
            .fill(COLOR_GLASS_AURORA)

          // 主按钮
          Column()
            .width(56)
            .height(56)
            .borderRadius(28)
            .backgroundColor(COLOR_AURORA_PRIMARY)
.shadow({
                  radius: 16,
                  color: COLOR_SHADOW_AURORA,
                  offsetX: 0,
                  offsetY: 4
                })
            .scale({ x: this.fabScale, y: this.fabScale })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.getUIContext().animateTo(AnimationTapScale, () => {
                  this.fabScale = 0.88
                })
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.getUIContext().animateTo({
                  duration: DURATION_NORMAL,
                  curve: Curve.EaseOut
                }, () => {
                  this.fabScale = 1.0
                })
              }
            })
            .onClick(() => {
              // 打开 AI 分析面板（使用 WebView）
              this.openAIAnalysis()
            }) {
            // AI 图标
            Row() {
              Image($r('app.media.ic_ai_assistant'))
                .width(26)
                .height(26)
                .fillColor('#FFFFFF')
            }
          }
        }
        .width('100%')
        .height('100%')
      }

      // AI 分析 WebView 面板（全屏遮罩）- 充满整个父容器
      this.AIAnalysisWebViewPanel()
    }
    .width('100%')
    .height('100%')
  }
}
