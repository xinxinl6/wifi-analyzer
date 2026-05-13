import { AbilityConstant, ConfigurationConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { RouterManager } from '@wifi-analyzer/core';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    // 初始化 isDarkMode 到 AppStorage
    const colorMode = this.context.config?.colorMode
    const isDark = (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
    AppStorage.setOrCreate('isDarkMode', isDark)
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate, isDarkMode=' + isDark);
  }

  // 监听系统深色/浅色模式切换 — 必须在 UIAbility 中实现
  onConfigurationUpdate(newConfig: Configuration): void {
    const isDark = (newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
    AppStorage.setOrCreate('isDarkMode', isDark)
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'onConfigurationUpdate: isDarkMode=' + isDark)
    // 同步更新状态栏文字颜色
    this.updateStatusBarColor(isDark)
  }

  // 更新状态栏文字颜色
  private updateStatusBarColor(isDark: boolean): void {
    try {
      const statusBarColor = isDark ? '0xFFFFFF' : '0x000000'
      // 获取当前窗口并更新状态栏颜色
      const windowStage = AppStorage.get<window.WindowStage>('windowStage')
      if (windowStage) {
        windowStage.getMainWindow().then((mainWindow) => {
          mainWindow.setWindowSystemBarProperties({
            statusBarContentColor: statusBarColor,
          }).catch((err: Error) => {
            hilog.warn(DOMAIN, 'testTag', 'updateStatusBarColor warning: %{public}s', err.message);
          });
        }).catch((err: Error) => {
          hilog.error(DOMAIN, 'testTag', 'Failed to get main window: %{public}s', err.message);
        });
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'updateStatusBarColor error: %{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 将 UIAbilityContext 存入 AppStorage，供 Page 组件使用
    AppStorage.set('abilityContext', this.context);
    // 保存 windowStage 供后续更新状态栏颜色使用
    AppStorage.set('windowStage', windowStage);
    hilog.info(DOMAIN, 'testTag', 'Context stored in AppStorage');

    // 窗口配置：全屏模式 + 自定义安全区处理
    try {
      windowStage.getMainWindow().then((mainWindow) => {
        // 尝试关闭底部导航栏（针对不同 HarmonyOS 版本）
        try {
          // HarmonyOS 3.1+ 方式
          mainWindow.setWindowSystemBarEnable(['status']);
        } catch (e) {
          // 忽略版本不支持错误
          hilog.warn(DOMAIN, 'testTag', 'setWindowSystemBarEnable not supported: %{public}s', JSON.stringify(e));
        }

        // 全屏模式：允许内容画到状态栏区域
        mainWindow.setWindowLayoutFullScreen(true);

        // 根据当前颜色模式设置状态栏文字颜色
        const isDark = AppStorage.get<boolean>('isDarkMode') || false
        const statusBarColor = isDark ? '0xFFFFFF' : '0x000000'
        mainWindow.setWindowSystemBarProperties({
          statusBarContentColor: statusBarColor,
        }).catch((err: Error) => {
          hilog.warn(DOMAIN, 'testTag', 'setWindowSystemBarProperties warning: %{public}s', err.message);
        });

        // 监听窗口尺寸变化事件
        mainWindow.on('windowSizeChange', (size: window.Size) => {
          hilog.info(DOMAIN, 'testTag', 'Window size changed: %{public}s', JSON.stringify(size));
          // 存储窗口尺寸供响应式组件使用
          AppStorage.set('windowWidth', size.width);
          AppStorage.set('windowHeight', size.height);
        });
      }).catch((err: Error) => {
        hilog.error(DOMAIN, 'testTag', 'Failed to get main window: %{public}s', err.message);
      });
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Window setup error: %{public}s', JSON.stringify(err));
    }

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  onBackPressed(): boolean {
    // 在子页面中时返回上一页，否则交由系统默认处理
    if (RouterManager.isInSubPage()) {
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'In sub page, goBack()');
      RouterManager.goBack();
      return true; // 已处理，不退出
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'In home page, let system handle');
    return false; // 交由系统默认处理（隐藏到后台）
  }
}
