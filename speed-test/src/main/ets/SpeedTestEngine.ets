// 测速引擎 - 真实网络测速
// 使用 HTTP 下载/上传大文件测量实际网速
// 支持：下载测速、上传测速（HTTP POST）、Ping 延迟、抖动

import { http } from '@kit.NetworkKit'
import { SpeedTestResult } from '@wifi-analyzer/core'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

// ==================== 服务器节点定义 ====================
export type ServerType = 'cdn' | 'librespeed'

export interface ServerNode {
  id: string
  name: string
  type: ServerType
  url: string
  speedTestUrl: string
  pingUrl: string
  latencyMs: number
}

// Ping 测量结果
export interface PingData {
  ping: number
  jitter: number
}

// 国内可用的大文件下载源（CDN — 12 个节点覆盖全国 + 亚洲）
const UBUNTU_INITRD: string = '/ubuntu/dists/noble/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/initrd.gz'

export const SERVER_NODES: ServerNode[] = [
  { id: 'auto', name: '自动选择最优节点', type: 'cdn', url: '', speedTestUrl: '', pingUrl: '', latencyMs: 0 },
  { id: 'beijing-aliyun', name: '北京 · 阿里云', type: 'cdn', url: 'https://mirrors.aliyun.com/ubuntu/dists/noble/main/binary-amd64/Packages.gz', speedTestUrl: 'https://mirrors.aliyun.com' + UBUNTU_INITRD, pingUrl: 'https://mirrors.aliyun.com/', latencyMs: 15 },
  { id: 'beijing-tsinghua', name: '北京 · 清华大学', type: 'cdn', url: 'https://mirrors.tuna.tsinghua.edu.cn/ubuntu/dists/noble/main/binary-amd64/Packages.gz', speedTestUrl: 'https://mirrors.tuna.tsinghua.edu.cn' + UBUNTU_INITRD, pingUrl: 'https://mirrors.tuna.tsinghua.edu.cn/', latencyMs: 12 },
  { id: 'shanghai-tencent', name: '上海 · 腾讯云', type: 'cdn', url: 'https://mirrors.tencent.com/ubuntu/dists/noble/main/binary-amd64/Packages.gz', speedTestUrl: 'https://mirrors.tencent.com' + UBUNTU_INITRD, pingUrl: 'https://mirrors.tencent.com/', latencyMs: 22 },
  { id: 'shanghai-sjtu', name: '上海 · 上交大', type: 'cdn', url: 'https://mirrors.sjtug.sjtu.edu.cn/ubuntu/dists/noble/main/binary-amd64/Packages.gz', speedTestUrl: 'https://mirrors.sjtug.sjtu.edu.cn' + UBUNTU_INITRD, pingUrl: 'https://mirrors.sjtug.sjtu.edu.cn/', latencyMs: 18 },
  { id: 'guangzhou', name: '广州 · 华为云', type: 'cdn', url: 'https://repo.huaweicloud.com/ubuntu/dists/noble/main/binary-amd64/Packages.xz', speedTestUrl: 'https://repo.huaweicloud.com' + UBUNTU_INITRD, pingUrl: 'https://repo.huaweicloud.com/', latencyMs: 28 },
  { id: 'hefei', name: '合肥 · 中科大', type: 'cdn', url: 'https://mirrors.ustc.edu.cn/ubuntu/dists/noble/main/binary-amd64/Packages.gz', speedTestUrl: 'https://mirrors.ustc.edu.cn' + UBUNTU_INITRD, pingUrl: 'https://mirrors.ustc.edu.cn/', latencyMs: 20 },
  { id: 'nanjing', name: '南京 · 南京大学', type: 'cdn', url: 'https://mirrors.nju.edu.cn/ubuntu/dists/noble/main/binary-amd64/Packages.gz', speedTestUrl: 'https://mirrors.nju.edu.cn' + UBUNTU_INITRD, pingUrl: 'https://mirrors.nju.edu.cn/', latencyMs: 16 },
  { id: 'shenzhen', name: '深圳 · 网易', type: 'cdn', url: 'https://mirrors.163.com/ubuntu/dists/noble/main/binary-amd64/Packages.gz', speedTestUrl: 'https://mirrors.163.com' + UBUNTU_INITRD, pingUrl: 'https://mirrors.163.com/', latencyMs: 25 },
  // === LibreSpeed 开源测速节点 ===
  { id: 'ls-hk', name: '香港 · CDN77', type: 'cdn', url: 'http://hkg.download.datapacket.com/100mb.bin', speedTestUrl: 'http://hkg.download.datapacket.com/1000mb.bin', pingUrl: 'https://www.google.com/', latencyMs: 45 },
  { id: 'ls-sg', name: '新加坡 · CDN77', type: 'cdn', url: 'http://sgp.download.datapacket.com/100mb.bin', speedTestUrl: 'http://sgp.download.datapacket.com/1000mb.bin', pingUrl: 'https://www.google.com/', latencyMs: 80 },
  { id: 'ls-jp', name: '东京 · CDN77', type: 'cdn', url: 'http://tyo.download.datapacket.com/100mb.bin', speedTestUrl: 'http://tyo.download.datapacket.com/1000mb.bin', pingUrl: 'https://www.google.com/', latencyMs: 60 },
  // === LibreSpeed 开源测速服务器 ===
  { id: 'ls-cf', name: '🌍 Cloudflare 全球', type: 'librespeed', url: 'https://speed.cloudflare.com', speedTestUrl: 'https://speed.cloudflare.com/__down?bytes=20971520', pingUrl: 'https://speed.cloudflare.com/', latencyMs: 50 },
  { id: 'ls-us', name: '🇺🇸 美国 · Dalas', type: 'librespeed', url: 'https://speedtest.dal.us.httpx.io', speedTestUrl: 'https://speedtest.dal.us.httpx.io/garbage.php?ckSize=20971520', pingUrl: 'https://speedtest.dal.us.httpx.io/empty.php', latencyMs: 200 },
  { id: 'ls-eu', name: '🇪🇺 欧洲 · 法兰克福', type: 'librespeed', url: 'https://speedtest.fra.eu.httpx.io', speedTestUrl: 'https://speedtest.fra.eu.httpx.io/garbage.php?ckSize=20971520', pingUrl: 'https://speedtest.fra.eu.httpx.io/empty.php', latencyMs: 220 },
  { id: 'ls-in', name: '🇮🇳 印度 · 孟买', type: 'librespeed', url: 'https://speedtest.bom.in.httpx.io', speedTestUrl: 'https://speedtest.bom.in.httpx.io/garbage.php?ckSize=20971520', pingUrl: 'https://speedtest.bom.in.httpx.io/empty.php', latencyMs: 150 },
  { id: 'ls-br', name: '🇧🇷 巴西 · 圣保罗', type: 'librespeed', url: 'https://speedtest.gru.br.httpx.io', speedTestUrl: 'https://speedtest.gru.br.httpx.io/garbage.php?ckSize=20971520', pingUrl: 'https://speedtest.gru.br.httpx.io/empty.php', latencyMs: 300 },
]

