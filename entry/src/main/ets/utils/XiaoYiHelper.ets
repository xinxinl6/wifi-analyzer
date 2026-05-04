/**
 * 小艺助手调用工具类
 * 提供启动华为小艺智能助手的功能
 * 支持降级为应用内嵌 WebView 显示 AI 分析结果
 */
import { Want } from '@kit.AbilityKit'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

// 小艺助手包名
const XIAOYI_BUNDLE_NAME = 'com.huawei.hiai'
const XIAOYI_ABILITY_NAME = 'com.huawei.hiai.app.MainActivity'

/**
 * WiFi网络信息结构
 */
export interface WifiNetworkInfo {
  ssid: string
  signal: number
  channel: number
  frequency: number
}

/**
 * 启动结果结构
 */
export class LaunchResult {
  success: boolean = false
  message: string = ''
  fallbackUrl: string = ''

  constructor(success: boolean, message: string, fallbackUrl: string = '') {
    this.success = success
    this.message = message
    this.fallbackUrl = fallbackUrl
  }
}

// 日志标签
const TAG = 'XiaoYiHelper'
const DOMAIN = 0xFF00

/**
 * 日志辅助函数
 */
function logInfo(msg: string, ...params: string[]): void {
  hilog.info(DOMAIN, TAG, '%{public}s', msg + ' ' + params.join(' '))
}

function logWarn(msg: string): void {
  hilog.warn(DOMAIN, TAG, '%{public}s', msg)
}

function logError(msg: string): void {
  hilog.error(DOMAIN, TAG, '%{public}s', msg)
}

/**
 * 检查设备是否支持小艺助手
 */
export function isXiaoyiSupported(): boolean {
  return true
}

/**
 * 启动小艺助手（支持降级方案）
 * 如果小艺不可用，返回降级URL供应用内WebView使用
 */
export async function launchXiaoyi(context: common.UIAbilityContext, query: string): Promise<LaunchResult> {
  logInfo('准备启动小艺助手，查询内容: ' + query)

  // 方案1: 直接启动小艺主界面
  const result1 = await tryLaunchXiaoyiDirect(context, query)
  if (result1.success) {
    return result1
  }

  // 方案2: 通过Want启动
  const result2 = await tryLaunchByWant(context, query)
  if (result2.success) {
    return result2
  }

  // 方案3: 降级方案 - 返回搜索URL供内嵌WebView使用
  const result3 = getSearchFallbackUrl(query)
  return result3
}

/**
 * 获取AI分析URL（不尝试启动小艺，避免系统弹窗）
 * 直接返回搜索URL供应用内WebView使用
 */
export function getAIAnalysisUrl(query: string): string {
  const searchQuery = encodeURIComponent(query + ' WiFi网络优化建议')
  const bingUrl = 'https://www.bing.com/search?q=' + searchQuery
  logInfo('获取AI分析URL: ' + bingUrl)
  return bingUrl
}

/**
 * 方案1: 直接启动小艺主界面
 */
async function tryLaunchXiaoyiDirect(context: common.UIAbilityContext, query: string): Promise<LaunchResult> {
  try {
    const encodedQuery = encodeURIComponent(query)
    const want: Want = {
      bundleName: XIAOYI_BUNDLE_NAME,
      abilityName: XIAOYI_ABILITY_NAME,
      uri: 'hiapp://aiassistant?query=' + encodedQuery
    } as Want

    await context.startAbility(want)

    logInfo('方案1成功: 直接启动小艺')
    return new LaunchResult(true, '已启动小艺助手')
  } catch (err) {
    logWarn('方案1失败')
    return new LaunchResult(false, '方案1失败')
  }
}

/**
 * 方案2: 通过Want启动
 */
async function tryLaunchByWant(context: common.UIAbilityContext, query: string): Promise<LaunchResult> {
  try {
    const encodedQuery = encodeURIComponent(query)
    const want: Want = {
      action: 'aiassist.intent.action.ASSIST',
      uri: 'hiapp://aiassistant?query=' + encodedQuery
    } as Want

    await context.startAbility(want)

    logInfo('方案2成功: 通过Want启动')
    return new LaunchResult(true, '已通过系统启动小艺')
  } catch (err) {
    logWarn('方案2失败')
    return new LaunchResult(false, '方案2失败')
  }
}

/**
 * 方案3（降级方案）: 获取搜索URL供内嵌WebView使用
 * 不再尝试启动外部应用，避免系统错误弹窗
 */
function getSearchFallbackUrl(query: string): LaunchResult {
  const searchQuery = encodeURIComponent(query + ' WiFi网络优化建议')
  const bingUrl = 'https://www.bing.com/search?q=' + searchQuery

  logInfo('降级方案: 返回内嵌WebView URL')
  return new LaunchResult(true, '正在为您分析网络...', bingUrl)
}

/**
 * 根据信号强度获取等级描述
 */
function getSignalLevel(signal: number): string {
  if (signal >= -50) {
    return '极强'
  } else if (signal >= -60) {
    return '良好'
  } else if (signal >= -70) {
    return '一般'
  } else if (signal >= -80) {
    return '较弱'
  } else {
    return '很弱'
  }
}

/**
 * 构建网络分析查询内容
 */
export function buildNetworkQuery(info: WifiNetworkInfo): string {
  const ssid = info.ssid || '未知网络'
  const signal = info.signal || 0
  const channel = info.channel || 0
  const signalLevel = getSignalLevel(signal)
  const frequency = info.frequency || 0
  const band = frequency >= 5000 ? '5GHz' : '2.4GHz'

  const query = '帮我分析WiFi网络：' + ssid + '，' +
    '信号强度' + signal + 'dBm（' + signalLevel + '），' +
    '当前在' + band + '频段' + channel + '信道。' +
    '请给出网络优化建议，比如是否应该切换到其他信道或频段？'

  logInfo('构建查询: ' + query)
  return query
}
