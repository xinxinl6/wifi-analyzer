// SlidingWindowAccumulator — 多窗口滑动 + EWMA 平滑累加器（从 SpeedTestEngine.ets 拆分）
import { SpeedSample, SpeedTestCallbacks, WARMUP_MS, BURST_WINDOW_MS, RECENT_WINDOW_MS, EWMA_ALPHA, SAMPLE_MAX, PROGRESS_INTERVAL_MS } from './SpeedTestTypes'

export class SlidingWindowAccumulator {
  private samples: SpeedSample[] = []
  private sampleIdx: number = 0
  private sampleCount: number = 0
  private totalBytes_: number = 0
  private startTime: number
  private lastReportTime: number
  private ewmaSpeed: number = 0
  private warmupUntil: number
  private effectiveStartTime: number

  constructor(startTime: number, warmupMs: number = WARMUP_MS) {
    this.startTime = startTime; this.warmupUntil = startTime + warmupMs
    this.effectiveStartTime = this.warmupUntil; this.lastReportTime = startTime
    for (let i = 0; i < SAMPLE_MAX; i++) this.samples[i] = { timestamp: 0, bytes: 0 }
  }

  isWarmup(now: number): boolean { return now < this.warmupUntil }
  get totalBytes(): number { return this.totalBytes_ }

  addBytes(bytes: number, now: number, isDownload: boolean, callbacks: SpeedTestCallbacks): void {
    if (now < this.warmupUntil) return
    this.totalBytes_ += bytes
    this.samples[this.sampleIdx] = { timestamp: now, bytes: bytes }
    this.sampleIdx = (this.sampleIdx + 1) % SAMPLE_MAX
    if (this.sampleCount < SAMPLE_MAX) this.sampleCount++
    if (now - this.lastReportTime >= PROGRESS_INTERVAL_MS) {
      this.lastReportTime = now
      const burstSpeed: number = this.windowSpeed(BURST_WINDOW_MS, now)
      this.ewmaSpeed = this.ewmaSpeed <= 0 ? burstSpeed : EWMA_ALPHA * burstSpeed + (1 - EWMA_ALPHA) * this.ewmaSpeed
      const smoothSpeed: number = Math.round(this.ewmaSpeed * 10) / 10
      if (isDownload) callbacks.onDownloadProgress(smoothSpeed)
      else callbacks.onUploadProgress(smoothSpeed)
    }
  }

  private windowSpeed(windowMs: number, now: number): number {
    const cutoff = now - windowMs; let windowBytes = 0
    for (let i = 0; i < this.sampleCount; i++) {
      const idx = (this.sampleIdx - 1 - i + SAMPLE_MAX) % SAMPLE_MAX
      const s = this.samples[idx]
      if (s.timestamp >= cutoff) windowBytes += s.bytes
      else break
    }
    const deltaSec = windowMs / 1000
    return deltaSec <= 0 ? 0 : (windowBytes * 8) / (deltaSec * 1024 * 1024)
  }

  burstSpeed(now: number): number { return this.windowSpeed(BURST_WINDOW_MS, now) }

  overallSpeed(): number {
    const elapsed = (Date.now() - this.effectiveStartTime) / 1000
    return elapsed <= 0.3 ? 0 : (this.totalBytes_ * 8) / (elapsed * 1024 * 1024)
  }

  recentSpeed(now: number): number { return this.windowSpeed(RECENT_WINDOW_MS, now) }
}
