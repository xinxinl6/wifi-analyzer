import { AbilityConstant, ConfigurationConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { RouterManager } from '@wifi-analyzer/core';

const DOMAIN = 0x0000;

export default class TabletAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', 'Failed to set colorMode. Cause: ' + JSON.stringify(err));
    }
    const colorMode = this.context.config?.colorMode;
    const isDark = (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    AppStorage.setOrCreate('isDarkMode', isDark);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate, isDarkMode=' + isDark);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    const isDark = (newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    AppStorage.setOrCreate('isDarkMode', isDark);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'onConfigurationUpdate: isDarkMode=' + isDark);
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
            hilog.warn(DOMAIN, 'testTag', '%{public}s', 'updateStatusBarColor warning: ' + err.message);
          });
        }).catch((err: Error) => {
          hilog.error(DOMAIN, 'testTag', '%{public}s', 'Failed to get main window: ' + err.message);
        });
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', 'updateStatusBarColor error: ' + JSON.stringify(err));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    AppStorage.set('abilityContext', this.context);
    AppStorage.set('windowStage', windowStage);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Context stored in AppStorage');

    try {
      windowStage.getMainWindow().then((mainWindow) => {
        mainWindow.setWindowLayoutFullScreen(true);

        const isDark = AppStorage.get<boolean>('isDarkMode') || false;
        const statusBarContentColor = isDark ? '0xFFFFFF' : '0x000000';
        mainWindow.setWindowSystemBarProperties({
          statusBarColor: '0x00000000',
          statusBarContentColor: statusBarContentColor,
          navigationBarColor: '0x00000000',
          navigationBarContentColor: '0x00000000',
        }).catch((err: Error) => {
          hilog.warn(DOMAIN, 'testTag', '%{public}s', 'setWindowSystemBarProperties warning: ' + err.message);
        });

        try {
          mainWindow.setSpecificSystemBarEnabled('navigationIndicator', false);
        } catch (e) {
          hilog.warn(DOMAIN, 'testTag', '%{public}s', 'setSpecificSystemBarEnabled not supported: ' + JSON.stringify(e));
        }

        mainWindow.on('windowSizeChange', (size: window.Size) => {
          hilog.info(DOMAIN, 'testTag', '%{public}s', 'Window size changed: ' + JSON.stringify(size));
          AppStorage.set('windowWidth', size.width);
          AppStorage.set('windowHeight', size.height);
        });
      }).catch((err: Error) => {
        hilog.error(DOMAIN, 'testTag', '%{public}s', 'Failed to get main window: ' + err.message);
      });
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', 'Window setup error: ' + JSON.stringify(err));
    }

    windowStage.loadContent('pages/Launcher', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', '%{public}s', 'Failed to load the content. Cause: ' + JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  onBackPressed(): boolean {
    if (RouterManager.isInSubPage()) {
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'In sub page, goBack()');
      RouterManager.goBack();
      return true;
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'In home page, let system handle');
    return false;
  }
}
