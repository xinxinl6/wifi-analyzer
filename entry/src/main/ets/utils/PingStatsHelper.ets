// Ping 统计计算辅助工具

import { PingResult, PingStats } from '../components/PingTestPage'
import {
  COLOR_SUCCESS,
  COLOR_WARNING,
  COLOR_SKY_BLUE,
  COLOR_SKY_BLUE_LIGHT,
  COLOR_DANGER
} from '@wifi-analyzer/design-system'

// 图表数据准备结果 — 必须在类外声明接口
export interface ChartDataResult {
  chartData: PingResult[]
  chartMaxY: number
  chartAvgMs: number
  chartMinMs: number
  chartMaxMs: number
}

/**
 * PingStatsHelper - 静态工具类
 * 提供 Ping 统计数据计算、图表数据准备、颜色辅助等静态方法
 */
export class PingStatsHelper {
  // ==================== 统计计算 ====================

  /**
   * 计算 Ping 统计数据
   */
  static recalcStats(pingHistory: PingResult[]): PingStats {
    if (pingHistory.length === 0) {
      const emptyStats: PingStats = {
        sentCount: 0,
        receivedCount: 0,
        lossRate: 0,
        maxTime: 0,
        minTime: 0,
        avgTime: 0,
        jitter: 0,
        stabilityScore: 100
      }
      return emptyStats
    }

    const successArr: number[] = []
    let received: number = 0
    for (let i = 0; i < pingHistory.length; i++) {
      if (pingHistory[i].status === 'success') {
        successArr.push(pingHistory[i].timeMs)
        received++
      }
    }

    const lossRateVal: number = pingHistory.length > 0
      ? Math.round((1 - received / pingHistory.length) * 10000) / 100
      : 0
    let maxVal: number = 0
    let minVal: number = 0
    let sum: number = 0
    let jitterVal: number = 0
    let stabilityScoreVal: number = 100

    if (successArr.length > 0) {
      maxVal = successArr[0]
      minVal = successArr[0]
      sum = 0
      for (let j = 0; j < successArr.length; j++) {
        const v: number = successArr[j]
        if (v > maxVal) maxVal = v
        if (v < minVal) minVal = v
        sum += v
      }

      const avg: number = sum / successArr.length
      let varianceSum: number = 0
      for (let k = 0; k < successArr.length; k++) {
        const diff: number = successArr[k] - avg
        varianceSum += diff * diff
      }
      jitterVal = Math.round(Math.sqrt(varianceSum / successArr.length) * 100) / 100

      const lossPenalty: number = Math.min(lossRateVal * 2, 100)
      const jitterPenalty: number = Math.min(jitterVal / 10, 20)
      stabilityScoreVal = Math.max(0, 100 - lossPenalty - jitterPenalty)
      stabilityScoreVal = Math.round(stabilityScoreVal)
    }

    const result: PingStats = {
      sentCount: pingHistory.length,
      receivedCount: received,
      lossRate: lossRateVal,
      maxTime: Math.round(maxVal * 100) / 100,
      minTime: Math.round(minVal * 100) / 100,
      avgTime: successArr.length > 0 ? Math.round((sum / successArr.length) * 100) / 100 : 0,
      jitter: jitterVal,
      stabilityScore: stabilityScoreVal
    }
    return result
  }

  // ==================== 图表数据准备 ====================

  /**
   * 准备图表显示数据
   */
  static prepareChartData(pingHistory: PingResult[]): ChartDataResult {
    if (pingHistory.length === 0) {
      const emptyResult: ChartDataResult = {
        chartData: [],
        chartMaxY: 35,
        chartAvgMs: 0,
        chartMinMs: 0,
        chartMaxMs: 0
      }
      return emptyResult
    }

    const displayCount: number = Math.min(pingHistory.length, 24)
    const startIndex: number = pingHistory.length - displayCount
    const sliced: PingResult[] = pingHistory.slice(startIndex)

    let maxY: number = 35
    let minValid: number = 999999
    let maxValid: number = 0
    let validSum: number = 0
    let validCount: number = 0

    for (let i = 0; i < sliced.length; i++) {
      if (sliced[i].status === 'success' && sliced[i].timeMs > 0) {
        if (sliced[i].timeMs > maxValid) maxValid = sliced[i].timeMs
        if (sliced[i].timeMs < minValid) minValid = sliced[i].timeMs
        validSum += sliced[i].timeMs
        validCount++
      }
    }

    if (maxValid > 0) {
      maxY = Math.ceil(maxValid * 1.2 / 5) * 5
      maxY = Math.max(5, Math.min(500, maxY))
    }
    const avgV: number = validCount > 0 ? validSum / validCount : 0

    const chartResult: ChartDataResult = {
      chartData: sliced,
      chartMaxY: maxY,
      chartAvgMs: avgV,
      chartMinMs: minValid === 999999 ? 0 : minValid,
      chartMaxMs: maxValid
    }
    return chartResult
  }

  // ==================== 图表辅助方法 ====================

  /**
   * 判断是否为最佳（最小值）数据点
   */
  static isChartBest(item: PingResult, chartMinMs: number): boolean {
    return item.status === 'success' && item.timeMs > 0 && item.timeMs === chartMinMs && chartMinMs > 0
  }

  /**
   * 判断是否为最差（最大值）数据点
   */
  static isChartWorst(item: PingResult, chartMaxMs: number): boolean {
    return item.status === 'success' && item.timeMs > 0 && item.timeMs === chartMaxMs && chartMaxMs > 0
  }

  // ==================== 颜色辅助 ====================

  /**
   * 获取稳定性颜色
   */
  static getStabilityColor(score: number, isDarkMode: boolean): string {
    if (score >= 80) return COLOR_SUCCESS
    if (score >= 60) return COLOR_SKY_BLUE
    if (score >= 40) return COLOR_WARNING
    return COLOR_DANGER
  }

  /**
   * 获取延迟颜色
   */
  static getLatencyColor(timeMs: number): string {
    if (timeMs < 0) return COLOR_DANGER
    if (timeMs < 50) return COLOR_SUCCESS
    if (timeMs < 100) return COLOR_SKY_BLUE
    if (timeMs < 200) return COLOR_WARNING
    return COLOR_DANGER
  }

  // ==================== 时间格式化 ====================

  /**
   * 格式化时间戳为 HH:mm 格式
   */
  static formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const hours: string = date.getHours().toString().padStart(2, '0')
    const minutes: string = date.getMinutes().toString().padStart(2, '0')
    return `${hours}:${minutes}`
  }

  /**
   * 格式化时间戳为完整格式
   */
  static formatDateTime(timestamp: number): string {
    const date = new Date(timestamp)
    const month: string = (date.getMonth() + 1).toString().padStart(2, '0')
    const day: string = date.getDate().toString().padStart(2, '0')
    const hours: string = date.getHours().toString().padStart(2, '0')
    const minutes: string = date.getMinutes().toString().padStart(2, '0')
    return `${month}/${day} ${hours}:${minutes}`
  }
}
