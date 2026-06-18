/**
 * WiFi分析仪 — 权限管理
 */
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
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
  private atManager;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.atManager = abilityAccessCtrl.createAtManager();
  }

  /**
   * 获取当前应用的 access token ID
   */
  private getSelfTokenId(): number {
    try {
      return this.atManager.getSelfTokenId();
    } catch {
      return 0;
    }
  }

  /**
   * 检查所有必需权限是否已授权
   */
  checkPermissions(): PermissionStatus {
    const tokenId = this.getSelfTokenId();
    let allGranted = true;
    let anyGranted = false;

    for (const perm of REQUIRED_PERMISSIONS) {
      const result = this.atManager.checkAccessTokenSync(tokenId, perm);
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
      const tokenId = this.getSelfTokenId();
      const needRequest: Permissions[] = [];

      for (const perm of REQUIRED_PERMISSIONS) {
        const result = this.atManager.checkAccessTokenSync(tokenId, perm);
        if (result !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          needRequest.push(perm);
        }
      }

      if (needRequest.length === 0) return true;

      await this.atManager.requestPermissionsFromUser(this.context, needRequest);
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
      // 从 context 自身获取 bundleName
const bundleName: string = this.context.bundleName;
      this.context.startAbility({
        bundleName: 'com.huawei.harmonyos.settings',
        abilityName: 'com.huawei.harmonyos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          pushParams: bundleName,
        },
      }).catch(() => {
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
