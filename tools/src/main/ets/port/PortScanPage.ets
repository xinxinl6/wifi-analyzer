// 端口扫描页面组件
// 界面：搜索栏 + 预设方案选择 + 扫描进度 + 端口状态列表

import promptAction from '@ohos.promptAction'
import {
  COLOR_PRIMARY, COLOR_PRIMARY_LIGHT, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE, COLOR_PINK, COLOR_CYAN,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_SM, BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
} from '@wifi-analyzer/design-system'
import { BackButtonCapsule } from '@wifi-analyzer/design-system'
import { PortScanEngine, PortScanResult, PortScanCallbacks, PortPreset } from '../ports/PortScanEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'

// ==================== 接口定义 ====================

interface PresetItem {
  name: string
  description: string
  portCount: number
}

// ==================== 组件 ====================

@Component
export struct PortScanPage {
  // 输入
  @State inputText: string = ''
  @State detectedGateway: string = ''

  // UI 状态：'idle' | 'scanning' | 'result'
  @State viewMode: string = 'idle'
  @State isScanning: boolean = false

  // 预设方案
  @State presetItems: PresetItem[] = []
  @State selectedPresetIndex: number = 0

  // 扫描数据
  @State resultList: PortScanResult[] = []
  @State openPorts: PortScanResult[] = []
  @State scannedCount: number = 0
  @State totalPorts: number = 0
  @State currentPort: number = 0

  // 引擎
  private engine: PortScanEngine = new PortScanEngine()

  // 脉冲动画
  @State pulseOpacity: number = 1.0
  private pulseTimerId: number = -1

