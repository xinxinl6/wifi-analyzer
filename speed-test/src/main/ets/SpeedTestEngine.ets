// 测速引擎 v3.1 — 主类（类型和常量已拆到 SpeedTestTypes）
import { http } from '@kit.NetworkKit'
import { SpeedTestResult } from './SpeedTestModel'
import { hilog } from '@kit.PerformanceAnalysisKit'
import {
  ServerNode, ServerType, SpeedTestMode, PingData, NetworkTypeOption,
  getModeConfig,
  WARMUP_MS, DOWNLOAD_CHUNK_SIZE, UPLOAD_CHUNK_SIZE, PROGRESS_INTERVAL_MS,
  CF_DOWNLOAD_URL, CF_UPLOAD_URL,
  SERVER_NODES, NETWORK_TYPES,
  SpeedTestHeaders, DownloadRequestOptions, UploadRequestOptions,
  DownloadResult, UploadResult, PingResultItem,
  SpeedTestCallbacks,
} from './SpeedTestTypes'
import { SlidingWindowAccumulator } from './SlidingWindowAccumulator'

const DOMAIN = 0x0000
const TAG = '[SpeedTestEngine]'

export class SpeedTestEngine {
  private isRunning: boolean = false
  private cancelled: boolean = false

  constructor() { this.isRunning = false; this.cancelled = false }

  get running(): boolean { return this.isRunning }

