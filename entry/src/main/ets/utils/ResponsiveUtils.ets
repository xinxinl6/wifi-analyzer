// 响应式尺寸工具
// 用于折叠屏、横竖屏切换、平板、PC 时的自适应尺寸

// ==================== 断点常量 ====================
// 参考 HarmonyOS 官方断点规范
const BREAKPOINT_SM: number = 600   // 折叠屏折叠态 / 大手机
const BREAKPOINT_MD: number = 840   // 折叠屏展开态 / 小平板
const BREAKPOINT_LG: number = 1024  // 平板
const BREAKPOINT_XL: number = 1280  // PC

// ==================== 屏幕信息 ====================

// 获取当前窗口宽度
export function getWindowWidth(): number {
  const val: number | undefined = AppStorage.get('windowWidth') as number | undefined
  return val ?? 360
}

// 获取当前窗口高度
export function getWindowHeight(): number {
  const val: number | undefined = AppStorage.get('windowHeight') as number | undefined
  return val ?? 780
}

// 获取屏幕短边（用于响应式计算）
export function getScreenShortSide(): number {
  const w = getWindowWidth()
  const h = getWindowHeight()
  return Math.min(w, h)
}

// 判断是否为横屏
export function isLandscape(): boolean {
  return getWindowWidth() > getWindowHeight()
}

// ==================== 断点判断 ====================

// 是否为平板或更大屏幕（>= 840vp）
export function isMediumOrLarger(): boolean {
  return getWindowWidth() >= BREAKPOINT_MD
}

// 是否为 PC 或大屏（>= 1024vp）
export function isLargeOrLarger(): boolean {
  return getWindowWidth() >= BREAKPOINT_LG
}

// 获取内容区最大宽度（手机=不限制，折叠屏=800，平板/PC=900）
export function getContentMaxWidth(): number {
  const w = getWindowWidth()
  if (w >= BREAKPOINT_LG) return 900
  if (w >= BREAKPOINT_MD) return 800
  return 0 // 0 表示不限制，填满宽度
}

// Grid 自适应列数：手机 2 列，平板+ 4 列
export function getGridColumns(itemMinWidth: number): number {
  const available = getWindowWidth() - 40 // 减去 padding
  return Math.max(2, Math.floor(available / itemMinWidth))
}

// 根据屏幕短边计算响应式尺寸（限制最大和最小值）
// 基准屏幕宽度为 360vp（如华为 P50）
export function responsive(px: number, minPx?: number, maxPx?: number): number {
  const baseWidth = 360
  const shortSide = getScreenShortSide()
  const scale = shortSide / baseWidth
  let scaled = px * scale
  // 限制最小值
  if (minPx !== undefined) {
    scaled = Math.max(scaled, minPx)
  }
  // 限制最大值（防止折叠屏展开后尺寸过大）
  if (maxPx !== undefined) {
    scaled = Math.min(scaled, maxPx)
  }
  return scaled
}

// 信号环形图尺寸（响应式）- 设置最大尺寸防止折叠屏展开后过大
export function getSignalGaugeSize(): number {
  // 横屏时缩小，竖屏时正常，最大不超过 140px
  return isLandscape() ? responsive(100, 80, 120) : responsive(128, 100, 140)
}

// 信号环形图周长（与尺寸匹配）
export function getSignalGaugeCircumference(): number {
  const size = getSignalGaugeSize()
  return Math.round(size * Math.PI * 0.55) // 约0.55圆弧
}

// 信号环形图线宽
export function getSignalGaugeStrokeWidth(): number {
  return isLandscape() ? responsive(7, 6, 10) : responsive(9, 7, 12)
}

// 小型信号环形图尺寸（如连接卡片中的）
export function getSmallGaugeSize(): number {
  return isLandscape() ? responsive(44, 36, 56) : responsive(56, 44, 70)
}

// 小型环形图线宽
export function getSmallGaugeStrokeWidth(): number {
  return responsive(3.5, 3, 5)
}

// 小型环形图周长
export function getSmallGaugeCircumference(): number {
  const size = getSmallGaugeSize()
  return Math.round(size * Math.PI * 0.55)
}

// 图标尺寸（响应式）
export function getResponsiveIconSize(base: number): number {
  return responsive(base, Math.round(base * 0.8))
}
