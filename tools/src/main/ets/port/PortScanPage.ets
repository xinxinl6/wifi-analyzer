// 端口扫描页面组件 — 天蓝色透明毛玻璃悬浮风格

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
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BackButtonGlass, BackButtonCapsule, PulseIndicator } from '@wifi-analyzer/design-system'
import { PortScanEngine, PortScanResult, PortPreset, PortScanCallbacks } from '../ports/PortScanEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'

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
    } catch {
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

  getProgressPercent(): number {
    if (this.totalPorts === 0) return 0
    return Math.round((this.scannedCount / this.totalPorts) * 100)
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'open': return COLOR_SUCCESS
      case 'closed': return COLOR_DANGER
      case 'filtered': return COLOR_WARNING
      default: return COLOR_TEXT_TERTIARY
    }
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'open': return this.getString($r('app.string.port_open'))
      case 'closed': return this.getString($r('app.string.port_closed'))
      case 'filtered': return this.getString($r('app.string.timeout_status'))
      default: return this.getString($r('app.string.unknown'))
    }
  }

  getStatusTextResource(status: string): Resource {
    switch (status) {
      case 'open': return $r('app.string.port_open')
      case 'closed': return $r('app.string.port_closed')
      case 'filtered': return $r('app.string.timeout_status')
      default: return $r('app.string.unknown')
    }
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
      onProgress: (scanned: number, total: number, currentPort: number): void => {
        this.scannedCount = scanned
        this.currentPort = currentPort
      },
      onPortFound: (port: PortScanResult): void => {
        this.openPorts.push(port)
        const refreshed: PortScanResult[] = []
        for (let i = 0; i < this.openPorts.length; i++) {
          refreshed.push(this.openPorts[i])
        }
        this.openPorts = refreshed
      },
      onComplete: (results: PortScanResult[]): void => {
        this.resultList = results
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
          this.IdleView()
        } else {
          this.ScanView()
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

  // ==================== 初始视图 ====================
  @Builder IdleView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.SearchBarSection()
        this.PresetSelector()
        this.FeatureCard()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_port')).width(20).height(20).fillColor(COLOR_PURPLE)

      TextInput({ placeholder: $r('app.string.input_ip_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.inputText = value })

      Row() {
        Text($r('app.string.scan_action'))
          .fontSize(FONT_SIZE_SM)
          .fontColor('#FFFFFF')
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_PURPLE)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.startScan())
    }
    .width('100%').padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 预设方案选择
  @Builder PresetSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.scan_preset')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Column({ space: 0 }) {
        ForEach(this.presetItems, (preset: PresetItem, index: number) => {
          this.PresetRow(preset, index)
        }, (preset: PresetItem, index: number): string => String(index))
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder PresetRow(preset: PresetItem, index: number) {
    Row({ space: SPACE_MD }) {
      Circle()
        .width(20).height(20)
        .fill(this.selectedPresetIndex === index ? COLOR_PURPLE : Color.Transparent)
        .border({ width: 2, color: this.selectedPresetIndex === index ? COLOR_PURPLE : adaptiveDivider(this.isDarkMode) })

      Column({ space: 2 }) {
        Text(preset.name)
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_MEDIUM)
        Text() {
          Span(preset.description + ' (')
          Span(String(preset.portCount))
          Span(' ')
          Span($r('app.string.port_count_ports'))
          Span(')')
        }
        .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%').padding({ top: 14, bottom: 14 })
    .border({
      width: index < this.presetItems.length - 1 ? 0.5 : 0,
      color: adaptiveDivider(this.isDarkMode)
    })
    .stateStyles({ pressed: { opacity: 0.8 } })
    .onClick(() => { this.selectedPresetIndex = index })
  }

  // 功能说明
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.port_scan_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('🔍', '端口检测', '检测常用端口是否开放')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', '安全扫描', '发现潜在安全风险')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📈', '结果导出', '查看开放端口详情')
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(emoji: string, title: string, desc: string) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? 'rgba(147,51,234,0.15)' : COLOR_GLASS_SKY_ACTIVE)
        Text(emoji).fontSize(16)
      }

      Column({ space: 3 }) {
        Text(title)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
  }

  // ==================== 扫描视图 ====================
  @Builder ScanView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.TargetInfoCard()
        if (this.isScanning) {
          this.ProgressCard()
        }
        if (this.openPorts.length > 0) {
          this.OpenPortsCard()
        }
        this.ActionButtons()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 目标信息卡
  @Builder TargetInfoCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? 'rgba(147,51,234,0.15)' : COLOR_GLASS_SKY_LIGHT)
          .opacity(this.isScanning ? this.pulser.opacity : 1.0)
        Circle().width(36).height(36)
          .fill(this.isScanning ? COLOR_PURPLE : COLOR_PURPLE)
        Image($r('app.media.ic_port')).width(18).height(18).fillColor('#FFFFFF')
      }

      Column({ space: 4 }) {
        Text(this.inputText)
          .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.isScanning) {
          Row({ space: 4 }) {
            Circle().width(5).height(5).fill(COLOR_PURPLE).opacity(this.pulser.opacity)
            Text($r('app.string.scanning_ports'))
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_PURPLE)
          }
        } else if (this.viewMode === 'result') {
          Row({ space: 4 }) {
            Circle().width(5).height(5).fill(COLOR_SUCCESS)
            Text($r('app.string.scan_complete'))
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 进度卡片
  @Builder ProgressCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.scan_progress'))
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text(String(this.scannedCount) + '/' + String(this.totalPorts))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_PURPLE)
      }
      .width('100%')

      // 进度条
      Row() {
        Column()
          .height(6)
          .borderRadius(3)
          .backgroundColor(COLOR_PURPLE)
          .width(String(this.getProgressPercent()) + '%')
        Blank()
      }
      .width('100%')
      .height(6)
      .borderRadius(3)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : COLOR_GLASS_SKY_LIGHT)

      Text($r('app.string.current_port') + ': ' + (this.currentPort > 0 ? String(this.currentPort) : '...'))
        .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
  }

  // 开放端口列表
  @Builder OpenPortsCard() {
    Column({ space: 0 }) {
      Row() {
        Row({ space: 6 }) {
          Text('📊').fontSize(14)
          Text($r('app.string.open_ports'))
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        Text() {
          Span(String(this.openPorts.length))
          Span(' ')
          Span($r('app.string.port_count_ports'))
        }
        .fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .backgroundColor(this.isDarkMode ? 'rgba(16,185,129,0.15)' : COLOR_GLASS_SKY_TAG_BG)
        .borderRadius(999)
      }
      .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      Column({ space: 0 }) {
        ForEach(this.openPorts, (port: PortScanResult, index: number) => {
          this.PortItem(port, index)
        }, (port: PortScanResult, index: number): string => String(index + '_' + port.port))
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  @Builder PortItem(port: PortScanResult, index: number) {
    Row({ space: SPACE_SM }) {
      Text(String(port.port))
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_PURPLE).fontWeight(FONT_WEIGHT_BOLD)
        .width(50).textAlign(TextAlign.Center)

      Text(port.service)
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextPrimary(this.isDarkMode))
        .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.getStatusText(port.status))
        .fontSize(FONT_SIZE_XS).fontColor(this.getStatusColor(port.status))
    }
    .width('100%').padding({ top: 8, bottom: 8 })

    if (index < this.openPorts.length - 1) {
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
    }
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      if (this.isScanning) {
        Row() {
          Text($r('app.string.stop_action')).fontSize(FONT_SIZE_MD).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor('rgba(239,68,68,0.85)')
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(239,68,68,0.5)' : 'rgba(239,68,68,0.35)', offsetX: 0, offsetY: 5 })
        .onClick(() => this.stopScan())
      } else {
        Row() {
          Text($r('app.string.re_scan')).fontSize(FONT_SIZE_MD).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor(COLOR_PURPLE)
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
        .onClick(() => this.startScan())
      }
    }
    .width('100%')
  }
}
