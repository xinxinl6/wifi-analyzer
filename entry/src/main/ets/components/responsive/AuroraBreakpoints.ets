// ============================================
// Aurora WiFi V2 — 响应式断点和设备类型系统
// ============================================

import { display, window } from '@kit.ArkUI'
import { AppStorageV2 } from '@kit.ArkUI'

// ==================== 设备类型枚举 ====================

/**
 * Aurora 设备类型
 * 基于屏幕宽度和设备特性的分类
 */
export enum AuroraDeviceType {
  // 手机系列
  PHONE_COMPACT = 'phone_compact',    // < 360dp 小屏手机
  PHONE_STANDARD = 'phone_standard', // 360-599dp 标准手机
  PHONE_LARGE = 'phone_large',       // 600-839dp 大屏手机 / 折叠屏折叠态

  // 折叠屏系列
  FOLDABLE_COMPACT = 'foldable_compact',    // 折叠屏折叠态 (纵向)
  FOLDABLE_EXPANDED = 'foldable_expanded',  // 折叠屏展开态 (横向)

  // 平板系列
  TABLET_COMPACT = 'tablet_compact',  // 600-839dp 小平板
  TABLET_STANDARD = 'tablet_standard', // 840-1023dp 标准平板
  TABLET_LARGE = 'tablet_large',     // 1024-1279dp 大平板

  // PC / 2in1 系列
  PC_STANDARD = 'pc_standard',       // 1280-1599dp PC标准
  PC_LARGE = 'pc_large',             // 1600-1919dp PC大屏
  PC_XLARGE = 'pc_xlarge',           // >= 1920dp PC超宽屏
}

/**
 * Aurora 屏幕方向
 */
export enum AuroraOrientation {
  PORTRAIT = 'portrait',     // 竖屏
  LANDSCAPE = 'landscape',   // 横屏
  SQUARE = 'square'         // 正方形 (少见)
}

/**
 * Aurora 布局模式
 */
export enum AuroraLayoutMode {
  COMPACT = 'compact',     // 紧凑模式 (手机底部Tab)
  MEDIUM = 'medium',       // 中等模式 (大屏手机/折叠屏)
  EXPANDED = 'expanded',   // 展开模式 (平板侧边栏)
  FULL = 'full'           // 完整模式 (PC双栏布局)
}

// ==================== 断点常量 (vp) ====================

/**
 * Aurora 断点定义
 * 与 HarmonyOS 官方断点规范对齐
 */
export const AuroraBreakpoints = {
  // 核心断点
  SM: 320,        // 超小屏
  MD: 600,        // 中小屏 / 折叠折叠态
  LG: 840,        // 中大屏 / 折叠展开态 / 小平板
  XL: 1024,       // 大屏 / 平板
  XXL: 1280,      // PC 标准
  XXXL: 1600,     // PC 大屏

  // 别名 (兼容性)
  PHONE_MAX: 599,
  TABLET_MIN: 600,
  PC_MIN: 1024,

  // 内容宽度约束
  CONTENT_PHONE: 0,      // 手机不限制
  CONTENT_FOLDABLE: 720, // 折叠屏最大 720
  CONTENT_TABLET: 840,   // 平板最大 840
  CONTENT_PC: 1200,      // PC 最大 1200

  // 侧边栏宽度
  SIDEBAR_WIDTH_COMPACT: 72,   // 收起态
  SIDEBAR_WIDTH_EXPANDED: 240,  // 展开态
  SIDEBAR_WIDTH_FULL: 320,     // PC 全宽
} as const

// ==================== 断点懒加载 ====================

// 懒加载的断点订阅器
let breakpointListener: window.WindowSizeChangeCallback | null = null
let currentBreakpoint: string = AuroraBreakpoints.MD.toString()

/**
 * 获取当前断点名称
 */
export function getCurrentBreakpoint(): string {
  return currentBreakpoint
}

/**
 * 获取设备类型
 */
export function getDeviceType(): AuroraDeviceType {
  const width = getWindowWidth()

  if (width < 360) return AuroraDeviceType.PHONE_COMPACT
  if (width < AuroraBreakpoints.MD) return AuroraDeviceType.PHONE_STANDARD
  if (width < AuroraBreakpoints.LG) return AuroraDeviceType.PHONE_LARGE
  if (width < AuroraBreakpoints.XL) return AuroraDeviceType.TABLET_COMPACT
  if (width < AuroraBreakpoints.XXL) return AuroraDeviceType.TABLET_STANDARD
  if (width < AuroraBreakpoints.XXXL) return AuroraDeviceType.TABLET_LARGE
  if (width < 1600) return AuroraDeviceType.PC_STANDARD
  if (width < 1920) return AuroraDeviceType.PC_LARGE
  return AuroraDeviceType.PC_XLARGE
}

/**
 * 获取布局模式
 */
export function getLayoutMode(): AuroraLayoutMode {
  const width = getWindowWidth()

  if (width < AuroraBreakpoints.MD) return AuroraLayoutMode.COMPACT
  if (width < AuroraBreakpoints.LG) return AuroraLayoutMode.MEDIUM
  if (width < AuroraBreakpoints.XXL) return AuroraLayoutMode.EXPANDED
  return AuroraLayoutMode.FULL
}

/**
 * 获取屏幕方向
 */
