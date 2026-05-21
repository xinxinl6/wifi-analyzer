// GatewayView Component
// 独立的网关显示组件，内部直接调用 connection API（异步版本）
// 参考 WlAN-03 实现：延迟启动 + 轮询重试 + 异步 API

import { COLOR_AURORA_PRIMARY, COLOR_TEXT_GLASS_PRIMARY, COLOR_TEXT_GLASS_TERTIARY, COLOR_TEXT_LIGHT_PRIMARY, COLOR_TEXT_LIGHT_TERTIARY, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_SKY_SOLID, COLOR_BORDER } from '@wifi-analyzer/design-system'
import { connection } from '@kit.NetworkKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0xFF04
const TAG = 'GatewayView'

@Component
export struct GatewayView {
  @Prop isDarkMode: boolean = false
  @State private displayGateway: string = '获取中...'

  // 轮询定时器ID
  private pollTimer: number = -1

  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  private get textTertiary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
  }

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'aboutToAppear, starting fetch...')

    // 延迟1秒再开始获取，确保网络连接已建立
    setTimeout((): void => {
      this.fetchGateway()
      // 启动轮询，每2秒重试一次
      this.pollTimer = setInterval((): void => {
        if (this.displayGateway === '--' || this.displayGateway === '获取中...') {
          this.fetchGateway()
        } else {
          // 已获取到网关，停止轮询
          if (this.pollTimer !== -1) {
            clearInterval(this.pollTimer)
            this.pollTimer = -1
          }
        }
      }, 2000)
      hilog.info(DOMAIN, TAG, 'Poll timer started (2s interval)')
    }, 1000)
    hilog.info(DOMAIN, TAG, 'Delayed fetch scheduled (1s)')
  }

  aboutToDisappear(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer)
      this.pollTimer = -1
      hilog.info(DOMAIN, TAG, 'Poll timer cleared')
    }
  }

  // 直接在组件内部异步获取网关地址
  private async fetchGateway(): Promise<void> {
    try {
      const netHandle = await connection.getDefaultNet()
      if (netHandle && netHandle.netId !== 0) {
        const connectionProperties = await connection.getConnectionProperties(netHandle)
        if (connectionProperties && connectionProperties.routes) {
          for (let i = 0; i < connectionProperties.routes.length; i++) {
            const route = connectionProperties.routes[i]
            // WlAN-03 模式：只检查 hasGateway && gateway，不强制要求 isDefaultRoute
            if (route && route.hasGateway && route.gateway) {
              const gatewayAddr: connection.NetAddress = route.gateway as connection.NetAddress
              const gateway = gatewayAddr.address || ''
              if (gateway) {
                this.displayGateway = gateway
                hilog.info(DOMAIN, TAG, 'Got real gateway: %{public}s', gateway)
                // 获取到真实网关后停止轮询
                if (this.pollTimer !== -1) {
                  clearInterval(this.pollTimer)
                  this.pollTimer = -1
                  hilog.info(DOMAIN, TAG, 'Poll timer stopped - gateway resolved')
                }
                return
              }
            }
          }
        }
      }
      this.displayGateway = '--'
    } catch (e) {
      const err: Error = e as Error
      hilog.error(DOMAIN, TAG, 'Error: %{public}s', err.message)
      this.displayGateway = '--'
    }
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Image($r('app.media.ic_route'))
          .width(14)
          .height(14)
          .fillColor(COLOR_AURORA_PRIMARY)
        Text($r('app.string.gateway'))
          .fontSize(11)
          .fontColor(this.textTertiary)
      }
      .alignItems(VerticalAlign.Center)

      Text(this.displayGateway)
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
