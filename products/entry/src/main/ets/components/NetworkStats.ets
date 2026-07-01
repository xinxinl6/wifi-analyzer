// NetworkStats — 网络状态统计组件（连接速度 + 延迟）
// 独立获取连接速度和网络延迟，自带卡片样式

import { wifiManager } from '@kit.ConnectivityKit'
import { socket } from '@kit.NetworkKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { NetworkTimeout, NetworkPort } from '@wifi-analyzer/core'
import {
  RADIUS_XL,
  adaptiveCardDarkGlass, adaptiveDivider,
  adaptiveTextSecondary,
  adaptiveInfo, adaptiveWarning
} from '@wifi-analyzer/design-system'

const TAG = '[NetworkStats]'

@ComponentV2
export struct LinkSpeedStat {
  @Param isDark: boolean = true
  @Local linkSpeed: string = '—'

  aboutToAppear(): void {
    this.fetchLinkSpeed()
  }

  private fetchLinkSpeed(): void {
    try {
      const linkInfo = wifiManager.getLinkedInfoSync()
      if (linkInfo && linkInfo.linkSpeed > 0) {
        this.linkSpeed = String(linkInfo.linkSpeed)
      } else {
        this.linkSpeed = '—'
      }
    } catch (e) {
      this.linkSpeed = '—'
    }
  }

  build() {
    Column({ space: 2 }) {
      Text(this.linkSpeed).fontSize(24).fontWeight(800)
        .fontColor(adaptiveInfo(this.isDark))
        .fontFamily('HarmonyOS Sans Mono').letterSpacing(-0.3)
      Text($r('app.string.netstat_link_speed')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(500)
      Text($r('app.string.unit_mbps')).fontSize(10).fontColor(adaptiveTextSecondary(this.isDark))
    }
    .width('100%').height(86).padding(14)
    .alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center)
    .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
    .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid).clip(true)
  }
}

@ComponentV2
export struct LatencyStat {
  @Param isDark: boolean = true
  @Local latency: string = '—'
  @Local isTesting: boolean = true

  aboutToAppear(): void {
    this.measureLatency()
  }

  private async measureLatency(): Promise<void> {
    const targets = ['192.168.1.1', '223.5.5.5', '8.8.8.8']
    for (let i = 0; i < targets.length; i++) {
      const target = targets[i]
      try {
        const result = await this.pingOnce(target)
        if (result > 0) {
          this.latency = String(result)
          this.isTesting = false
          return
        }
      } catch (e) { hilog.warn(0x0000, TAG, 'latency probe error: %{public}s', JSON.stringify(e)) }
    }
    this.latency = '—'
    this.isTesting = false
  }

  private pingOnce(host: string): Promise<number> {
    return new Promise((resolve) => {
      try {
        const tcpSocket = socket.constructTCPSocketInstance()
        const startTime = Date.now()
        tcpSocket.connect({ address: { address: host, port: NetworkPort.DNS }, timeout: NetworkTimeout.LATENCY_PROBE_MS })
          .then(() => {
            const latency = Date.now() - startTime
            tcpSocket.close()
            resolve(latency)
          })
          .catch(() => {
            try { tcpSocket.close(() => {}) } catch (_e) { hilog.warn(0x0000, TAG, 'tcpSocket close error in catch') }
            resolve(0)
          })
      } catch (e) {
        resolve(0)
      }
    })
  }

  build() {
    Column({ space: 2 }) {
      Text(this.latency).fontSize(24).fontWeight(800)
        .fontColor(adaptiveWarning(this.isDark))
        .fontFamily('HarmonyOS Sans Mono').letterSpacing(-0.3)
      Text($r('app.string.netstat_network_latency')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(500)
      Text($r('app.string.unit_ms')).fontSize(10).fontColor(adaptiveTextSecondary(this.isDark))
    }
    .width('100%').height(86).padding(14)
    .alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center)
    .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
    .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid).clip(true)
  }
}
