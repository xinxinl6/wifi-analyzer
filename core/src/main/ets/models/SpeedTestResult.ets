// 测速结果数据模型

export interface SpeedTestResult {
  timestamp: string           // 时间戳（如 "2026-04-12 17:48"）
  timeLabel: string            // 显示标签（如 "今天 17:48"）
  downloadSpeed: number        // 下载速度 Mbps
  uploadSpeed: number          // 上传速度 Mbps
  pingMs: number               // 延迟 ms
  jitterMs: number             // 抖动 ms
  bufferbloatDownloadMs: number // 下载满载额外延迟 ms
  bufferbloatUploadMs: number   // 上传满载额外延迟 ms
  networkType: string          // 网络类型
  serverName: string           // 服务器名称
}
