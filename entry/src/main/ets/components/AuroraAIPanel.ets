// ============================================
// Aurora WiFi V2 — AI 面板组件
// API Level: 23+
// ============================================

import {
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_AURORA_GLOW,
  // 毛玻璃色彩
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  // 功能色
  COLOR_SUCCESS,
  // 文字色
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY
} from '@wifi-analyzer/design-system'
import { AIFeatures, AIFeatureItem, AIMessage } from './AIConfig'

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
        content: $r('app.string.ai_welcome_message'),
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

  private generateAIResponse(userInput: string): string | Resource {
    const input = userInput.toLowerCase()
    if (input.includes('信号') || input.includes('wifi')) {
      return $r('app.string.ai_response_signal')
    } else if (input.includes('信道') || input.includes('channel')) {
      return $r('app.string.ai_response_channel')
    } else if (input.includes('速度') || input.includes('测速')) {
      return $r('app.string.ai_response_speed')
    } else {
      return $r('app.string.ai_response_default')
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
                .fontColor(COLOR_SUCCESS)
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
