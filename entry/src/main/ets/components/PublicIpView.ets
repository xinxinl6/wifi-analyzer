// PublicIpView Component
// 独立的公网IP显示组件，内部直接处理HTTP请求
// 从 AuroraNetworkGrid 的 InfoGridItem 中抽离，保持一致的视觉样式

import { COLOR_AURORA_PRIMARY, COLOR_TEXT_GLASS_PRIMARY, COLOR_TEXT_GLASS_TERTIARY, COLOR_TEXT_LIGHT_PRIMARY, COLOR_TEXT_LIGHT_TERTIARY, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_SKY_SOLID, COLOR_BORDER } from '@wifi-analyzer/design-system'
import { http } from '@kit.NetworkKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0xFF02
const TAG = 'PublicIpView'

@Component
export struct PublicIpView {
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
    this.fetchPublicIp()
  }

  // 直接在组件内部获取公网IP（多API降级）
  private async fetchPublicIp(): Promise<void> {
    const apis: string[] = [
      'https://myip.ipip.net',
      'https://ip.3322.net',
      'https://pv.sohu.com/ipimsg',
      'https://api.ipify.org?format=text',
      'https://checkip.amazonaws.com'
    ]

    for (let i = 0; i < apis.length; i++) {
      try {
        hilog.info(DOMAIN, TAG, 'Trying API: %{public}s', apis[i])
        const request = http.createHttp()
        const result: http.HttpResponse = await request.request(apis[i], {
          method: http.RequestMethod.GET,
          connectTimeout: 5000,
          readTimeout: 5000
        } as http.HttpRequestOptions)
        request.destroy()

        if (result.responseCode === 200 && result.result) {
          const text: string = result.result.toString()
          const match = text.match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)
          if (match && match[1]) {
            this.displayIp = match[1]
            hilog.info(DOMAIN, TAG, 'Got IP: %{public}s', match[1])
            return
          }
        }
        hilog.warn(DOMAIN, TAG, 'API %{public}s failed, trying next...', apis[i])
      } catch (e) {
        const err: Error = e as Error
        hilog.warn(DOMAIN, TAG, 'API %{public}s error: %{public}s', apis[i], err.message)
      }
    }

    hilog.error(DOMAIN, TAG, 'All public IP APIs failed')
    this.displayIp = '--'
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Image($r('app.media.ic_route'))
          .width(14)
          .height(14)
          .fillColor(COLOR_AURORA_PRIMARY)
        Text($r('app.string.public_ip'))
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
