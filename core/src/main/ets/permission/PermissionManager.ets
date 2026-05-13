// 运行时权限管理工具
// user_grant 类型的权限（LOCATION、APPROXIMATELY_LOCATION）
// 必须在运行时通过 API 弹窗请求用户授权

import { abilityAccessCtrl, common, Permissions, Want } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

// 需要的权限列表 — 使用 Permissions 类型（与 module.json5 中声明的 6 个权限保持一致）
const REQUIRED_PERMISSIONS: Permissions[] = [
  'ohos.permission.GET_WIFI_INFO' as Permissions,
  'ohos.permission.LOCATION' as Permissions,
  'ohos.permission.APPROXIMATELY_LOCATION' as Permissions,
  'ohos.permission.INTERNET' as Permissions,
  'ohos.permission.GET_NETWORK_INFO' as Permissions,
]

export class PermissionManager {
  // 缓存 AtManager 实例，避免重复创建
  private static atManager: abilityAccessCtrl.AtManager | null = null
  private static instance: PermissionManager | null = null

  // 获取单例实例
  static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager()
    }
    return PermissionManager.instance
  }

  // 获取或创建 AtManager（静态版本，供 static 方法调用）
  private static getAtManagerStatic(): abilityAccessCtrl.AtManager {
    if (!PermissionManager.atManager) {
      PermissionManager.atManager = abilityAccessCtrl.createAtManager()
    }
    return PermissionManager.atManager
  }

  // 获取或创建 AtManager 单例
  private getAtManager(): abilityAccessCtrl.AtManager {
    if (!PermissionManager.atManager) {
      PermissionManager.atManager = abilityAccessCtrl.createAtManager()
    }
    return PermissionManager.atManager
  }

  // 检查并请求所有必要权限
  // 接受 UIAbilityContext 参数
  static async requestPermissions(context: common.UIAbilityContext): Promise<boolean> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Starting permission request...')
      const atManager: abilityAccessCtrl.AtManager = PermissionManager.getAtManagerStatic()

      // 获取 accessTokenId
      const tokenId: number = context.applicationInfo.accessTokenId
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] accessTokenId:' + JSON.stringify(tokenId))

      // 检查每个权限状态
      const grantStatus: number[] = []
      for (let i = 0; i < REQUIRED_PERMISSIONS.length; i++) {
        const permName: string = REQUIRED_PERMISSIONS[i] as string
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Checking permission:' + JSON.stringify(permName))
        try {
          const status: number = await atManager.checkAccessToken(tokenId, permName as Permissions)
          hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Permission status for ' + JSON.stringify(permName) + ': ' + JSON.stringify(status) + ' (0=GRANTED, -1=DENIED)')
          grantStatus.push(status)
        } catch (checkError) {
          hilog.error(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] checkAccessToken error for ' + JSON.stringify(permName) + ': ' + JSON.stringify(checkError))
          // 继续尝试其他权限
          grantStatus.push(-1)
        }
      }

      // 如果所有权限都已授权，直接返回 true
      const allGranted: boolean = grantStatus.every((s: number) =>
        s === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      )
      if (allGranted) {
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] All permissions already granted')
        return true
      }

      // 有未授权的权限，弹出授权窗口
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Permissions not granted, showing request dialog...')
      const result = await atManager.requestPermissionsFromUser(
        context,
        REQUIRED_PERMISSIONS as Permissions[]
      )

      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Permission request result:' + JSON.stringify(result))

      if (result.authResults) {
        const allOk: boolean = result.authResults.every((r: number) =>
          r === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        )
        if (allOk) {
          hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] All permissions granted by user')
          return true
        } else {
          hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Some permissions denied:' + JSON.stringify(result.authResults))
          return false
        }
      }
      return false
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Error requesting permissions:' + JSON.stringify(e))
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Error message:' + (e as Error).message)
      return false
    }
  }

  // 检查单个权限是否已授权
  async checkPermission(context: common.UIAbilityContext, permissionName: Permissions): Promise<boolean> {
    try {
      const atManager: abilityAccessCtrl.AtManager = this.getAtManager()
      const status: number = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        permissionName
      )
      const granted: boolean = status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      hilog.info(DOMAIN, 'testTag', '%{public}s', `[PermissionManager] Permission ${permissionName}: ${granted ? 'GRANTED' : 'DENIED'} (status: ${status})`)
      return granted
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Check permission error:' + JSON.stringify(e))
      return false
    }
  }

  // 检查所有必要权限的状态（返回详细状态对象）
  async checkAllPermissions(context: common.UIAbilityContext): Promise<PermissionStatus[]> {
    const results: PermissionStatus[] = []
    for (let i = 0; i < REQUIRED_PERMISSIONS.length; i++) {
      try {
        const atManager: abilityAccessCtrl.AtManager = this.getAtManager()
        const status: number = await atManager.checkAccessToken(
          context.applicationInfo.accessTokenId,
          REQUIRED_PERMISSIONS[i] as Permissions
        )
        const granted: boolean = status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        results.push({
          permission: REQUIRED_PERMISSIONS[i],
          granted: granted,
          status: status
        })
        hilog.info(DOMAIN, 'testTag', '%{public}s', `[PermissionManager] ${REQUIRED_PERMISSIONS[i]}: ${granted ? 'GRANTED' : 'DENIED'}`)
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', `[PermissionManager] Error checking ${REQUIRED_PERMISSIONS[i]}:` + JSON.stringify(e))
        results.push({
          permission: REQUIRED_PERMISSIONS[i],
          granted: false,
          status: -1
        })
      }
    }
    return results
  }

  // 跳转到应用权限设置页面
  static async openAppSettings(context: common.UIAbilityContext): Promise<boolean> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Opening app settings...')

      // 获取当前应用的 bundleName
      const bundleName: string = context.abilityInfo.bundleName
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Current app bundleName:' + JSON.stringify(bundleName))

      // 方法1：跳转到应用权限设置页面（HarmonyOS 标准方式）
      // bundleName 和 abilityName 是固定值
      // uri: 'application_info_entry' 打开应用详情页
      // parameters.pushParams 指定要打开哪个应用的设置
      let want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          pushParams: bundleName  // 指定跳转到当前应用的设置页面
        }
      }

      try {
        await context.startAbility(want)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Opened app permission settings successfully')
        return true
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] HarmonyOS settings failed:' + JSON.stringify(e))
      }

      // 方法2：尝试 OpenHarmony 通用设置应用
      try {
        want = {
          bundleName: 'com.ohos.settings',
          abilityName: 'com.ohos.settings.MainAbility',
          uri: 'application_info_entry',
          parameters: {
            pushParams: bundleName
          }
        }
        await context.startAbility(want)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Opened via OpenHarmony settings')
        return true
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] OpenHarmony settings failed:' + JSON.stringify(e))
      }

      // 方法3：打开系统设置主页（让用户手动找到应用）
      try {
        want = {
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility'
        }
        await context.startAbility(want)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Opened settings main page')
        return true
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Settings main page failed:' + JSON.stringify(e))
      }

      // 方法4：尝试隐式 Want
      try {
        want = {
          action: 'action.settings'
        }
        await context.startAbility(want)
        return true
      } catch (e) {
        hilog.error(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] All methods failed:' + JSON.stringify(e))
        return false
      }

    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Fatal error:' + JSON.stringify(e))
      return false
    }
  }

  // 退出应用
  static terminateApp(context: common.UIAbilityContext): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Terminating app...')
    context.terminateSelf()
  }

}

// 权限状态接口 - 定义在类外部（ArkTS 不允许类内部接口定义）
export interface PermissionStatus {
  permission: Permissions
  granted: boolean
  status: number
}
