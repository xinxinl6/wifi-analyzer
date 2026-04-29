// 查找终端页面组件
// 界面：搜索/筛选栏 + 扫描模式切换 + 设备列表（带厂商信息）+ 扫描结果

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_EMERALD,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XXS, FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL, SPACE_2XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_SM, BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM,
} from '@wifi-analyzer/design-system'
import {
  FindDeviceEngine, DeviceSearchResult, EnrichedDevice, DeviceFilter, FindDeviceCallbacks,
} from '../finddevice/FindDeviceEngine'
import { RouterManager } from '@wifi-analyzer/core'

@Component
export struct FindDevicePage {
  // UI 状态：'idle' | 'scanning' | 'done' | 'error'
  @State viewMode: string = 'idle'

  // 搜索筛选
  @State searchKeyword: string = ''
  @State vendorFilter: string = ''
  @State onlineOnly: boolean = false

  // 扫描模式：'quick' | 'full'
  @State scanMode: string = 'quick'

  // 扫描进度
  @State scanProgress: number = 0
  @State scanTotal: number = 20
  @State scanCurrentIp: string = ''

  // 发现的设备
  @State allDevices: EnrichedDevice[] = []
  @State filteredDevices: EnrichedDevice[] = []

  // 扫描统计
  @State scanDuration: number = 0
  @State totalScanned: number = 0
  @State errorMessage: string = ''

  // 引擎
  private engine: FindDeviceEngine = new FindDeviceEngine()

  aboutToDisappear(): void {
    this.engine.stopFind()
  }

  // ==================== 业务逻辑 ====================

  startFind(): void {
    this.viewMode = 'scanning'
    this.allDevices = []
    this.filteredDevices = []
    this.scanProgress = 0
    this.errorMessage = ''

    const callbacks: FindDeviceCallbacks = {
      onProgress: (scanned: number, total: number, currentIp: string): void => {
        this.scanProgress = scanned
        this.scanTotal = total
        this.scanCurrentIp = currentIp
      },
      onDeviceFound: (enriched: EnrichedDevice): void => {
        this.allDevices.push(enriched)
      },
      onMatchFound: (enriched: EnrichedDevice): void => {
        // 设备已通过 onDeviceFound 处理
      },
      onComplete: (result: DeviceSearchResult): void => {
        this.allDevices = result.enrichedDevices
        this.scanDuration = result.scanDuration
        this.totalScanned = result.totalScanned
        this.applyFilter()
        this.viewMode = 'done'
      },
      onError: (message: string): void => {
        this.errorMessage = message
        this.viewMode = 'error'
      }
    }

    if (this.scanMode === 'quick') {
      this.engine.quickFind(callbacks)
    } else {
      this.engine.fullScan(callbacks)
    }
  }

  stopFind(): void {
    this.engine.stopFind()
    this.applyFilter()
    this.viewMode = 'done'
  }

  applyFilter(): void {
    const filter: DeviceFilter = {
      keyword: this.searchKeyword.trim(),
      vendorKeyword: this.vendorFilter.trim(),
      onlineOnly: this.onlineOnly
    }
    this.filteredDevices = this.engine.filterDevices(this.allDevices, filter)
  }

  onSearchChange(): void {
    if (this.allDevices.length > 0) {
      this.applyFilter()
    }
  }

  getDeviceTypeName(type: string): string {
    return FindDeviceEngine.getDeviceTypeName(type)
  }

  getDeviceTypeColor(type: string): string {
    if (type === 'router') return COLOR_PRIMARY
    if (type === 'server') return COLOR_INFO
    if (type === 'computer') return COLOR_EMERALD
    if (type === 'phone') return COLOR_WARNING
    return COLOR_TEXT_TERTIARY
  }

  getDeviceTypeBg(type: string): string {
    if (type === 'router') return '#EEF2FF'
    if (type === 'server') return '#F5F3FF'
    if (type === 'computer') return '#ECFDF5'
    if (type === 'phone') return '#FEF3C7'
    return COLOR_DIVIDER
  }

  getLatencyColor(latency: number): string {
    if (latency < 50) return COLOR_SUCCESS
    if (latency < 200) return COLOR_WARNING
    return COLOR_DANGER
  }

