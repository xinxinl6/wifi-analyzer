// WiFi项目数据模型
export interface WifiItem {
  ssid: string
  bssid: string
  signal: number       // RSSI (dBm), e.g. -45
  freq: number         // 频段: 2.4 或 5 (GHz)
  channel: number      // 信道号, e.g. 149, 6, 11
  security: string     // 加密类型: WPA2, WPA3, OPEN 等
  isConnected?: boolean // 是否为当前已连接的网络
  bandwidth?: string   // 频宽: 20MHz, 40MHz, 80MHz, 160MHz（根据信道估算）
}
