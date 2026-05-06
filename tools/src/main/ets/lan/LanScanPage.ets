// 设备发现页面 — Aurora WiFi V2 天蓝极光设计
// 功能：局域网设备扫描、IP/MAC搜索、设备筛选

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE, COLOR_CYAN, COLOR_PINK, COLOR_INDIGO, COLOR_ORANGE,
  FONT_SIZE_XXS, FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL, SPACE_2XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_TEXT_GLASS_PRIMARY, COLOR_TEXT_GLASS_SECONDARY, COLOR_TEXT_GLASS_TERTIARY,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider,
  adaptiveCardBg
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import {
  LanEngine, LanDevice, LanScanCallbacks, LanNetworkInfo,
} from '../lanscan/LanEngine'
import { RouterManager } from '@wifi-analyzer/core'

// 扫描模式类型
enum ScanMode {
  QUICK = 'quick',
  FULL = 'full'
}

// 筛选类型
enum FilterType {
  ALL = 'all',
  ONLINE = 'online',
  ROUTER = 'router',
  COMPUTER = 'computer'
}

// ==================== ViewModel 定义 ====================

// 扫描进度状态
interface ScanProgressState {
  progress: number      // 已扫描数
  total: number         // 总数
  currentIp: string     // 当前扫描IP
  startTime: number     // 开始时间戳
  duration: number      // 已耗时(ms)
}

// 扫描统计
interface ScanStats {
  onlineCount: number
  errorMessage: string
}

@Component
export struct LanScanPage {
  @Consume isDarkMode: boolean = false

  // UI 状态：'idle' | 'scanning' | 'done' | 'error'
  @State viewMode: string = 'idle'

  // 扫描模式
  @State scanMode: ScanMode = ScanMode.QUICK

  // 筛选状态
  @State currentFilter: FilterType = FilterType.ALL

  // 搜索关键词
  @State searchKeyword: string = ''

  // 网络信息
  @State networkInfo: LanNetworkInfo = {
    localIp: '', gateway: '192.168.1.1', subnetMask: '255.255.255.0',
    networkPrefix: '192.168.1', hostCount: 254
  }

  // === ViewModel: 扫描进度 ===
  @State scanProgress: ScanProgressState = {
    progress: 0, total: 254, currentIp: '',
    startTime: 0, duration: 0
  }

  // === ViewModel: 扫描统计 ===
  @State scanStats: ScanStats = {
    onlineCount: 0, errorMessage: ''
  }

  // 发现的设备
  @State deviceList: LanDevice[] = []

  // 缓存筛选后的设备列表（避免 build() 中重复调用 getFilteredDevices）
  @State filteredDevices: LanDevice[] = []

  // 引擎
  private engine: LanEngine = new LanEngine()

  aboutToAppear(): void {
    this.detectNetwork()
    this.updateFilteredCache()
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
    this.filteredDevices = []
    const totalIp: number = this.scanMode === ScanMode.QUICK ? 20 : 254
    this.scanProgress = { progress: 0, total: totalIp, currentIp: '', startTime: Date.now(), duration: 0 }
    this.scanStats = { onlineCount: 0, errorMessage: '' }

    const callbacks: LanScanCallbacks = {
      onProgress: (scanned: number, total: number, currentIp: string): void => {
        this.scanProgress = { progress: scanned, total: total, currentIp: currentIp, startTime: this.scanProgress.startTime, duration: 0 }
      },
      onDeviceFound: (device: LanDevice): void => {
        this.deviceList.push(device)
        this.scanStats.onlineCount = this.deviceList.length
        this.updateFilteredCache()
      },
      onComplete: (devices: LanDevice[]): void => {
        this.scanProgress.duration = Date.now() - this.scanProgress.startTime
        this.deviceList = devices
        this.scanStats.onlineCount = devices.length
        this.viewMode = 'done'
        this.updateFilteredCache()
      },
      onError: (message: string): void => {
        this.scanStats.errorMessage = message
        this.scanProgress.duration = Date.now() - this.scanProgress.startTime
        this.viewMode = 'error'
      }
    }

    this.engine.scan(callbacks)
  }

  stopScan(): void {
    this.engine.stopScan()
    this.scanProgress.duration = Date.now() - this.scanProgress.startTime
    this.viewMode = 'done'
  }

  resetFilter(): void {
    this.currentFilter = FilterType.ALL
    this.searchKeyword = ''
  }

  // 更新筛选缓存（在 keyword / currentFilter / deviceList 变化时调用）
  private updateFilteredCache(): void {
    this.filteredDevices = this.getFilteredDevices()
  }