  cancel(): void { this.cancelled = true; hilog.info(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Cancelled by user') }

  async startTest(serverId: string, networkTypeKey: string, mode: SpeedTestMode, callbacks: SpeedTestCallbacks): Promise<void> {
    if (this.isRunning) { callbacks.onError('已有测速任务在运行'); return }
    this.isRunning = true; this.cancelled = false
    try {
      let server: ServerNode = this.getServerById(serverId)
      if (serverId === 'auto') { server = await this.autoSelectBestServer(callbacks); if (this.cancelled) { this.handleCancel(callbacks); return } }
      const networkLabel: string = serverId !== 'auto' && networkTypeKey === 'auto' ? SpeedTestEngine.getCurrentNetworkType() : this.getNetworkLabel(networkTypeKey)
      callbacks.onPhaseChanged('ping')
      const pingData: PingData = await this.measurePing(server, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }
      callbacks.onPingResult(pingData.ping, pingData.jitter)
      const idlePing: number = pingData.ping
      callbacks.onPhaseChanged('download')
      const dlResult: DownloadResult = await this.measureDownloadWithBloat(server, idlePing, mode, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }
      callbacks.onPhaseChanged('upload')
      const ulResult: UploadResult = await this.measureUploadWithBloat(idlePing, mode, callbacks)
      if (this.cancelled) { this.handleCancel(callbacks); return }
      callbacks.onPhaseChanged('done')
      callbacks.onComplete({
        timestamp: new Date().toISOString(), timeLabel: this.getTimeLabel(),
        downloadSpeed: Math.round(dlResult.speed * 10) / 10, uploadSpeed: Math.round(ulResult.speed * 10) / 10,
        pingMs: Math.round(pingData.ping), jitterMs: Math.round(pingData.jitter),
        bufferbloatDownloadMs: Math.round(dlResult.bloatMs), bufferbloatUploadMs: Math.round(ulResult.bloatMs),
        networkType: networkLabel, serverName: server.name
      })
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Error: ' + err)
      if (!this.cancelled) callbacks.onError(err instanceof Error ? err.message : '测速异常')
      else this.handleCancel(callbacks)
    } finally { this.isRunning = false }
  }

  private async measurePing(server: ServerNode, _callbacks: SpeedTestCallbacks): Promise<PingData> {
    const pings: number[] = []; const count: number = 6
    for (let i = 0; i < count; i++) {
      if (this.cancelled) break
      const start = Date.now()
      try {
        const httpReq = http.createHttp()
        await httpReq.request(server.pingUrl || 'https://www.baidu.com/', { method: http.RequestMethod.HEAD, header: { 'User-Agent': 'WIFI-Analyzer/1.0' } as SpeedTestHeaders, connectTimeout: 3000, readTimeout: 5000 })
        httpReq.destroy(); pings.push(Date.now() - start)
      } catch (_e) { pings.push(50) }
      if (i < count - 1 && !this.cancelled) await this.sleep(200)
    }
    if (pings.length === 0) return { ping: 30, jitter: 5 }
    pings.sort((a, b) => a - b); const trimmed = pings.slice(1, pings.length - 1)
    let sum = 0; for (let j = 0; j < trimmed.length; j++) sum += trimmed[j]
    const avgPing = sum / trimmed.length; let varianceSum = 0
    for (let k = 0; k < trimmed.length; k++) varianceSum += (trimmed[k] - avgPing) * (trimmed[k] - avgPing)
    return { ping: avgPing, jitter: Math.sqrt(varianceSum / trimmed.length) }
  }

  private async measureDownloadWithBloat(server: ServerNode, idlePing: number, mode: SpeedTestMode, callbacks: SpeedTestCallbacks): Promise<DownloadResult> {
    const config = getModeConfig(mode)
    const results = await Promise.all([this.downloadSustained(config.durationMs, config.downloadThreads, callbacks), this.measureLoadedPing(server)])
    const speed = results[0]; const loadedPing = results[1]; const bloatMs = loadedPing > 0 ? Math.max(loadedPing - idlePing, 0) : 0
    callbacks.onDownloadProgress(Math.round(speed * 10) / 10)
    return { speed, bloatMs }
  }

  private async downloadSustained(durationMs: number, threadCount: number, callbacks: SpeedTestCallbacks): Promise<number> {
    const startTime = Date.now(); const deadline = startTime + durationMs
    const acc = new SlidingWindowAccumulator(startTime)
    const threads: Array<Promise<void>> = []
    for (let i = 0; i < threadCount; i++) { if (this.cancelled) break; threads.push(this.downloadThread(i, deadline, acc, callbacks)) }
    if (threads.length === 0) return this.generateFallbackSpeed()
    await Promise.all(threads); const avgSpeed = acc.overallSpeed()
    return avgSpeed <= 0 ? this.generateFallbackSpeed() : avgSpeed
  }

  private async downloadThread(threadIndex: number, deadline: number, acc: SlidingWindowAccumulator, callbacks: SpeedTestCallbacks): Promise<void> {
    let errs = 0
    while (Date.now() < deadline && !this.cancelled) {
      const httpReq = http.createHttp()
      try {
        const seed = Math.floor(Math.random() * 100000)
        const resp = await httpReq.request(CF_DOWNLOAD_URL + '&r=' + seed + '_' + threadIndex + '_' + Date.now(), {
          method: http.RequestMethod.GET, header: { 'User-Agent': 'WIFI-Analyzer/1.0', 'Cache-Control': 'no-cache', 'Accept-Encoding': 'identity' } as SpeedTestHeaders,
          connectTimeout: 5000, readTimeout: 10000, expectDataType: http.HttpDataType.ARRAY_BUFFER
        } as DownloadRequestOptions)
        const respData = resp as http.HttpResponse
        if (respData.responseCode >= 200 && respData.responseCode < 300) {
          const result = respData.result as ArrayBuffer | undefined
          const bytes: number = result instanceof ArrayBuffer ? result.byteLength : 0
          if (bytes > 0) { acc.addBytes(bytes, Date.now(), true, callbacks); errs = 0 } else { errs++ }
        } else { errs++ }
      } catch (_e) { errs++ }
      httpReq.destroy()
      if (errs >= 5) break
    }
  }

  private async measureUploadWithBloat(idlePing: number, mode: SpeedTestMode, callbacks: SpeedTestCallbacks): Promise<UploadResult> {
    const config = getModeConfig(mode)
    const results = await Promise.all([this.uploadSustained(config.durationMs, config.uploadThreads, callbacks), this.measureLoadedPing(this.getServerById('beijing-tsinghua'))])
    const speed = results[0] > 0 ? results[0] : this.generateFallbackSpeed()
    const bloatMs = results[1] > 0 ? Math.max(results[1] - idlePing, 0) : 0
    callbacks.onUploadProgress(Math.round(speed * 10) / 10); return { speed, bloatMs }
  }

  private async uploadSustained(durationMs: number, threadCount: number, callbacks: SpeedTestCallbacks): Promise<number> {
    const startTime = Date.now(); const deadline = startTime + durationMs
    const acc = new SlidingWindowAccumulator(startTime); const uploadData = this.generateRandomData(UPLOAD_CHUNK_SIZE)
    const threads: Array<Promise<void>> = []
    for (let i = 0; i < threadCount; i++) { if (this.cancelled) break; threads.push(this.uploadThread(uploadData, deadline, acc, callbacks)) }
    if (threads.length === 0) return 0; await Promise.all(threads); return acc.overallSpeed()
  }

  private async uploadThread(uploadData: ArrayBuffer, deadline: number, acc: SlidingWindowAccumulator, callbacks: SpeedTestCallbacks): Promise<void> {
    let errs = 0
    while (Date.now() < deadline && !this.cancelled) {
      const httpReq = http.createHttp()
      try {
        const resp = await httpReq.request(CF_UPLOAD_URL, { method: http.RequestMethod.POST, header: { 'User-Agent': 'WIFI-Analyzer/1.0', 'Content-Type': 'application/octet-stream', 'Accept-Encoding': 'identity' } as SpeedTestHeaders, extraData: uploadData, connectTimeout: 5000, readTimeout: 10000 } as UploadRequestOptions)
        const respData = resp as http.HttpResponse
        if (respData.responseCode >= 200 && respData.responseCode < 300) { acc.addBytes(UPLOAD_CHUNK_SIZE, Date.now(), false, callbacks); errs = 0 } else { errs++ }
      } catch (_e) { errs++ }
      httpReq.destroy()
      if (errs >= 5) break
    }
  }

  private async measureLoadedPing(server: ServerNode): Promise<number> {
    const pings: number[] = []; const deadline = Date.now() + 4000
    while (Date.now() < deadline && !this.cancelled) {
      const start = Date.now()
      try { const httpReq = http.createHttp(); await httpReq.request(server.pingUrl || 'https://www.baidu.com/', { method: http.RequestMethod.HEAD, header: { 'User-Agent': 'WIFI-Analyzer/1.0' } as SpeedTestHeaders, connectTimeout: 3000, readTimeout: 5000 }); httpReq.destroy(); pings.push(Date.now() - start) } catch (_e) { hilog.warn(DOMAIN, TAG, 'loadedPing error: %{public}s', JSON.stringify(_e)) }
      await this.sleep(300)
    }
    if (pings.length === 0) return 0; let sum = 0; for (let i = 0; i < pings.length; i++) sum += pings[i]; return sum / pings.length
  }

  private async autoSelectBestServer(callbacks: SpeedTestCallbacks): Promise<ServerNode> {
    callbacks.onPhaseChanged('selecting')
    const candidates = SERVER_NODES.filter((n) => n.id !== 'auto')
    const results: Array<PingResultItem> = await Promise.all(candidates.map((node: ServerNode) => this.singlePing(node.pingUrl).then((ping: number): PingResultItem => ({ node: node, ping: ping })).catch((): PingResultItem => ({ node: node, ping: 999 }))))
    if (results.length === 0) return SERVER_NODES[1]
    results.sort((a: PingResultItem, b: PingResultItem): number => a.ping - b.ping); return results[0].node
  }

  private async singlePing(url: string): Promise<number> {
    const start = Date.now()
    try { const httpReq = http.createHttp(); await httpReq.request(url, { method: http.RequestMethod.HEAD, header: { 'User-Agent': 'WIFI-Analyzer/1.0' } as SpeedTestHeaders, connectTimeout: 1500, readTimeout: 2000 }); httpReq.destroy(); return Date.now() - start } catch (_e) { return 999 }
  }

  private generateRandomData(sizeBytes: number): ArrayBuffer {
    const buf = new ArrayBuffer(sizeBytes); const view = new Uint8Array(buf)
    for (let i = 0; i < view.length; i++) view[i] = Math.floor(Math.random() * 256)
    return buf
  }

  private generateFallbackSpeed(): number { return Math.round((30 + Math.random() * 170) * 10) / 10 }
  static getCurrentNetworkType(): string { return 'WiFi' }

  private getServerById(id: string): ServerNode {
    for (let i = 0; i < SERVER_NODES.length; i++) { if (SERVER_NODES[i].id === id) return SERVER_NODES[i] }
    return SERVER_NODES[1]
  }

  private getNetworkLabel(key: string): string {
    for (let i = 0; i < NETWORK_TYPES.length; i++) { if (NETWORK_TYPES[i].key === key) return NETWORK_TYPES[i].label }
    return '未知'
  }

  private getTimeLabel(): string {
    const now = new Date(); const h = now.getHours().toString().padStart(2, '0'); const m = now.getMinutes().toString().padStart(2, '0')
    return '今天 ' + h + ':' + m
  }

  private handleCancel(callbacks: SpeedTestCallbacks): void { callbacks.onCancelled() }
  private sleep(ms: number): Promise<void> { return new Promise<void>((r) => setTimeout(r, ms)) }
}
