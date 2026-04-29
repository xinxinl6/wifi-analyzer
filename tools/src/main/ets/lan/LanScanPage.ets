// 局域网扫描页面组件
// 界面：网络信息卡 + 扫描进度 + 设备列表（按IP排序）+ 扫描统计

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XXS, FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL, SPACE_2XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_SM, BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM,
} from '@wifi-analyzer/design-system'
import {
  LanEngine, LanDevice, LanScanCallbacks, LanNetworkInfo,
} from '../lanscan/LanEngine'
import { RouterManager } from '@wifi-analyzer/core'

@Component
export struct LanScanPage {
  // UI 状态：'idle' | 'scanning' | 'done' | 'error'
  @State viewMode: string = 'idle'

  // 网络信息
  @State networkInfo: LanNetworkInfo = {
    localIp: '', gateway: '192.168.1.1', subnetMask: '255.255.255.0',
    networkPrefix: '192.168.1', hostCount: 254
  }

  // 扫描进度
  @State scanProgress: number = 0
  @State scanTotal: number = 254
  @State scanCurrentIp: string = ''
  @State scanStartTime: number = 0

  // 发现的设备
  @State deviceList: LanDevice[] = []

  // 扫描统计
  @State scanDuration: number = 0
  @State onlineCount: number = 0
  @State errorMessage: string = ''

  // 排序方式：'ip' | 'latency'
  @State sortMode: string = 'ip'

  // 引擎
  private engine: LanEngine = new LanEngine()

  aboutToAppear(): void {
    this.detectNetwork()
  }

  aboutToDisappear(): void {
    this.engine.stopScan()
  }

  // ==================== 业务逻辑 ====================

  async detectNetwork(): Promise<void> {
    const info: LanNetworkInfo = await this.engine.detectNetworkInfo()
    this.networkInfo = info
  }

  startScan(): void {
    this.viewMode = 'scanning'
    this.deviceList = []
    this.scanProgress = 0
    this.scanTotal = 254
    this.scanStartTime = Date.now()
    this.errorMessage = ''
    this.onlineCount = 0

    const callbacks: LanScanCallbacks = {
      onProgress: (scanned: number, total: number, currentIp: string): void => {
        this.scanProgress = scanned
        this.scanTotal = total
        this.scanCurrentIp = currentIp
      },
      onDeviceFound: (device: LanDevice): void => {
        this.deviceList.push(device)
        this.onlineCount = this.deviceList.length
      },
      onComplete: (devices: LanDevice[]): void => {
        this.scanDuration = Date.now() - this.scanStartTime
        this.deviceList = devices
        this.onlineCount = devices.length
        this.viewMode = 'done'
      },
      onError: (message: string): void => {
        this.errorMessage = message
        this.scanDuration = Date.now() - this.scanStartTime
        this.viewMode = 'error'
      }
    }

    this.engine.scan(callbacks)
  }

  stopScan(): void {
    this.engine.stopScan()
    this.scanDuration = Date.now() - this.scanStartTime
    this.viewMode = 'done'
  }

  refreshScan(): void {
    this.detectNetwork()
    this.startScan()
  }

  toggleSort(): void {
    if (this.sortMode === 'ip') {
      this.sortMode = 'latency'
    } else {
      this.sortMode = 'ip'
    }
    if (this.sortMode === 'latency') {
      this.deviceList.sort((a: LanDevice, b: LanDevice): number => a.latency - b.latency)
    } else {
      this.deviceList.sort((a: LanDevice, b: LanDevice): number => {
        const aNum: number = this.ipToNumber(a.ip)
        const bNum: number = this.ipToNumber(b.ip)
        return aNum - bNum
      })
    }
  }

  getDeviceTypeIcon(device: LanDevice): string {
    if (LanEngine.isGateway(device.ip, this.networkInfo.gateway)) return 'ic_lan'
    if (LanEngine.isLocalHost(device.ip, this.networkInfo.localIp)) return 'ic_mac'
    if (device.port === 80 || device.port === 443 || device.port === 8080) return 'ic_port'
    return 'ic_mac'
  }

  getDeviceTypeLabel(device: LanDevice): Resource {
    if (LanEngine.isGateway(device.ip, this.networkInfo.gateway)) return $r('app.string.device_type_router')
    if (LanEngine.isLocalHost(device.ip, this.networkInfo.localIp)) return $r('app.string.device_type_local')
    if (device.port === 80 || device.port === 443 || device.port === 8080) return $r('app.string.device_type_server')
    return $r('app.string.device_type_device')
  }

  getDeviceTypeColor(device: LanDevice): string {
    if (LanEngine.isGateway(device.ip, this.networkInfo.gateway)) return COLOR_PRIMARY
    if (LanEngine.isLocalHost(device.ip, this.networkInfo.localIp)) return COLOR_SUCCESS
    return COLOR_PURPLE
  }

  getLatencyColor(latency: number): string {
    if (latency < 50) return COLOR_SUCCESS
    if (latency < 200) return COLOR_WARNING
    return COLOR_DANGER
  }

