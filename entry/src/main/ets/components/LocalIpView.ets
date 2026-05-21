// LocalIpView Component
// 独立的本机IP显示组件，内部直接调用 wifiManager API
// 从 AuroraNetworkGrid 的 InfoGridItem 中抽离，保持一致的视觉样式

import { COLOR_AURORA_PRIMARY, COLOR_TEXT_GLASS_PRIMARY, COLOR_TEXT_GLASS_TERTIARY, COLOR_TEXT_LIGHT_PRIMARY, COLOR_TEXT_LIGHT_TERTIARY, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_SKY_SOLID, COLOR_BORDER } from '@wifi-analyzer/design-system'
import { wifiManager } from '@kit.ConnectivityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0xFF03
const TAG = 'LocalIpView'

@Component
export struct LocalIpView {
  @Prop isDarkMode: boolean = false
  @State private displayIp: string = '获取中...'

  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  private get textTertiary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
  }

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'aboutToAppear, starting fetch...')
    this.fetchLocalIp()
  }

  // 直接在组件内部获取本机IP
  private fetchLocalIp(): void {
    try {
      const ipInfo = wifiManager.getIpInfo()
      if (ipInfo && ipInfo.ipAddress && ipInfo.ipAddress !== 0) {
        const ip: string = ((ipInfo.ipAddress >>> 24) & 0xFF) + '.' +
                   ((ipInfo.ipAddress >> 16) & 0xFF) + '.' +
                   ((ipInfo.ipAddress >> 8) & 0xFF) + '.' +
                   (ipInfo.ipAddress & 0xFF)
        if (ip !== '0.0.0.0') {
          this.displayIp = ip
          hilog.info(DOMAIN, TAG, 'Local IP fetched: %{public}s', ip)
          return
        }
      }
    } catch (e) {
      const err: Error = e as Error
      hilog.warn(DOMAIN, TAG, 'wifiManager.getIpInfo failed: %{public}s', err.message)
    }
    this.displayIp = '--'
    hilog.info(DOMAIN, TAG, 'Local IP fallback: --')
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Image($r('app.media.ic_device'))
          .width(14)
          .height(14)
          .fillColor(COLOR_AURORA_PRIMARY)
        Text($r('app.string.local_ip'))
          .fontSize(11)
          .fontColor(this.textTertiary)
      }
      .alignItems(VerticalAlign.Center)

      Text(this.displayIp)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_SOLID)
    .borderRadius(12)
    .border({
      width: this.isDarkMode ? 1 : 0,
      color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_BORDER,
      radius: 12
    })
  }
}
