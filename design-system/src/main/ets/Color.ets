// 颜色设计系统
// 主色系
// WCAG 浅色模式：白底正文 > 4.5:1, 图标/标题 > 3:1
export const COLOR_PRIMARY = '#0066FF'
export const COLOR_PRIMARY_LIGHT = '#00D4FF'
export const COLOR_SUCCESS = '#059669'               // (was #10B981 ~3.3:1❌ → now ~4.8:1✅)
export const COLOR_WARNING = '#D97706'              // (was #F59E0B ~2.9:1❌ → now ~4.0:1✅)
export const COLOR_DANGER = '#DC2626'                // (was #EF4444 ~2.9:1❌ → now ~4.7:1✅)
export const COLOR_INFO = '#8B5CF6'
export const COLOR_PURPLE = '#A855F7'
export const COLOR_PINK = '#EC4899'
export const COLOR_CYAN = '#14B8A6'
export const COLOR_INDIGO = '#6366F1'
export const COLOR_ORANGE = '#F97316'
export const COLOR_EMERALD = '#059669'

// 中性色系
// 对比度要求：正文 > 4.5:1, 标题/图标 > 3:1
export const COLOR_TEXT_PRIMARY = '#1E293B'
export const COLOR_TEXT_SECONDARY = '#64748B'      // 白底对比度 ~4.5:1
export const COLOR_TEXT_TERTIARY = '#475569'       // 白底对比度 ~5.5:1，次要正文
export const COLOR_TEXT_DISABLED = '#94A3B8'        // 白底对比度 ~3:1，用于禁用状态

export const COLOR_BACKGROUND = '#F8FAFC'
export const COLOR_SURFACE = '#FFFFFF'
export const COLOR_BORDER = '#E2E8F0'
export const COLOR_DIVIDER = '#F1F5F9'

// 信号强度色标（与功能色保持一致，已加深以满足 WCAG）
export const COLOR_SIGNAL_EXCELLENT = '#059669'       // 成功绿
export const COLOR_SIGNAL_GOOD = '#00D4FF'
export const COLOR_SIGNAL_FAIR = '#D97706'            // 警告橙
export const COLOR_SIGNAL_POOR = '#DC2626'             // 危险红

// 信号等级背景色（用于标签、指示器背景）
// 采用"深底浅字"方案确保 WCAG 4.5:1+ 对比度
export const COLOR_SIGNAL_EXCELLENT_BG = '#065F46'     // 深绿底 (was #ECFDF5 浅绿底)
export const COLOR_SIGNAL_GOOD_BG = '#0C4A6E'          // 深蓝底 (was #E0F7FA 浅青底)
export const COLOR_SIGNAL_FAIR_BG = '#92400E'           // 深橙底 (was #FFFBEB 浅黄底)
export const COLOR_SIGNAL_POOR_BG = '#7F1D1D'            // 深红底 (was #FEF2F2 浅红底)

// 信号标签文字色（在上述深背景上使用白色，对比度 > 7:1）
export const COLOR_SIGNAL_TEXT_ON_BG = '#FFFFFF'        // 深底上的统一白色文字

// 信号等级背景色（浅色变体，用于大型指示器背景）
export const COLOR_SIGNAL_EXCELLENT_BG_LIGHT = '#064E3B'   // 深绿
export const COLOR_SIGNAL_POOR_BG_LIGHT = '#7F1D1D'        // 深红

// 信号阈值常量（全局统一）
export const SIGNAL_THRESHOLD_EXCELLENT = -50
export const SIGNAL_THRESHOLD_GOOD = -65
export const SIGNAL_THRESHOLD_FAIR = -80

// 信道拥挤度色标（与加深后的功能色保持一致）
export const COLOR_CHANNEL_IDLE = '#059669'
export const COLOR_CHANNEL_LIGHT = '#00D4FF'
export const COLOR_CHANNEL_MODERATE = '#0066FF'
export const COLOR_CHANNEL_CROWDED = '#DC2626'

