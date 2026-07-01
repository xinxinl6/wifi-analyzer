/**
 * 更新检测服务
 * 从官网 API 获取最新版本信息，与本地版本对比
 *
 * API: https://www.xinnxin.cn/api/version.json
 */
import { http } from '@kit.NetworkKit'
import { bundleManager } from '@kit.AbilityKit'

const VERSION_URL = 'https://www.xinnxin.cn/api/version.json'

/** 远端版本信息 */
export interface RemoteVersion {
  name: string
  version: string
  versionCode: number
  forceUpdate: boolean
  downloadUrl: string
  changelog: string[]
  size: string
}

/** 检查结果 */
export interface UpdateResult {
  hasUpdate: boolean
  forceUpdate: boolean
  currentVersion: string
  remoteInfo: RemoteVersion | null
  errorMsg: string
}

/**
 * 执行更新检查
 */
export async function checkUpdate(): Promise<UpdateResult> {
  try {
    const bundleInfo = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT
    )
    const currentCode: number = bundleInfo.versionCode
    const currentName: string = bundleInfo.versionName

    const remoteInfo = await fetchLatestVersion()

    if (!remoteInfo) {
      return {
        hasUpdate: false,
        forceUpdate: false,
        currentVersion: currentName,
        remoteInfo: null,
        errorMsg: 'Cannot connect to server, please check network'
      }
    }

    const hasUpdate = remoteInfo.versionCode > currentCode

    return {
      hasUpdate,
      forceUpdate: remoteInfo.forceUpdate,
      currentVersion: currentName,
      remoteInfo,
      errorMsg: ''
    }
  } catch (_err) {
    return {
      hasUpdate: false,
      forceUpdate: false,
      currentVersion: '0.0.0',
      remoteInfo: null,
      errorMsg: 'An error occurred while checking for updates'
    }
  }
}

async function fetchLatestVersion(): Promise<RemoteVersion | null> {
  return new Promise<RemoteVersion | null>((resolve) => {
    const httpReq = http.createHttp()
    httpReq.request(
      VERSION_URL,
      {
        method: http.RequestMethod.GET,
        header: { 'Content-Type': 'application/json' },
        connectTimeout: 8000,
        readTimeout: 8000,
      },
      (_err, data) => {
        try {
          const result = typeof data.result === 'string'
            ? JSON.parse(data.result as string) as RemoteVersion
            : data.result as RemoteVersion
          resolve(result)
        } catch (_parseErr) {
          resolve(null)
        }
      }
    )
  })
}