  // 获取筛选后的设备列表
  getFilteredDevices(): LanDevice[] {
    let filtered: LanDevice[] = this.deviceList

    // 根据搜索关键词筛选
    if (this.searchKeyword.trim() !== '') {
      const keyword: string = this.searchKeyword.toLowerCase()
      filtered = filtered.filter((device: LanDevice): boolean => {
        const matchIp: boolean = device.ip.toLowerCase().includes(keyword)
        const matchMac: boolean = device.mac.toLowerCase().includes(keyword)
        const matchVendor: boolean = device.vendor ? device.vendor.toLowerCase().includes(keyword) : false
        return matchIp || matchMac || matchVendor
      })
    }

    // 根据类型筛选
    switch (this.currentFilter) {
      case FilterType.ONLINE:
        return filtered.filter((d: LanDevice): boolean => d.status === 'online')
      case FilterType.ROUTER:
        return filtered.filter((d: LanDevice): boolean => this.isRouter(d))
      case FilterType.COMPUTER:
        return filtered.filter((d: LanDevice): boolean => this.isComputer(d))
      default:
        return filtered
    }
  }

  isRouter(device: LanDevice): boolean {
    return LanEngine.isGateway(device.ip, this.networkInfo.gateway)
  }

  isComputer(device: LanDevice): boolean {
    return device.port === 80 || device.port === 443 || device.port === 8080 ||
           LanEngine.isLocalHost(device.ip, this.networkInfo.localIp)
  }

