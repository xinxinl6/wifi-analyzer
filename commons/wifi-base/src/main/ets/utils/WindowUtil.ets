/**
 * WiFi分析仪 — 窗口工具（v2 升级版）
 * 参照 Spatialization 项目的 WindowUtil + GlobalInfoModel 模式
 * 封装窗口信息、安全区、状态栏、导航指示器、断点等
 * 同步更新 GlobalInfoModel 全局状态
 * API Level: 23+
 */

import { ConfigurationConstant } from '@kit.AbilityKit';
import { UIContext, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from './Logger';
import { GlobalInfoModel } from '../model/GlobalInfoModel';

/**
 * 获取 GlobalInfoModel 单例
 */
function getGlobalModel(): GlobalInfoModel {
  return GlobalInfoModel.getInstance();
}

/**
 * WindowUtil — 窗口管理类
 * 通过 AppStorageV2.connect 注册为全局单例，支持跨组件响应式共享
 */
export class WindowUtil {
  public windowStage?: window.WindowStage;
  public uiContext?: UIContext;
  public mainWindow: window.Window | null = null;
  public mainWindowInfo: WindowInfo = new WindowInfo();

  constructor(mainWindow: window.Window) {
    this.mainWindow = mainWindow;
  }

  // ==================== 事件回调 ====================

  /** 窗口尺寸变化回调 */
  public onWindowSizeChange: (windowSize: window.Size) => void = (windowSize: window.Size) => {
    this.mainWindowInfo.windowSize = windowSize;
    const uiContext = this.uiContext;
    if (!uiContext) {
      return;
    }
    this.mainWindowInfo.widthBp = uiContext.getWindowWidthBreakpoint();
    this.mainWindowInfo.heightBp = uiContext.getWindowHeightBreakpoint();
    // 同步更新 GlobalInfoModel
    const model = getGlobalModel();
    model.widthBreakpoint = uiContext.getWindowWidthBreakpoint();
    model.heightBreakpoint = uiContext.getWindowHeightBreakpoint();
    model.deviceWidth = uiContext.px2vp(windowSize.width);
    model.deviceHeight = uiContext.px2vp(windowSize.height);
  };

  /** 窗口状态变化回调 */
  public onStatusTypeChange: (statusType: window.WindowStatusType) => void =
    (statusType: window.WindowStatusType) => {
      this.mainWindowInfo.windowStatusType = statusType;
    };

  /** 避让区变化回调 */
  public onAvoidAreaChange: (avoidOptions: window.AvoidAreaOptions) => void =
    (avoidOptions: window.AvoidAreaOptions) => {
      const model = getGlobalModel();
      if (avoidOptions.type === window.AvoidAreaType.TYPE_SYSTEM) {
        this.mainWindowInfo.avoidSystem = avoidOptions.area;
        this.mainWindowInfo.statusBarHeight = this.uiContext?.px2vp(avoidOptions.area.topRect.height) ?? 0;
        model.statusBarHeight = this.mainWindowInfo.statusBarHeight;
      } else if (avoidOptions.type === window.AvoidAreaType.TYPE_CUTOUT) {
        this.mainWindowInfo.avoidCutout = avoidOptions.area;
      } else if (avoidOptions.type === window.AvoidAreaType.TYPE_SYSTEM_GESTURE) {
        this.mainWindowInfo.avoidSystemGesture = avoidOptions.area;
      } else if (avoidOptions.type === window.AvoidAreaType.TYPE_KEYBOARD) {
        this.mainWindowInfo.avoidKeyboard = avoidOptions.area;
      } else if (avoidOptions.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        this.mainWindowInfo.avoidNavigationIndicator = avoidOptions.area;
        this.mainWindowInfo.naviIndicatorHeight = this.uiContext?.px2vp(avoidOptions.area.bottomRect.height) ?? 0;
        model.naviIndicatorHeight = this.mainWindowInfo.naviIndicatorHeight;
      }
    };

  /** 窗口按钮区域变化回调 */
  public onWindowButtonRectChange: (titleButtonRect: window.TitleButtonRect) => void =
    (titleButtonRect: window.TitleButtonRect) => {
      this.mainWindowInfo.titleButtonRect = titleButtonRect;
    };

  // ==================== 公共方法 ====================

  /** 设置 UIContext */
  setUIContext(): void {
    try {
      this.uiContext = this.mainWindow?.getUIContext();
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('Failed to set UI context. Code: ' + err.code + ', message: ' + err.message);
    }
  }

  /** 设置全屏模式 */
  setFullScreen(isFullScreen: boolean): void {
    if (!this.mainWindow) return;
    if (canIUse('SystemCapability.Window.SessionManager.Extension')) {
      this.mainWindow.setWindowLayoutFullScreen(isFullScreen)
        .then(() => {
          this.mainWindowInfo.isFullScreen = isFullScreen;
        })
        .catch((err: BusinessError) => {
          Logger.error('Failed to set full-screen mode. Code: ' + err.code + ', message: ' + err.message);
        });
    }
  }

  /** 设置窗口方向 */
  setWindowOrientation(orientation: window.Orientation): void {
    if (!this.mainWindow) return;
    this.mainWindow.setPreferredOrientation(orientation)
      .then(() => {
        this.mainWindowInfo.orientation = orientation;
      })
      .catch((err: BusinessError) => {
        Logger.error('Failed to set window orientation. Code: ' + err.code + ', message: ' + err.message);
      });
  }

  /** 设置沉浸式 */
  setImmersive(): void {
    try {
      if (!this.mainWindow) return;
      this.mainWindow.setWindowDecorVisible(false);
      this.mainWindow.setWindowDecorHeight(56);
      this.mainWindow.setDecorButtonStyle({
        buttonIconSize: 24,
        spacingBetweenButtons: 16,
        colorMode: ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      });
      this.recover();
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('Failed to set immersive. Code: ' + err.code + ', message: ' + err.message);
    }
  }

  /** 设置装饰按钮样式 */
  setDecorButtonStyle(mode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK): void {
    try {
      if (!this.mainWindow) return;
      this.mainWindow.setDecorButtonStyle({
        buttonIconSize: 24,
        spacingBetweenButtons: 24,
        colorMode: mode
      });
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('Failed to set decor button style. Code: ' + err.code + ', message: ' + err.message);
    }
  }

  /** 从全屏恢复 */
  recover(): void {
    try {
      if (!this.mainWindow) return;
      if (this.mainWindow.getWindowStatus() === window.WindowStatusType.FULL_SCREEN) {
        this.mainWindow.recover()
          .then(() => { })
          .catch((err: BusinessError) => {
            Logger.error('Failed to recover window. Code: ' + err.code + ', message: ' + err.message);
          });
      }
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('Failed to recover. Code: ' + err.code + ', message: ' + err.message);
    }
  }

  /** 初始化窗口信息（注册所有监听） */
  updateWindowInfo(): void {
    try {
      if (!this.mainWindow) return;

      this.mainWindowInfo.windowStatusType = this.mainWindow.getWindowStatus();

      // 首次获取窗口尺寸
      let width: number = this.mainWindow.getWindowProperties().windowRect.width;
      let height: number = this.mainWindow.getWindowProperties().windowRect.height;
      let windowSize: window.Size = { width: width, height: height };
      this.mainWindowInfo.windowSize = windowSize;

      // 注册窗口状态变化监听
      this.mainWindow.on('windowStatusChange', this.onStatusTypeChange);

      // 获取断点
      if (!this.uiContext) {
        this.setUIContext();
      }
      const uiContext = this.uiContext;
      if (!uiContext) {
        return;
      }
      this.mainWindowInfo.widthBp = uiContext.getWindowWidthBreakpoint();
      this.mainWindowInfo.heightBp = uiContext.getWindowHeightBreakpoint();

      // 同步 GlobalInfoModel
      const model = getGlobalModel();
      model.widthBreakpoint = uiContext.getWindowWidthBreakpoint();
      model.heightBreakpoint = uiContext.getWindowHeightBreakpoint();
      model.deviceWidth = uiContext.px2vp(width);
      model.deviceHeight = uiContext.px2vp(height);

      // 注册窗口尺寸变化监听
      this.mainWindow.on('windowSizeChange', this.onWindowSizeChange);

      // 首次获取避让区信息
      this.mainWindowInfo.avoidSystem = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      this.mainWindowInfo.avoidNavigationIndicator =
        this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.mainWindowInfo.avoidCutout = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      this.mainWindowInfo.avoidSystemGesture =
        this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM_GESTURE);
      this.mainWindowInfo.avoidKeyboard = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
      this.mainWindow.on('avoidAreaChange', this.onAvoidAreaChange);

      // 同步避让区到 GlobalInfoModel
      model.statusBarHeight = this.mainWindowInfo.statusBarHeight;
      model.naviIndicatorHeight = this.mainWindowInfo.naviIndicatorHeight;

      // 首次获取标题栏按钮区域
      this.mainWindowInfo.titleButtonRect = this.mainWindow.getTitleButtonRect();
      this.mainWindow.on('windowTitleButtonRectChange', this.onWindowButtonRectChange);

      Logger.info('WindowUtil initialized successfully');
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('Failed to update window info. Code: ' + err.code + ', message: ' + err.message);
    }
  }

  /** 释放所有窗口监听 */
  release(): void {
    try {
      if (!this.mainWindow) return;
      this.mainWindow.off('windowStatusChange');
      this.mainWindow.off('windowSizeChange');
      this.mainWindow.off('avoidAreaChange');
      this.mainWindow.off('windowTitleButtonRectChange');
      Logger.info('WindowUtil released');
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('Failed to release window listeners. Code: ' + err.code + ', message: ' + err.message);
    }
  }

  /** 获取底部安全区域（用于 TabBar 等） */
  get bottomSafeArea(): number {
    return Math.max(this.mainWindowInfo.naviIndicatorHeight, 16);
  }
}

