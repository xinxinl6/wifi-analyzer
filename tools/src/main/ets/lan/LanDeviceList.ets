// 设备列表 — Aurora WiFi V2

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER, COLOR_PURPLE,
  FONT_SIZE_XXS, FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD,
  GLASS_BLUR_MD,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary
} from '@wifi-analyzer/design-system'
import { LanDevice, LanNetworkInfo, LanEngine } from '../lanscan/LanEngine'

// ==================== 设备列表 ====================
@Component
export struct LanDeviceList {
  @Prop isDarkMode: boolean = false
  @Prop filteredDevices: LanDevice[] = []
  @Prop networkInfo: LanNetworkInfo = {
    localIp: '', gateway: '192.168.1.1', subnetMask: '255.255.255.0',
    networkPrefix: '192.168.1', hostCount: 254
  }

  // ==================== 设备类型辅助方法 ====================

  isRouter(device: LanDevice): boolean {
    return LanEngine.isGateway(device.ip, this.networkInfo.gateway)
  }

  isComputer(device: LanDevice): boolean {
    return device.port === 80 || device.port === 443 || device.port === 8080 ||
           LanEngine.isLocalHost(device.ip, this.networkInfo.localIp)
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
      return AppStorage.get<Context>('appContext')?.resourceManager?.getStringSync($r('app.string.lan_router').id) ?? ''
    }
    if (this.isComputer(device)) {
      return AppStorage.get<Context>('appContext')?.resourceManager?.getStringSync($r('app.string.lan_computer').id) ?? ''
    }
    return AppStorage.get<Context>('appContext')?.resourceManager?.getStringSync($r('app.string.lan_device').id) ?? ''
  }

  getDeviceTypeShortLabel(device: LanDevice): string {
    if (this.isRouter(device)) {
      return AppStorage.get<Context>('appContext')?.resourceManager?.getStringSync($r('app.string.lan_gateway').id) ?? ''
    }
    if (this.isComputer(device)) {
      return AppStorage.get<Context>('appContext')?.resourceManager?.getStringSync($r('app.string.lan_host').id) ?? ''
    }
    return AppStorage.get<Context>('appContext')?.resourceManager?.getStringSync($r('app.string.lan_device').id) ?? ''
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

  // ==================== 构建 ====================

  build() {
    Column({ space: SPACE_SM }) {
      Row() {
        Text($r('app.string.lan_discovered_devices'))
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span(String(this.filteredDevices.length))
          Span(' ')
          Span($r('app.string.lan_unit'))
        }
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
}
