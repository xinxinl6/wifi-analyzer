// 运行时权限管理工具
// user_grant 类型的权限（LOCATION、APPROXIMATELY_LOCATION）
// 必须在运行时通过 API 弹窗请求用户授权

import { abilityAccessCtrl, common, Permissions, Want } from '@kit.AbilityKit'
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

  // 静态版本：仅检查所有权限状态，不弹窗（供 onPageShow 使用）
  static async checkPermissionsSilently(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager: abilityAccessCtrl.AtManager = PermissionManager.getAtManagerStatic()
      const tokenId: number = context.applicationInfo.accessTokenId
      for (let i = 0; i < REQUIRED_PERMISSIONS.length; i++) {
        const perm: string = REQUIRED_PERMISSIONS[i] as string
        const status: number = await atManager.checkAccessToken(tokenId, REQUIRED_PERMISSIONS[i] as Permissions)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] SilentCheck ' + perm + ' = ' + status + ' (0=OK, -1=NO)')
        if (status !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] ❌ DENIED: ' + perm + ' status=' + status)
          return false
        }
      }
      return true
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Silent check error: ' + JSON.stringify(e))
      return false
    }
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
      await atManager.requestPermissionsFromUser(
        context,
        REQUIRED_PERMISSIONS as Permissions[]
      )

      // 弹窗后重新静默检查实际权限状态（比依赖 result.authResults 更可靠，避免"仅使用期间允许"误判）
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Re-checking permissions after user interaction...')
      return await PermissionManager.checkPermissionsSilently(context)
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
  // 华为审核要求：必须能正确跳转到权限设置，让用户可授权位置信息
  //
  // ⚠️ 关键经验：startAbility 对无效 URI 不会抛异常！
  //    它会"成功"打开一个空白页面。所以不能用 try-catch 判断是否真正成功。
  //    策略：把最稳定、最不容易白屏的方案放前面。
  static async openAppSettings(context: common.UIAbilityContext): Promise<boolean> {
    try {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Opening app settings...')
      const bundleName: string = context.abilityInfo.bundleName
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] bundleName:' + JSON.stringify(bundleName))

      // ════════════════════════════════════════
      // ① 应用详情页（最稳定）
      //    用户可在详情页中找到"权限"入口
      //    uri: application_info_entry 在各版本华为设备上表现最一致
      // ════════════════════════════════════════
      let want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          pushParams: bundleName
        }
      }

      try {
        await context.startAbility(want)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] ✅ Method1 (application_info_entry) accepted')
        return true
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Method1 (application_info_entry) rejected:' + JSON.stringify(e))
      }

      // ════════════════════════════════════════
      // ② 华为设置主页（无 URI，100% 能打开）
      //    用户手动导航到 应用 → 权限
      // ════════════════════════════════════════
      try {
        want = {
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility'
        }
        await context.startAbility(want)
        hilog.info(DOMAIN, 'testTag', '%{public)s', '[PermissionManager] ✅ Method2 (settings main) accepted')
        return true
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', '%{public)s', '[PermissionManager] Method2 (settings main) rejected:' + JSON.stringify(e))
      }

      // ════════════════════════════════════════
      // ③ 权限管理页（⚠️ 某些系统版本可能白屏！）
      //    仅当前面两种都失败时才尝试
      // ════════════════════════════════════════
      try {
        want = {
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          uri: 'permission_manager_apps',
          parameters: {
            pushParams: bundleName
          }
        }
        await context.startAbility(want)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] ✅ Method3 (permission_manager_apps) accepted')
        return true
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Method3 (permission_manager_apps) rejected:' + JSON.stringify(e))
      }

      // ════════════════════════════════════════
      // ④ OpenHarmony 兼容（模拟器 / 纯 OHOS 设备）
      // ════════════════════════════════════════
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
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] ✅ Method4 (OH app info) accepted')
        return true
      } catch (e) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Method4 (OH app info) rejected:' + JSON.stringify(e))
      }

      // ════════════════════════════════════════
      // ⑤ 隐式 Want（最终兜底）
      // ════════════════════════════════════════
      try {
        want = {
          action: 'action.settings'
        }
        await context.startAbility(want)
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] ✅ Method5 (implicit) accepted')
        return true
      } catch (e) {
        hilog.error(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] ❌ ALL methods failed, last error:' + JSON.stringify(e))
        return false
      }

    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PermissionManager] Fatal error in openAppSettings:' + JSON.stringify(e))
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