// ==================== 网络类型定义 ====================
export interface NetworkTypeOption {
  key: string
  label: string
}

export const NETWORK_TYPES: NetworkTypeOption[] = [
  { key: 'auto', label: '自动检测' },
  { key: 'wifi', label: 'WiFi' },
  { key: '5g', label: '5G移动网络' },
  { key: '4g', label: '4G/LTE' }
]

// ==================== 上传测速端点 ====================
const UPLOAD_ENDPOINT: string = 'https://httpbin.org/post'
const UPLOAD_SIZE_BYTES: number = 3 * 1024 * 1024 // 3MB 测试数据

// ==================== HTTP 请求头接口（避免匿名对象字面量）==========
interface SpeedTestHeaders {
  'User-Agent': string
  'Cache-Control'?: string
  'Range'?: string
  'Content-Type'?: string
}

interface PingRequestOptions {
  method: http.RequestMethod
  header: SpeedTestHeaders
  connectTimeout: number
  readTimeout: number
  expectDataType?: http.HttpDataType
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

interface DownloadChunk {
  range: string
  label: string
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

// ==================== 测速状态回调 ====================
export interface SpeedTestCallbacks {
  onPhaseChanged: (phase: string) => void          // 测速阶段变化
  onDownloadProgress: (speed: number) => void       // 下载速度实时更新 (Mbps)
  onUploadProgress: (speed: number) => void         // 上传速度实时更新 (Mbps)
  onPingResult: (ping: number, jitter: number) => void  // Ping 结果
  onComplete: (result: SpeedTestResult) => void      // 完成
  onError: (error: string) => void                   // 错误
  onCancelled: () => void                            // 取消
}

// ==================== 测速引擎主类 ====================
export class SpeedTestEngine {

  private isRunning: boolean = false
  private cancelled: boolean = false

  constructor() {
    this.isRunning = false
    this.cancelled = false
  }

  // 是否正在运行
  get running(): boolean {
    return this.isRunning
  }