  // 获取资源字符串的辅助方法
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
    this.detectGateway()
  }

  aboutToDisappear(): void {
    this.engine.stopScan()
    this.stopPulse()
  }

  // 加载预设
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

  // 检测网关（预留）
  private detectGateway(): void {
    // 端口扫描不需要网关检测
  }

  // 脉冲动画
  private startPulse(): void {
    this.pulseTimerId = setInterval((): void => {
      this.pulseOpacity = this.pulseOpacity === 1.0 ? 0.3 : 1.0
    }, 600)
  }

  private stopPulse(): void {
    if (this.pulseTimerId >= 0) {
      clearInterval(this.pulseTimerId)
      this.pulseTimerId = -1
    }
    this.pulseOpacity = 1.0
  }

  // 获取进度百分比
  getProgressPercent(): number {
    if (this.totalPorts === 0) return 0
    return Math.round((this.scannedCount / this.totalPorts) * 100)
  }

  // 获取状态颜色
  getStatusColor(status: string): string {
    switch (status) {
      case 'open': return COLOR_SUCCESS
      case 'closed': return COLOR_DANGER
      case 'filtered': return COLOR_WARNING
      default: return COLOR_TEXT_TERTIARY
    }
  }

  // 获取状态文字（Resource 类型，用于 i18n）
  getStatusTextResource(status: string): Resource {
    switch (status) {
      case 'open': return $r('app.string.port_open')
      case 'closed': return $r('app.string.port_closed')
      case 'filtered': return $r('app.string.timeout_status')
      default: return $r('app.string.unknown')
    }
  }

  // 获取状态文字（兼容字符串）
  getStatusText(status: string): string {
    switch (status) {
      case 'open': return this.getString($r('app.string.port_status_open'))
      case 'closed': return this.getString($r('app.string.port_status_closed'))
      case 'filtered': return this.getString($r('app.string.port_status_filtered'))
      default: return this.getString($r('app.string.unknown'))
    }
  }

  // ==================== 业务逻辑 ====================

  // 验证输入
  private validateInput(addr: string): string {
    const trimmed: string = addr.trim()

    // 检查是否为空
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }

    // 检查长度限制（域名/IP最大255字符）
    if (trimmed.length > 255) {
      return this.getString($r('app.string.err_input_too_long'))
    }

    // 检查是否为内网IP（安全限制）
    if (ValidationPatterns.isValidIpv4(trimmed) && ValidationPatterns.isPrivateIp(trimmed)) {
      return this.getString($r('app.string.err_private_ip'))
    }

    // 验证IP或域名格式
    if (!ValidationPatterns.isValidIpOrDomain(trimmed)) {
      return this.getString($r('app.string.err_invalid_ip_or_domain'))
    }

    return ''
  }

  async startScan(): Promise<void> {
    const addr: string = this.inputText.trim()

    // 输入验证
    const errorMsg: string = this.validateInput(addr)
    if (errorMsg !== '') {
      promptAction.showToast({
        message: errorMsg,
        duration: 2000
      })
      return
    }

    this.resultList = []
    this.openPorts = []
    this.scannedCount = 0
    this.totalPorts = 0
    this.currentPort = 0
    this.isScanning = true
    this.viewMode = 'scanning'
    this.startPulse()

    const preset: PortPreset = PortScanEngine.PRESETS[this.selectedPresetIndex]
    this.totalPorts = preset.ports.length

    const callbacks: PortScanCallbacks = {
      onProgress: (scanned: number, total: number, currentPort: number): void => {
        this.scannedCount = scanned
        this.currentPort = currentPort
      },
      onPortFound: (port: PortScanResult): void => {
        this.openPorts.push(port)
        // 触发刷新
        const refreshed: PortScanResult[] = []
        for (let i = 0; i < this.openPorts.length; i++) {
          refreshed.push(this.openPorts[i])
        }
        this.openPorts = refreshed
      },
      onComplete: (results: PortScanResult[]): void => {
        this.resultList = results
        this.isScanning = false
        this.stopPulse()
        this.viewMode = 'result'
      },
      onError: (message: string): void => {
        this.isScanning = false
        this.stopPulse()
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
    this.stopPulse()
    if (this.resultList.length > 0) {
      this.viewMode = 'result'
    } else {
      this.viewMode = 'idle'
    }
  }

  // aboutToDisappear 已处理引擎清理

  // ==================== 页面入口 ====================
  build() {
    Column() {
      if (this.viewMode === 'idle') {
        this.IdleView()
      } else {
        this.ScanView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
    .padding({ top: SAFE_AREA_TOP, bottom: SAFE_AREA_BOTTOM })
  }

  // ==================== 初始视图 ====================
  @Builder IdleView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.SearchBarSection()
        this.PresetSelector()
        this.FeatureCard()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_port')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_PURPLE)

      TextInput({ placeholder: $r('app.string.input_ip_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.inputText = value })

      Button($r('app.string.scan_action'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_PURPLE)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_SM)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.startScan())
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 预设方案选择
  @Builder PresetSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.scan_preset')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Column({ space: SPACE_SM }) {
        ForEach(this.presetItems, (preset: PresetItem, index: number) => {
          this.PresetRow(preset, index)
        }, (preset: PresetItem, index: number): string => String(index))
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder PresetRow(preset: PresetItem, index: number) {
    Row({ space: SPACE_MD }) {
      // 选中指示器
      Circle()
        .width(20).height(20)
        .fill(this.selectedPresetIndex === index ? COLOR_PURPLE : Color.Transparent)
        .border({ width: 2, color: this.selectedPresetIndex === index ? COLOR_PURPLE : COLOR_BORDER })

      Column({ space: 2 }) {
        Text(preset.name)
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
        Text() {
          Span(preset.description + ' (' + preset.portCount + ' ')
          Span($r('app.string.port_count_ports'))
          Span(')')
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_MD)
    .border({ width: 1, color: this.selectedPresetIndex === index ? COLOR_PURPLE : COLOR_BORDER })
    .stateStyles({ pressed: { opacity: 0.8 } })
    .onClick(() => { this.selectedPresetIndex = index })
  }

  // 功能说明
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#F0EBFF')
          Image($r('app.media.ic_port')).width(18).height(18).fillColor(COLOR_PURPLE)
        }
        Column({ space: 2 }) {
          Text($r('app.string.port_scan_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.port_scan_intro_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_2XL).border({ width: 1, color: COLOR_BORDER })
  }

  // ==================== 扫描视图 ====================
  @Builder ScanView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 扫描状态卡
        this.ScanStatusCard()

        // 开放端口统计
        if (this.openPorts.length > 0) {
          this.OpenPortsSummary()
        }

        // 端口结果列表
        if (this.viewMode === 'result' && this.resultList.length > 0) {
          this.PortResultsList()
        }

        // 操作按钮
        this.ActionButtons()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // 扫描状态卡
  @Builder ScanStatusCard() {
    Column({ space: SPACE_MD }) {
      // 目标 + 状态图标
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(40).height(40)
            .fill(this.isScanning ? (COLOR_PURPLE + Math.round(this.pulseOpacity * 60).toString(16).padStart(2, '0')) : '#F0EBFF')
          Image($r('app.media.ic_port')).width(22).height(22).fillColor(COLOR_PURPLE)
        }

        Column({ space: 2 }) {
          Text(this.inputText)
            .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          if (this.isScanning) {
            Text() {
              Span($r('app.string.scanning_port'))
              Span(' ' + String(this.currentPort) + '...')
            }.fontSize(FONT_SIZE_XS).fontColor(COLOR_PURPLE)
          } else {
            Text(this.viewMode === 'result' ? $r('app.string.scan_complete') : $r('app.string.scan_stopped'))
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }

      // 进度条
      if (this.isScanning) {
        Column({ space: SPACE_XS }) {
          Row() {
            Text() {
              Span($r('app.string.progress_label'))
              Span(String(this.scannedCount) + ' / ' + String(this.totalPorts))
            }
              .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY)
            Blank()
            Text(this.getProgressPercent() + '%')
              .fontSize(FONT_SIZE_SM).fontColor(COLOR_PURPLE).fontWeight(FONT_WEIGHT_BOLD)
          }
          .width('100%')

          // 进度条
          Stack() {
            Column()
              .width('100%').height(6).backgroundColor(COLOR_DIVIDER).borderRadius(3)
            Column()
              .width(this.getProgressPercent() + '%').height(6)
              .backgroundColor(COLOR_PURPLE).borderRadius(3)
          }
          .width('100%')
        }
      }

      // 统计行
      Row() {
        this.StatCell($r('app.string.scanned'), String(this.scannedCount), COLOR_PRIMARY)
        this.StatCell($r('app.string.port_open'), String(this.openPorts.length), COLOR_SUCCESS)
        this.StatCell($r('app.string.port_closed'), String(this.scannedCount - this.openPorts.length), COLOR_DANGER)
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  @Builder StatCell(label: Resource | string, value: string, valueColor: string) {
    Column({ space: SPACE_XS }) {
      Text(value).fontSize(FONT_SIZE_2XL).fontColor(valueColor).fontWeight(FONT_WEIGHT_BOLD)
      Text(label).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  // 开放端口摘要
  @Builder OpenPortsSummary() {
    Column({ space: SPACE_SM }) {
      Row() {
        Text($r('app.string.discovered_open_ports'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span(String(this.openPorts.length))
          Span(' ')
          Span($r('app.string.device_count_suffix'))
        }.fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS)
      }
      .width('100%')

      ForEach(this.openPorts, (port: PortScanResult, index: number) => {
        Row({ space: SPACE_MD }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle().width(32).height(32).fill('#ECFDF5')
            Text(String(port.port)).fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_BOLD)
          }

          Column({ space: 2 }) {
            Text(port.service).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
            Text() {
              Span($r('app.string.port_service'))
              Span(' ' + String(port.port) + ' · ' + port.latency + 'ms')
            }
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text($r('app.string.port_open'))
            .fontSize(FONT_SIZE_XS).fontColor(Color.White)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(COLOR_SUCCESS).borderRadius(RADIUS_SM)
        }
        .width('100%')
        .padding(SPACE_SM)
        .backgroundColor(COLOR_SURFACE)
        .borderRadius(RADIUS_MD)
        .border({ width: 1, color: COLOR_BORDER })
      }, (port: PortScanResult, index: number): string => String(port.port))
    }
    .width('100%')
  }

  // 端口结果完整列表
  @Builder PortResultsList() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.all_ports'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span(String(this.resultList.length))
          Span(' ')
          Span($r('app.string.ports_total'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      }
      .width('100%').padding({ bottom: SPACE_SM })

      // 表头
      Row() {
        Text('端口').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY).width(50)
        Text('服务').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY).layoutWeight(1)
        Text('延迟').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY).width(60).textAlign(TextAlign.End)
        Text('状态').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY).width(50).textAlign(TextAlign.End)
      }
      .width('100%').padding({ top: SPACE_XS, bottom: SPACE_XS })
      Divider().color(COLOR_DIVIDER)

      ForEach(this.resultList, (item: PortScanResult, index: number) => {
        Column({ space: 0 }) {
          Row() {
            Text(String(item.port))
              .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_PRIMARY).width(50).fontWeight(FONT_WEIGHT_MEDIUM)
            Text(item.service)
              .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).layoutWeight(1)
            Text(item.latency + 'ms')
              .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_TERTIARY).width(60).textAlign(TextAlign.End)
            Text(this.getStatusTextResource(item.status))
              .fontSize(FONT_SIZE_XS).fontColor(this.getStatusColor(item.status)).fontWeight(FONT_WEIGHT_MEDIUM)
              .width(50).textAlign(TextAlign.End)
          }
          .width('100%').padding({ top: SPACE_SM, bottom: SPACE_SM })

          if (index < this.resultList.length - 1) {
            Divider().color(COLOR_DIVIDER)
          }
        }
      }, (item: PortScanResult, index: number): string => String(index + '_' + item.port))
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      if (this.isScanning) {
        Button($r('app.string.stop_scan'))
          .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
          .backgroundColor(COLOR_DANGER)
          .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.stopScan())
      } else {
        Button($r('app.string.re_scan'))
          .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
          .backgroundColor(COLOR_PURPLE)
          .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.startScan())
      }
    }
    .width('100%')
  }
}