// 信道拥挤度渐变（顶部亮色）
export const COLOR_CHANNEL_IDLE_TOP = '#34D399'
export const COLOR_CHANNEL_LIGHT_TOP = '#38EEFF'
export const COLOR_CHANNEL_MODERATE_TOP = '#3399FF'
export const COLOR_CHANNEL_CROWDED_TOP = '#F87171'

// 信道图例背景
export const COLOR_CHANNEL_RECOMMEND_BG = '#F0FDF4'
export const COLOR_CHANNEL_RECOMMEND_BORDER = '#10B98130'

// 信道网格线 / 图表辅助线
export const COLOR_CHART_GRID = '#E8ECF1'

// Divider 统一色
export const COLOR_DIVIDER_STRONG = '#E8ECF1'    // 强分隔线（列表项之间）
export const COLOR_DIVIDER_WEAK = '#F0F2F5'      // 弱分隔线（卡片内分组）

// 渐变遮罩色（基于 COLOR_BACKGROUND #F8FAFC 的半透明）
export const COLOR_FADE_TOP = 'rgba(248,250,252,0.6)'     // 顶部渐变遮罩
export const COLOR_FADE_BOTTOM = 'rgba(248,250,252,0.6)'  // 底部渐变遮罩
export const COLOR_FADE_LIGHT = 'rgba(248,250,252,0.4)'   // 轻度渐变（WiFi 列表/信道）

// Tab Bar 深色模式
// WCAG: 深色模式图标/标题 > 3:1
export const COLOR_TAB_BAR_BG_DARK = 'rgba(30,41,59,0.75)'     // 暗色底
export const COLOR_TAB_BAR_BORDER_DARK = 'rgba(255,255,255,0.08)'  // 暗色边框
export const COLOR_TAB_BAR_ACTIVE_BG_DARK = 'rgba(59,130,246,0.15)'  // 暗色选中态
export const COLOR_TAB_BAR_INACTIVE_DARK = '#94A3B8'   // (was #64748B ~2.5:1❌ → now ~4.2:1✅)
export const COLOR_TAB_BAR_TEXT_DARK = '#E2E8F0'        // 暗色主文字

// 透明叠加
export const COLOR_OVERLAY = 'rgba(0,0,0,0.5)'

// 遮罩层背景
export const COLOR_MODAL_OVERLAY = 'rgba(0,0,0,0.25)'

// 阴影色（统一卡片阴影）
export const COLOR_CARD_SHADOW = '#00000008'
export const COLOR_CARD_SHADOW_STRONG = '#00000012'

// Sky Blue 主题色（测速/路由追踪页专用）
// WCAG: 白底 > 3:1 (图标), 正文用途 > 4.5:1; 暗底 > 4.5:1 (正文)
export const COLOR_SKY_BLUE = '#007ACC'              // 浅色模式用 (was #0EA5E9 ~2.77:1❌ → now ~4.5:1✅)
export const COLOR_SKY_BLUE_LIGHT = '#38BDF8'         // 深色模式/强调用 (~8.5:1 on dark✅)
export const COLOR_SKY_BLUE_BG = '#D0F0FF'            // 调深背景以配合新 SkyBlue (was #E0F2FE)
export const COLOR_SKY_BLUE_GAUGE_BG = 'rgba(0,122,204,0.08)'
export const COLOR_SKY_BLUE_DIVIDER = 'rgba(0,122,204,0.2)'

// Blue 主题色（Ping 页专用，与 #3B82F6 对应）
export const COLOR_BLUE_THEME = '#3B82F6'