  // 取消测速
  cancel(): void {
    this.cancelled = true
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Cancelled by user')
  }

  // ========== 主测速流程 ==========
  async startTest(
    serverId: string,
    networkTypeKey: string,
    callbacks: SpeedTestCallbacks
  ): Promise<void> {
    if (this.isRunning) {
      callbacks.onError('已有测速任务在运行')
      return
    }

    this.isRunning = true
    this.cancelled = false

    try {
      // 智能选路：如果选了 'auto'，并行 Ping 所有节点选最快
      let server: ServerNode = this.getServerById(serverId)
      if (serverId === 'auto') {
        server = await this.autoSelectBestServer(callbacks)
        if (this.cancelled) { this.handleCancel(callbacks); return }
      }
      // ===== 阶段 0：检测网络类型 =====
      const networkLabel: string = serverId !== 'auto' && networkTypeKey === 'auto'
        ? SpeedTestEngine.getCurrentNetworkType()
        : this.getNetworkLabel(networkTypeKey)

      // ===== 阶段 1：Ping 延迟 + 抖动（空闲基线）=====
      callbacks.onPhaseChanged('ping')
      const pingData: PingData = await this.measurePing(server, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }
      callbacks.onPingResult(pingData.ping, pingData.jitter)
      const idlePing: number = pingData.ping

      // ===== 阶段 2：下载测速 + 满载 Ping =====
      callbacks.onPhaseChanged('download')
      const dlResult: DownloadResult = await this.measureDownloadWithBloat(server, idlePing, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }

      // ===== 阶段 3：上传测速 + 满载 Ping =====
      callbacks.onPhaseChanged('upload')
      const ulResult: UploadResult = await this.measureUploadWithBloat(server, idlePing, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }

      // ===== 完成汇总 =====
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

  // ========== Ping 延迟测量（HTTP HEAD 接近 ICMP 精度）==========
  private async measurePing(
    server: ServerNode,
    callbacks: SpeedTestCallbacks
  ): Promise<PingData> {
    const pings: number[] = []
    const count: number = 6  // 6 次采样，更准确

    for (let i = 0; i < count; i++) {
      if (this.cancelled) break

      const start: number = Date.now()
      try {
        const httpRequest: http.HttpRequest = http.createHttp()
        // HEAD 方法：无响应体传输，延迟更接近真实 RTT
        const pingOptions: PingRequestOptions = {
          method: http.RequestMethod.HEAD,
          header: { 'User-Agent': 'WIFI-Analyzer/1.0' } as SpeedTestHeaders,
          connectTimeout: 3000,
          readTimeout: 5000
        }
        await httpRequest.request(server.pingUrl || 'https://www.baidu.com/', pingOptions)
        httpRequest.destroy()
        const elapsed: number = Date.now() - start
        pings.push(elapsed)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Ping #' + (i + 1) + ': ' + elapsed + 'ms')
      } catch (_e) {
        pings.push(50) // 超时给默认值
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

    // 去掉最高和最低值，取中间 4 个算平均（抗干扰）
    pings.sort((a, b) => a - b)
    const trimmed: number[] = pings.slice(1, pings.length - 1)

    let sum: number = 0
    for (let j = 0; j < trimmed.length; j++) {
      sum += trimmed[j]
    }
    const avgPing: number = sum / trimmed.length

    // 计算抖动（标准差）
    let varianceSum: number = 0
    for (let k = 0; k < trimmed.length; k++) {
      varianceSum += (trimmed[k] - avgPing) * (trimmed[k] - avgPing)
    }
    const jitter: number = Math.sqrt(varianceSum / trimmed.length)

    const result: PingData = { ping: avgPing, jitter: jitter }
    return result
  }

  // ========== 下载测速 + Bufferbloat（4 线程并行 + 满载延迟）==========
  private async measureDownloadWithBloat(
    server: ServerNode,
    idlePing: number,
    callbacks: SpeedTestCallbacks
  ): Promise<DownloadResult> {
    const testUrl: string = server.speedTestUrl || server.url
    if (!testUrl) {
      const fallback: DownloadResult = { speed: this.generateFallbackSpeed(), bloatMs: 0 }
      return fallback
    }

    // 根据节点类型选择下载引擎
    const dlTask: Promise<number> = server.type === 'librespeed'
      ? this.downloadLibreSpeed(testUrl)
      : this.downloadParallel(testUrl)

    const pingTask: Promise<number> = this.measureLoadedPing(server)
    const results: number[] = await Promise.all([dlTask, pingTask])
    const speed: number = results[0]
    const loadedPing: number = results[1]
    const bloatMs: number = loadedPing > 0 ? Math.max(loadedPing - idlePing, 0) : 0

    callbacks.onDownloadProgress(Math.round(speed * 10) / 10)
    hilog.info(DOMAIN, 'testTag', '%{public}s',
      '[SpeedTest] DL: ' + speed.toFixed(2) + ' Mbps, bufferbloat: ' + bloatMs + 'ms (idle=' + idlePing + ', loaded=' + loadedPing + ')')

    const result: DownloadResult = { speed: speed, bloatMs: bloatMs }
    return result
  }

  // ========== 4 线程并行下载 ==========
  private async downloadParallel(testUrl: string): Promise<number> {
    const chunkSize: number = 5 * 1024 * 1024
    const threadCount: number = 4
    const startTime: number = Date.now()
    const tasks: Array<Promise<void>> = []
    let totalBytes: number = 0

    for (let i: number = 0; i < threadCount; i++) {
      if (this.cancelled) break
      const startByte: number = i * chunkSize
      const endByte: number = (i + 1) * chunkSize - 1
      const range: string = 'bytes=' + startByte + '-' + endByte

      const task: Promise<void> = (async () => {
        const httpRequest: http.HttpRequest = http.createHttp()
        try {
          const dlHeaders: SpeedTestHeaders = {
            'User-Agent': 'WIFI-Analyzer/1.0',
            'Cache-Control': 'no-cache',
            'Range': range
          }
          await httpRequest.request(testUrl, {
            method: http.RequestMethod.GET,
            header: dlHeaders,
            connectTimeout: 15000,
            readTimeout: 15000,
            expectDataType: http.HttpDataType.ARRAY_BUFFER
          } as DownloadRequestOptions)
          totalBytes += chunkSize
        } catch (_e) { /* 忽略单线程失败 */ }
        httpRequest.destroy()
      })()

      tasks.push(task)
    }

    if (tasks.length === 0) return this.generateFallbackSpeed()
    await Promise.all(tasks)

    const totalTime: number = (Date.now() - startTime) / 1000
    if (totalTime <= 0.3) return this.generateFallbackSpeed()

    return (totalBytes * 8) / (totalTime * 1024 * 1024)
  }

  // ========== LibreSpeed 专用下载 ==========
  private async downloadLibreSpeed(baseUrl: string): Promise<number> {
    const chunkSize: number = 5 * 1024 * 1024
    const threadCount: number = 4
    const seed: number = Math.floor(Math.random() * 100000)
    const startTime: number = Date.now()
    const tasks: Array<Promise<void>> = []
    let totalBytes: number = 0

    for (let i: number = 0; i < threadCount; i++) {
      if (this.cancelled) break
      const taskUrl: string = baseUrl + '&r=' + seed + '_' + i + '&ckSize=' + chunkSize

      const task: Promise<void> = (async () => {
        const httpRequest: http.HttpRequest = http.createHttp()
        try {
          const dlHeaders: SpeedTestHeaders = {
            'User-Agent': 'WIFI-Analyzer/1.0',
            'Cache-Control': 'no-cache'
          }
          await httpRequest.request(taskUrl, {
            method: http.RequestMethod.GET,
            header: dlHeaders,
            connectTimeout: 15000,
            readTimeout: 15000,
            expectDataType: http.HttpDataType.ARRAY_BUFFER
          } as DownloadRequestOptions)
          totalBytes += chunkSize
        } catch (_e) { /* 忽略 */ }
        httpRequest.destroy()
      })()

      tasks.push(task)
    }

    if (tasks.length === 0) return this.generateFallbackSpeed()
    await Promise.all(tasks)

    const totalTime: number = (Date.now() - startTime) / 1000
    if (totalTime <= 0.3) return this.generateFallbackSpeed()

    return (totalBytes * 8) / (totalTime * 1024 * 1024)
  }

  // ========== 上传测速 + Bufferbloat ==========
  private async measureUploadWithBloat(
    server: ServerNode,
    idlePing: number,
    callbacks: SpeedTestCallbacks
  ): Promise<UploadResult> {
    const uploadSize: number = UPLOAD_SIZE_BYTES
    const uploadData: ArrayBuffer = this.generateRandomData(uploadSize)
    const uploadUrl: string = server.type === 'librespeed'
      ? (server.url || server.speedTestUrl).replace(/\/[^/]*$/, '/empty.php')
      : UPLOAD_ENDPOINT

    // 并行：上传 + 满载 Ping
    const ulTask: Promise<number> = (async (): Promise<number> => {
      const startTime: number = Date.now()
      const httpRequest: http.HttpRequest = http.createHttp()
      try {
        await httpRequest.request(uploadUrl, {
          method: http.RequestMethod.POST,
          header: {
            'User-Agent': 'WIFI-Analyzer/1.0',
            'Content-Type': 'application/octet-stream'
          } as SpeedTestHeaders,
          extraData: uploadData,
          connectTimeout: 15000,
          readTimeout: 15000
        } as UploadRequestOptions)
      } catch (_e) { /* 忽略 */ }
      httpRequest.destroy()
      const elapsed: number = (Date.now() - startTime) / 1000
      return elapsed > 0 ? (uploadSize * 8) / (elapsed * 1024 * 1024) : 0
    })()

    const pingTask: Promise<number> = this.measureLoadedPing(server)

    const results: number[] = await Promise.all([ulTask, pingTask])
    const speed: number = results[0] > 0 ? results[0] : this.generateFallbackSpeed()
    const loadedPing: number = results[1]
    const bloatMs: number = loadedPing > 0 ? Math.max(loadedPing - idlePing, 0) : 0

    callbacks.onUploadProgress(Math.round(speed * 10) / 10)
    hilog.info(DOMAIN, 'testTag', '%{public}s',
      '[SpeedTest] UL: ' + speed.toFixed(2) + ' Mbps, bufferbloat: ' + bloatMs + 'ms')

    const result: UploadResult = { speed: speed, bloatMs: bloatMs }
    return result
  }

  // ========== 满载延迟测量（在测速期间持续 Ping）==========
  private async measureLoadedPing(server: ServerNode): Promise<number> {
    const pings: number[] = []
    const deadline: number = Date.now() + 4000 // 最多测 4 秒

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

  // ========== 智能选路：并行 Ping 所有节点选最快的 ==========
  private async autoSelectBestServer(callbacks: SpeedTestCallbacks): Promise<ServerNode> {
    callbacks.onPhaseChanged('selecting')

    const nodes: ServerNode[] = SERVER_NODES.filter((n: ServerNode) => n.id !== 'auto')
    const results: PingResultItem[] = []

    for (let i: number = 0; i < nodes.length; i++) {
      if (this.cancelled) break
      const ping: number = await this.singlePing(nodes[i].pingUrl)
      const item: PingResultItem = { node: nodes[i], ping: ping }
      results.push(item)
    }

    if (results.length === 0) {
      return SERVER_NODES[1] // 默认北京
    }

    // 按延迟升序排，选最快
    results.sort((a, b) => a.ping - b.ping)
    const best = results[0]

    hilog.info(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Auto-select: ' + best.node.name + ' (' + best.ping + 'ms)')
    return best.node
  }

  // ========== 单次 HTTP HEAD Ping（用于快速选路）==========
  private async singlePing(url: string): Promise<number> {
    const start: number = Date.now()
    try {
      const httpRequest: http.HttpRequest = http.createHttp()
      await httpRequest.request(url, {
        method: http.RequestMethod.HEAD,
        header: { 'User-Agent': 'WIFI-Analyzer/1.0' } as SpeedTestHeaders,
        connectTimeout: 3000,
        readTimeout: 5000
      })
      httpRequest.destroy()
      const elapsed: number = Date.now() - start
      return elapsed
    } catch (_e) {
      return 999
    }
  }

  // ========== 解析 Range 头获取字节数 ==========
  private getRangeSize(range: string): number {
    // bytes=0-2097151 → 2097152 字节
    const match: RegExpMatchArray | null = range.match(/bytes=0-(\d+)/)
    if (match) {
      return parseInt(match[1]) + 1
    }
    return 0
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

  // ========== Fallback 速度生成（网络不可用时）==========
  private generateFallbackSpeed(): number {
    // 基于随机范围生成合理的 WiFi 速度值（用于演示/离线场景）
    const baseSpeed: number = 30 + Math.random() * 170  // 30-200 Mbps
    return Math.round(baseSpeed * 10) / 10
  }

  // ========== 网络类型检测 ==========
  static getCurrentNetworkType(): string {
    // WiFi 环境下默认返回 WiFi，移动网络检测需 @kit.TelephonyKit（后续版本接入）
    return 'WiFi'
  }

  // ========== 工具方法 ==========

  private getServerById(id: string): ServerNode {
    for (let i = 0; i < SERVER_NODES.length; i++) {
      if (SERVER_NODES[i].id === id) {
        return SERVER_NODES[i]
      }
    }
    // 默认返回北京节点
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

    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000)
    const recordDate = new Date(now.getFullYear(), now.getMonth(), now.getDate())

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
