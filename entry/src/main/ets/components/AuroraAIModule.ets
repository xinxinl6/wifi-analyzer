// ============================================
// Aurora WiFi V2 — AI 智能助手模块
// API Level: 23+
// ============================================

import {
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_AURORA_GLOW,
  // 毛玻璃色彩
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  // 文字色
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  // 阴影
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_AURORA,
  // 动效
  DURATION_FAST,
  DURATION_NORMAL,
  AnimationTapScale
} from '@wifi-analyzer/design-system'
import { getAIAnalysisUrl, buildNetworkQuery, WifiNetworkInfo } from '../utils/XiaoYiHelper'
import web_webview from '@ohos.web.webview'
import { promptAction } from '@kit.ArkUI'

// ============================================
// AI 消息数据结构
// ============================================

interface AIMessage {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: number
  type?: 'text' | 'analysis' | 'suggestion' | 'warning'
}

// ============================================
// AI 功能配置
// ============================================

interface AIFeatureItem {
  enabled: boolean
  title: ResourceStr
  icon: Resource
  description: ResourceStr
}

interface AIFeatureMap {
  networkHealth: AIFeatureItem
  channelRecommend: AIFeatureItem
  anomalyAlert: AIFeatureItem
  optimizationTip: AIFeatureItem
}

export const AIFeatures: AIFeatureMap = {
  // 网络健康诊断
  networkHealth: {
    enabled: true,
    title: 'ai_feature_network_health',
    icon: $r('app.media.ic_health'),
    description: 'ai_feature_network_health_desc'
  },
  // 智能信道推荐
  channelRecommend: {
    enabled: true,
    title: 'ai_feature_channel_recommend',
    icon: $r('app.media.ic_channel'),
    description: 'ai_feature_channel_recommend_desc'
  },
  // 异常预警
  anomalyAlert: {
    enabled: true,
    title: 'ai_feature_anomaly_alert',
    icon: $r('app.media.ic_warning'),
    description: 'ai_feature_anomaly_alert_desc'
  },
  // 优化建议
  optimizationTip: {
    enabled: true,
    title: 'ai_feature_optimization_tip',
    icon: $r('app.media.ic_tip'),
    description: 'ai_feature_optimization_tip_desc'
  }
}

// AI响应消息接口
interface AIMessageResponses {
  signal: string
  channel: string
  speed: string
  defaultMsg: string
}

// AI消息集合接口
interface AIMessagesMap {
  launchFailed: string
  welcome: string
  panelTitle: string
  onlineStatus: string
  placeholder: string
  responses: AIMessageResponses
}

// ============================================
// AI 消息配置（便于国际化）
// ============================================
export const AIMessages: AIMessagesMap = {
  // FAB 按钮失败消息
  launchFailed: 'ai_launch_failed',

  // 欢迎消息
  welcome: 'ai_welcome_message',

  // 面板标题
  panelTitle: 'ai_panel_title',

  // 在线状态
  onlineStatus: 'ai_online_status',

  // 输入占位符
  placeholder: 'ai_placeholder',

  // AI 响应消息
  responses: {
    signal: 'ai_response_signal',
    channel: 'ai_response_channel',
    speed: 'ai_response_speed',
    defaultMsg: 'ai_response_default'
  }
}

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
      message: '正在为您分析网络...',
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
          .backgroundColor('rgba(0,0,0,0.6)')
          .onClick(() => {
            this.closeAIAnalysis()
          })

        // WebView 面板内容
        Column({ space: 0 }) {
          // 顶部拖拽指示条
          Column()
            .width(40)
            .height(4)
            .backgroundColor('rgba(148,163,184,0.4)')
            .borderRadius(2)
            .margin({ top: 12, bottom: 8 })

          // 标题栏
          Row() {
            Text('网络优化分析')
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
              Text('正在加载...')
                .fontSize(14)
                .fontColor(COLOR_TEXT_GLASS_SECONDARY)
                .margin({ left: 8 })
            }
            .padding(16)
            .width('100%')
          }

          // WebView 内容
          Web({ src: this.aiWebViewUrl, controller: this.aiAnalysisController })
            .width('100%')
            .layoutWeight(1)
            .onPageBegin(() => {
              this.aiLoading = true
            })
            .onPageEnd(() => {
              this.aiLoading = false
            })
            .onErrorReceive((event) => {
              console.error('WebView error: ' + (event?.error?.getErrorInfo() || 'Unknown error'))
              this.aiLoading = false
            })
        }
        .width('100%')
        .height('85%')
        .backgroundColor('rgba(20,38,72,0.98)')
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
            .fill(`rgba(74,144,217,0.15)`)

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

