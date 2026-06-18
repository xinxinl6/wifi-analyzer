/**
 * WiFi分析仪 — 窗口工具
 * 封装窗口信息、安全区、状态栏、导航指示器等
 */

export class WindowInfo {
  windowWidth: number = 0;
  windowHeight: number = 0;
  statusBarHeight: number = 0;
  naviIndicatorHeight: number = 0;
}

export class WindowUtil {
  public mainWindowInfo: WindowInfo = {
    windowWidth: 0,
    windowHeight: 0,
    statusBarHeight: 0,
    naviIndicatorHeight: 0,
  };

  /**
   * 更新窗口尺寸
   */
  updateWindowSize(width: number, height: number): void {
    this.mainWindowInfo.windowWidth = width;
    this.mainWindowInfo.windowHeight = height;
  }

  /**
   * 更新安全区信息
   */
  updateSafeArea(statusBarH: number, naviIndicatorH: number): void {
    this.mainWindowInfo.statusBarHeight = statusBarH;
    this.mainWindowInfo.naviIndicatorHeight = naviIndicatorH;
  }

  /**
   * 获取底部安全区域（用于 TabBar 等）
   */
  get bottomSafeArea(): number {
    return Math.max(this.mainWindowInfo.naviIndicatorHeight, 16);
  }
}

/**
 * 全局 WindowUtil 实例 key
 */
export const WINDOW_UTIL_KEY: string = 'WindowUtil';
