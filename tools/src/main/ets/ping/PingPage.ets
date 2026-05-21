// Ping 测试页面 — 容器组件

import promptAction from '@ohos.promptAction'
import {
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_SOLID, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_LINE,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL, GLASS_SHADOW_3XL, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider,
  PulseIndicator
} from '@wifi-analyzer/design-system'
import {
  PingEngine, PingResult, PingStats, PingConfig
} from '../ping/PingEngine'
import { RouterManager, ValidationPatterns, DnsConfig, DiagnosticsConfig } from '@wifi-analyzer/core'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { PingIdleView } from './PingIdleView'
import { PingResultView } from './PingResultView'
import { PingActionButtons } from './PingActionButtons'

const DOMAIN = 0x0000

// ==================== 接口定义 ====================

interface QuickTargetItem {
  name: string | Resource
  address: string
}

// ==================== 容器组件 ====================

@Component
export struct PingPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State detectedGateway: string = ''
  @State inputText: string = ''
  @State viewMode: string = 'idle'

  // 推荐目标
  private recommendItems: QuickTargetItem[] = [
    { name: $r('app.string.gateway'), address: '' },
    { name: 'DNS', address: DnsConfig.ALI_DNS },
    { name: $r('app.string.baidu'), address: 'baidu.com' }
  ]

  @State pingResults: PingResult[] = []
  @State pingStats: PingStats = {
    sent: 0, received: 0, lost: 0, lossRate: 0,
    minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0
  }
  @State targetHost: string = ''
  @State resolvedIp: string = ''
  @State isRunning: boolean = false
  @State progress: string = '0/0'

  private engine: PingEngine = new PingEngine()
  private pulser: PulseIndicator = new PulseIndicator()

  aboutToAppear(): void {
    this.detectGateway()
  }

  aboutToDisappear(): void {
    this.engine.stopPing()
    this.pulser.stop()
  }

  // 获取字符串资源的辅助方法
  private getStringSync(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
      return ''
    }
  }

  // ==================== 网关检测 ====================
  private detectGateway(): void {
    this.engine.resolveHost(DiagnosticsConfig.DEFAULT_GATEWAY)
      .then((gw: string) => {
        this.detectedGateway = gw
        if (this.recommendItems.length > 0) {
          this.recommendItems[0].address = gw || DiagnosticsConfig.DEFAULT_GATEWAY
        }
      })
  }

  // ==================== 业务逻辑 ====================

  // 验证目标地址输入
  private validateTarget(addr: string): string {
    const trimmed: string = addr.trim()

    if (trimmed.length === 0) {
      return this.getStringSync($r('app.string.ping_enter_target'))
    }

    if (trimmed.length > 255) {
      return this.getStringSync($r('app.string.ping_addr_too_long'))
    }

    if (!ValidationPatterns.isValidIpOrDomain(trimmed)) {
      return this.getStringSync($r('app.string.ping_invalid_format'))
    }

    return ''
  }

  onRecommendTap(index: number): void {
    const item = this.recommendItems[index]
    if (item.address) {
      this.inputText = item.address
    }
  }

  startPing(): void {
    const addr: string = this.inputText.trim()

    // 输入验证
    const errorMsg: string = this.validateTarget(addr)
    if (errorMsg !== '') {
      promptAction.showToast({
        message: errorMsg,
        duration: 2000
      })
      return
    }

    this.targetHost = addr
    this.resolvedIp = addr
    this.pingResults = []
    this.pingStats = {
      sent: 0, received: 0, lost: 0, lossRate: 0,
      minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0
    }
    this.isRunning = true
    this.viewMode = 'pinging'
    this.pulser.start()
    this.progress = '0/4'

    const config: PingConfig = PingEngine.getDefaultConfig(addr)
    this.engine.startPing(config, {
      onResult: (result: PingResult): void => {
        this.pingResults = [...this.pingResults, result]
        this.pingStats = PingEngine.calcStats(this.pingResults)
        if (this.resolvedIp !== result.address && result.address !== addr) {
          this.resolvedIp = result.address
        }
      },
      onProgress: (sent: number, received: number): void => {
        this.progress = `${sent}/4`
      },
      onComplete: (results: PingResult[], stats: PingStats): void => {
        this.pingResults = results
        this.pingStats = stats
        this.isRunning = false
        this.pulser.stop()
        this.viewMode = 'completed'
      },
      onError: (message: string): void => {
        hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingPage] Error: ' + message)
        this.isRunning = false
        this.pulser.stop()
        this.viewMode = 'completed'
        promptAction.showToast({
          message: this.getStringSync($r('app.string.ping_failed')) + message,
          duration: 3000
        })
      }
    })
  }

  stopPing(): void {
    this.engine.stopPing()
    this.isRunning = false
    this.pulser.stop()
    if (this.pingResults.length > 0) {
      this.viewMode = 'completed'
    } else {
      this.viewMode = 'idle'
    }
  }

  goBackToIdle(): void {
    this.viewMode = 'idle'
    this.inputText = this.targetHost
  }

  // ==================== 页面入口 ====================
  build() {
    Stack() {
      // ===== Aurora 天蓝渐变背景 =====
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })

      // 主内容
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          PingIdleView({
            isDarkMode: this.isDarkMode,
            inputText: this.inputText,
            detectedGateway: this.detectedGateway,
            recommendItems: this.recommendItems,
            onInputChange: (value: string) => { this.inputText = value },
            onSubmit: () => this.startPing(),
            onRecommendTap: (index: number) => this.onRecommendTap(index)
          })
        } else {
          Column({ space: SPACE_LG }) {
            PingResultView({
              isDarkMode: this.isDarkMode,
              targetHost: this.targetHost,
              resolvedIp: this.resolvedIp,
              pingResults: this.pingResults,
              pingStats: this.pingStats,
              isRunning: this.isRunning,
              viewMode: this.viewMode,
              progress: this.progress,
              pulseOpacity: this.pulser.opacity,
              onGoBack: () => this.goBackToIdle(),
              onRestart: () => this.startPing(),
              onStop: () => this.stopPing()
            })

            if (this.viewMode !== 'idle') {
              PingActionButtons({
                isRunning: this.isRunning,
                onStop: () => this.stopPing(),
                onRestart: () => this.startPing()
              })
            }
          }
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }
}