/**
 * WindowInfo — 响应式窗口信息模型
 * 使用 @ObservedV2 + @Trace 实现属性级响应式更新
 */
@ObservedV2
export class WindowInfo {
  /** 窗口状态 */
  @Trace public windowStatusType: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  /** 是否全屏 */
  @Trace public isFullScreen: boolean = false;
  /** 窗口方向 */
  @Trace public orientation: window.Orientation = window.Orientation.UNSPECIFIED;
  /** 窗口尺寸 */
  @Trace public windowSize: window.Size = { width: 0, height: 0 };
  /** 宽度断点 */
  @Trace public widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_XS;
  /** 高度断点 */
  @Trace public heightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;
  /** 系统避让区（状态栏） */
  @Trace public avoidSystem?: window.AvoidArea;
  /** 导航指示器避让区 */
  @Trace public avoidNavigationIndicator?: window.AvoidArea;
  /** 刘海屏避让区 */
  @Trace public avoidCutout?: window.AvoidArea;
  /** 手势避让区 */
  @Trace public avoidSystemGesture?: window.AvoidArea;
  /** 键盘避让区 */
  @Trace public avoidKeyboard?: window.AvoidArea;
  /** 标题栏按钮区域 */
  @Trace public titleButtonRect?: window.TitleButtonRect;
  /** 状态栏高度 (vp) */
  @Trace public statusBarHeight: number = 0;
  /** 导航指示器高度 (vp) */
  @Trace public naviIndicatorHeight: number = 0;
}

/**
 * 全局 WindowUtil 实例 key（用于 AppStorageV2.connect）
 */
export const WINDOW_UTIL_KEY: string = 'wifiAnalyzerWindowUtil';
