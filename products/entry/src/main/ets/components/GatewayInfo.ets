// GatewayInfo — 独立网关信息组件（复刻 GatewayView）
// 内部管理自己的状态和生命周期，不依赖父组件

import { connection } from '@kit.NetworkKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import {
  adaptiveTextPrimary, adaptiveTextSecondary
} from '@wifi-analyzer/design-system'

const TAG = '[GatewayInfo]'

@ComponentV2
export struct GatewayInfo {
  @Param isDark: boolean = true
  @Local displayGateway: string = 'Fetching...'
  private pollTimer: number = -1

  aboutToAppear(): void {
    // 延迟1秒启动 + 每2秒轮询
    setTimeout(() => {
      this.fetchGateway()
      this.pollTimer = setInterval(() => {
        if (this.displayGateway === 'Fetching...' || this.displayGateway === '--') {
          this.fetchGateway()
        } else {
          this.stopPoll()
        }
      }, 2000)
    }, 1000)
  }

  aboutToDisappear(): void {
    this.stopPoll()
  }

  private stopPoll(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer)
      this.pollTimer = -1
    }
  }

  private async fetchGateway(): Promise<void> {
    try {
      const netHandle = await connection.getDefaultNet()
      if (netHandle && netHandle.netId !== 0) {
        const props = await connection.getConnectionProperties(netHandle)
        if (props && props.routes) {
          for (let i = 0; i < props.routes.length; i++) {
            const route = props.routes[i]
            if (route && route.hasGateway && route.gateway) {
              const gw = (route.gateway as connection.NetAddress).address || ''
              if (gw) {
                this.displayGateway = gw
                this.stopPoll()
                return
              }
            }
          }
        }
      }
    } catch (e) { hilog.warn(0x0000, TAG, 'fetchGateway error: %{public}s', JSON.stringify(e)) }
    this.displayGateway = '--'
  }

  build() {
    Column({ space: 2 }) {
      Text(this.displayGateway)
        .fontSize(12).fontWeight(600)
        .fontColor(adaptiveTextPrimary(this.isDark))
        .fontFamily('HarmonyOS Sans Mono')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text($r('app.string.trace_gateway'))
        .fontSize(11).fontColor(adaptiveTextSecondary(this.isDark))
    }.layoutWeight(1).alignItems(HorizontalAlign.Center)
  }
}
