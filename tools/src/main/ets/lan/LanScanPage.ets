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
import { FilterType } from './LanSearchFilter'
import { ScanProgressState, ScanStats } from './LanScanProgress'
import { LanIdleState, LanActionButtons } from './LanIdleView'
import { LanScanProgress } from './LanScanProgress'
import { LanDeviceList } from './LanDeviceList'
import { LanSearchFilter } from './LanSearchFilter'

// 扫描模式类型
enum ScanMode {
  QUICK = 'quick',
  FULL = 'full'
}

@Component
export struct LanScanPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  @State viewMode: string = 'idle'
  @State scanMode: ScanMode = ScanMode.QUICK
  @State currentFilter: FilterType = FilterType.ALL
  @State searchKeyword: string = ''
  @State networkInfo: LanNetworkInfo = {
    localIp: '', gateway: '192.168.1.1', subnetMask: '255.255.255.0',
    networkPrefix: '192.168.1', hostCount: 254
  }
  @State scanProgress: ScanProgressState = {
    progress: 0, total: 254, currentIp: '',
    startTime: 0, duration: 0
  }
  @State scanStats: ScanStats = {
    onlineCount: 0, errorMessage: ''
  }
  @State deviceList: LanDevice[] = []
  @State filteredDevices: LanDevice[] = []

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
    this.updateFilteredCache()
  }

  private updateFilteredCache(): void {
    this.filteredDevices = this.getFilteredDevices()
  }

  getFilteredDevices(): LanDevice[] {
    let filtered: LanDevice[] = this.deviceList
    if (this.searchKeyword.trim() !== '') {
      const keyword: string = this.searchKeyword.toLowerCase()
      filtered = filtered.filter((device: LanDevice): boolean => {
        const matchIp: boolean = device.ip.toLowerCase().includes(keyword)
        const matchMac: boolean = device.mac.toLowerCase().includes(keyword)
        const matchVendor: boolean = device.vendor ? device.vendor.toLowerCase().includes(keyword) : false
        return matchIp || matchMac || matchVendor
      })
    }
    switch (this.currentFilter) {
      case FilterType.ONLINE:
        return filtered.filter((d: LanDevice): boolean => d.status === 'online')
      case FilterType.ROUTER:
        return filtered.filter((d: LanDevice): boolean => LanEngine.isGateway(d.ip, this.networkInfo.gateway))
      case FilterType.COMPUTER:
        return filtered.filter((d: LanDevice): boolean =>
          d.port === 80 || d.port === 443 || d.port === 8080 || LanEngine.isLocalHost(d.ip, this.networkInfo.localIp))
      default:
        return filtered
    }
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
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

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

      Column() {
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
        // 搜索框 + 筛选标签
        LanSearchFilter({
          isDarkMode: this.isDarkMode,
          searchKeyword: this.searchKeyword,
          currentFilter: this.currentFilter,
          onSearchChange: (val: string) => { this.searchKeyword = val; this.updateFilteredCache() },
          onFilterChange: (filter: FilterType) => { this.currentFilter = filter; this.updateFilteredCache() },
          onResetFilter: () => this.resetFilter()
        })

        // 扫描模式选择
        if (this.viewMode === 'idle') {
          Column({ space: 0 }) {
            this.ScanModeSelector()
          }
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
              .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
            TransitionEffect.OPACITY.animation({ duration: 200 })
          ))
        }

        // 扫描进度
        if (this.viewMode === 'scanning') {
          Column({ space: 0 }) {
            LanScanProgress({
              isDarkMode: this.isDarkMode,
              scanProgress: this.scanProgress,
              scanStats: this.scanStats,
              progressPercent: this.getProgressPercent()
            })
          }
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
              .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
            TransitionEffect.OPACITY.animation({ duration: 200 })
          ))
        }

        // 设备列表
        if (this.viewMode === 'done' || this.viewMode === 'error' || this.deviceList.length > 0) {
          Column({ space: 0 }) {
            LanDeviceList({
              isDarkMode: this.isDarkMode,
              filteredDevices: this.filteredDevices,
              networkInfo: this.networkInfo
            })
          }
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
              .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
            TransitionEffect.OPACITY.animation({ duration: 200 })
          ))
        }

        // 空状态
        if (this.viewMode === 'idle' && this.deviceList.length === 0) {
          Column({ space: 0 }) {
            LanIdleState({ isDarkMode: this.isDarkMode })
          }
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
              .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
            TransitionEffect.OPACITY.animation({ duration: 200 })
          ))
        }

        // 操作按钮
        LanActionButtons({
          isDarkMode: this.isDarkMode,
          viewMode: this.viewMode,
          onStartScan: () => this.startScan(),
          onStopScan: () => this.stopScan()
        })

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

  // ==================== 扫描模式选择（内联） ====================
  @Builder ScanModeSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.lan_scan_mode'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_MD }) {
        this.ScanModeCard($r('app.string.lan_quick_scan'), $r('app.string.lan_quick_scan_desc'), $r('app.media.ic_lan'), ScanMode.QUICK)
        this.ScanModeCard($r('app.string.lan_full_scan'), $r('app.string.lan_full_scan_desc'), $r('app.media.ic_port'), ScanMode.FULL)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder ScanModeCard(title: string | Resource, desc: string | Resource, icon: Resource, mode: ScanMode) {
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

  // ==================== 功能说明卡片（内联） ====================
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
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

        Column({ space: 2 }) {
          Text($r('app.string.lan_find_device_intro'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.lan_find_device_desc'))
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
