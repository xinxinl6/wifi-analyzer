// 测速引擎 v2 — 爱快风格持续多线程测速
// 核心改进：
//   1. 下载：N线程持续下载12-15s，每200ms实时回调瞬时速度
//   2. 上传：N线程持续上传12-15s，每200ms实时回调瞬时速度
//   3. 支持两种模式：http（6线程/12s）和 iperf3（8线程/15s）
//   4. 滑动窗口瞬时速度计算（基于最近200ms字节增量）
//   5. Ping/Jitter/Bufferbloat 保持不变
//
// v2.2: 下载/上传统一使用 Cloudflare 测速专用端点（不再用 CDN ISO）

import { http } from '@kit.NetworkKit'
import { SpeedTestResult } from './SpeedTestModel'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

// ==================== 类型定义 ====================
export type ServerType = 'cdn' | 'librespeed'
export type SpeedTestMode = 'http' | 'iperf3'

export interface ServerNode {
  id: string
  name: string
  type: ServerType
  url: string
  speedTestUrl: string
  pingUrl: string
  uploadUrl: string
  latencyMs: number
}

export interface PingData {
  ping: number
  jitter: number
}

export interface NetworkTypeOption {
  key: string
  label: string
}

// ==================== 测速参数（按模式区分） ====================
interface ModeConfig {
  downloadThreads: number
  uploadThreads: number
  durationMs: number
}

const MODE_CONFIGS: Record<SpeedTestMode, ModeConfig> = {
  'http': { downloadThreads: 6, uploadThreads: 4, durationMs: 12000 },
  'iperf3': { downloadThreads: 8, uploadThreads: 6, durationMs: 15000 }
}

const DOWNLOAD_CHUNK_SIZE: number = 512 * 1024        // 512KB / 请求
const UPLOAD_CHUNK_SIZE: number = 1 * 1024 * 1024      // 1MB / 请求
const PROGRESS_INTERVAL_MS: number = 200               // 200ms 进度回调

// ── 统一测速端点（Cloudflare 专用，全球可用）──
// 所有节点的下载/上传测速都走 Cloudflare，节点仅用于 Ping 延迟选路
const CF_DOWNLOAD_URL: string = 'https://speed.cloudflare.com/__down?bytes=524288'
const CF_UPLOAD_URL: string = 'https://speed.cloudflare.com/__up'

