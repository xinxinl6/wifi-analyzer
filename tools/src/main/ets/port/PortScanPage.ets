// 端口扫描页面组件 — 容器组件

import promptAction from '@ohos.promptAction'
import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_MD,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_SOLID, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_LINE,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider,
  PulseIndicator
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { PortScanEngine, PortPreset, PortScanCallbacks, PortScanResult as EnginePortScanResult } from '../ports/PortScanEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import { PortIdleView } from './PortIdleView'
import { PortScanView, PortScanResult } from './PortScanView'
import { PortActionButtons } from './PortActionButtons'

interface PresetItem {
  name: string
  description: string
  portCount: number
}

@Component
export struct PortScanPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State inputText: string = ''
  @State detectedGateway: string = ''

  @State viewMode: string = 'idle'
  @State isScanning: boolean = false

  @State presetItems: PresetItem[] = []
  @State selectedPresetIndex: number = 0

  @State resultList: PortScanResult[] = []
  @State openPorts: PortScanResult[] = []
  @State scannedCount: number = 0
  @State totalPorts: number = 0
  @State currentPort: number = 0

  private engine: PortScanEngine = new PortScanEngine()

  private pulser: PulseIndicator = new PulseIndicator()

  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
      return ''
    }
  }

  aboutToAppear(): void {
    this.loadPresets()
  }

  aboutToDisappear(): void {
    this.engine.stopScan()
    this.pulser.stop()
  }

  private loadPresets(): void {
    const presets: PortPreset[] = PortScanEngine.PRESETS
    const items: PresetItem[] = []
    for (let i = 0; i < presets.length; i++) {
      const item: PresetItem = {
        name: presets[i].name,
        description: presets[i].description,
        portCount: presets[i].ports.length,
      }
      items.push(item)
    }
    this.presetItems = items
  }

  // ==================== 业务逻辑 ====================

  private validateInput(addr: string): string {
    const trimmed: string = addr.trim()
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }
    if (trimmed.length > 255) {
      return this.getString($r('app.string.err_input_too_long'))
    }
    if (ValidationPatterns.isValidIpv4(trimmed) && ValidationPatterns.isPrivateIp(trimmed)) {
      return this.getString($r('app.string.err_private_ip'))
    }
    if (!ValidationPatterns.isValidIpOrDomain(trimmed)) {
      return this.getString($r('app.string.err_invalid_ip_or_domain'))
    }
    return ''
  }

  async startScan(): Promise<void> {
    const addr: string = this.inputText.trim()
    const errorMsg: string = this.validateInput(addr)
    if (errorMsg !== '') {
      promptAction.showToast({ message: errorMsg, duration: 2000 })
      return
    }
    this.resultList = []
    this.openPorts = []
    this.scannedCount = 0
    this.totalPorts = 0
    this.currentPort = 0
    this.isScanning = true
    this.viewMode = 'scanning'
    this.pulser.start(600)

    const preset: PortPreset = PortScanEngine.PRESETS[this.selectedPresetIndex]
    this.totalPorts = preset.ports.length

    const callbacks: PortScanCallbacks = {
      onProgress: (scanned: number, total: number, currentPortNum: number): void => {
        this.scannedCount = scanned
        this.currentPort = currentPortNum
      },
      onPortFound: (port: EnginePortScanResult): void => {
        const result: PortScanResult = {
          port: port.port,
          service: port.service,
          status: port.status === 'error' ? 'unknown' : port.status
        }
        this.openPorts.push(result)
        const refreshed: PortScanResult[] = []
        for (let i = 0; i < this.openPorts.length; i++) {
          refreshed.push(this.openPorts[i])
        }
        this.openPorts = refreshed
      },
      onComplete: (results: EnginePortScanResult[]): void => {
        const mappedList: PortScanResult[] = []
        for (let i = 0; i < results.length; i++) {
          const r = results[i]
          const item: PortScanResult = { port: r.port, service: r.service, status: r.status === 'error' ? 'unknown' : r.status }
          mappedList.push(item)
        }
        this.resultList = mappedList
        this.isScanning = false
        this.pulser.stop()
        this.viewMode = 'result'
      },
      onError: (message: string): void => {
        this.isScanning = false
        this.pulser.stop()
        if (this.resultList.length > 0) {
          this.viewMode = 'result'
        } else {
          this.viewMode = 'idle'
        }
      },
    }

    await this.engine.scan(addr, preset.ports, 2000, callbacks)
  }

  stopScan(): void {
    this.engine.stopScan()
    this.isScanning = false
    this.pulser.stop()
    if (this.resultList.length > 0) {
      this.viewMode = 'result'
    } else {
      this.viewMode = 'idle'
    }
  }

  goBackToIdle(): void {
    this.stopScan()
    this.viewMode = 'idle'
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
          BackButtonGlass({
            onBack: () => {
              if (this.viewMode !== 'idle') {
                this.stopScan()
                this.viewMode = 'idle'
              } else {
                RouterManager.goBack()
              }
            }
          })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          Column({ space: 0 }) {
            PortIdleView({
              isDarkMode: this.isDarkMode,
              inputText: this.inputText,
              presetItems: this.presetItems,
              selectedPresetIndex: this.selectedPresetIndex,
              onInputChange: (value: string) => { this.inputText = value },
              onPresetSelect: (index: number) => { this.selectedPresetIndex = index },
              onStartScan: () => this.startScan()
            })
          }
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
              .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
            TransitionEffect.OPACITY.animation({ duration: 200 })
          ))
        } else {
          Column({ space: 0 }) {
            PortScanView({
              isDarkMode: this.isDarkMode,
              inputText: this.inputText,
              isScanning: this.isScanning,
              viewMode: this.viewMode,
              scannedCount: this.scannedCount,
              totalPorts: this.totalPorts,
              currentPort: this.currentPort,
              openPorts: this.openPorts,
              pulseOpacity: this.pulser.opacity,
              onGoBack: () => this.goBackToIdle(),
              onStop: () => this.stopScan(),
              onRestart: () => this.startScan()
            })

            PortActionButtons({
              isDarkMode: this.isDarkMode,
              isScanning: this.isScanning,
              onGoBack: () => this.goBackToIdle(),
              onStop: () => this.stopScan(),
              onRestart: () => this.startScan()
            })
          }
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
              .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
            TransitionEffect.OPACITY.animation({ duration: 200 })
          ))
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }
}
