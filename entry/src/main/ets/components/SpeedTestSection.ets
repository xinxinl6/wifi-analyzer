// 测速页组件 - 天蓝色透明毛玻璃悬浮风格（容器组件）
// 功能：测速节点选择、真实HTTP测速、实时速度显示、历史记录
// 风格：天蓝色渐变 + 透明毛玻璃 + 悬浮卡片

import { COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER,
  COLOR_BACKGROUND, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_GAUGE_BG, COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_WHITE, COLOR_GLASS_WHITE_SOLID, COLOR_GLASS_SKY,
  COLOR_GLASS_SKY_SOLID, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_CLOUD_1, COLOR_CLOUD_2,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD, FONT_WEIGHT_NORMAL,
  SPACE_MD, SPACE_SM, SPACE_LG, SPACE_XL, SPACE_2XL,
  GAUGE_SIZE_XL, STROKE_WIDTH_3XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_XL, RADIUS_2XL, RADIUS_3XL,
  GLASS_BLUR_LG, GLASS_BLUR_XL, GLASS_BLUR_MAX,
  GLASS_SHADOW_SM, GLASS_SHADOW_MD, GLASS_SHADOW_LG, GLASS_SHADOW_XL,
  GLASS_SHADOW_2XL, GLASS_SHADOW_3XL, GLASS_SHADOW_MAX,
  TAB_BAR_SAFE_BOTTOM,
  // 暗色模式自适应工具
  adaptiveBackgroundList,
  adaptiveGlowLarge,
  adaptiveGlowMedium,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_GLASS_DARK_SURFACE,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_SHADOW_AURORA
} from '@wifi-analyzer/design-system'
import { SpeedTestResult } from '@wifi-analyzer/core'
import { SpeedTestEngine, SERVER_NODES, SpeedTestCallbacks, ServerNode } from '@wifi-analyzer/speed-test'
import { SpeedGauge } from './SpeedGauge'
import { SpeedServerSelector, SpeedServerPopup } from './SpeedServerPopup'
import { SpeedHistoryList } from './SpeedHistoryList'
import { SpeedDetailPopup, SpeedDetailCard } from './SpeedDetailPopup'
import { SpeedCurve, SpeedSample } from './SpeedCurve'
import { addToHistory, saveHistory, loadHistoryAsyncWithCallback } from '../utils/SpeedTestStorage'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { common } from '@kit.AbilityKit'

const DOMAIN = 0x0000

@Component
export struct SpeedTestSection {
  // 状态
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State selectedServerIndex: number = 0
  @State showServerPanel: boolean = false
  @State serverPopupScale: number = 0
  @State serverPopupOpacity: number = 0
  @State isTesting: boolean = false
  @State currentPhase: string = 'idle'
  @State displaySpeed: number = 0
  @State displayPing: number = 0
  @State displayJitter: number = 0
  @State displayDownloadSpeed: number = 0
  @State displayUploadSpeed: number = 0
  @State displayBufferbloatDownloadMs: number = 0
  @State displayBufferbloatUploadMs: number = 0
  @State phaseLabel: string = ''
  @State detectedNetworkType: string = ''
  @State speedSamples: SpeedSample[] = []
  @State gaugeProgress: number = 0
  @State historyList: Array<SpeedTestResult> = []
  @State showAllHistory: boolean = false
  @State showDetailPopup: boolean = false
  @State selectedResult: SpeedTestResult | null = null
  @State detailPopupScale: number = 0
  @State detailPopupOpacity: number = 0

  private engine: SpeedTestEngine = new SpeedTestEngine()

  aboutToAppear(): void {
    this.loadHistory()
  }

  aboutToDisappear(): void {
    // 防止测速中离开页面导致内存泄漏
    if (this.isTesting && this.engine.running) {
      console.info('[SpeedTest] Component destroyed, cancelling test')
      this.engine.cancel()
    }
  }

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

      // 主内容（可滚动）
      Scroll() {
        Column({ space: SPACE_LG }) {
          SpeedServerSelector({
            selectedServerIndex: this.selectedServerIndex,
            onServerSelectorClick: () => { this.showServerPanelWithAnimation() }
          })

          if (this.detectedNetworkType !== '') {
            Text(this.detectedNetworkType)
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_SKY_BLUE)
              .fontWeight(FONT_WEIGHT_BOLD)
              .padding({ left: 10, right: 10, top: 2, bottom: 2 })
              .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_SKY_TAG_BG)
              .borderRadius(6)
          }