  getProgressPercent(): number {
    if (this.scanTotal <= 0) return 0
    return Math.round(this.scanProgress / this.scanTotal * 100)
  }

  ipToNumber(ip: string): number {
    const octets: string[] = ip.split('.')
    if (octets.length !== 4) return 0
    return ((parseInt(octets[0], 10) << 24) | (parseInt(octets[1], 10) << 16) |
      (parseInt(octets[2], 10) << 8) | parseInt(octets[3], 10)) >>> 0
  }

  // ==================== 页面入口 ====================
  build() {
    Column() {
      // 顶部返回按钮栏
      Row() {
        Row() {
          Text('←')
            .fontSize(20)
            .fontColor(COLOR_PRIMARY)
          Text($r('app.string.back'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(COLOR_PRIMARY)
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .padding({ left: 4, right: 12, top: 6, bottom: 6 })
        .borderRadius(20)
        .backgroundColor(COLOR_SURFACE)
        .onClick(() => RouterManager.goBack())

        Blank()
      }
      .width('100%')
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: SAFE_AREA_BOTTOM })
      .alignItems(VerticalAlign.Center)

      this.MainContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
    .onBackPress(() => {
      RouterManager.goBack()
      return true
    })
  }

  // ==================== 主内容 ====================
  @Builder MainContent() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 网络信息卡片
        this.NetworkInfoCard()

        // 扫描进度
        if (this.viewMode === 'scanning') {
          this.ScanProgressCard()
        }

        // 扫描结果统计
        if (this.viewMode === 'done' || this.viewMode === 'error') {
          this.ScanSummaryCard()
        }

        // 错误提示
        if (this.viewMode === 'error') {
          this.ErrorTip()
        }

        // 设备列表
        if (this.deviceList.length > 0) {
          this.DeviceListSection()
        }

        // 空状态
        if (this.viewMode === 'idle') {
          this.IdleState()
        }

        // 操作按钮
        this.ActionButtons()

        // 功能说明
        this.FeatureCard()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // ==================== 网络信息卡片 ====================
  @Builder NetworkInfoCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(40).height(40).fill('#F5F3FF')
          Image($r('app.media.ic_lan')).width(22).height(22).fillColor(COLOR_PURPLE)
        }
        Column({ space: 2 }) {
          Text($r('app.string.current_network'))
            .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          Text(this.networkInfo.networkPrefix + '.0/24')
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')

      Divider().color(COLOR_DIVIDER)

      // 网络详情
      Row({ space: SPACE_XL }) {
        Column({ space: SPACE_XS }) {
          Text($r('app.string.local_ip')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(this.networkInfo.localIp !== '' ? this.networkInfo.localIp : $r('app.string.getting_ip'))
            .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: SPACE_XS }) {
          Text($r('app.string.gateway_label')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(this.networkInfo.gateway)
            .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: SPACE_XS }) {
          Text($r('app.string.subnet_mask_label')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(this.networkInfo.subnetMask)
            .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // ==================== 扫描进度卡片 ====================
  @Builder ScanProgressCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.scanning_hint'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_PURPLE).fontWeight(FONT_WEIGHT_MEDIUM)
        Blank()
        Text(this.getProgressPercent() + '%')
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_PURPLE).fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')

      // 进度条
      Row() {
        Row()
          .width(this.getProgressPercent() + '%').height(6)
          .backgroundColor(COLOR_PURPLE).borderRadius(3)
      }
      .width('100%').height(6).backgroundColor(COLOR_DIVIDER).borderRadius(3)

      Row({ space: SPACE_SM }) {
        Text() {
          Span($r('app.string.scanned_count'))
          Span(' ' + String(this.scanProgress) + '/' + String(this.scanTotal))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        Blank()
        Text() {
          Span($r('app.string.current_scan'))
          Span(' ' + this.scanCurrentIp)
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        Blank()
        Text() {
          Span($r('app.string.found_devices'))
          Span(' ' + String(this.onlineCount) + ' ')
          Span($r('app.string.online_devices'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_MEDIUM)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG).backgroundColor('#F5F3FF').borderRadius(RADIUS_2XL)
  }

  // ==================== 扫描结果统计卡片 ====================
  @Builder ScanSummaryCard() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.scan_summary'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)

      Row({ space: SPACE_XL }) {
        Column({ space: SPACE_XS }) {
          Text($r('app.string.online_device_count')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text() {
          Span(String(this.onlineCount))
          Span(' ')
          Span($r('app.string.device_count_suffix'))
        }
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: SPACE_XS }) {
          Text($r('app.string.scan_duration')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(String(this.scanDuration) + 'ms')
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_INFO).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: SPACE_XS }) {
          Text($r('app.string.scan_range')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(String(this.scanTotal) + ' IP')
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_PURPLE).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // ==================== 错误提示 ====================
  @Builder ErrorTip() {
    Row({ space: SPACE_SM }) {
      Text('!').fontSize(FONT_SIZE_SM).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
        .width(20).height(20).textAlign(TextAlign.Center)
        .backgroundColor(COLOR_DANGER).borderRadius(10)
      Text(this.errorMessage).fontSize(FONT_SIZE_SM).fontColor(COLOR_DANGER)
    }
    .width('100%').padding(SPACE_MD).backgroundColor('#FEF2F2').borderRadius(RADIUS_MD)
  }

  // ==================== 设备列表 ====================
  @Builder DeviceListSection() {
    Column({ space: SPACE_SM }) {
      Row() {
        Text($r('app.string.discovered_devices'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span($r('app.string.sort_by'))
          Span(' ')
          Span(this.sortMode === 'ip' ? $r('app.string.sort_by_ip') : $r('app.string.sort_by_latency'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_PURPLE)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.toggleSort())
      }
      .width('100%')

      ForEach(this.deviceList, (device: LanDevice) => {
        this.DeviceRow(device)
      }, (device: LanDevice): string => device.ip + ':' + String(device.port))
    }
    .width('100%')
  }

  @Builder DeviceRow(device: LanDevice) {
    Row({ space: SPACE_MD }) {
      // 设备图标
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(36).height(36).fill(this.getDeviceTypeBgColor(device))
        if (LanEngine.isGateway(device.ip, this.networkInfo.gateway)) {
          Image($r('app.media.ic_lan')).width(18).height(18)
            .fillColor(this.getDeviceTypeColor(device))
        } else if (LanEngine.isLocalHost(device.ip, this.networkInfo.localIp)) {
          Image($r('app.media.ic_mac')).width(18).height(18)
            .fillColor(this.getDeviceTypeColor(device))
        } else if (device.port === 80 || device.port === 443 || device.port === 8080) {
          Image($r('app.media.ic_port')).width(18).height(18)
            .fillColor(this.getDeviceTypeColor(device))
        } else {
          Image($r('app.media.ic_mac')).width(18).height(18)
            .fillColor(this.getDeviceTypeColor(device))
        }
      }

      // 设备信息
      Column({ space: 2 }) {
        Row({ space: SPACE_SM }) {
          Text(this.getDeviceTypeLabel(device))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text(this.getDeviceTypeLabel(device))
            .fontSize(FONT_SIZE_XXS).fontColor(this.getDeviceTypeColor(device))
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .backgroundColor(this.getDeviceTypeTagBg(device)).borderRadius(RADIUS_SM)
        }
        Row({ space: SPACE_SM }) {
          Text(device.ip).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_SECONDARY)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
          Text(':' + String(device.port)).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
          Text(String(device.latency) + 'ms')
            .fontSize(FONT_SIZE_XS).fontColor(this.getLatencyColor(device.latency))
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      // 在线状态指示灯
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(8).height(8).fill(COLOR_SUCCESS)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_MD)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 辅助方法：获取设备类型标签背景色
  getDeviceTypeTagBg(device: LanDevice): string {
    if (LanEngine.isGateway(device.ip, this.networkInfo.gateway)) return '#EEF2FF'
    if (LanEngine.isLocalHost(device.ip, this.networkInfo.localIp)) return '#ECFDF5'
    if (device.port === 80 || device.port === 443 || device.port === 8080) return '#FEF3C7'
    return '#F5F3FF'
  }

  // 辅助方法：获取图标背景色
  getDeviceTypeBgColor(device: LanDevice): string {
    if (LanEngine.isGateway(device.ip, this.networkInfo.gateway)) return '#EEF2FF'
    if (LanEngine.isLocalHost(device.ip, this.networkInfo.localIp)) return '#ECFDF5'
    if (device.port === 80 || device.port === 443 || device.port === 8080) return '#FEF3C7'
    return '#F5F3FF'
  }

  // ==================== 空状态 ====================
  @Builder IdleState() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(80).height(80).fill('#F5F3FF')
        Image($r('app.media.ic_lan')).width(40).height(40).fillColor(COLOR_PURPLE)
      }
      Text($r('app.string.scan_hint'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_TERTIARY)
      Text() {
        Span($r('app.string.scan_range_hint'))
        Span(' ' + this.networkInfo.networkPrefix + '.1 ~ .254 ')
        Span($r('app.string.scan_range_to'))
      }
        .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
    }
    .width('100%').padding({ top: SPACE_2XL, bottom: SPACE_2XL }).justifyContent(FlexAlign.Center)
  }

  // ==================== 操作按钮 ====================
  @Builder ActionButtons() {
    if (this.viewMode === 'scanning') {
      Button($r('app.string.stop_scan'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_DANGER)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).width('100%')
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.stopScan())
    } else {
      Row({ space: SPACE_MD }) {
        if (this.viewMode === 'done' || this.viewMode === 'error') {
          Button($r('app.string.retry_scan'))
            .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
            .backgroundColor(COLOR_PURPLE)
            .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.refreshScan())
        }
        if (this.viewMode === 'idle') {
          Button($r('app.string.start_scan'))
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

  // ==================== 功能说明卡片 ====================
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#F5F3FF')
          Image($r('app.media.ic_lan')).width(18).height(18).fillColor(COLOR_PURPLE)
        }
        Column({ space: 2 }) {
          Text($r('app.string.lan_scan_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.lan_scan_intro_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_2XL).border({ width: 1, color: COLOR_BORDER })
  }
}