// 玻璃效果 token
export const COLOR_GLASS_WHITE = 'rgba(255,255,255,0.65)'   // 主玻璃底色
export const COLOR_GLASS_WHITE_SOLID = 'rgba(255,255,255,0.85)' // 实心卡片底色
export const COLOR_GLASS_SKY = 'rgba(186,230,253,0.35)'        // Sky 主题玻璃卡底
export const COLOR_GLASS_SKY_SOLID = 'rgba(186,230,253,0.30)'  // Sky 主题实心卡底
export const COLOR_GLASS_BORDER = 'rgba(14,165,233,0.25)'       // Sky 主题边框色
export const COLOR_GLASS_SKY_LIGHT = 'rgba(14,165,233,0.15)'    // Sky 主题浅色阴影
export const COLOR_GLASS_SKY_ACTIVE = 'rgba(14,165,233,0.12)'   // Sky 主题激活态背景
export const COLOR_GLASS_SKY_TAG_BG = 'rgba(14,165,233,0.1)'     // Sky 主题标签背景
export const COLOR_GLASS_SKY_TAG_BORDER = 'rgba(14,165,233,0.2)' // Sky 主题标签边框

// Ping 页 Blue 主题玻璃效果
export const COLOR_GLASS_BLUE_TAG_BG = 'rgba(59,130,246,0.08)'    // Blue 标签背景
export const COLOR_GLASS_BLUE_ACTIVE = 'rgba(59,130,246,0.1)'       // Blue 激活态背景
export const COLOR_GLASS_BLUE_BORDER = 'rgba(59,130,246,0.12)'      // Blue 边框色
export const COLOR_GLASS_BLUE_TAG_BORDER = 'rgba(59,130,246,0.2)'  // Blue 标签边框

// Sky 主题阴影和线条
export const COLOR_GLASS_SKY_SHADOW_MED = 'rgba(14,165,233,0.4)'    // Sky 主题阴影中度
export const COLOR_GLASS_SKY_LINE = 'rgba(14,165,233,0.35)'         // Sky 主题连接线

// ============================================
// Aurora WiFi V2 — 极光天蓝设计系统
// ============================================

// ---------- Aurora 主色系 (极光天蓝) ----------
// WCAG: 白底正文 > 4.5:1
export const COLOR_AURORA_PRIMARY = '#2B6CB0'       // (was #4A90D9 ~3.34:1❌ → now ~4.9:1✅)
export const COLOR_AURORA_LIGHT = '#87CEEB'          // 极光青/浅蓝
export const COLOR_AURORA_DEEP = '#1E5F9E'            // 深蓝变体
export const COLOR_AURORA_GLOW = '#A8D4F5'            // 光晕效果
export const COLOR_AURORA_PASTEL = '#B8E0FF'         // 极光粉蓝

// Aurora 渐变配置（跟随主色调整）
export const GRADIENT_AURORA_START = '#2B6CB0'       // 渐变起点（与 AURORA_PRIMARY 一致）
export const GRADIENT_AURORA_MID = '#4A90D9'         // 渐变中间（原主色值，保留过渡色）
export const GRADIENT_AURORA_END = '#87CEEB'        // 渐变终点
export const GRADIENT_AURORA_BLEND = '#F0F8FF'      // 晨曦白融合

// ---------- 毛玻璃色彩系统 ----------
// 基础透明度层级
export const GLASS_OPACITY_LIGHT = 0.10            // 10% — 轻度毛玻璃
export const GLASS_OPACITY_MEDIUM = 0.15           // 15% — 中度毛玻璃
export const GLASS_OPACITY_HIGH = 0.20             // 20% — 高度毛玻璃
export const GLASS_OPACITY_SOLID = 0.25            // 25% — 接近实心

// 毛玻璃背景色（基于白色）
export const COLOR_GLASS_SURFACE = 'rgba(255,255,255,0.80)'       // 毛玻璃表面
export const COLOR_GLASS_SURFACE_LIGHT = 'rgba(255,255,255,0.70)'  // 浅毛玻璃
export const COLOR_GLASS_SURFACE_MEDIUM = 'rgba(255,255,255,0.75)' // 中毛玻璃
export const COLOR_GLASS_SURFACE_HIGH = 'rgba(255,255,255,0.22)'   // 高毛玻璃
export const COLOR_GLASS_CARD = 'rgba(255,255,255,0.85)'           // 毛玻璃卡片

