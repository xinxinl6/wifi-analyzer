// 漫游测试引擎
// 监测 WiFi 连接的 AP 切换（漫游）行为
// 通过周期性检测 BSSID 变化来判断漫游事件

import { wifiManager } from '@kit.ConnectivityKit'
import {
  RoamEvent, RoamTestConfig, RoamTestCallbacks, RoamTestInfo,
  RoamTestSummary, BssidRecord, WifiInfo
} from '../models/ToolModels'

export class RoamTestEngine {
  private isRunning: boolean = false
  private abortRequested: boolean = false
  private timerId: number = -1

  /**
   * 获取默认配置
   */
  static getDefaultConfig(): RoamTestConfig {
    const config: RoamTestConfig = {
      intervalMs: 1000,
      durationSec: 60,
      targetBssid: '',
    }
    return config
  }

  /**
   * 获取当前 WiFi 连接信息
   */
  async getCurrentInfo(): Promise<WifiInfo> {
    try {
      const linkedInfo = await wifiManager.getLinkedInfo()
      const bssid: string = linkedInfo.bssid || ''
      const rssi: number = linkedInfo.rssi || 0
      const ssid: string = linkedInfo.ssid || ''
      const result: WifiInfo = { bssid: bssid, rssi: rssi, ssid: ssid }
      return result
    } catch (e) {
      const result: WifiInfo = { bssid: '', rssi: -100, ssid: '' }
      return result
    }
  }

  /**
   * 开始漫游测试
   */
  async startTest(config: RoamTestConfig, callbacks: RoamTestCallbacks): Promise<void> {
    this.isRunning = true
    this.abortRequested = false

    const roamEvents: RoamEvent[] = []
    const bssidHistory: BssidRecord[] = []
    let prevBssid: string = ''
    let prevRssi: number = 0
    let prevTimestamp: number = 0
    let totalRssi: number = 0
    let rssiCount: number = 0
    let minRssi: number = 0
    let maxRssi: number = -100
    const startTime: number = Date.now()
    const totalMs: number = config.durationSec * 1000

    // 初始值
    const initialInfo: WifiInfo = await this.getCurrentInfo()
    prevBssid = initialInfo.bssid
    prevRssi = initialInfo.rssi
    prevTimestamp = startTime

    // 定时检测循环
    this.timerId = setInterval(async (): Promise<void> => {
      if (this.abortRequested) {
        clearInterval(this.timerId)
        this.timerId = -1
        this.isRunning = false
        this.buildAndReportSummary(
          startTime, roamEvents, bssidHistory,
          totalRssi, rssiCount, minRssi, maxRssi, callbacks
        )
        return
      }

      const elapsed: number = Date.now() - startTime
      if (elapsed >= totalMs) {
        clearInterval(this.timerId)
        this.timerId = -1
        this.isRunning = false
        this.buildAndReportSummary(
          startTime, roamEvents, bssidHistory,
          totalRssi, rssiCount, minRssi, maxRssi, callbacks
        )
        return
      }

      try {
        const info: WifiInfo = await this.getCurrentInfo()

        // 统计信号
        if (info.rssi > -100) {
          totalRssi = totalRssi + info.rssi
          rssiCount = rssiCount + 1
          if (info.rssi < minRssi || rssiCount === 1) minRssi = info.rssi
          if (info.rssi > maxRssi) maxRssi = info.rssi
        }

        // 记录 BSSID 历史
        const record: BssidRecord = {
          bssid: info.bssid,
          rssi: info.rssi,
          timestamp: Date.now()
        }
        bssidHistory.push(record)
        if (bssidHistory.length > 3600) bssidHistory.shift()

        // 检测漫游
        if (prevBssid.length > 0 && info.bssid.length > 0 && info.bssid !== prevBssid) {
          const event: RoamEvent = {
            timestamp: Date.now(),
            fromBssid: prevBssid,
            toBssid: info.bssid,
            rssiBefore: prevRssi,
            rssiAfter: info.rssi,
            duration: Date.now() - prevTimestamp
          }
          roamEvents.push(event)
          callbacks.onRoamDetected(event)
        }

        prevBssid = info.bssid
        prevRssi = info.rssi
        prevTimestamp = Date.now()

        // 上报实时信息
        const bssidSlice: BssidRecord[] = []
        const startIdx: number = Math.max(0, bssidHistory.length - 60)
        for (let i = startIdx; i < bssidHistory.length; i++) {
          bssidSlice.push(bssidHistory[i])
        }

        const testInfo: RoamTestInfo = {
          isRunning: true,
          currentBssid: info.bssid,
          currentRssi: info.rssi,
          elapsedSec: Math.floor(elapsed / 1000),
          totalSec: config.durationSec,
          roamCount: roamEvents.length,
          avgRssi: rssiCount > 0 ? Math.round(totalRssi / rssiCount) : 0,
          bssidHistory: bssidSlice
        }
        callbacks.onUpdate(testInfo)
      } catch (e) {
        // 忽略单次检测失败
      }
    }, config.intervalMs)
  }

  /**
   * 构建并上报测试摘要
   */
  private buildAndReportSummary(
    startTime: number,
    roamEvents: RoamEvent[],
    bssidHistory: BssidRecord[],
    totalRssi: number,
    rssiCount: number,
    minRssi: number,
    maxRssi: number,
    callbacks: RoamTestCallbacks
  ): void {
    // 统计不同 BSSID 数量
    const bssidSet: string[] = []
    for (let i = 0; i < bssidHistory.length; i++) {
      const b: string = bssidHistory[i].bssid
      if (b.length > 0 && bssidSet.indexOf(b) < 0) {
        bssidSet.push(b)
      }
    }

    // 稳定性评分
    let stabilityScore: number = 100
    stabilityScore = stabilityScore - roamEvents.length * 5
    const rssiRange: number = maxRssi - minRssi
    if (rssiRange > 30) stabilityScore = stabilityScore - 10
    stabilityScore = Math.max(0, Math.min(100, stabilityScore))

    const summary: RoamTestSummary = {
      totalDuration: Date.now() - startTime,
      roamCount: roamEvents.length,
      roamEvents: roamEvents,
      avgRssi: rssiCount > 0 ? Math.round(totalRssi / rssiCount) : 0,
      minRssi: minRssi,
      maxRssi: maxRssi,
      bssidCount: bssidSet.length,
      stabilityScore: stabilityScore
    }
    callbacks.onComplete(summary)
  }

  /**
   * 停止测试
   */
  stopTest(): void {
    this.abortRequested = true
    if (this.timerId >= 0) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
    this.isRunning = false
  }

  /**
   * 是否正在运行
   */
  getIsRunning(): boolean {
    return this.isRunning
  }

  /**
   * 格式化 BSSID（缩略显示）
   */
  static formatBssid(bssid: string): string {
    if (bssid.length === 0) return '--'
    if (bssid.length <= 8) return bssid.toUpperCase()
    return bssid.toUpperCase().substring(0, 8) + '...'
  }

  /**
   * 获取 BSSID 显示标签
   */
  static getBssidLabel(bssid: string, index: number): string {
    if (bssid.length === 0) return 'AP ' + String(index)
    return 'AP-' + bssid.replace(/[:\-\.]/g, '').toUpperCase().substring(4, 8)
  }
}
