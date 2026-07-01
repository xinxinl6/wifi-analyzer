import { GlobalInfoModel } from 'wifi-base';
import { MainView } from './MainView';
import { RouterManager, PermissionManager } from '@wifi-analyzer/core';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PingPageBuilder } from '../components/PingPage';
import { DnsPageBuilder } from '../components/DnsPage';
import { TraceroutePageBuilder } from '../components/TraceroutePage';
import { PortScanPageBuilder } from '../components/PortScanPage';
import { SubnetPageBuilder } from '../components/SubnetPage';
import { IpGeoPageBuilder } from '../components/IpGeoPage';
import { PoePageBuilder } from '../components/PoePage';
import { LanScanPageBuilder } from '../components/LanScanPage';
import { SettingsPageBuilder } from '../components/SettingsPage';
import { SpeedTestPageBuilder } from '../components/SpeedTestPage';

@Entry
@Component
struct Index {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string) {
    if (name === 'PingPage') {
      PingPageBuilder()
    } else if (name === 'DnsPage') {
      DnsPageBuilder()
    } else if (name === 'TraceroutePage') {
      TraceroutePageBuilder()
    } else if (name === 'PortScanPage') {
      PortScanPageBuilder()
    } else if (name === 'SubnetPage') {
      SubnetPageBuilder()
    } else if (name === 'IpGeoPage') {
      IpGeoPageBuilder()
    } else if (name === 'PoePage') {
      PoePageBuilder()
    } else if (name === 'LanScanPage') {
      LanScanPageBuilder()
    } else if (name === 'SettingsPage') {
      SettingsPageBuilder()
    } else if (name === 'SpeedTestPage') {
      SpeedTestPageBuilder()
    }
  }

  aboutToAppear(): void {
    AppStorage.setOrCreate<boolean>('isDarkMode', false);
    GlobalInfoModel.getInstance().isDarkMode = false;
    RouterManager.createStack(this.pageStack)

    // 申请定位等运行时权限
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
      PermissionManager.requestPermissions(ctx)
    } catch (e) {
      hilog.warn(0x0000, 'WiFiAnalyzer', '权限申请失败（冷启动时正常）: ' + JSON.stringify(e))
    }
  }

  build() {
    Navigation(this.pageStack) {
      MainView()
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .hideBackButton(false)
    .title('')
    .navDestination(this.PageMap)
  }
}
