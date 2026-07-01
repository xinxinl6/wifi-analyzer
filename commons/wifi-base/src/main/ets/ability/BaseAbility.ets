/**
 * BaseAbility — 统一 Ability 基类
 * 参照 MultiFinancialManagement 的 AppStorageV2.connect(WindowUtil) 模式
 * 提取 phone/tablet/pc 三个产品 Ability 的公共逻辑
 *
 * 子类只需：
 * 1. 调用 super.onCreate/windowStageCreate 等
 * 2. 指定 loadContent 的页面路径
 */

import { AbilityConstant, ConfigurationConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { WindowUtil, WINDOW_UTIL_KEY } from '../utils/WindowUtil';
import { GlobalInfoModel } from '../model/GlobalInfoModel';
import Logger from '../utils/Logger';

export default class BaseAbility extends UIAbility {
  /** 子类可重写此路径，指定加载的首页 */
  protected pageUrl: string = 'pages/Launcher';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      Logger.error('Failed to set colorMode. Cause: ' + JSON.stringify(err));
    }
    // Aurora v3 Dark-First: 初始化 isDarkMode，默认深色
    const colorMode = this.context.config?.colorMode;
    const isDark = (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
      ? true   // NOT_SET 时默认深色
      : (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    AppStorage.setOrCreate('isDarkMode', isDark);
    // 同步到 GlobalInfoModel 单例
    GlobalInfoModel.getInstance().isDarkMode = isDark;
    Logger.info('Ability onCreate, isDarkMode=' + isDark);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const isDark = (newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    AppStorage.setOrCreate('isDarkMode', isDark);
    // 同步到 GlobalInfoModel 单例
    GlobalInfoModel.getInstance().isDarkMode = isDark;
    Logger.info('onConfigurationUpdate: isDarkMode=' + isDark);
    this.updateStatusBarColor(isDark);
  }

  private updateStatusBarColor(isDark: boolean): void {
    try {
      const statusBarContentColor = isDark ? '0xFFFFFF' : '0x000000';
      const windowStage = AppStorage.get<window.WindowStage>('windowStage');
      if (windowStage) {
        windowStage.getMainWindow().then((mainWindow) => {
          mainWindow.setWindowSystemBarProperties({
            statusBarColor: '0x00000000',
            statusBarContentColor: statusBarContentColor,
            navigationBarColor: '0x00000000',
            navigationBarContentColor: '0x00000000',
          }).catch((err: Error) => {
            Logger.warn('updateStatusBarColor warning: ' + err.message);
          });
        }).catch((err: Error) => {
          Logger.error('Failed to get main window: ' + err.message);
        });
      }
    } catch (err) {
      Logger.error('updateStatusBarColor error: ' + JSON.stringify(err));
    }
  }

  onDestroy(): void {
    Logger.info('Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info('Ability onWindowStageCreate');

    try {
      windowStage.getMainWindow().then((mainWindow) => {
        // 1. 全屏布局
        mainWindow.setWindowLayoutFullScreen(true);

        // 2. 状态栏/导航栏透明化
        const isDark = AppStorage.get<boolean>('isDarkMode') ?? true;
        const statusBarContentColor = isDark ? '0xFFFFFF' : '0x000000';
        mainWindow.setWindowSystemBarProperties({
          statusBarColor: '0x00000000',
          statusBarContentColor: statusBarContentColor,
          navigationBarColor: '0x00000000',
          navigationBarContentColor: '0x00000000',
        }).catch((err: Error) => {
          Logger.warn('setWindowSystemBarProperties warning: ' + err.message);
        });

        // 3. 隐藏底部手势导航指示条
        try {
          mainWindow.setSpecificSystemBarEnabled('navigationIndicator', false);
        } catch (e) {
          Logger.warn('setSpecificSystemBarEnabled not supported: ' + JSON.stringify(e));
        }

        // 4. 初始化 WindowUtil 并通过 AppStorage 注册为全局单例
        // （不使用 AppStorageV2.connect，以避免 ArkTS strict 模式下的编译问题）
        const windowUtil: WindowUtil = new WindowUtil(mainWindow);
        windowUtil.updateWindowInfo();
        AppStorage.setOrCreate(WINDOW_UTIL_KEY, windowUtil);
        Logger.info('WindowUtil registered via AppStorage.setOrCreate');
      }).catch((err: Error) => {
        Logger.error('Failed to get main window: ' + err.message);
      });
    } catch (err) {
      Logger.error('Window setup error: ' + JSON.stringify(err));
    }

    windowStage.loadContent(this.pageUrl, (err) => {
      if (err.code) {
        Logger.error('Failed to load content. Cause: ' + JSON.stringify(err));
        return;
      }
      Logger.info('Succeeded in loading content: ' + this.pageUrl);
    });
  }

  onWindowStageDestroy(): void {
    // 释放 WindowUtil 监听
    try {
      const windowUtil = AppStorage.get<WindowUtil>(WINDOW_UTIL_KEY);
      if (windowUtil) {
        windowUtil.release();
      }
    } catch (e) {
      Logger.warn('Failed to release WindowUtil: ' + JSON.stringify(e));
    }
    Logger.info('Ability onWindowStageDestroy');
  }

  onForeground(): void {
    Logger.info('Ability onForeground');
  }

  onBackground(): void {
    Logger.info('Ability onBackground');
  }
}