// ============================================
// AI 助手面板
// ============================================

@Component
export struct AuroraAIPanel {
  @Prop panelOpen: boolean = false

  @State private panelHeight: number = 0
  @State private messageList: AIMessage[] = []
  @State private inputText: string = ''
  @State private isTyping: boolean = false

  private panelClose: () => void = () => {}

  private getFeatureList(): AIFeatureItem[] {
    return [
      AIFeatures.networkHealth,
      AIFeatures.channelRecommend,
      AIFeatures.anomalyAlert,
      AIFeatures.optimizationTip
    ]
  }

  aboutToAppear(): void {
    // 初始化欢迎消息
    this.messageList = [
      {
        id: 'welcome',
        role: 'assistant',
        content: $r('app.string.ai_welcome_message').toString(),
        timestamp: Date.now(),
        type: 'text'
      }
    ]
  }

  private togglePanel(): void {
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.panelHeight = this.panelOpen ? 0 : 500
    })
  }

  private sendMessage(): void {
    if (this.inputText.trim() === '') return

    const userMsg: AIMessage = {
      id: `user_${Date.now()}`,
      role: 'user',
      content: this.inputText,
      timestamp: Date.now()
    }

    this.messageList.push(userMsg)
    this.inputText = ''
    this.isTyping = true

    // 模拟 AI 响应
    setTimeout(() => {
      const aiMsg: AIMessage = {
        id: `ai_${Date.now()}`,
        role: 'assistant',
        content: this.generateAIResponse(userMsg.content),
        timestamp: Date.now(),
        type: 'analysis'
      }
      this.messageList.push(aiMsg)
      this.isTyping = false
    }, 1500)
  }

  private generateAIResponse(userInput: string): string {
    const input = userInput.toLowerCase()
    if (input.includes('信号') || input.includes('wifi')) {
      return $r('app.string.ai_response_signal').toString()
    } else if (input.includes('信道') || input.includes('channel')) {
      return $r('app.string.ai_response_channel').toString()
    } else if (input.includes('速度') || input.includes('测速')) {
      return $r('app.string.ai_response_speed').toString()
    } else {
      return $r('app.string.ai_response_default').toString()
    }
  }

  @Builder
  MessageBubble(msg: AIMessage) {
    Row() {
      if (msg.role === 'assistant') {
        // AI 头像
        Circle()
          .width(28)
          .height(28)
          .fill(COLOR_AURORA_PRIMARY)
          .margin({ right: 8 })
        Image($r('app.media.ic_ai_assistant'))
          .width(14)
          .height(14)
          .fillColor('#FFFFFF')
          .position({ x: 7, y: 7 })
      }

      Column() {
        Text(msg.content)
          .fontSize(14)
          .fontColor(COLOR_TEXT_GLASS_PRIMARY)
          .lineHeight(20)
      }
      .layoutWeight(1)
      .padding(12)
      .backgroundColor(msg.role === 'user' ? COLOR_GLASS_AURORA : COLOR_GLASS_SURFACE)
      .borderRadius(16)
      .alignItems(msg.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)

      if (msg.role === 'user') {
        // 用户头像
        Circle()
          .width(28)
          .height(28)
          .fill(COLOR_GLASS_SURFACE)
          .margin({ left: 8 })
        Image($r('app.media.ic_user'))
          .width(14)
          .height(14)
          .fillColor(COLOR_TEXT_GLASS_SECONDARY)
          .position({ x: 7, y: 7 })
      }
    }
    .width('100%')
    .justifyContent(msg.role === 'user' ? FlexAlign.End : FlexAlign.Start)
  }

  @Builder
  QuickActions() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(this.getFeatureList(), (feature: AIFeatureItem) => {
          Column() {
            Image(feature.icon)
              .width(24)
              .height(24)
              .fillColor(COLOR_AURORA_PRIMARY)
            Text($r(`app.string.${feature.title}`))
              .fontSize(11)
              .fontColor(COLOR_TEXT_GLASS_SECONDARY)
              .margin({ top: 4 })
          }
          .padding(12)
          .backgroundColor(COLOR_GLASS_SURFACE)
          .borderRadius(12)
          .onClick(() => {
            this.inputText = $r(`app.string.${feature.title}`).toString()
          })
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(72)
    .scrollBar(BarState.Off)
  }

  build() {
    Column() {
      // 面板内容
      Column() {
        // 标题栏
        Row() {
          Row({ space: 10 }) {
            // AI 头像
            Stack({ alignContent: Alignment.Center }) {
              Circle()
                .width(36)
                .height(36)
                .fill(COLOR_AURORA_PRIMARY)
              Image($r('app.media.ic_ai_assistant'))
                .width(20)
                .height(20)
                .fillColor('#FFFFFF')
            }

            Column() {
              Text($r('app.string.ai_panel_title'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLOR_TEXT_GLASS_PRIMARY)
              Text($r('app.string.ai_online_status'))
                .fontSize(11)
                .fontColor('#00D97E')
            }
          }

          Blank()

          // 关闭按钮
          Image($r('app.media.ic_close'))
            .width(24)
            .height(24)
            .fillColor(COLOR_TEXT_GLASS_TERTIARY)
            .onClick(() => {
              this.panelClose()
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 12 })

        Divider()
          .color(COLOR_GLASS_BORDER_LIGHT)

        // 消息列表
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.messageList, (msg: AIMessage) => {
              this.MessageBubble(msg)
            })

            // 打字指示器
            if (this.isTyping) {
              Row() {
                Circle()
                  .width(8)
                  .height(8)
                  .backgroundColor(COLOR_AURORA_LIGHT)
                Circle()
                  .width(8)
                  .height(8)
                  .backgroundColor(COLOR_AURORA_PRIMARY)
                Circle()
                  .width(8)
                  .height(8)
                  .backgroundColor(COLOR_AURORA_GLOW)
              }
              .width(48)
              .height(32)
              .padding(8)
              .backgroundColor(COLOR_GLASS_SURFACE)
              .borderRadius(16)
            }
          }
          .padding({ left: 16, right: 16, top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // 快速功能入口
        this.QuickActions()

        Divider()
          .color(COLOR_GLASS_BORDER_LIGHT)

        // 输入区
        Row({ space: 12 }) {
          TextInput({ placeholder: $r('app.string.ai_placeholder'), text: this.inputText })
            .width('100%')
            .height(44)
            .padding({ left: 16, right: 16 })
            .backgroundColor(COLOR_GLASS_SURFACE_HIGH)
            .borderRadius(22)
            .border({
              width: 1,
              color: COLOR_GLASS_BORDER_LIGHT,
              radius: 22
            })
            .fontColor(COLOR_TEXT_GLASS_PRIMARY)
            .placeholderColor(COLOR_TEXT_GLASS_TERTIARY)
            .onChange((value: string) => {
              this.inputText = value
            })
            .onSubmit(() => {
              this.sendMessage()
            })

          // 发送按钮
          Circle()
            .width(44)
            .height(44)
            .fill(COLOR_AURORA_PRIMARY)
            .onClick(() => {
              this.sendMessage()
            }) {
            Image($r('app.media.ic_send'))
              .width(20)
              .height(20)
              .fillColor('#FFFFFF')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COLOR_GLASS_CARD)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .border({
        width: 1,
        color: COLOR_GLASS_BORDER_LIGHT,
        radius: { topLeft: 24, topRight: 24 }
      })
    }
    .width('100%')
    .height(this.panelHeight)
    .clip(true)
  }
}

// ============================================
// AI 网络分析卡片
// ============================================

@Component
export struct AuroraAIAnalysisCard {
  @Prop cardTitle: string = ''
  @Prop analysisResult: string = ''
  @Prop cardSuggestion: string = ''
  @Prop healthScore: number = 85 // 0-100
  @Prop cardType: string = 'analysis'

  private getScoreColor(): string {
    if (this.healthScore >= 80) return '#00D97E'
    if (this.healthScore >= 60) return '#FBBF24'
    return '#F87171'
  }

  private getTypeIcon(): Resource {
    switch (this.cardType) {
      case 'warning': return $r('app.media.ic_warning')
      case 'suggestion': return $r('app.media.ic_tip')
      default: return $r('app.media.ic_ai_assistant')
    }
  }

  private getTypeBgColor(): string {
    switch (this.cardType) {
      case 'warning': return 'rgba(248,113,113,0.15)'
      case 'suggestion': return 'rgba(74,144,217,0.15)'
      default: return 'rgba(0,217,126,0.15)'
    }
  }

  build() {
    Column({ space: 16 }) {
      // 标题行
      Row({ space: 12 }) {
        // 图标
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(40)
            .height(40)
            .fill(this.getTypeBgColor())
          Image(this.getTypeIcon())
            .width(20)
            .height(20)
            .fillColor(this.cardType === 'warning' ? '#F87171' : COLOR_AURORA_PRIMARY)
        }

        Column({ space: 2 }) {
          Text(this.cardTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLOR_TEXT_GLASS_PRIMARY)
          Text(this.analysisResult)
            .fontSize(13)
            .fontColor(COLOR_TEXT_GLASS_SECONDARY)
        }

        Blank()

        // 健康分数
        if (this.healthScore > 0) {
          Column() {
            Text(String(this.healthScore))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getScoreColor())
            Text('分')
              .fontSize(10)
              .fontColor(COLOR_TEXT_GLASS_TERTIARY)
          }
        }
      }

      // 建议内容
      if (this.cardSuggestion !== '') {
        Row() {
          Image($r('app.media.ic_tip'))
            .width(16)
            .height(16)
            .fillColor(COLOR_AURORA_LIGHT)
          Text(this.cardSuggestion)
            .fontSize(13)
            .fontColor(COLOR_TEXT_GLASS_SECONDARY)
            .layoutWeight(1)
            .margin({ left: 8 })
        }
        .padding(12)
        .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
        .borderRadius(12)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLOR_GLASS_CARD)
    .borderRadius(16)
    .border({
      width: 1,
      color: this.cardType === 'warning' ? 'rgba(248,113,113,0.3)' : COLOR_GLASS_BORDER_LIGHT,
      radius: 16
    })
  }
}

// ============================================
// 导出 AI 模块
// ============================================

interface AuroraAIModuleExport {
  AIFabButton: object
  AIPanel: object
  AIAnalysisCard: object
  features: AIFeatureMap
  messages: AIMessagesMap
}

export const AuroraAIModule: AuroraAIModuleExport = {
  AIFabButton: AuroraAIFabButton,
  AIPanel: AuroraAIPanel,
  AIAnalysisCard: AuroraAIAnalysisCard,
  features: AIFeatures,
  messages: AIMessages
}