export function getOrientation(): AuroraOrientation {
  const width = getWindowWidth()
  const height = getWindowHeight()

  if (width > height) return AuroraOrientation.LANDSCAPE
  if (width < height) return AuroraOrientation.PORTRAIT
  return AuroraOrientation.SQUARE
}

/**
 * 是否为横屏
 */
export function isLandscape(): boolean {
  return getOrientation() === AuroraOrientation.LANDSCAPE
}

/**
 * 是否为竖屏
 */
export function isPortrait(): boolean {
  return getOrientation() === AuroraOrientation.PORTRAIT
}

/**
 * 是否使用底部导航 (手机模式)
 */
export function useBottomNav(): boolean {
  return getLayoutMode() === AuroraLayoutMode.COMPACT
}

/**
 * 是否使用侧边导航 (平板/PC模式)
 */
export function useSideNav(): boolean {
  const mode = getLayoutMode()
  return mode === AuroraLayoutMode.EXPANDED || mode === AuroraLayoutMode.FULL
}

/**
 * 是否为大屏设备
 */
export function isLargeScreen(): boolean {
  return getWindowWidth() >= AuroraBreakpoints.LG
}

/**
 * 是否为平板
 */
export function isTablet(): boolean {
  const type = getDeviceType()
  return type >= AuroraDeviceType.TABLET_COMPACT
}

/**
 * 是否为 PC / 2in1
 */
export function isPC(): boolean {
  const type = getDeviceType()
  return type >= AuroraDeviceType.PC_STANDARD
}

/**
 * 是否为折叠屏
 */
export function isFoldable(): boolean {
  try {
    const displayInfo = display.getDefaultDisplaySync()
    // 折叠屏通常有特殊的屏幕属性
    return displayInfo.rotation !== 0 || displayInfo.densityDPI > 400
  } catch (e) {
    return false
  }
}

// ==================== 响应式尺寸计算 ====================

// 基准屏幕宽度 (华为 P50)
const BASE_WIDTH = 360

/**
 * 获取窗口宽度
 */
export function getWindowWidth(): number {
  try {
    const w = window.getLastWindowSync().getWindowProperties().windowRect.width
    return w / (px2vp(1)) // 转换为 vp
  } catch (e) {
    const val = AppStorage.get<number>('windowWidth')
    return val ?? 360
  }
}

/**
 * 获取窗口高度
 */
export function getWindowHeight(): number {
  try {
    const h = window.getLastWindowSync().getWindowProperties().windowRect.height
    return h / (px2vp(1))
  } catch (e) {
    const val = AppStorage.get<number>('windowHeight')
    return val ?? 720
  }
}

/**
 * 获取屏幕短边
 */
export function getScreenShortSide(): number {
  return Math.min(getWindowWidth(), getWindowHeight())
}

/**
 * 获取屏幕长边
 */
export function getScreenLongSide(): number {
  return Math.max(getWindowWidth(), getWindowHeight())
}

/**
 * 响应式尺寸计算
 * @param base 设计基准尺寸
 * @param options.min 最小值
 * @param options.max 最大值
 * @param options.scaleFactor 缩放因子 (默认 1.0)
 */
export function auroraResponsive(
  base: number,
  options?: {
    min?: number
    max?: number
    scaleFactor?: number
  }
): number {
  const shortSide = getScreenShortSide()
  const scale = shortSide / BASE_WIDTH
  let scaled = base * scale * (options?.scaleFactor ?? 1)

  if (options?.min !== undefined) {
    scaled = Math.max(scaled, options.min)
  }
  if (options?.max !== undefined) {
    scaled = Math.min(scaled, options.max)
  }

  return scaled
}

/**
 * 根据布局模式获取内容最大宽度
 */
export function getContentMaxWidth(): number {
  const width = getWindowWidth()

  if (width >= AuroraBreakpoints.XXXL) return AuroraBreakpoints.CONTENT_PC
  if (width >= AuroraBreakpoints.XXL) return AuroraBreakpoints.CONTENT_TABLET
  if (width >= AuroraBreakpoints.LG) return AuroraBreakpoints.CONTENT_FOLDABLE
  return 0 // 手机不限制
}

// ==================== 工具函数 ====================

/**
 * 获取 Grid 列数
 */
export function getGridColumns(minColumnWidth: number): number {
  const available = getWindowWidth() - auroraResponsive(48)
  return Math.max(2, Math.floor(available / minColumnWidth))
}

/**
 * 获取列表列数 (平板多列布局)
 */
export function getListColumns(): number {
  const width = getWindowWidth()
  if (width >= AuroraBreakpoints.XXXL) return 3
  if (width >= AuroraBreakpoints.XXL) return 2
  return 1
}

/**
 * 获取侧边栏宽度
 */
export function getSidebarWidth(collapsed: boolean = false): number {
  if (collapsed) return AuroraBreakpoints.SIDEBAR_WIDTH_COMPACT

  const mode = getLayoutMode()
  if (mode === AuroraLayoutMode.FULL) return AuroraBreakpoints.SIDEBAR_WIDTH_FULL
  if (mode === AuroraLayoutMode.EXPANDED) return AuroraBreakpoints.SIDEBAR_WIDTH_EXPANDED
  return AuroraBreakpoints.SIDEBAR_WIDTH_COMPACT
}