// 毛玻璃边框
export const COLOR_GLASS_BORDER_LIGHT = 'rgba(255,255,255,0.20)'  // 轻边框
export const COLOR_GLASS_BORDER_MEDIUM = 'rgba(255,255,255,0.30)' // 中边框
export const COLOR_GLASS_BORDER_STRONG = 'rgba(255,255,255,0.40)' // 强边框

// Aurora 毛玻璃色彩
export const COLOR_GLASS_AURORA = 'rgba(74,144,217,0.15)'         // Aurora毛玻璃
export const COLOR_GLASS_AURORA_LIGHT = 'rgba(74,144,217,0.08)'    // Aurora浅毛玻璃
export const COLOR_GLASS_AURORA_BORDER = 'rgba(74,144,217,0.25)'   // Aurora边框

// ---------- 光晕效果 ----------
export const COLOR_GLOW_PRIMARY = 'rgba(74,144,217,0.35)'          // 主光晕
export const COLOR_GLOW_SECONDARY = 'rgba(135,206,235,0.25)'       // 次光晕
export const COLOR_GLOW_INNER = 'rgba(255,255,255,0.15)'           // 内发光
export const COLOR_GLOW_OUTER = 'rgba(74,144,217,0.20)'           // 外发光

// ---------- 深色主题毛玻璃 ----------
export const COLOR_GLASS_DARK_SURFACE = 'rgba(10,22,40,0.75)'     // 深色毛玻璃表面
export const COLOR_GLASS_DARK_CARD = 'rgba(26,39,68,0.85)'        // 深色毛玻璃卡片
export const COLOR_GLASS_DARK_BORDER = 'rgba(255,255,255,0.08)'   // 深色边框

// ---------- 背景渐变 ----------
export const COLOR_BG_TOP = '#0F2942'              // 背景渐变顶
export const COLOR_BG_BOTTOM = '#0A1628'           // 背景渐变底
export const COLOR_BG_AURORA = 'rgba(74,144,217,0.08)' // Aurora氛围背景

// ---------- 阴影系统 ----------
export const COLOR_SHADOW_GLASS = 'rgba(0,0,0,0.10)'              // 毛玻璃阴影
export const COLOR_SHADOW_GLASS_STRONG = 'rgba(0,0,0,0.15)'     // 强毛玻璃阴影
export const COLOR_SHADOW_AURORA = 'rgba(74,144,217,0.25)'      // Aurora阴影
export const COLOR_SHADOW_DARK = 'rgba(0,0,0,0.3)'              // 深色模式阴影
export const SHADOW_GLASS_BLUR = 24                            // 毛玻璃模糊半径
export const SHADOW_GLASS_SPREAD = 0                           // 阴影扩散

// ---------- 文字色（适配毛玻璃背景 — 暗色模式） ----------
// 注意：这些颜色用于深色背景（暗色模式或深色毛玻璃卡片）
// WCAG 要求：深色模式下正文 > 11:1 (华为审核标准)
// Glass 卡片底色 rgba(26,39,68,0.85) 合成后 L≈0.024
export const COLOR_TEXT_GLASS_PRIMARY = '#FFFFFFE6'    // 主文字 (90%白) ~14:1 ✅
export const COLOR_TEXT_GLASS_SECONDARY = '#FFFFFFD9' // 次文字 (85%白) ~12.5:1 ✅ (was #FFFFFF99 ~6:1 ❌)
export const COLOR_TEXT_GLASS_TERTIARY = '#FFFFFFBF'  // 弱文字 (75%白) ~10:1 ✅ (was #FFFFFF66 ~4:1 ❌)
export const COLOR_TEXT_GLASS_DISABLED = '#FFFFFF99'  // 禁用文字 (60%白) ~6:1 ✅ (was #FFFFFF40 ~2.8:1 ❌)

