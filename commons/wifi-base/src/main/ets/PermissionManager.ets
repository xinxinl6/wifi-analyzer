/**
 * WiFi分析仪 — 权限管理
 */
import { abilityAccessCtrl, AbilityConstant, common, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

/** 所需权限列表（精确位置默认不请求） */
const REQUIRED_PERMISSIONS: Permissions[] = [
  'ohos.permission.GET_WIFI_INFO',
  'ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.INTERNET',
  'ohos.permission.GET_NETWORK_INFO',
];

export enum PermissionStatus {
  GRANTED = 'granted',
  DENIED = 'denied',
  PARTIAL = 'partial',
}

export class PermissionManager {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 检查所有必需权限是否已授权
   */
  checkPermissions(): PermissionStatus {
    const atManager = abilityAccessCtrl.createAtManager();
    let allGranted = true;
    let anyGranted = false;

    for (const perm of REQUIRED_PERMISSIONS) {
      const result = atManager.checkAccessTokenSync(this.context.token, perm);
      if (result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        anyGranted = true;
      } else {
        allGranted = false;
      }
    }

    if (allGranted) return PermissionStatus.GRANTED;
    if (anyGranted) return PermissionStatus.PARTIAL;
    return PermissionStatus.DENIED;
  }

  /**
   * 请求所有必需权限
   */
  async requestPermissions(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const needRequest: Permissions[] = [];

      for (const perm of REQUIRED_PERMISSIONS) {
        const result = atManager.checkAccessTokenSync(this.context.token, perm);
        if (result !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          needRequest.push(perm);
        }
      }

      if (needRequest.length === 0) return true;

      await atManager.requestPermissionsFromUser(this.context, needRequest);
      return this.checkPermissions() === PermissionStatus.GRANTED;
    } catch (err) {
      hilog.error(DOMAIN, 'WiFiAnalyzer', '权限请求失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 打开应用权限设置页面
   */
  openAppSettings(): void {
    try {
      const bundleName = this.context.applicationInfo.bundleName;
      this.context.startAbility({
        bundleName: 'com.huawei.harmonyos.settings',
        abilityName: 'com.huawei.harmonyos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          pushParams: bundleName,
        },
      }).catch(() => {
        // fallback: 通用设置入口
        this.context.startAbility({
          bundleName: 'com.huawei.harmonyos.settings',
          abilityName: 'com.huawei.harmonyos.settings.MainAbility',
        }).catch(() => {
          hilog.warn(DOMAIN, 'WiFiAnalyzer', '无法打开设置页面');
        });
      });
    } catch (err) {
      hilog.error(DOMAIN, 'WiFiAnalyzer', 'openAppSettings 失败: %{public}s', JSON.stringify(err));
    }
  }
}
