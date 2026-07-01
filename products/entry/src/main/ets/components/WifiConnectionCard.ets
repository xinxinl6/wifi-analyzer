// WiFi 连接状态卡片 — 独立系统级监听组件（仅显示状态，不向父组件通信）
// 直接使用 wifiManager + connection API，不依赖扫描结果

import { hilog } from '@kit.PerformanceAnalysisKit'
import wifiManager from '@ohos.wifiManager'
import { connection } from '@kit.NetworkKit'
import {
  adaptiveSuccess, adaptiveDanger, adaptiveTextPrimary, adaptiveTextSecondary
} from '@wifi-analyzer/design-system'

const DOMAIN = 0x0000
const TAG = '[WifiConnectionCard]'

@ComponentV2
export struct WifiConnectionCard {
  @Param isDark: boolean = true

  @Local isConnected: boolean = false

  private netConnection: connection.NetConnection | null = null
  private pollTimerId: number = -1

  aboutToAppear(): void {
    hilog.info(DOMAIN, 'testTag', '[WifiConnectionCard] aboutToAppear')
    // 初始检测
    this.detect()

    // 创建网络连接监听器
    this.netConnection = connection.createNetConnection()
    this.netConnection.on('netAvailable', () => {
      setTimeout(() => { this.detect() }, 500)
    })
    this.netConnection.on('netLost', () => {
      this.setDisconnected()
    })
    this.netConnection.on('netCapabilitiesChange', () => {
      setTimeout(() => { this.detect() }, 600)
    })
    this.netConnection.register((err: Error | null) => {
      if (err) {
        hilog.error(DOMAIN, 'testTag', '[WifiConnectionCard] register error: ' + JSON.stringify(err))
      } else {
        hilog.info(DOMAIN, 'testTag', '[WifiConnectionCard] NetConnection registered')
      }
    })

    // 监听 WiFi 连接事件
    wifiManager.on('wifiConnectionChange', () => {
      setTimeout(() => { this.detect() }, 800)
    })

    // 每 10 秒轮询兜底
    this.pollTimerId = setInterval(() => {
      this.detect()
    }, 10000) as number
  }

  aboutToDisappear(): void {
    hilog.info(DOMAIN, 'testTag', '[WifiConnectionCard] aboutToDisappear')
    try { wifiManager.off('wifiConnectionChange') } catch (e) { hilog.warn(DOMAIN, TAG, 'off wifiConnectionChange error: %{public}s', JSON.stringify(e)) }
    if (this.netConnection) {
      try { this.netConnection.unregister(() => {}) } catch (e) { hilog.warn(DOMAIN, TAG, 'unregister netConnection error: %{public}s', JSON.stringify(e)) }
      this.netConnection = null
    }
    if (this.pollTimerId !== -1) {
      clearInterval(this.pollTimerId)
      this.pollTimerId = -1
    }
  }

  private setDisconnected(): void {
    this.isConnected = false
  }

  private detect(): void {
    connection.getDefaultNet((err: Error | null, netHandle: connection.NetHandle | null) => {
      if (err || !netHandle || netHandle.netId === 0) {
        this.setDisconnected()
        return
      }

      // 尝试 WiFi API
      let isWifiConnected = false
      try {
        const info = wifiManager.getLinkedInfoSync()
        if (info && info.ssid && info.ssid !== ''
          && !info.ssid.toLowerCase().includes('virtwifi')
          && !info.ssid.toLowerCase().includes('virtual')) {
          isWifiConnected = true
        }
      } catch (e) { hilog.warn(DOMAIN, TAG, 'getLinkedInfoSync error: %{public}s', JSON.stringify(e)) }

      if (isWifiConnected) {
        this.isConnected = true
        return
      }

      // 后备：通过 connection API 确认有网络
      try {
        const props = connection.getConnectionPropertiesSync(netHandle)
        const hasRoutes = props && props.routes && props.routes.length > 0
        const hasDns = props && props.dnses && props.dnses.length > 0
        if (hasRoutes || hasDns) {
          this.isConnected = true
          return
        }
      } catch (e) { hilog.warn(DOMAIN, TAG, 'getConnectionPropertiesSync error: %{public}s', JSON.stringify(e)) }

      this.setDisconnected()
    })
  }

  build() {
    Row({ space: 6 }) {
      Circle()
        .width(8).height(8)
        .fill(this.isConnected ? adaptiveSuccess(this.isDark) : adaptiveDanger(this.isDark))
      Text(this.isConnected ? $r('app.string.connected') : $r('app.string.disconnected'))
        .fontSize(12).fontWeight(500)
        .fontColor(this.isConnected ? adaptiveSuccess(this.isDark) : adaptiveTextSecondary(this.isDark))
    }
    .padding({ left: 12, right: 14, top: 6, bottom: 6 })
    .borderRadius(16)
    .backgroundColor(this.isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)')
  }
}