  getProgressPercent(): number {
    if (this.scanProgress.total <= 0) {
      return 0
    }
    return Math.round(this.scanProgress.progress / this.scanProgress.total * 100)
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
        .position({ x: -100, y: -80 })
        .blur(40)

      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '70%', y: '50%' })
        .blur(30)

      // 主内容
      Column() {
        // 顶部返回按钮栏 - 统一使用毛玻璃返回按钮
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        this.MainContent()
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

  // ==================== 主内容 ====================
  @Builder MainContent() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 搜索框
        this.SearchBar()

        // 筛选标签
        this.FilterTags()

        // 扫描模式选择（仅在空闲状态显示）
        if (this.viewMode === 'idle') {
          this.ScanModeSelector()
        }

        // 扫描进度
        if (this.viewMode === 'scanning') {
          this.ScanProgressCard()
        }

        // 设备列表（扫描完成或有结果时显示）
        if (this.viewMode === 'done' || this.viewMode === 'error' || this.deviceList.length > 0) {
          this.DeviceListSection()
        }

        // 空状态
        if (this.viewMode === 'idle' && this.deviceList.length === 0) {
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

  // ==================== 搜索框 ====================
  @Builder SearchBar() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_lan'))
        .width(20)
        .height(20)
        .fillColor(COLOR_PRIMARY)

      TextInput({ placeholder: '搜索IP/MAC/厂商', text: $$this.searchKeyword })
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(44)

      if (this.searchKeyword !== '') {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_mac'))
            .width(16)
            .height(16)
            .fillColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .width(28)
        .height(28)
        .backgroundColor(adaptiveDivider(this.isDarkMode))
        .onClick(() => this.searchKeyword = '')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 筛选标签 ====================
  @Builder FilterTags() {
    Row({ space: SPACE_SM }) {
      this.FilterTag('仅在线', FilterType.ONLINE)
      this.FilterTag('路由器', FilterType.ROUTER)
      this.FilterTag('电脑', FilterType.COMPUTER)
      this.FilterTag('全部', FilterType.ALL, true)
    }
    .width('100%')
  }

  @Builder FilterTag(label: string, type: FilterType, isReset: boolean = false) {
    Text(label)
      .fontSize(FONT_SIZE_XS)
      .fontColor(this.currentFilter === type && !isReset ? Color.White : (isReset ? COLOR_PRIMARY : adaptiveTextSecondary(this.isDarkMode)))
      .fontWeight(FONT_WEIGHT_MEDIUM)
      .padding({ left: SPACE_MD, right: SPACE_MD, top: SPACE_XS, bottom: SPACE_XS })
      .backgroundColor(this.currentFilter === type && !isReset ? COLOR_PRIMARY : (isReset ? (this.isDarkMode ? 'rgba(16,185,129,0.18)' : 'rgba(16,185,129,0.12)') : adaptiveCardBg(this.isDarkMode)))
      .borderRadius(RADIUS_3XL)
      .border({ width: (this.currentFilter === type || isReset) ? 0 : 1, color: adaptiveDivider(this.isDarkMode) })
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => {
        if (isReset) {
          this.resetFilter()
        } else {
          this.currentFilter = type
        }
        this.updateFilteredCache()
      })
  }

  // ==================== 扫描模式选择 ====================
  @Builder ScanModeSelector() {
    Column({ space: SPACE_SM }) {
      Text('扫描模式')
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_MD }) {
        // 快速扫描
        this.ScanModeCard(
          '快速扫描',
          '约20个常用IP',
          $r('app.media.ic_lan'),
          ScanMode.QUICK
        )

        // 完整扫描
        this.ScanModeCard(
          '完整扫描',
          '全部254个IP',
          $r('app.media.ic_port'),
          ScanMode.FULL
        )
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder ScanModeCard(title: string, desc: string, icon: Resource, mode: ScanMode) {
    Column({ space: SPACE_SM }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(48)
          .height(48)
          .fill(this.scanMode === mode ? (this.isDarkMode ? 'rgba(16,185,129,0.18)' : 'rgba(16,185,129,0.12)') : (this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(255,255,255,0.4)'))
        Image(icon)
          .width(24)
          .height(24)
          .fillColor(this.scanMode === mode ? COLOR_PRIMARY : adaptiveTextTertiary(this.isDarkMode))
      }

      Text(title)
        .fontSize(FONT_SIZE_MD)
        .fontColor(this.scanMode === mode ? adaptiveTextPrimary(this.isDarkMode) : adaptiveTextSecondary(this.isDarkMode))
        .fontWeight(FONT_WEIGHT_MEDIUM)

      Text(desc)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .layoutWeight(1)
    .padding({ top: SPACE_LG, bottom: SPACE_LG, left: 14, right: 14 })
    .backgroundColor(this.scanMode === mode ? (this.isDarkMode ? 'rgba(16,185,129,0.12)' : 'rgba(16,185,129,0.08)') : adaptiveCardBg(this.isDarkMode))
    .borderRadius(RADIUS_2XL)
    .border({ width: this.scanMode === mode ? 1.5 : 1, color: this.scanMode === mode ? COLOR_PRIMARY : adaptiveDivider(this.isDarkMode) })
    .backdropBlur(GLASS_BLUR_MD)
    .stateStyles({ pressed: { opacity: 0.8 } })
    .onClick(() => this.scanMode = mode)
  }

  // ==================== 扫描进度卡片 ====================
  @Builder ScanProgressCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text('正在扫描...')
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_MEDIUM)
        Blank()
        Text(this.getProgressPercent() + '%')
          .fontSize(FONT_SIZE_MD)
          .fontColor(COLOR_PRIMARY)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')

      // 进度条
      Row() {
        Column()
          .height(6)
          .borderRadius(3)
          .backgroundColor(COLOR_PRIMARY)
          .width(String(this.getProgressPercent()) + '%')
        Blank()
      }
      .width('100%')
      .height(6)
      .borderRadius(3)
      .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : COLOR_GLASS_SKY_LIGHT)

      Row({ space: SPACE_SM }) {
        Text() {
          Span('已扫描 ')
          Span(String(this.scanProgress.progress) + '/' + String(this.scanProgress.total))
        }
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))

        Blank()

        Text() {
          Span('当前 ')
          Span(this.scanProgress.currentIp)
        }
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))

        Blank()

        Text() {
          Span('发现 ')
          Span(String(this.scanStats.onlineCount) + ' 台')
        }
        .fontSize(FONT_SIZE_XS)
        .fontColor(COLOR_SUCCESS)
        .fontWeight(FONT_WEIGHT_MEDIUM)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 设备列表 ====================
  @Builder DeviceListSection() {
    Column({ space: SPACE_SM }) {
      Row() {
        Text('发现的设备')
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text(String(this.filteredDevices.length) + ' 台')
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.isDarkMode ? 'rgba(16,185,129,0.15)' : 'rgba(16,185,129,0.1)')
          .borderRadius(999)
      }
      .width('100%')

      ForEach(this.filteredDevices, (device: LanDevice) => {
        this.DeviceRow(device)
      }, (device: LanDevice): string => device.ip + ':' + String(device.port))
    }
    .width('100%')
  }

  @Builder DeviceRow(device: LanDevice) {
    Row({ space: SPACE_MD }) {
      // 设备图标
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(44)
          .height(44)
          .fill(this.getDeviceTypeBgColor(device))
        Image(this.getDeviceIcon(device))
          .width(22)
          .height(22)
          .fillColor(this.getDeviceTypeColor(device))
      }

      // 设备信息
      Column({ space: 4 }) {
        Row({ space: SPACE_SM }) {
          Text(this.getDeviceTypeLabel(device))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_MEDIUM)

          Text(this.getDeviceTypeShortLabel(device))
            .fontSize(FONT_SIZE_XXS)
            .fontColor(this.getDeviceTypeColor(device))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.getDeviceTypeTagBg(device))
            .borderRadius(999)
        }

        Row({ space: SPACE_SM }) {
          Text(device.ip)
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextSecondary(this.isDarkMode))
          Text('·')
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text(device.mac)
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 延迟
      Text(String(device.latency) + 'ms')
        .fontSize(FONT_SIZE_SM)
        .fontColor(this.getLatencyColor(device.latency))
        .fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(14)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_MD)
    .stateStyles({ pressed: { opacity: 0.8 } })
  }

  getDeviceIcon(device: LanDevice): Resource {
    if (this.isRouter(device)) {
      return $r('app.media.ic_lan')
    }
    if (this.isComputer(device)) {
      return $r('app.media.ic_mac')
    }
    return $r('app.media.ic_port')
  }

  getDeviceTypeLabel(device: LanDevice): string {
    if (this.isRouter(device)) {
      return '路由器'
    }
    if (this.isComputer(device)) {
      return '电脑'
    }
    return '设备'
  }

  getDeviceTypeShortLabel(device: LanDevice): string {
    if (this.isRouter(device)) {
      return '网关'
    }
    if (this.isComputer(device)) {
      return '主机'
    }
    return '设备'
  }

  getDeviceTypeColor(device: LanDevice): string {
    if (this.isRouter(device)) {
      return COLOR_PRIMARY
    }
    if (this.isComputer(device)) {
      return COLOR_SUCCESS
    }
    return COLOR_PURPLE
  }

  getDeviceTypeBgColor(device: LanDevice): string {
    if (this.isRouter(device)) {
      return this.isDarkMode ? 'rgba(99,102,241,0.15)' : '#EEF2FF'
    }
    if (this.isComputer(device)) {
      return this.isDarkMode ? 'rgba(16,185,129,0.15)' : '#ECFDF5'
    }
    return this.isDarkMode ? 'rgba(139,92,246,0.15)' : '#F5F3FF'
  }

  getDeviceTypeTagBg(device: LanDevice): string {
    if (this.isRouter(device)) {
      return this.isDarkMode ? 'rgba(99,102,241,0.2)' : '#EEF2FF'
    }
    if (this.isComputer(device)) {
      return this.isDarkMode ? 'rgba(16,185,129,0.2)' : '#ECFDF5'
    }
    return this.isDarkMode ? 'rgba(139,92,246,0.2)' : '#F5F3FF'
  }

  getLatencyColor(latency: number): string {
    if (latency < 50) {
      return COLOR_SUCCESS
    }
    if (latency < 200) {
      return COLOR_WARNING
    }
    return COLOR_DANGER
  }

  // ==================== 空状态 ====================
  @Builder IdleState() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(80)
          .height(80)
          .fill(this.isDarkMode ? 'rgba(16,185,129,0.18)' : 'rgba(16,185,129,0.12)')

        Image($r('app.media.ic_lan'))
          .width(40)
          .height(40)
          .fillColor(COLOR_PRIMARY)
      }

      Text('查找局域网终端')
        .fontSize(FONT_SIZE_LG)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .fontWeight(FONT_WEIGHT_BOLD)

      Text('通过扫描发现设备，自动识别设备类型和厂商信息')
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: SPACE_2XL, bottom: SPACE_2XL })
    .justifyContent(FlexAlign.Center)
  }

  // ==================== 操作按钮 ====================
  @Builder ActionButtons() {
    if (this.viewMode === 'scanning') {
      Row() {
        Text('停止扫描')
          .fontSize(FONT_SIZE_MD)
          .fontColor(Color.White)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLOR_DANGER)
      .borderRadius(RADIUS_3XL)
      .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(239,68,68,0.5)' : 'rgba(239,68,68,0.35)', offsetX: 0, offsetY: 4 })
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => this.stopScan())
    } else if (this.viewMode === 'idle') {
      Row() {
        Text('开始查找')
          .fontSize(FONT_SIZE_MD)
          .fontColor(Color.White)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLOR_PRIMARY)
      .borderRadius(RADIUS_3XL)
      .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(16,185,129,0.5)' : 'rgba(16,185,129,0.35)', offsetX: 0, offsetY: 4 })
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => this.startScan())
    } else {
      Row() {
        Text('重新扫描')
          .fontSize(FONT_SIZE_MD)
          .fontColor(Color.White)
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(COLOR_PRIMARY)
      .borderRadius(RADIUS_3XL)
      .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(16,185,129,0.5)' : 'rgba(16,185,129,0.35)', offsetX: 0, offsetY: 4 })
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => this.startScan())
    }
  }

  // ==================== 功能说明卡片 ====================
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        // 图标
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(36)
            .height(36)
            .fill(this.isDarkMode ? 'rgba(16,185,129,0.18)' : 'rgba(16,185,129,0.12)')
          Image($r('app.media.ic_lan'))
            .width(18)
            .height(18)
            .fillColor(COLOR_PRIMARY)
        }

        // 文字内容
        Column({ space: 2 }) {
          Text('查找终端说明')
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_MEDIUM)
          Text('结合局域网扫描和MAC厂商查询，快速定位并识别网络中的终端设备')
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }
}
