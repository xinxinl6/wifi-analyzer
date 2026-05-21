// SpeedTestStorage.ets - 测速历史存储工具
// 提取自 SpeedTestSection.ets

import { SpeedTestResult } from '@wifi-analyzer/core'
import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

// 添加到历史记录
export function addToHistory(historyList: Array<SpeedTestResult>, result: SpeedTestResult): Array<SpeedTestResult> {
  const newList: Array<SpeedTestResult> = [result]
  for (let i = 0; i < historyList.length; i++) {
    newList.push(historyList[i])
  }
  while (newList.length > 20) {
    newList.pop()
  }
  return newList
}

// 保存历史记录
export function saveHistory(historyList: Array<SpeedTestResult>, context: common.UIAbilityContext): void {
  try {
    const jsonStr: string = JSON.stringify(historyList)
    preferences.getPreferences(context, 'speedtest_data').then((pref: preferences.Preferences) => {
      pref.put('history_list', jsonStr).then(() => {
        pref.flush()
      }).catch((e: Object) => {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to flush history: ' + e)
      })
    }).catch((e: Object) => {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to get preferences: ' + e)
    })
  } catch (e) {
    hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to save history: ' + e)
  }
}

// 加载历史记录（异步，不返回 Promise）
export function loadHistoryAsync(context: common.UIAbilityContext): Array<SpeedTestResult> {
  let result: Array<SpeedTestResult> = []
  try {
    preferences.getPreferences(context, 'speedtest_data').then((pref: preferences.Preferences) => {
      pref.get('history_list', '[]').then((value: Object) => {
        const jsonStr: string = String(value)
        try {
          const parsed: Array<SpeedTestResult> = JSON.parse(jsonStr)
          if (parsed && parsed.length > 0) {
            result = parsed
          }
        } catch (parseError) {
          hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to parse history: ' + parseError)
        }
      }).catch((e: Object) => {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to get history: ' + e)
      })
    }).catch((e: Object) => {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to get preferences: ' + e)
    })
  } catch (e) {
    hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to load history: ' + e)
  }
  return result
}

// 异步加载历史记录（回调方式，与原接口兼容）
export function loadHistoryAsyncWithCallback(
  context: common.UIAbilityContext,
  onLoaded: (list: Array<SpeedTestResult>) => void
): void {
  try {
    preferences.getPreferences(context, 'speedtest_data').then((pref: preferences.Preferences) => {
      pref.get('history_list', '[]').then((value: Object) => {
        const jsonStr: string = String(value)
        try {
          const parsed: Array<SpeedTestResult> = JSON.parse(jsonStr)
          if (parsed && parsed.length > 0) {
            onLoaded(parsed)
          } else {
            onLoaded([])
          }
        } catch (parseError) {
          hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to parse history: ' + parseError)
          onLoaded([])
        }
      }).catch((e: Object) => {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to get history: ' + e)
        onLoaded([])
      })
    }).catch((e: Object) => {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to get preferences: ' + e)
      onLoaded([])
    })
  } catch (e) {
    hilog.warn(DOMAIN, 'testTag', '%{public}s', '[SpeedTest] Failed to load history: ' + e)
    onLoaded([])
  }
}
