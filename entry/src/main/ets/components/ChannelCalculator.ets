/**
 * ChannelCalculator - 信道计算模块
 * 包含信道推荐算法、缓存计算逻辑和常量定义
 */
import { WifiItem, SharedWifiState } from '@wifi-analyzer/core'

// 信道-AP数量对（用于排序）
export interface ChannelCountPair {
  channel: number
  count: number
}

// 信道缓存数据（避免 build 中重复计算）
export interface ChannelCacheData {
  channel: number
  count: number
  height: number
  barWidth: string
  color: string
  gradientTop: string
  gradientBottom: string
}

// 信道计算结果
export interface ChannelComputeResult {
  channels: number[]
  channelData: ChannelCacheData[]
  recommended: Array<ChannelCountPair>
  totalCount: number
}

// 预定义的信道列表
export const CHANNELS_2_4G: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
export const CHANNELS_5G1: number[] = [36, 40, 44, 48]
export const CHANNELS_5G2: number[] = [149, 153, 157, 161, 165]

// 颜色配置 — 复用 design-system Token
export const COLOR_2_4G: string = '#3B82F6'  // ≡ COLOR_BLUE_THEME
export const COLOR_5G1: string = '#8B5CF6'   // ≡ COLOR_INFO
export const COLOR_5G2: string = '#EC4899'   // ≡ COLOR_PINK

// 频段列表（用于切换）
export const BANDS: string[] = ['2.4', '5g1', '5g2']

/**
 * 获取当前频段简称
 */
export function getBandShortName(band: string): string {
  if (band === '5g1') return '5.1'
  if (band === '5g2') return '5.8'
  return '2.4'
}

/**
 * 获取当前频段名称（资源）
 */
export function getBandNameResource(band: string): Resource {
  if (band === '5g1') return $r('app.string.5_2ghz')
  if (band === '5g2') return $r('app.string.5_8ghz')
  return $r('app.string.2_4ghz')
}

/**
 * 获取当前频段描述（资源）
 */
export function getBandDescriptionResource(band: string): Resource {
  if (band === '5g1') return $r('app.string.5_1ghz_desc')
  if (band === '5g2') return $r('app.string.5_8ghz_desc')
  return $r('app.string.2_4ghz_desc')
}

/**
 * 获取当前频段范围
 */
export function getBandRange(band: string): string {
  if (band === '5g1') return '5150-5250 MHz'
  if (band === '5g2') return '5725-5850 MHz'
  return '2400-2500 MHz'
}

/**
 * 获取当前频段颜色
 */
export function getBandColor(band: string): string {
  if (band === '5g1') return COLOR_5G1
  if (band === '5g2') return COLOR_5G2
  return COLOR_2_4G
}

/**
 * 获取当前信道列表
 */
export function getCurrentChannels(band: string): number[] {
  if (band === '5g1') return CHANNELS_5G1
  if (band === '5g2') return CHANNELS_5G2
  return CHANNELS_2_4G
}

/**
 * 获取指示器偏移量
 */
export function getIndicatorMargin(band: string): string {
  if (band === '5g1') return '33.33%'
  if (band === '5g2') return '66.66%'
  return '0%'
}

/**
 * 判断是否是5G频段
 */
export function is5GBand(band: string): boolean {
  return band !== '2.4'
}

/**
 * 获取指示器偏移量数值（用于动画）
 */
export function getIndicatorOffset(band: string): number {
  if (band === '5g1') return 1
  if (band === '5g2') return 2
  return 0
}

/**
 * 统一预计算所有信道数据
 */
export function computeChannelCache(
  wifiState: SharedWifiState,
  band: string,
  CHANNEL_IDLE: string,
  CHANNEL_LIGHT: string,
  CHANNEL_MODERATE: string,
  CHANNEL_CROWDED: string,
  CHANNEL_IDLE_TOP: string,
  CHANNEL_LIGHT_TOP: string,
  CHANNEL_MODERATE_TOP: string,
  CHANNEL_CROWDED_TOP: string
): ChannelComputeResult {
  const channels: number[] = getCurrentChannels(band)
  const list: WifiItem[] = wifiState.wifiList || []

  // 频段过滤
  const is2_4G: boolean = band === '2.4'
  const is5G: boolean = !is2_4G

  // 单次遍历计算
  const counts: number[] = []
  let maxCount: number = 1
  let totalCount: number = 0

  for (let c = 0; c < channels.length; c++) {
    let count: number = 0
    for (let i = 0; i < list.length; i++) {
      const wifi: WifiItem = list[i]
      const freqMatch: boolean = (is2_4G && wifi.freq === 2.4) || (is5G && wifi.freq === 5.0)
      if (freqMatch && wifi.channel === channels[c]) {
        count++
      }
    }
    counts.push(count)
    totalCount += count
    if (count > maxCount) maxCount = count
  }
  maxCount = Math.max(maxCount, 1)

  // 生成缓存数据
  const cacheData: ChannelCacheData[] = []
  for (let c = 0; c < channels.length; c++) {
    const count: number = counts[c]
    const height: number = Math.max(Math.round(20 + (count / maxCount) * 100), 10)
    const barPercent: number = Math.min(count / maxCount * 100, 100)

    cacheData.push({
      channel: channels[c],
      count: count,
      height: height,
      barWidth: barPercent + '%',
      color: count === 0 ? CHANNEL_IDLE : count === 1 ? CHANNEL_LIGHT : count <= 3 ? CHANNEL_MODERATE : CHANNEL_CROWDED,
      gradientTop: count === 0 ? CHANNEL_IDLE_TOP : count === 1 ? CHANNEL_LIGHT_TOP : count <= 3 ? CHANNEL_MODERATE_TOP : CHANNEL_CROWDED_TOP,
      gradientBottom: count === 0 ? CHANNEL_IDLE : count === 1 ? CHANNEL_LIGHT : count <= 3 ? CHANNEL_MODERATE : CHANNEL_CROWDED
    })
  }

  // 推荐信道
  const pairs: Array<ChannelCountPair> = []
  for (let c = 0; c < channels.length; c++) {
    pairs.push({ channel: channels[c], count: counts[c] })
  }
  pairs.sort((a: ChannelCountPair, b: ChannelCountPair): number => a.count - b.count)
  const limit: number = Math.min(3, pairs.length)

  const result: ChannelComputeResult = {
    channels,
    channelData: cacheData,
    recommended: pairs.slice(0, limit),
    totalCount
  }
  return result
}
