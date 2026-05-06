/**
 * AI 搜索工具类
 * 直接使用 WebView 加载 Bing 搜索结果，不再调用小艺助手
 */
import { hilog } from '@kit.PerformanceAnalysisKit'

/**
 * WiFi网络信息结构
 */
export interface WifiNetworkInfo {
  ssid: string
  signal: number
  channel: number
  frequency: number
}

// 日志标签
const TAG = 'AISearchHelper'
const DOMAIN = 0xFF00

function logInfo(msg: string): void {
  hilog.info(DOMAIN, TAG, '%{public}s', msg)
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

/**
 * 获取AI分析URL（直接返回搜索URL供 WebView 使用）
 */
export function getAIAnalysisUrl(query: string): string {
  const searchQuery = encodeURIComponent(query + ' WiFi网络优化建议')
  // 使用百度移动版，界面更简洁，没有麦克风图标
  const baiduUrl = 'https://m.baidu.com/s?word=' + searchQuery
  logInfo('获取AI分析URL: ' + baiduUrl)
  return baiduUrl
}

/**
 * 获取 DeepSeek AI 分析 URL（可选）
 */
export function getDeepSeekAnalysisUrl(query: string): string {
  const searchQuery = encodeURIComponent(query + ' WiFi网络优化建议')
  // 使用百度移动版，界面更简洁
  const baiduUrl = 'https://m.baidu.com/s?word=' + searchQuery
  return baiduUrl
}
