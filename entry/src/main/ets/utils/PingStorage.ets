// Ping 历史记录持久化存储
// 使用 @ohos.data.preferences 实现 KV 持久化存储
// 职责：Ping 结果历史 + 会话摘要的读写、容量管理

import preferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

// ==================== 数据类型 ====================
export interface StoredPingResult {
  address: string
  timeMs: number
  timestamp: number
  status: 'success' | 'timeout' | 'error'
}

export interface StoredSessionSummary {
  timestamp: number
  targetHost: string
  avgTime: number
  lossRate: number
  jitter: number
  stabilityScore: number
  pingCount: number
}

// ==================== 存储常量 ====================
const PREF_NAME = 'ping_history_store'
const KEY_PING_RESULTS = 'ping_results'
const KEY_SESSION_SUMMARIES = 'session_summaries'

// 最大保存数量
const MAX_PING_RESULTS = 200
const MAX_SESSION_SUMMARIES = 50

// ==================== PingStorage 工具类 ====================
export class PingStorage {
  private static pref: preferences.Preferences | null = null
  private static context: common.UIAbilityContext | null = null

  /** 初始化（必须在 UIAbility context 可用时调用） */
  static async init(context: common.UIAbilityContext): Promise<void> {
    try {
      PingStorage.context = context
      PingStorage.pref = await preferences.getPreferences(context, PREF_NAME)
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingStorage] init failed: ' + JSON.stringify(e))
    }
  }

  /** 确保已初始化，未初始化时返回空数据 */
  private static ensureInit(): boolean {
    if (!PingStorage.pref) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PingStorage] not initialized, returning empty data')
      return false
    }
    return true
  }

  // ========== Ping 结果历史 ==========

  /** 读取所有 Ping 结果历史 */
  static async loadPingResults(): Promise<StoredPingResult[]> {
    if (!PingStorage.ensureInit()) return []
    try {
      const json = await PingStorage.pref!.get(KEY_PING_RESULTS, '[]') as string
      const arr = JSON.parse(json) as StoredPingResult[]
      return Array.isArray(arr) ? arr : []
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingStorage] loadPingResults failed: ' + JSON.stringify(e))
      return []
    }
  }

  /** 追加一条 Ping 结果 */
  static async addPingResult(result: StoredPingResult): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      const list = await PingStorage.loadPingResults()
      list.unshift(result)
      // 容量裁剪
      while (list.length > MAX_PING_RESULTS) {
        list.pop()
      }
      await PingStorage.pref!.put(KEY_PING_RESULTS, JSON.stringify(list))
      await PingStorage.pref!.flush()
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingStorage] addPingResult failed: ' + JSON.stringify(e))
    }
  }

  /** 清空 Ping 结果历史 */
  static async clearPingResults(): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      await PingStorage.pref!.put(KEY_PING_RESULTS, '[]')
      await PingStorage.pref!.flush()
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingStorage] clearPingResults failed: ' + JSON.stringify(e))
    }
  }

  // ========== 会话摘要 ==========

  /** 读取会话摘要列表 */
  static async loadSessionSummaries(): Promise<StoredSessionSummary[]> {
    if (!PingStorage.ensureInit()) return []
    try {
      const json = await PingStorage.pref!.get(KEY_SESSION_SUMMARIES, '[]') as string
      const arr = JSON.parse(json) as StoredSessionSummary[]
      return Array.isArray(arr) ? arr : []
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingStorage] loadSessionSummaries failed: ' + JSON.stringify(e))
      return []
    }
  }

  /** 追加一条会话摘要（最新的排在前面） */
  static async addSessionSummary(summary: StoredSessionSummary): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      const list = await PingStorage.loadSessionSummaries()
      list.unshift(summary)
      // 容量裁剪
      while (list.length > MAX_SESSION_SUMMARIES) {
        list.pop()
      }
      await PingStorage.pref!.put(KEY_SESSION_SUMMARIES, JSON.stringify(list))
      await PingStorage.pref!.flush()
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingStorage] addSessionSummary failed: ' + JSON.stringify(e))
    }
  }

  /** 清空会话摘要 */
  static async clearSessionSummaries(): Promise<void> {
    if (!PingStorage.ensureInit()) return
    try {
      await PingStorage.pref!.put(KEY_SESSION_SUMMARIES, '[]')
      await PingStorage.pref!.flush()
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingStorage] clearSessionSummaries failed: ' + JSON.stringify(e))
    }
  }

  // ========== 批量操作 ==========

  /** 清空所有 Ping 相关数据 */
  static async clearAll(): Promise<void> {
    await PingStorage.clearPingResults()
    await PingStorage.clearSessionSummaries()
  }
}