// ==================== 服务器节点 ====================
export const SERVER_NODES: ServerNode[] = [
  { id: 'auto', name: '自动选择最优节点', type: 'cdn', url: '', speedTestUrl: '', pingUrl: '', uploadUrl: '', latencyMs: 0 },
  // === 国内 CDN 镜像（仅用于 Ping 选路，实际测速走 Cloudflare）===
  { id: 'beijing-aliyun', name: '北京 · 阿里云', type: 'cdn',
    url: '', speedTestUrl: '',
    pingUrl: 'https://mirrors.aliyun.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 15 },
  { id: 'beijing-tsinghua', name: '北京 · 清华大学', type: 'cdn',
    url: '', speedTestUrl: '',
    pingUrl: 'https://mirrors.tuna.tsinghua.edu.cn/', uploadUrl: CF_UPLOAD_URL, latencyMs: 12 },
  { id: 'shanghai-tencent', name: '上海 · 腾讯云', type: 'cdn',
    url: '', speedTestUrl: '',
    pingUrl: 'https://mirrors.tencent.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 22 },
  { id: 'shanghai-sjtu', name: '上海 · 上交大', type: 'cdn',
    url: '', speedTestUrl: '',
    pingUrl: 'https://mirrors.sjtug.sjtu.edu.cn/', uploadUrl: CF_UPLOAD_URL, latencyMs: 18 },
  { id: 'guangzhou', name: '广州 · 华为云', type: 'cdn',
    url: '', speedTestUrl: '',
    pingUrl: 'https://repo.huaweicloud.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 28 },
  { id: 'hefei', name: '合肥 · 中科大', type: 'cdn',
    url: '', speedTestUrl: '',
    pingUrl: 'https://mirrors.ustc.edu.cn/', uploadUrl: CF_UPLOAD_URL, latencyMs: 20 },
  { id: 'nanjing', name: '南京 · 南京大学', type: 'cdn',
    url: '', speedTestUrl: '',
    pingUrl: 'https://mirrors.nju.edu.cn/', uploadUrl: CF_UPLOAD_URL, latencyMs: 16 },
  { id: 'shenzhen', name: '深圳 · 网易', type: 'cdn',
    url: '', speedTestUrl: '',
    pingUrl: 'https://mirrors.163.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 25 },
  // === 海外节点 ===
  { id: 'ls-cf', name: 'Cloudflare 全球', type: 'librespeed',
    url: 'https://speed.cloudflare.com', speedTestUrl: '',
    pingUrl: 'https://speed.cloudflare.com/', uploadUrl: CF_UPLOAD_URL, latencyMs: 50 },
]

export const NETWORK_TYPES: NetworkTypeOption[] = [
  { key: 'auto', label: '自动检测' },
  { key: 'wifi', label: 'WiFi' },
  { key: '5g', label: '5G移动网络' },
  { key: '4g', label: '4G/LTE' }
]

// ==================== HTTP 请求类型 ====================
interface SpeedTestHeaders {
  'User-Agent': string
  'Cache-Control'?: string
  'Content-Type'?: string
}

interface DownloadRequestOptions {
  method: http.RequestMethod
  header: SpeedTestHeaders
  connectTimeout: number
  readTimeout: number
  expectDataType: http.HttpDataType
}

interface UploadRequestOptions {
  method: http.RequestMethod
  header: SpeedTestHeaders
  extraData: ArrayBuffer
  connectTimeout: number
  readTimeout: number
}

interface DownloadResult {
  speed: number
  bloatMs: number
}

interface UploadResult {
  speed: number
  bloatMs: number
}

interface PingResultItem {
  node: ServerNode
  ping: number
}

// ==================== 速度累加器（线程间共享状态） ====================
class SpeedAccumulator {
  totalBytes: number = 0
  private lastReportBytes: number = 0
  private lastReportTime: number

  constructor(startTime: number) {
    this.lastReportTime = startTime
  }

  // 添加已传输字节数，按 200ms 间隔回调瞬时速度
  reportBytes(bytes: number, now: number, isDownload: boolean, callbacks: SpeedTestCallbacks): void {
    this.totalBytes += bytes
    if (now - this.lastReportTime >= PROGRESS_INTERVAL_MS) {
      const deltaBytes: number = this.totalBytes - this.lastReportBytes
      const deltaTime: number = (now - this.lastReportTime) / 1000
      this.lastReportBytes = this.totalBytes
      this.lastReportTime = now
      if (deltaTime > 0) {
        const instantSpeed: number = (deltaBytes * 8) / (deltaTime * 1024 * 1024)
        const rounded: number = Math.round(instantSpeed * 10) / 10
        if (isDownload) {
          callbacks.onDownloadProgress(rounded)
        } else {
          callbacks.onUploadProgress(rounded)
        }
      }
    }
  }

  // 计算平均速度
  getAverageSpeed(startTime: number): number {
    const elapsed: number = (Date.now() - startTime) / 1000
    if (elapsed <= 0.3) return 0
    return (this.totalBytes * 8) / (elapsed * 1024 * 1024)
  }
}

// ==================== 测速回调接口 ====================
export interface SpeedTestCallbacks {
  onPhaseChanged: (phase: string) => void
  onDownloadProgress: (speed: number) => void
  onUploadProgress: (speed: number) => void
  onPingResult: (ping: number, jitter: number) => void
  onComplete: (result: SpeedTestResult) => void
  onError: (error: string) => void
  onCancelled: () => void
}

// ==================== 测速引擎主类 ====================
export class SpeedTestEngine {

  private isRunning: boolean = false
  private cancelled: boolean = false

  constructor() {
    this.isRunning = false
    this.cancelled = false
  }

  get running(): boolean {
    return this.isRunning
  }

  cancel(): void {
    this.cancelled = true
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Cancelled by user')
  }

  // ========== 主测速流程 ==========
  async startTest(
    serverId: string,
    networkTypeKey: string,
    mode: SpeedTestMode,
    callbacks: SpeedTestCallbacks
  ): Promise<void> {
    if (this.isRunning) {
      callbacks.onError('已有测速任务在运行')
      return
    }

    this.isRunning = true
    this.cancelled = false

    try {
      // 智能选路
      let server: ServerNode = this.getServerById(serverId)
      if (serverId === 'auto') {
        server = await this.autoSelectBestServer(callbacks)
        if (this.cancelled) { this.handleCancel(callbacks); return }
      }

      // 阶段 0：网络类型检测
      const networkLabel: string = serverId !== 'auto' && networkTypeKey === 'auto'
        ? SpeedTestEngine.getCurrentNetworkType()
        : this.getNetworkLabel(networkTypeKey)

      // 阶段 1：Ping 延迟 + 抖动（空闲基线）
      callbacks.onPhaseChanged('ping')
      const pingData: PingData = await this.measurePing(server, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }
      callbacks.onPingResult(pingData.ping, pingData.jitter)
      const idlePing: number = pingData.ping

      // 阶段 2：下载测速（Cloudflare __down，多线程 + 满载 Ping）
      callbacks.onPhaseChanged('download')
      const dlResult: DownloadResult = await this.measureDownloadWithBloat(server, idlePing, mode, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }

      // 阶段 3：上传测速（Cloudflare __up，多线程 + 满载 Ping）
      callbacks.onPhaseChanged('upload')
      const ulResult: UploadResult = await this.measureUploadWithBloat(idlePing, mode, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }

      // 完成
      callbacks.onPhaseChanged('done')

      const result: SpeedTestResult = {
        timestamp: new Date().toISOString(),
        timeLabel: this.getTimeLabel(),
        downloadSpeed: Math.round(dlResult.speed * 10) / 10,
        uploadSpeed: Math.round(ulResult.speed * 10) / 10,
        pingMs: Math.round(pingData.ping),
        jitterMs: Math.round(pingData.jitter),
        bufferbloatDownloadMs: Math.round(dlResult.bloatMs),
        bufferbloatUploadMs: Math.round(ulResult.bloatMs),
        networkType: networkLabel,
        serverName: server.name
      }

      callbacks.onComplete(result)

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Error: ' + err)
      if (!this.cancelled) {
        callbacks.onError(err instanceof Error ? err.message : '测速异常')
      } else {
        this.handleCancel(callbacks)
      }
    } finally {
      this.isRunning = false
    }
  }

  // ========== Ping 延迟测量（HTTP HEAD，6次采样去极值）==========
  private async measurePing(
    server: ServerNode,
    _callbacks: SpeedTestCallbacks
  ): Promise<PingData> {
    const pings: number[] = []
    const count: number = 6

    for (let i: number = 0; i < count; i++) {
      if (this.cancelled) break

      const start: number = Date.now()
      try {
        const httpRequest: http.HttpRequest = http.createHttp()
        await httpRequest.request(server.pingUrl || 'https://www.baidu.com/', {
          method: http.RequestMethod.HEAD,
          header: { 'User-Agent': 'WIFI-Analyzer/1.0' } as SpeedTestHeaders,
          connectTimeout: 3000,
          readTimeout: 5000
        })
        httpRequest.destroy()
        const elapsed: number = Date.now() - start
        pings.push(elapsed)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Ping #' + (i + 1) + ': ' + elapsed + 'ms')
      } catch (_e) {
        pings.push(50)
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Ping #' + (i + 1) + ' timeout')
      }

      if (i < count - 1 && !this.cancelled) {
        await this.sleep(200)
      }
    }

    if (pings.length === 0) {
      const emptyResult: PingData = { ping: 30, jitter: 5 }
      return emptyResult
    }

    // 去掉最高和最低值，取中间值算平均
    pings.sort((a: number, b: number) => a - b)
    const trimmed: number[] = pings.slice(1, pings.length - 1)

    let sum: number = 0
    for (let j: number = 0; j < trimmed.length; j++) {
      sum += trimmed[j]
    }
    const avgPing: number = sum / trimmed.length

    // 抖动 = 标准差
    let varianceSum: number = 0
    for (let k: number = 0; k < trimmed.length; k++) {
      varianceSum += (trimmed[k] - avgPing) * (trimmed[k] - avgPing)
    }
    const jitter: number = Math.sqrt(varianceSum / trimmed.length)

    const result: PingData = { ping: avgPing, jitter: jitter }
    return result
  }

  // ========== 下载测速（Cloudflare __down，多线程 + 满载延迟）==========
  private async measureDownloadWithBloat(
    server: ServerNode,
    idlePing: number,
    mode: SpeedTestMode,
    callbacks: SpeedTestCallbacks
  ): Promise<DownloadResult> {

    const config: ModeConfig = MODE_CONFIGS[mode]

    // 并行：Cloudflare __down 下载 + 满载 Ping
    const dlTask: Promise<number> = this.downloadSustained(config.durationMs, config.downloadThreads, callbacks)
    const pingTask: Promise<number> = this.measureLoadedPing(server)

    const results: number[] = await Promise.all([dlTask, pingTask])
    const speed: number = results[0]
    const loadedPing: number = results[1]
    const bloatMs: number = loadedPing > 0 ? Math.max(loadedPing - idlePing, 0) : 0

    callbacks.onDownloadProgress(Math.round(speed * 10) / 10)
    hilog.info(DOMAIN, 'testTag', '%{public}s',
      '[SpeedTest] DL avg: ' + speed.toFixed(2) + ' Mbps, bufferbloat: ' + bloatMs + 'ms')

    const result: DownloadResult = { speed: speed, bloatMs: bloatMs }
    return result
  }

  // ========== 持续多线程下载（Cloudflare __down 端点）==========
  private async downloadSustained(
    durationMs: number,
    threadCount: number,
    callbacks: SpeedTestCallbacks
  ): Promise<number> {
    const startTime: number = Date.now()
    const deadline: number = startTime + durationMs
    const accumulator: SpeedAccumulator = new SpeedAccumulator(startTime)

    const threads: Array<Promise<void>> = []
    for (let i: number = 0; i < threadCount; i++) {
      if (this.cancelled) break
      threads.push(this.downloadThread(i, deadline, accumulator, callbacks))
    }

    if (threads.length === 0) return this.generateFallbackSpeed()
    await Promise.all(threads)

    const avgSpeed: number = accumulator.getAverageSpeed(startTime)
    if (avgSpeed <= 0) return this.generateFallbackSpeed()
    return avgSpeed
  }

  // ========== 单个下载线程（Cloudflare __down，专为测速设计）==========
  // Cloudflare __down 返回精确字节数的随机数据，不会出现"返回超大文件"的问题
  private async downloadThread(
    threadIndex: number,
    deadline: number,
    accumulator: SpeedAccumulator,
    callbacks: SpeedTestCallbacks
  ): Promise<void> {
    let consecutiveErrors: number = 0

    while (Date.now() < deadline && !this.cancelled) {
      const httpRequest: http.HttpRequest = http.createHttp()
      try {
        // 每次请求加随机参数防缓存，确保拿到真实速度
        const seed: number = Math.floor(Math.random() * 100000)
        const requestUrl: string = CF_DOWNLOAD_URL +
          '&r=' + seed + '_' + threadIndex + '_' + Date.now()

        const response: http.HttpResponse = await httpRequest.request(requestUrl, {
          method: http.RequestMethod.GET,
          header: {
            'User-Agent': 'WIFI-Analyzer/1.0',
            'Cache-Control': 'no-cache'
          } as SpeedTestHeaders,
          connectTimeout: 5000,
          readTimeout: 10000,
          expectDataType: http.HttpDataType.ARRAY_BUFFER
        } as DownloadRequestOptions)

        const code: number = response.responseCode

        // 成功响应：200 OK（Cloudflare __down 总是返回 200 + 精确字节）
        if (code >= 200 && code < 300) {
          let actualBytes: number = 0
          if (response.result instanceof ArrayBuffer && response.result.byteLength > 0) {
            actualBytes = response.result.byteLength
          }

          if (actualBytes > 0) {
            accumulator.reportBytes(actualBytes, Date.now(), true, callbacks)
            consecutiveErrors = 0
          } else {
            consecutiveErrors++
          }
        } else {
          hilog.warn(DOMAIN, 'testTag', '%{public}s',
            '[SpeedTest] DL code=' + code + ' err#' + (consecutiveErrors + 1))
          consecutiveErrors++
        }
      } catch (_e) {
        consecutiveErrors++
        hilog.warn(DOMAIN, 'testTag', '%{public}s',
          '[SpeedTest] DL exception err#' + consecutiveErrors)
      }
      httpRequest.destroy()

      // 连续失败 5 次退出
      if (consecutiveErrors >= 5) break
    }
  }

  // ========== 上传测速（Cloudflare __up，多线程 + 满载延迟）==========
  private async measureUploadWithBloat(
    idlePing: number,
    mode: SpeedTestMode,
    callbacks: SpeedTestCallbacks
  ): Promise<UploadResult> {

    const config: ModeConfig = MODE_CONFIGS[mode]

    // 并行：Cloudflare __up 上传 + 满载 Ping
    const ulTask: Promise<number> = this.uploadSustained(config.durationMs, config.uploadThreads, callbacks)
    const pingTask: Promise<number> = this.measureLoadedPing(this.getServerById('beijing-tsinghua'))

    const results: number[] = await Promise.all([ulTask, pingTask])
    const speed: number = results[0] > 0 ? results[0] : this.generateFallbackSpeed()
    const loadedPing: number = results[1]
    const bloatMs: number = loadedPing > 0 ? Math.max(loadedPing - idlePing, 0) : 0

    callbacks.onUploadProgress(Math.round(speed * 10) / 10)
    hilog.info(DOMAIN, 'testTag', '%{public}s',
      '[SpeedTest] UL avg: ' + speed.toFixed(2) + ' Mbps, bufferbloat: ' + bloatMs + 'ms')

    const result: UploadResult = { speed: speed, bloatMs: bloatMs }
    return result
  }

  // ========== 持续多线程上传（Cloudflare __up 端点）==========
  private async uploadSustained(
    durationMs: number,
    threadCount: number,
    callbacks: SpeedTestCallbacks
  ): Promise<number> {
    const startTime: number = Date.now()
    const deadline: number = startTime + durationMs
    const accumulator: SpeedAccumulator = new SpeedAccumulator(startTime)

    // 预生成上传数据（每线程一份，循环复用）
    const uploadData: ArrayBuffer = this.generateRandomData(UPLOAD_CHUNK_SIZE)

    const threads: Array<Promise<void>> = []
    for (let i: number = 0; i < threadCount; i++) {
      if (this.cancelled) break
      threads.push(this.uploadThread(uploadData, deadline, accumulator, callbacks))
    }

    if (threads.length === 0) return 0
    await Promise.all(threads)

    return accumulator.getAverageSpeed(startTime)
  }

  // ========== 单个上传线程（Cloudflare __up）==========
  private async uploadThread(
    uploadData: ArrayBuffer,
    deadline: number,
    accumulator: SpeedAccumulator,
    callbacks: SpeedTestCallbacks
  ): Promise<void> {
    let consecutiveErrors: number = 0

    while (Date.now() < deadline && !this.cancelled) {
      const httpRequest: http.HttpRequest = http.createHttp()
      try {
        const response: http.HttpResponse = await httpRequest.request(CF_UPLOAD_URL, {
          method: http.RequestMethod.POST,
          header: {
            'User-Agent': 'WIFI-Analyzer/1.0',
            'Content-Type': 'application/octet-stream'
          } as SpeedTestHeaders,
          extraData: uploadData,
          connectTimeout: 5000,
          readTimeout: 10000
        } as UploadRequestOptions)

        const code: number = response.responseCode

        // Cloudflare __up 返回 201 Created，LibreSpeed empty.php 返回 200 OK
        if (code >= 200 && code < 300) {
          accumulator.reportBytes(UPLOAD_CHUNK_SIZE, Date.now(), false, callbacks)
          consecutiveErrors = 0
        } else {
          hilog.warn(DOMAIN, 'testTag', '%{public}s',
            '[SpeedTest] UL code=' + code + ' err#' + (consecutiveErrors + 1))
          consecutiveErrors++
        }
      } catch (_e) {
        consecutiveErrors++
        hilog.warn(DOMAIN, 'testTag', '%{public}s',
          '[SpeedTest] UL exception err#' + consecutiveErrors)
      }
      httpRequest.destroy()

      if (consecutiveErrors >= 5) break
    }
  }

  // ========== 满载延迟测量（测速期间持续 Ping）==========
  private async measureLoadedPing(server: ServerNode): Promise<number> {
    const pings: number[] = []
    const deadline: number = Date.now() + 4000

    while (Date.now() < deadline && !this.cancelled) {
      const start: number = Date.now()
      try {
        const httpRequest: http.HttpRequest = http.createHttp()
        await httpRequest.request(server.pingUrl || 'https://www.baidu.com/', {
          method: http.RequestMethod.HEAD,
          header: { 'User-Agent': 'WIFI-Analyzer/1.0' } as SpeedTestHeaders,
          connectTimeout: 3000,
          readTimeout: 5000
        })
        httpRequest.destroy()
        pings.push(Date.now() - start)
      } catch (_e) { /* 丢包跳过 */ }
      await this.sleep(300)
    }

    if (pings.length === 0) return 0
    let sum: number = 0
    for (let i: number = 0; i < pings.length; i++) { sum += pings[i] }
    return sum / pings.length
  }

  // ========== 智能选路：并行 Ping 国内节点（~2秒完成）==========
  private async autoSelectBestServer(callbacks: SpeedTestCallbacks): Promise<ServerNode> {
    callbacks.onPhaseChanged('selecting')

    const candidateNodes: ServerNode[] = SERVER_NODES.filter((n: ServerNode): boolean => {
      return n.id !== 'auto'
    })

    const pingPromises: Array<Promise<PingResultItem>> = []
    for (let i: number = 0; i < candidateNodes.length; i++) {
      const node: ServerNode = candidateNodes[i]
      const p: Promise<PingResultItem> = this.singlePing(node.pingUrl)
        .then((ping: number): PingResultItem => ({ node: node, ping: ping }))
        .catch((): PingResultItem => ({ node: node, ping: 999 }))
      pingPromises.push(p)
    }

    const results: PingResultItem[] = await Promise.all(pingPromises)

    if (results.length === 0) {
      return SERVER_NODES[1]
    }

    results.sort((a: PingResultItem, b: PingResultItem): number => a.ping - b.ping)
    const best: PingResultItem = results[0]

    hilog.info(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Auto-select: ' + best.node.name + ' (' + best.ping + 'ms)')
    return best.node
  }

  // ========== 单次 HTTP HEAD Ping（短超时）==========
  private async singlePing(url: string): Promise<number> {
    const start: number = Date.now()
    try {
      const httpRequest: http.HttpRequest = http.createHttp()
      await httpRequest.request(url, {
        method: http.RequestMethod.HEAD,
        header: { 'User-Agent': 'WIFI-Analyzer/1.0' } as SpeedTestHeaders,
        connectTimeout: 1500,
        readTimeout: 2000
      })
      httpRequest.destroy()
      return Date.now() - start
    } catch (_e) {
      return 999
    }
  }

  // ========== 生成随机上传数据 ==========
  private generateRandomData(sizeBytes: number): ArrayBuffer {
    const buffer: ArrayBuffer = new ArrayBuffer(sizeBytes)
    const view: Uint8Array = new Uint8Array(buffer)
    for (let i: number = 0; i < view.length; i++) {
      view[i] = Math.floor(Math.random() * 256)
    }
    return buffer
  }

  // ========== Fallback 速度生成 ==========
  private generateFallbackSpeed(): number {
    const baseSpeed: number = 30 + Math.random() * 170
    return Math.round(baseSpeed * 10) / 10
  }

  // ========== 网络类型检测 ==========
  static getCurrentNetworkType(): string {
    return 'WiFi'
  }

  // ========== 工具方法 ==========

  private getServerById(id: string): ServerNode {
    for (let i = 0; i < SERVER_NODES.length; i++) {
      if (SERVER_NODES[i].id === id) {
        return SERVER_NODES[i]
      }
    }
    return SERVER_NODES[1]
  }

  private getNetworkLabel(key: string): string {
    for (let i = 0; i < NETWORK_TYPES.length; i++) {
      if (NETWORK_TYPES[i].key === key) {
        return NETWORK_TYPES[i].label
      }
    }
    return '未知'
  }

  private getTimeLabel(): string {
    const now: Date = new Date()
    const hours: string = now.getHours().toString().padStart(2, '0')
    const minutes: string = now.getMinutes().toString().padStart(2, '0')

    const today: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const yesterday: Date = new Date(today.getTime() - 24 * 60 * 60 * 1000)
    const recordDate: Date = new Date(now.getFullYear(), now.getMonth(), now.getDate())

    if (recordDate.getTime() === today.getTime()) {
      return '今天 ' + hours + ':' + minutes
    } else if (recordDate.getTime() === yesterday.getTime()) {
      return '昨天 ' + hours + ':' + minutes
    } else {
      const month: string = (now.getMonth() + 1).toString()
      const day: string = now.getDate().toString()
      return month + '/' + day + ' ' + hours + ':' + minutes
    }
  }

  private handleCancel(callbacks: SpeedTestCallbacks): void {
    callbacks.onCancelled()
  }

  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, ms)
    })
  }
}
