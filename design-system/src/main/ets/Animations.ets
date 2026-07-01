// ============================================
// HM7 动画系统 — 统一动画 Token
// 300ms 标准转场 / 500ms 材质切换 / 150ms 点击反馈
// ============================================

import { DURATION_FAST, DURATION_NORMAL, DURATION_SLOW } from './Glass'

// ==================== 时长 Token ====================

/** 瞬时（按压波纹、Scale 回弹） */
export const DURATION_INSTANT = 100

/** 快捷（小元素显隐、chip 切换、tooltip） */
export const DURATION_QUICK = 200

/** 优雅（重要过渡、首次加载动画）500ms — HM7 材质切换 */
export const DURATION_GRACEFUL = 500

// DURATION_FAST(150) / DURATION_NORMAL(300) / DURATION_SLOW(400) 从 Glass.ets 引用

// ==================== 缓动曲线 ====================

/** 标准缓动 — 适用于大多数 UI 动画（Tab 切换、卡片动画） */
export const CURVE_STANDARD: Curve = Curve.FastOutSlowIn

/** 减速缓动 — 适用于元素入场/出现（Overlay 入场、FAB 出现） */
export const CURVE_DECELERATE: Curve = Curve.EaseOut

/** 加速缓动 — 适用于元素退场/消失（Overlay 退场、弹窗关闭） */
export const CURVE_ACCELERATE: Curve = Curve.EaseIn

/** 强调缓动 — 适用于需要醒目的转场（Overlay 缩放、弹窗弹出） */
export const CURVE_EMPHASIZED: Curve = Curve.EaseInOut

// ==================== 预设动画配置 ====================

export interface AnimationPreset {
  duration: number
  curve: Curve
}

/** 点击反馈 Scale 动画（按钮、卡片、列表项按下） */
export const PRESET_TAP: AnimationPreset = {
  duration: DURATION_FAST,
  curve: CURVE_DECELERATE
}

/** 转场入场（页面/Overlay 出现）300ms — HM7 标准 */
export const PRESET_ENTER: AnimationPreset = {
  duration: DURATION_NORMAL,
  curve: CURVE_EMPHASIZED
}

/** 转场退场（页面/Overlay 消失） */
export const PRESET_EXIT: AnimationPreset = {
  duration: DURATION_NORMAL,
  curve: CURVE_EMPHASIZED
}

/** Tab 阶段1：预压缩（快速） */
export const PRESET_TAB_PHASE1: AnimationPreset = {
  duration: DURATION_INSTANT,
  curve: CURVE_STANDARD
}

/** Tab 阶段2：弹跳伸展 */
export const PRESET_TAB_PHASE2: AnimationPreset = {
  duration: DURATION_SLOW,
  curve: CURVE_STANDARD
}

/** Tab 阶段3：回弹 */
export const PRESET_TAB_PHASE3: AnimationPreset = {
  duration: DURATION_QUICK,
  curve: CURVE_DECELERATE
}

/** Tab 内容切换淡入 300ms */
export const PRESET_TAB_CONTENT: AnimationPreset = {
  duration: DURATION_NORMAL,
  curve: CURVE_DECELERATE
}

// ==================== 兼容旧 API ====================

/** @deprecated 使用 DURATION_FAST (Glass.ets) */
export const DURATION_FAST_OLD = 150

/** @deprecated 使用 DURATION_NORMAL (Glass.ets) */
export const DURATION_NORMAL_OLD = 300