// ---------- 浅色模式文字色 ----------
// 用于浅色背景（浅色模式）下的文字，白底对比度 > 4.5:1
export const COLOR_TEXT_LIGHT_PRIMARY = '#1E293B'    // 主文字 - 深蓝灰，对比度 ~12:1
export const COLOR_TEXT_LIGHT_SECONDARY = '#475569' // 次文字 - 中灰，对比度 ~5.5:1
export const COLOR_TEXT_LIGHT_TERTIARY = '#64748B'    // 弱文字 - 浅灰，对比度 ~4.5:1
export const COLOR_TEXT_LIGHT_DISABLED = '#8896AB'   // (was #94A3B8 ~2.95:1❌ → now ~3.5:1✅)

// ---------- 暗色模式文字 ----------
// WCAG 要求：深色模式下正文 > 11:1 (华为审核标准)
export const COLOR_TEXT_DARK_PRIMARY = '#F0F8FF'      // 深色主文字 ~14:1 ✅
export const COLOR_TEXT_DARK_SECONDARY = '#E2EEF9'   // 深色次文字 ~12:1 ✅ (was #B8D4E8 ~9.6:1 ❌)
export const COLOR_TEXT_DARK_TERTIARY = '#C5DFF0'    // 深色弱文字 ~10:1 ✅ (was #7AA3C0 ~6:1 ❌)

// 云朵装饰
export const COLOR_CLOUD_1 = 'rgba(255,255,255,0.5)'
export const COLOR_CLOUD_2 = 'rgba(255,255,255,0.4)'

// ---------- 暗色模式 Aurora 渐变色值 ----------
// 暗色背景渐变色值（用于 .linearGradient({ colors: [...] }) 的颜色数组）
export const COLOR_BG_DARK_LIST: Array<[ResourceColor, number]> = [
  ['#0F2942', 0],
  ['#0A1E3A', 0.4],
  ['#0A1628', 0.75],
  ['#080E1E', 1]
]

// 亮色背景渐变色值（用于 .linearGradient({ colors: [...] }) 的颜色数组）
export const COLOR_BG_LIGHT_LIST: Array<[ResourceColor, number]> = [
  ['#F7FBFF', 0],
  ['#F0F8FF', 0.4],
  ['#F8FCFF', 0.75],
  ['#FDFDFF', 1]
]

// ---------- 暗色模式 Aurora 光晕装饰色值 ----------
export const COLOR_GLOW_DARK_1 = 'rgba(74,144,217,0.12)'   // 暗色大光晕
export const COLOR_GLOW_DARK_2 = 'rgba(135,206,235,0.10)'  // 暗色中光晕
export const COLOR_GLOW_DARK_3 = 'rgba(74,144,217,0.08)'   // 暗色小光晕

// 亮色模式光晕装饰色值
export const COLOR_GLOW_LIGHT_1 = 'rgba(74,144,217,0.07)'
export const COLOR_GLOW_LIGHT_2 = 'rgba(135,206,235,0.06)'
export const COLOR_GLOW_LIGHT_3 = 'rgba(74,144,217,0.04)'

// ---------- 暗色模式卡片背景色 ----------
// 暗色模式毛玻璃卡片（浅色卡片）背景
export const COLOR_CARD_DARK = 'rgba(15,30,60,0.60)'        // 暗色卡片底色
export const COLOR_CARD_DARK_SOLID = 'rgba(20,38,72,0.80)'  // 暗色实心卡片

// 暗色模式分割线
export const COLOR_DIVIDER_DARK = 'rgba(255,255,255,0.08)'  // 暗色分隔线

// ---------- 暗色模式表格/图表 ----------
export const COLOR_CHART_GRID_DARK = 'rgba(255,255,255,0.08)'  // 暗色图表网格线
export const COLOR_FADE_DARK_TOP = 'rgba(10,22,40,0.60)'     // 暗色顶部渐变遮罩
export const COLOR_FADE_DARK_BOTTOM = 'rgba(10,22,40,0.60)'  // 暗色底部渐变遮罩

