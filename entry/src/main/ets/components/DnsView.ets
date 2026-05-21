// DnsView Component
// 独立的DNS显示组件，内部直接调用 connection API
// 从 AuroraNetworkGrid 的 InfoGridItem 中抽离，保持一致的视觉样式

import { COLOR_AURORA_PRIMARY, COLOR_TEXT_GLASS_PRIMARY, COLOR_TEXT_GLASS_TERTIARY, COLOR_TEXT_LIGHT_PRIMARY, COLOR_TEXT_LIGHT_TERTIARY, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_SKY_SOLID, COLOR_BORDER } from '@wifi-analyzer/design-system'
import { connection } from '@kit.NetworkKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0xFF05
const TAG = 'DnsView'

@Component
export struct DnsView {
  @Prop isDarkMode: boolean = false
  @State private displayDns: string = '获取中...'

  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  private get textTertiary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
  }

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'aboutToAppear, starting fetch...')
    this.fetchDns()
  }

  // 直接在组件内部获取DNS
  private fetchDns(): void {
    try {
      const netHandle = connection.getDefaultNetSync()
      if (netHandle && netHandle.netId !== 0) {
        const connectionProperties: connection.ConnectionProperties = connection.getConnectionPropertiesSync(netHandle)
        if (connectionProperties && connectionProperties.dnses) {
          for (let i = 0; i < connectionProperties.dnses.length; i++) {
            const d = connectionProperties.dnses[i]
            if (d && d.address && !d.address.startsWith('::') && d.address !== '0.0.0.0') {
              this.displayDns = d.address
              hilog.info(DOMAIN, TAG, 'DNS fetched successfully')
              return
            }
          }
        }
      }
    } catch (e) {
      const err: Error = e as Error
      hilog.warn(DOMAIN, TAG, 'fetchDns error: %{public}s', err.message)
    }
    this.displayDns = '--'
    hilog.info(DOMAIN, TAG, 'DNS fallback: --')
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Image($r('app.media.ic_dns'))
          .width(14)
          .height(14)
          .fillColor(COLOR_AURORA_PRIMARY)
        Text($r('app.string.dns'))
          .fontSize(11)
          .fontColor(this.textTertiary)
      }
      .alignItems(VerticalAlign.Center)

      Text(this.displayDns)
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