          SpeedGauge({
            isTesting: this.isTesting,
            currentPhase: this.currentPhase,
            displaySpeed: this.displaySpeed,
            displayPing: this.displayPing,
            displayDownloadSpeed: this.displayDownloadSpeed,
            displayUploadSpeed: this.displayUploadSpeed,
            phaseLabel: this.phaseLabel,
            gaugeProgress: this.gaugeProgress
          })

          this.buildActionButton()

          if (this.currentPhase === 'done') {
            SpeedDetailCard({
              displayDownloadSpeed: this.displayDownloadSpeed,
              displayUploadSpeed: this.displayUploadSpeed,
              displayPing: this.displayPing,
              serverName: this.getServerName(),
              bufferbloatDownloadMs: this.displayBufferbloatDownloadMs,
              bufferbloatUploadMs: this.displayBufferbloatUploadMs
            })
          }

          if (!this.isTesting) {
            SpeedHistoryList({
              historyList: this.historyList,
              showAllHistory: this.showAllHistory,
              onToggleHistory: () => { this.showAllHistory = !this.showAllHistory },
              onHistoryItemClick: (item: SpeedTestResult) => {
                this.selectedResult = item
                this.showDetailPopupWithAnimation()
              }
            })
          }
        }
        .alignItems(HorizontalAlign.Center)
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: 140 })
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .layoutWeight(1)

      if (this.showServerPanel) {
        SpeedServerPopup({
          selectedServerIndex: this.selectedServerIndex,
          serverPopupScale: this.serverPopupScale,
          serverPopupOpacity: this.serverPopupOpacity,
          onClose: () => { this.hideServerPanelWithAnimation() },
          onServerSelect: (index: number) => {
            this.selectedServerIndex = index
            this.hideServerPanelWithAnimation()
          }
        })
      }

      if (this.showDetailPopup && this.selectedResult !== null) {
        SpeedDetailPopup({
          selectedResult: this.selectedResult,
          detailPopupScale: this.detailPopupScale,
          detailPopupOpacity: this.detailPopupOpacity,
          onClose: () => { this.hideDetailPopupWithAnimation() }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  // 开始/停止按钮 — 居中悬浮胶囊风格
  @Builder buildActionButton() {
    Row() {
      Text(this.isTesting ? $r('app.string.stop_test') : $r('app.string.start_test'))
        .fontSize(FONT_SIZE_2XL)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(COLOR_TEXT_GLASS_PRIMARY)
        .letterSpacing(1)
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 48, right: 48, top: 14, bottom: 14 })
    .backgroundColor(this.isTesting ? COLOR_DANGER : COLOR_SKY_BLUE)
    .borderRadius(999)
    .shadow({ radius: GLASS_SHADOW_2XL, color: this.isTesting ? COLOR_SHADOW_AURORA : COLOR_SHADOW_AURORA, offsetX: 0, offsetY: 6 })
    .onClick(() => {
      if (this.isTesting) {
        this.engine.cancel()
      } else {
        this.startSpeedTest()
      }
    })
  }

  // 显示详情弹窗（线性动画）
  private showDetailPopupWithAnimation(): void {
    this.showDetailPopup = true
    this.getUIContext().animateTo({
      duration: 280,
      curve: Curve.Linear,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {}
    }, () => {
      this.detailPopupOpacity = 1
      this.detailPopupScale = 1
    })
  }

  // 关闭详情弹窗（线性动画）
  private hideDetailPopupWithAnimation(): void {
    this.getUIContext().animateTo({
      duration: 220,
      curve: Curve.Linear,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.showDetailPopup = false
        this.selectedResult = null
        this.detailPopupScale = 0
        this.detailPopupOpacity = 0
      }
    }, () => {
      this.detailPopupOpacity = 0
      this.detailPopupScale = 0
    })
  }

  // 显示弹窗（线性动画）
  private showServerPanelWithAnimation(): void {
    this.showServerPanel = true
    this.getUIContext().animateTo({
      duration: 280,
      curve: Curve.Linear,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {}
    }, () => {
      this.serverPopupOpacity = 1
      this.serverPopupScale = 1
    })
  }

  // 关闭弹窗（线性动画）
  private hideServerPanelWithAnimation(): void {
    this.getUIContext().animateTo({
      duration: 220,
      curve: Curve.Linear,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.showServerPanel = false
        this.serverPopupScale = 0
        this.serverPopupOpacity = 0
      }
    }, () => {
      this.serverPopupOpacity = 0
      this.serverPopupScale = 0
    })
  }

  // 核心方法
  startSpeedTest(): void {
    this.isTesting = true
    this.currentPhase = 'idle'
    this.displaySpeed = 0
    this.displayPing = 0
    this.displayJitter = 0
    this.displayDownloadSpeed = 0
    this.displayUploadSpeed = 0
    this.phaseLabel = ''
    this.gaugeProgress = 0

    const serverId: string = SERVER_NODES[this.selectedServerIndex].id
    const callbacks: SpeedTestCallbacks = {
      onPhaseChanged: (phase: string): void => { this.onPhaseChanged(phase) },
      onDownloadProgress: (speed: number): void => { this.onDownloadProgress(speed) },
      onUploadProgress: (speed: number): void => { this.onUploadProgress(speed) },
      onPingResult: (ping: number, jitter: number): void => { this.onPingResult(ping, jitter) },
      onComplete: (result: SpeedTestResult): void => { this.onComplete(result) },
      onError: (error: string): void => { this.onError(error) },
      onCancelled: (): void => { this.onCancelled() }
    }

    this.speedSamples = []
    this.engine.startTest(serverId, '', callbacks)
    this.detectedNetworkType = SpeedTestEngine.getCurrentNetworkType()
  }

  private onPhaseChanged(phase: string): void {
    this.currentPhase = phase
    switch (phase) {
      case 'selecting': this.phaseLabel = 'selecting'; this.gaugeProgress = 0.02; break
      case 'ping': this.phaseLabel = 'ping'; this.gaugeProgress = 0.05; break
      case 'download':
        this.phaseLabel = 'download'
        this.gaugeProgress = 0.25
        break
      case 'upload':
        this.phaseLabel = 'upload'
        this.gaugeProgress = 0.7
        this.displaySpeed = this.displayDownloadSpeed
        break
      case 'done':
        this.phaseLabel = 'done'
        this.gaugeProgress = 1.0
        this.displaySpeed = this.displayDownloadSpeed
        break
    }
  }

  private onDownloadProgress(speed: number): void {
    this.displaySpeed = speed
    this.displayDownloadSpeed = speed
    const progress: number = Math.min(speed / 300, 0.65)
    this.gaugeProgress = 0.25 + progress * 0.45
    this.addSample(speed, 'download')
  }

  private lastSampleTime: number = 0

  private onUploadProgress(speed: number): void {
    this.displaySpeed = speed
    this.displayUploadSpeed = speed
    this.addSample(speed, 'upload')
  }

  private addSample(speedMbps: number, phase: string): void {
    const now: number = Date.now()
    // 限流：最少 400ms 采一次
    if (now - this.lastSampleTime < 400) return
    this.lastSampleTime = now
    // 最多 30 个采样点
    if (this.speedSamples.length >= 30) return
    const sample: SpeedSample = {
      timeMs: now,
      speedMbps: speedMbps,
      phase: phase
    }
    this.speedSamples = [...this.speedSamples, sample]
  }

  private onPingResult(ping: number, jitter: number): void {
    this.displayPing = ping
    this.displayJitter = jitter
    this.gaugeProgress = 0.15
  }

  private onComplete(result: SpeedTestResult): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Complete: ' + JSON.stringify(result))
    this.isTesting = false
    this.displayDownloadSpeed = result.downloadSpeed
    this.displayUploadSpeed = result.uploadSpeed
    this.displayPing = result.pingMs
    this.displayJitter = result.jitterMs
    this.displayBufferbloatDownloadMs = result.bufferbloatDownloadMs
    this.displayBufferbloatUploadMs = result.bufferbloatUploadMs
    this.displaySpeed = result.downloadSpeed
    this.currentPhase = 'done'
    this.historyList = addToHistory(this.historyList, result)
    this.doSaveHistory()
  }

  private onError(error: string): void {
    hilog.error(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Error: ' + error)
    this.isTesting = false
    this.currentPhase = 'error'
    this.phaseLabel = 'error'
  }

  private onCancelled(): void {
    this.isTesting = false
    this.currentPhase = 'idle'
    this.displaySpeed = 0
    this.phaseLabel = 'cancelled'
  }

  private getServerName(): string {
    if (this.selectedServerIndex < SERVER_NODES.length) {
      return SERVER_NODES[this.selectedServerIndex].name
    }
    return 'Unknown'
  }

  private loadHistory(): void {
    const context = this.getUIContext().getHostContext()
    if (context) {
      loadHistoryAsyncWithCallback(context as common.UIAbilityContext, (list: Array<SpeedTestResult>) => {
        this.historyList = list
      })
    }
  }

  private doSaveHistory(): void {
    const context = this.getUIContext().getHostContext()
    if (context) {
      saveHistory(this.historyList, context as common.UIAbilityContext)
    }
  }
}