  // ==================== 页面入口 ====================
  build() {
    Column() {
      this.MainContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
    .padding({ top: SPACE_LG, bottom: SAFE_AREA_BOTTOM })
  }

  // ==================== 主内容 ====================
  @Builder MainContent() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 搜索栏 + 筛选
        this.SearchAndFilter()

        // 扫描模式选择
        if (this.viewMode === 'idle') {
          this.ScanModeSelector()
          this.IdleState()
        }

        // 扫描进度
        if (this.viewMode === 'scanning') {
          this.ScanProgressCard()
        }

        // 错误提示
        if (this.viewMode === 'error') {
          this.ErrorTip()
        }

        // 扫描统计
        if (this.viewMode === 'done') {
          this.ScanSummaryCard()
        }

        // 设备列表
        if (this.filteredDevices.length > 0) {
          this.DeviceListSection()
        }

        // 空筛选结果
        if (this.viewMode === 'done' && this.allDevices.length > 0 && this.filteredDevices.length === 0) {
          this.EmptyFilterResult()
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

  // ==================== 搜索栏 + 筛选 ====================
  @Builder SearchAndFilter() {
    Column({ space: SPACE_SM }) {
      // 搜索栏
      Row({ space: SPACE_SM }) {
        Image($r('app.media.ic_device')).width(FONT_SIZE_LG).height(FONT_SIZE_LG)
        TextInput({ placeholder: $r('app.string.search_ip_mac_vendor'), text: this.searchKeyword })
          .layoutWeight(1)
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.searchKeyword = value
            this.onSearchChange()
          })
        if (this.searchKeyword.length > 0) {
          Text('x')
            .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_TERTIARY)
            .width(20).height(20).textAlign(TextAlign.Center)
            .onClick(() => {
              this.searchKeyword = ''
              this.onSearchChange()
            })
        }
      }
      .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
      .border({ width: 1, color: COLOR_BORDER })

      // 筛选选项
      Row({ space: SPACE_SM }) {
        // 仅在线
        Text(this.onlineOnly ? $r('app.string.online_only_active') : $r('app.string.online_only'))
          .fontSize(FONT_SIZE_XS)
          .fontColor(this.onlineOnly ? Color.White : COLOR_TEXT_TERTIARY)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.onlineOnly ? COLOR_EMERALD : COLOR_DIVIDER).borderRadius(RADIUS_3XL)
          .onClick(() => {
            this.onlineOnly = !this.onlineOnly
            this.onSearchChange()
          })

        // 设备类型快捷筛选
        Text($r('app.string.device_type_router'))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_PRIMARY)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor('#EEF2FF').borderRadius(RADIUS_3XL)
          .onClick(() => {
            this.searchKeyword = ''
            this.onlineOnly = false
            const filter: DeviceFilter = { keyword: '', vendorKeyword: '', onlineOnly: false }
            this.filteredDevices = this.engine.filterDevices(this.allDevices, filter)
            const routers: EnrichedDevice[] = []
            for (let i = 0; i < this.filteredDevices.length; i++) {
              if (this.filteredDevices[i].deviceType === 'router') {
                routers.push(this.filteredDevices[i])
              }
            }
            this.filteredDevices = routers
          })