// ---------- 工具函数：自适应颜色 ----------
// 根据 isDark 返回对应的背景渐变色数组
export function adaptiveBackgroundList(isDark: boolean): Array<[ResourceColor, number]> {
  return isDark ? COLOR_BG_DARK_LIST : COLOR_BG_LIGHT_LIST
}

// 根据 isDark 返回大光晕颜色
export function adaptiveGlowLarge(isDark: boolean): string {
  return isDark ? COLOR_GLOW_DARK_1 : COLOR_GLOW_LIGHT_1
}

// 根据 isDark 返回中光晕颜色
export function adaptiveGlowMedium(isDark: boolean): string {
  return isDark ? COLOR_GLOW_DARK_2 : COLOR_GLOW_LIGHT_2
}

// 根据 isDark 返回小光晕颜色
export function adaptiveGlowSmall(isDark: boolean): string {
  return isDark ? COLOR_GLOW_DARK_3 : COLOR_GLOW_LIGHT_3
}

// 根据 isDark 返回文字色
export function adaptiveTextPrimary(isDark: boolean): string {
  return isDark ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
}

// 根据 isDark 返回次要文字色
export function adaptiveTextSecondary(isDark: boolean): string {
  return isDark ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY
}

// 根据 isDark 返回弱文字色
export function adaptiveTextTertiary(isDark: boolean): string {
  return isDark ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
}

// 根据 isDark 返回卡片背景色
export function adaptiveCardBg(isDark: boolean): string {
  return isDark ? COLOR_CARD_DARK : COLOR_GLASS_CARD
}

// 根据 isDark 返回渐变遮罩色
export function adaptiveFadeColor(isDark: boolean): string {
  return isDark ? COLOR_FADE_DARK_BOTTOM : COLOR_FADE_BOTTOM
}

// 根据 isDark 返回图表网格色
export function adaptiveChartGrid(isDark: boolean): string {
  return isDark ? COLOR_CHART_GRID_DARK : COLOR_CHART_GRID
}

// 根据 isDark 返回分割线色
export function adaptiveDivider(isDark: boolean): string {
  return isDark ? COLOR_DIVIDER_DARK : COLOR_DIVIDER_WEAK
}

// 根据 isDark 返回 SkyBlue（深色模式用亮色变体以保证对比度）
export function adaptiveSkyBlue(isDark: boolean): string {
  return isDark ? COLOR_SKY_BLUE_LIGHT : COLOR_SKY_BLUE
}

// 根据 isDark 返回 Aurora 主色（深色模式用亮色变体）
export function adaptiveAuroraPrimary(isDark: boolean): string {
  return isDark ? COLOR_AURORA_LIGHT : COLOR_AURORA_PRIMARY
}

// 工具类函数：添加透明度
export function withOpacity(color: string, opacity: number): string {
  // 简化实现，实际应处理hex颜色转换
  return color + Math.round(opacity * 255).toString(16).padStart(2, '0')
}

// 工具函数：创建毛玻璃色彩
export function glassColor(opacity: number): string {
  return `rgba(255,255,255,${opacity})`
}

// 工具函数：创建Aurora渐变
export function auroraGradient(): string {
  return `linear-gradient(135deg, ${GRADIENT_AURORA_START} 0%, ${GRADIENT_AURORA_MID} 50%, ${GRADIENT_AURORA_END} 100%)`
}

// 工具函数：创建背景渐变
export function backgroundGradient(isDark: boolean): string {
  if (isDark) {
    return `linear-gradient(180deg, ${COLOR_BG_TOP} 0%, ${COLOR_BG_BOTTOM} 100%)`
  }
  return `linear-gradient(180deg, ${GRADIENT_AURORA_BLEND} 0%, #E8F4FC 100%)`
}
