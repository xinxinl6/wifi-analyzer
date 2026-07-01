// SpeedTestTypes — 测速类型定义和常量（从 SpeedTestEngine.ets 拆分）
import { http } from '@kit.NetworkKit'
import { SpeedTestResult } from './SpeedTestModel'

export type ServerType = 'cdn' | 'librespeed'
export type SpeedTestMode = 'http' | 'iperf3'

export interface ServerNode {
  id: string; name: string; type: ServerType; url: string; speedTestUrl: string
  pingUrl: string; uploadUrl: string; latencyMs: number
}

export interface PingData { ping: number; jitter: number }

export interface NetworkTypeOption { key: string; label: string }

interface ModeConfig { downloadThreads: number; uploadThreads: number; durationMs: number }

const MODE_CONFIGS_HTTP: ModeConfig = { downloadThreads: 6, uploadThreads: 4, durationMs: 12000 }
const MODE_CONFIGS_IPERF3: ModeConfig = { downloadThreads: 8, uploadThreads: 6, durationMs: 15000 }

export function getModeConfig(mode: SpeedTestMode): ModeConfig {
  return mode === 'iperf3' ? MODE_CONFIGS_IPERF3 : MODE_CONFIGS_HTTP
}

export const WARMUP_MS: number = 1500
export const DOWNLOAD_CHUNK_SIZE: number = 512 * 1024
export const UPLOAD_CHUNK_SIZE: number = 1 * 1024 * 1024
export const PROGRESS_INTERVAL_MS: number = 200

export const CF_DOWNLOAD_URL: string = 'https://speed.cloudflare.com/__down?bytes=524288'
export const CF_UPLOAD_URL: string = 'https://speed.cloudflare.com/__up'

export const SERVER_NODES: ServerNode[] = [
  { id: 'auto', name: '自动选择最优节点', type: 'cdn', url: '', speedTestUrl: '', pingUrl: '', uploadUrl: '', latencyMs: 0 },
  { id: 'beijing-aliyun', name: '北京 · 阿里云', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://mirrors.aliyun.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 15 },
  { id: 'beijing-tsinghua', name: '北京 · 清华大学', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://mirrors.tuna.tsinghua.edu.cn/', uploadUrl: CF_UPLOAD_URL, latencyMs: 12 },
  { id: 'shanghai-tencent', name: '上海 · 腾讯云', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://mirrors.tencent.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 22 },
  { id: 'shanghai-sjtu', name: '上海 · 上交大', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://mirrors.sjtug.sjtu.edu.cn/', uploadUrl: CF_UPLOAD_URL, latencyMs: 18 },
  { id: 'guangzhou', name: '广州 · 华为云', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://repo.huaweicloud.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 28 },
  { id: 'hefei', name: '合肥 · 中科大', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://mirrors.ustc.edu.cn/', uploadUrl: CF_UPLOAD_URL, latencyMs: 20 },
  { id: 'nanjing', name: '南京 · 南京大学', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://mirrors.nju.edu.cn/', uploadUrl: CF_UPLOAD_URL, latencyMs: 16 },
  { id: 'shenzhen', name: '深圳 · 网易', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://mirrors.163.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 25 },
  { id: 'shenzhen-qq', name: '深圳 · QQ', type: 'cdn', url: '', speedTestUrl: '', pingUrl: 'https://dldir1.qq.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 24 },
  { id: 'ls-cf', name: 'Cloudflare 全球', type: 'librespeed', url: 'https://speed.cloudflare.com', speedTestUrl: '', pingUrl: 'https://speed.cloudflare.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 50 },
]

export const NETWORK_TYPES: NetworkTypeOption[] = [
  { key: 'auto', label: '自动检测' }, { key: 'wifi', label: 'WiFi' }, { key: '5g', label: '5G移动网络' }, { key: '4g', label: '4G/LTE' }
]

// 内部 HTTP 类型
export interface SpeedTestHeaders { 'User-Agent': string; 'Cache-Control'?: string; 'Content-Type'?: string; 'Accept-Encoding'?: string }

export interface DownloadRequestOptions { method: http.RequestMethod; header: SpeedTestHeaders; connectTimeout: number; readTimeout: number; expectDataType: http.HttpDataType }

export interface UploadRequestOptions { method: http.RequestMethod; header: SpeedTestHeaders; extraData: ArrayBuffer; connectTimeout: number; readTimeout: number }

export interface DownloadResult { speed: number; bloatMs: number }
export interface UploadResult { speed: number; bloatMs: number }
export interface PingResultItem { node: ServerNode; ping: number }

// 采样点
export interface SpeedSample { timestamp: number; bytes: number }

export const BURST_WINDOW_MS: number = 1000
export const RECENT_WINDOW_MS: number = 5000
export const EWMA_ALPHA: number = 0.3
export const SAMPLE_MAX: number = 128

export interface SpeedTestCallbacks {
  onPhaseChanged: (phase: string) => void
  onDownloadProgress: (speed: number) => void
  onUploadProgress: (speed: number) => void
  onPingResult: (ping: number, jitter: number) => void
  onComplete: (result: SpeedTestResult) => void
  onError: (error: string) => void
  onCancelled: () => void
}