        Text($r('app.string.device_type_computer'))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_EMERALD)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor('#ECFDF5').borderRadius(RADIUS_3XL)
          .onClick(() => {
            this.searchKeyword = ''
            this.onlineOnly = false
            const filter: DeviceFilter = { keyword: '', vendorKeyword: '', onlineOnly: false }
            this.filteredDevices = this.engine.filterDevices(this.allDevices, filter)
            const computers: EnrichedDevice[] = []
            for (let i = 0; i < this.filteredDevices.length; i++) {
              if (this.filteredDevices[i].deviceType === 'computer') {
                computers.push(this.filteredDevices[i])
              }
            }
            this.filteredDevices = computers
          })

        Text($r('app.string.reset_all'))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(Color.Transparent).borderRadius(RADIUS_3XL)
          .border({ width: 1, color: COLOR_BORDER })
          .onClick(() => {
            this.searchKeyword = ''
            this.onlineOnly = false
            this.onSearchChange()
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  // ==================== 扫描模式选择 ====================
  @Builder ScanModeSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.scan_mode'))
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Row({ space: SPACE_MD }) {
        // 快速扫描
        Column({ space: SPACE_XS }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle().width(36).height(36).fill(this.scanMode === 'quick' ? '#ECFDF5' : COLOR_DIVIDER)
            Image($r('app.media.ic_device')).width(20).height(20)
          }
          Text($r('app.string.quick_scan'))
            .fontSize(FONT_SIZE_XS).fontColor(this.scanMode === 'quick' ? COLOR_EMERALD : COLOR_TEXT_TERTIARY)
          Text($r('app.string.quick_scan_hint'))
            .fontSize(FONT_SIZE_XXS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .layoutWeight(1).padding(SPACE_MD)
        .backgroundColor(this.scanMode === 'quick' ? '#ECFDF5' : COLOR_SURFACE)
        .borderRadius(RADIUS_MD)
        .border({ width: 1, color: this.scanMode === 'quick' ? COLOR_EMERALD : COLOR_BORDER })
        .onClick(() => { this.scanMode = 'quick' })

        // 完整扫描
        Column({ space: SPACE_XS }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle().width(36).height(36).fill(this.scanMode === 'full' ? '#ECFDF5' : COLOR_DIVIDER)
            Image($r('app.media.ic_device')).width(20).height(20)
          }
          Text($r('app.string.full_scan'))
            .fontSize(FONT_SIZE_XS).fontColor(this.scanMode === 'full' ? COLOR_EMERALD : COLOR_TEXT_TERTIARY)
          Text($r('app.string.full_scan_hint'))
            .fontSize(FONT_SIZE_XXS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .layoutWeight(1).padding(SPACE_MD)
        .backgroundColor(this.scanMode === 'full' ? '#ECFDF5' : COLOR_SURFACE)
        .borderRadius(RADIUS_MD)
        .border({ width: 1, color: this.scanMode === 'full' ? COLOR_EMERALD : COLOR_BORDER })
        .onClick(() => { this.scanMode = 'full' })
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // ==================== 空状态 ====================
  @Builder IdleState() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(80).height(80).fill('#ECFDF5')
        Image($r('app.media.ic_device')).width(44).height(44)
      }
      Text($r('app.string.find_lan_device'))
        .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
      Text($r('app.string.find_lan_device_desc'))
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_TERTIARY)
    }
    .width('100%').padding({ top: SPACE_LG, bottom: SPACE_LG }).justifyContent(FlexAlign.Center)
  }

  // ==================== 扫描进度 ====================
  @Builder ScanProgressCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.scanning_device'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_EMERALD).fontWeight(FONT_WEIGHT_MEDIUM)
        Blank()
        Text(String(this.scanProgress) + '/' + String(this.scanTotal))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_EMERALD).fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')

      Row() {
        Row()
          .width(this.scanTotal > 0 ? Math.round(this.scanProgress / this.scanTotal * 100) + '%' : '0%')
          .height(6).backgroundColor(COLOR_EMERALD).borderRadius(3)
      }
      .width('100%').height(6).backgroundColor(COLOR_DIVIDER).borderRadius(3)

      Row({ space: SPACE_SM }) {
        Text() {
          Span($r('app.string.current_colon'))
          Span(this.scanCurrentIp)
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        Blank()
        Text() {
          Span($r('app.string.found_count'))
          Span(' ' + String(this.allDevices.length) + ' ')
          Span($r('app.string.device_unit'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_MEDIUM)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG).backgroundColor('#ECFDF5').borderRadius(RADIUS_2XL)
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

  // ==================== 扫描统计 ====================
  @Builder ScanSummaryCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.scan_complete'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span($r('app.string.scanned_ips'))
          Span(' ' + String(this.totalScanned) + ' ')
          Span($r('app.string.ip_suffix'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      }
      .width('100%')

      Row({ space: SPACE_XL }) {
        Column({ space: SPACE_XS }) {
          Text($r('app.string.discovered_devices')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text() {
            Span(String(this.allDevices.length))
            Span(' ')
            Span($r('app.string.device_unit'))
          }
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: SPACE_XS }) {
          Text($r('app.string.matched_result')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text() {
            Span(String(this.filteredDevices.length))
            Span(' ')
            Span($r('app.string.device_unit'))
          }
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_EMERALD).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: SPACE_XS }) {
          Text($r('app.string.scan_time')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text((this.scanDuration / 1000).toFixed(1) + 's')
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_INFO).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // ==================== 设备列表 ====================
  @Builder DeviceListSection() {
    Column({ space: SPACE_SM }) {
      Row() {
        Text($r('app.string.device_list'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span(String(this.filteredDevices.length))
          Span(' ')
          Span($r('app.string.device_unit'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      }
      .width('100%')

      ForEach(this.filteredDevices, (enriched: EnrichedDevice) => {
        this.EnrichedDeviceRow(enriched)
      }, (enriched: EnrichedDevice): string => enriched.device.ip + ':' + String(enriched.device.port))
    }
    .width('100%')
  }

  @Builder EnrichedDeviceRow(enriched: EnrichedDevice) {
    Row({ space: SPACE_MD }) {
      // 设备图标
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(40).height(40).fill(this.getDeviceTypeBg(enriched.deviceType))
        Image($r('app.media.ic_device')).width(20).height(20)
      }

      // 设备信息
      Column({ space: 2 }) {
        Row({ space: SPACE_SM }) {
          Text(this.getDeviceTypeName(enriched.deviceType))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text(this.getDeviceTypeName(enriched.deviceType))
            .fontSize(FONT_SIZE_XXS).fontColor(this.getDeviceTypeColor(enriched.deviceType))
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .backgroundColor(this.getDeviceTypeBg(enriched.deviceType)).borderRadius(RADIUS_SM)
        }
        Row({ space: SPACE_SM }) {
          Text(enriched.device.ip).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_SECONDARY)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
          Text(':' + String(enriched.device.port)).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
          Text(String(enriched.device.latency) + 'ms')
            .fontSize(FONT_SIZE_XS).fontColor(this.getLatencyColor(enriched.device.latency))
        }
        if (enriched.macInfo.vendor !== '') {
          Text(enriched.macInfo.vendor)
            .fontSize(FONT_SIZE_XXS).fontColor(COLOR_TEXT_TERTIARY).maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      // 在线状态
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(8).height(8).fill(COLOR_SUCCESS)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_MD)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // ==================== 空筛选结果 ====================
  @Builder EmptyFilterResult() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.no_matched_device'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_TERTIARY)
      Text($r('app.string.try_modify_filter'))
        .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
    }
    .width('100%').padding({ top: SPACE_2XL, bottom: SPACE_2XL }).justifyContent(FlexAlign.Center)
  }

  // ==================== 操作按钮 ====================
  @Builder ActionButtons() {
    if (this.viewMode === 'scanning') {
      Button($r('app.string.stop_find'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_DANGER)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).width('100%')
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.stopFind())
    } else if (this.viewMode === 'idle') {
      Button($r('app.string.start_find'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_EMERALD)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).width('100%')
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.startFind())
    } else if (this.viewMode === 'done' || this.viewMode === 'error') {
      Row({ space: SPACE_MD }) {
        Button($r('app.string.back_action'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_SECONDARY).fontWeight(FONT_WEIGHT_MEDIUM)
          .backgroundColor(Color.Transparent).borderWidth(1).borderColor(COLOR_BORDER)
          .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => RouterManager.goBack())
        Button($r('app.string.find_again'))
          .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
          .backgroundColor(COLOR_EMERALD)
          .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.startFind())
      }
      .width('100%')
    }
  }

  // ==================== 功能说明卡片 ====================
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#ECFDF5')
          Image($r('app.media.ic_device')).width(20).height(20)
        }
        Column({ space: 2 }) {
          Text($r('app.string.find_device_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.find_device_intro_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_2XL).border({ width: 1, color: COLOR_BORDER })
  }
}
