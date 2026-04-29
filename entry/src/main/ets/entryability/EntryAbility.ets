import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
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
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 将 UIAbilityContext 存入 AppStorage，供 Page 组件使用
    AppStorage.set('abilityContext', this.context);
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

        // 非全屏模式：系统自动为内容区预留状态栏空间，避免内容重叠
        mainWindow.setWindowLayoutFullScreen(false);

        // 设置系统栏属性（状态栏）
        mainWindow.setWindowSystemBarProperties({
          statusBarContentColor: '0xFFFFFF',
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
    // 在子页面中时返回上一页，否则隐藏到后台
    if (RouterManager.isInSubPage()) {
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'NavPathStack pop (size=%d)', RouterManager.getStackSize());
      RouterManager.goBack();
      return true; // 已处理，不退出
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'In home page, terminate self');
    // 在主页时，隐藏应用而不是退出
    this.context.terminateSelf();
    return true; // 已处理返回事件
  }
}
