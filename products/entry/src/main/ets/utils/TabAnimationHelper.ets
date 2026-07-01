// Tab 动画辅助工具 — 使用 design-system 统一动画 Token
// 从旧项目移植，供 API 17-22 降级 TabBar 动画使用

import {
  DURATION_INSTANT, DURATION_NORMAL, DURATION_SLOW, DURATION_QUICK,
  CURVE_STANDARD, CURVE_DECELERATE, CURVE_EMPHASIZED,
  PRESET_TAB_PHASE1, PRESET_TAB_PHASE2, PRESET_TAB_PHASE3, PRESET_TAB_CONTENT,
  PRESET_ENTER, PRESET_EXIT
} from '@wifi-analyzer/design-system'

// ==================== 接口 ====================

export interface Phase1States {
  scales: number[]
  offsets: number[]
  dots: number[]
}

export interface Phase2States {
  scales: number[]
  offsets: number[]
  glows: number[]
  dots: number[]
}

export interface Phase3States {
  scales: number[]
  offsets: number[]
  glows: number[]
}

export interface AnimationConfig {
  duration: number
  curve: Curve | ICurve
}

export interface OverlayState {
  opacity: number
  scale: number
}

/**
 * TabAnimationHelper — Tab 切换动画辅助工具
 * 所有时长/曲线引用 design-system 统一 Token
 */
export class TabAnimationHelper {
  static readonly TAB_COUNT: number = 5

  // ==================== 动画状态计算 ====================

  static calcPhase1States(
    prevIndex: number,
    index: number,
    currentTabScales: number[],
    currentTabOffsetY: number[],
    currentTabDotOpacity: number[]
  ): Phase1States {
    const scales: number[] = [...currentTabScales]
    const offsets: number[] = [...currentTabOffsetY]
    const dots: number[] = [...currentTabDotOpacity]

    scales[prevIndex] = 0.85
    scales[index] = 0.75
    offsets[index] = 4
    dots[prevIndex] = 0

    return { scales, offsets, dots }
  }

  static calcPhase2States(
    index: number,
    currentTabScales: number[],
    currentTabOffsetY: number[],
    currentTabGlows: number[],
    currentTabDotOpacity: number[]
  ): Phase2States {
    const scales: number[] = [...currentTabScales]
    const offsets: number[] = [...currentTabOffsetY]
    const glows: number[] = [...currentTabGlows]
    const dots: number[] = [...currentTabDotOpacity]

    scales[index] = 1.12
    offsets[index] = -6
    glows[index] = 1
    dots[index] = 1

    return { scales, offsets, glows, dots }
  }

  static calcPhase3States(): Phase3States {
    return {
      scales: [1.0, 1.0, 1.0, 1.0, 1.0],
      offsets: [0, 0, 0, 0, 0],
      glows: [0, 0, 0, 0, 0]
    }
  }

  // ==================== 子页面动画配置 ====================

  static getEnterAnimationConfig(): AnimationConfig {
    return PRESET_ENTER
  }

  static getExitAnimationConfig(): AnimationConfig {
    return PRESET_EXIT
  }

  // ==================== 初始状态 ====================

  static getInitialTabScales(): number[] { return [1, 1, 1, 1, 1] }
  static getInitialTabGlows(): number[] { return [0, 0, 0, 0, 0] }
  static getInitialTabOffsetY(): number[] { return [0, 0, 0, 0, 0] }
  static getInitialTabDotOpacity(): number[] { return [1, 0, 0, 0, 0] }
  static getInitialContentOpacity(): number { return 1 }
  static getInitialContentOffsetY(): number { return 0 }

  // ==================== 子页面入场动画状态 ====================

  static getOverlayEnterInitial(): OverlayState { return { opacity: 0, scale: 0.92 } }
  static getOverlayEnterFinal(): OverlayState { return { opacity: 1, scale: 1 } }
  static getOverlayExitFinal(): OverlayState { return { opacity: 0, scale: 0.92 } }

  // ==================== 延迟常量 ====================

  static getPhase1Delay(): number { return 0 }
  static getPhase2Delay(): number { return DURATION_INSTANT }
  static getPhase3Delay(): number { return DURATION_INSTANT + DURATION_SLOW }
  static getEnterAnimationDelay(): number { return 20 }
}
