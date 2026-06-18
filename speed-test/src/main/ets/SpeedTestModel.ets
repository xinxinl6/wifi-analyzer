// WiFi分析仪 — 测速模型

export interface SpeedTestResult {
  timestamp: string;
  timeLabel: string;
  downloadSpeed: number;
  uploadSpeed: number;
  pingMs: number;
  jitterMs: number;
  bufferbloatDownloadMs: number;
  bufferbloatUploadMs: number;
  networkType: string;
  serverName: string;
}
