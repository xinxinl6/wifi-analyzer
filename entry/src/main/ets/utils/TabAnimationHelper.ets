// Tab 动画辅助工具

// ==================== 显式接口声明 ====================

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
 * TabAnimationHelper - Tab 动画辅助工具类
 * 提供 Tab 切换动画相关的静态方法和状态计算
 */
export class TabAnimationHelper {
  // ==================== 常量 ====================
  static readonly TAB_COUNT: number = 5
  static readonly ANIMATION_DURATION_FAST: number = 100
  static readonly ANIMATION_DURATION_NORMAL: number = 250
  static readonly ANIMATION_DURATION_SLOW: number = 280
  static readonly ANIMATION_DURATION_BOUNCE: number = 300
  static readonly ANIMATION_DURATION_REBOUND: number = 220

  // ==================== 动画状态计算 ====================

  /**
   * 计算阶段1动画状态（旧 Tab 缩小 + 新 Tab 预压缩）
   */
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

    const result: Phase1States = { scales, offsets, dots }
    return result
  }

  /**
   * 计算阶段2动画状态（图标弹出 + 光晕出现）
   */
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

    const result: Phase2States = { scales, offsets, glows, dots }
    return result
  }

  /**
   * 计算阶段3动画状态（回弹到正常大小）
   */
  static calcPhase3States(): Phase3States {
    const result: Phase3States = {
      scales: [1.0, 1.0, 1.0, 1.0, 1.0],
      offsets: [0, 0, 0, 0, 0],
      glows: [0, 0, 0, 0, 0]
    }
    return result
  }

  // ==================== 子页面动画 ====================

  /**
   * 获取入场动画配置
   */
  static getEnterAnimationConfig(): AnimationConfig {
    const result: AnimationConfig = {
      duration: TabAnimationHelper.ANIMATION_DURATION_BOUNCE,
      curve: Curve.EaseInOut
    }
    return result
  }

  /**
   * 获取退场动画配置
   */
  static getExitAnimationConfig(): AnimationConfig {
    const result: AnimationConfig = {
      duration: TabAnimationHelper.ANIMATION_DURATION_BOUNCE,
      curve: Curve.EaseInOut
    }
    return result
  }

  // ==================== 初始状态 ====================

  static getInitialTabScales(): number[] {
    return [1, 1, 1, 1, 1]
  }

  static getInitialTabGlows(): number[] {
    return [0, 0, 0, 0, 0]
  }

  static getInitialTabOffsetY(): number[] {
    return [0, 0, 0, 0, 0]
  }

  static getInitialTabDotOpacity(): number[] {
    return [1, 0, 0, 0, 0]
  }

  static getInitialContentOpacity(): number {
    return 1
  }

  static getInitialContentOffsetY(): number {
    return 0
  }

  // ==================== 子页面入场动画状态 ====================

  static getOverlayEnterInitial(): OverlayState {
    const result: OverlayState = { opacity: 0, scale: 0.92 }
    return result
  }

  static getOverlayEnterFinal(): OverlayState {
    const result: OverlayState = { opacity: 1, scale: 1 }
    return result
  }

  static getOverlayExitFinal(): OverlayState {
    const result: OverlayState = { opacity: 0, scale: 0.92 }
    return result
  }

  // ==================== 延迟常量 ====================

  static getPhase1Delay(): number {
    return 0
  }

  static getPhase2Delay(): number {
    return TabAnimationHelper.ANIMATION_DURATION_FAST
  }

  static getPhase3Delay(): number {
    return TabAnimationHelper.ANIMATION_DURATION_FAST +
      TabAnimationHelper.ANIMATION_DURATION_SLOW
  }

  static getEnterAnimationDelay(): number {
    return 20
  }
}
