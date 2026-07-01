// Ping 历史记录持久化存储
// 使用 @ohos.data.preferences 实现 KV 持久化

import preferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = '[PingStorage]'

// ==================== 数据类型 ====================
export interface StoredPingResult {
  address: string
  timeMs: number
  timestamp: number
  status: 'success' | 'timeout' | 'error'
}

export interface StoredPingConfig {
  pingCount: number
  customHost: string
  timestamp: number
}

export interface StoredSessionSummary {
  timestamp: number
  targetHost: string
  avgTime: number
  lossRate: number
  jitter: number
  stabilityScore: number
  pingCount: number
  details?: PingDetail[]
}

export interface PingDetail {
  target: string
  index: number
  timeMs: number
  status: 'success' | 'timeout'
}

// ==================== 存储常量 ====================
const PREF_NAME: string = 'ping_history_store'
const KEY_PING_RESULTS: string = 'ping_results'
const KEY_SESSION_SUMMARIES: string = 'session_summaries'
const MAX_PING_RESULTS: number = 200
const MAX_SESSION_SUMMARIES: number = 50

export class PingStorage {
  private static pref: preferences.Preferences | null = null
  private static ctx: common.UIAbilityContext | null = null

  static async init(context: common.UIAbilityContext): Promise<void> {
    try {
      PingStorage.ctx = context
      PingStorage.pref = await preferences.getPreferences(context, PREF_NAME)
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingStorage] init failed')
    }
  }

  private static ensureInit(): boolean {
    if (!PingStorage.pref) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PingStorage] not initialized')
      return false
    }
    return true
  }

  // ========== Ping 结果 ==========

  static async loadPingResults(): Promise<StoredPingResult[]> {
    if (!PingStorage.ensureInit()) return []
    try {
      const json: string = await PingStorage.pref!.get(KEY_PING_RESULTS, '[]') as string
      const arr: StoredPingResult[] = JSON.parse(json) as StoredPingResult[]
      return Array.isArray(arr) ? arr : []
    } catch (_e) {
      return []
    }
  }

  static async addPingResult(result: StoredPingResult): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      const list: StoredPingResult[] = await PingStorage.loadPingResults()
      list.unshift(result)
      while (list.length > MAX_PING_RESULTS) { list.pop() }
      await PingStorage.pref!.put(KEY_PING_RESULTS, JSON.stringify(list))
      await PingStorage.pref!.flush()
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, 'addPingResult flush error: %{public}s', JSON.stringify(_e))
    }
  }

  static async clearPingResults(): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      await PingStorage.pref!.put(KEY_PING_RESULTS, '[]')
      await PingStorage.pref!.flush()
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, 'clearPingResults flush error: %{public}s', JSON.stringify(_e))
    }
  }

  // ========== 会话摘要 ==========

  static async loadSessionSummaries(): Promise<StoredSessionSummary[]> {
    if (!PingStorage.ensureInit()) return []
    try {
      const json: string = await PingStorage.pref!.get(KEY_SESSION_SUMMARIES, '[]') as string
      const arr: StoredSessionSummary[] = JSON.parse(json) as StoredSessionSummary[]
      return Array.isArray(arr) ? arr : []
    } catch (_e) {
      return []
    }
  }

  static async addSessionSummary(summary: StoredSessionSummary): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      const list: StoredSessionSummary[] = await PingStorage.loadSessionSummaries()
      list.unshift(summary)
      while (list.length > MAX_SESSION_SUMMARIES) { list.pop() }
      await PingStorage.pref!.put(KEY_SESSION_SUMMARIES, JSON.stringify(list))
      await PingStorage.pref!.flush()
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, 'addSessionSummary flush error: %{public}s', JSON.stringify(_e))
    }
  }

  static async clearSessionSummaries(): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      await PingStorage.pref!.put(KEY_SESSION_SUMMARIES, '[]')
      await PingStorage.pref!.flush()
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, 'clearSessionSummaries flush error: %{public}s', JSON.stringify(_e))
    }
  }

  static async clearAll(): Promise<void> {
    await PingStorage.clearPingResults()
    await PingStorage.clearSessionSummaries()
  }

  // ========== 监测配置持久化 ==========

  private static readonly KEY_PING_CONFIG: string = 'ping_monitor_config'

  static async getLastConfig(): Promise<StoredPingConfig | null> {
    if (!PingStorage.ensureInit()) return null
    try {
      const json: string = await PingStorage.pref!.get(PingStorage.KEY_PING_CONFIG, '') as string
      if (!json) return null
      return JSON.parse(json) as StoredPingConfig
    } catch (_e) {
      return null
    }
  }

  static async saveLastConfig(config: StoredPingConfig): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      await PingStorage.pref!.put(PingStorage.KEY_PING_CONFIG, JSON.stringify(config))
      await PingStorage.pref!.flush()
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, 'saveLastConfig flush error: %{public}s', JSON.stringify(_e))
    }
  }
}
