/**
 * API版本兼容性工具类
 * 用于检查设备API版本并提供降级方案
 * 目标SDK: 6.1.0(23), 兼容: 5.0.5(17)
 *
 * 实现方式：使用 deviceInfo.sdkApiVersion 读取设备真实 API 版本号
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo } from '@kit.BasicServicesKit';

const DOMAIN: number = 0x0001;

/**
 * API兼容性管理器
 *
 * 设计说明：
 * - 使用 deviceInfo.sdkApiVersion 读取设备真实 API 版本号
 * - 缓存检测结果，避免重复调用
 */
export class ApiCompat {
  private static readonly TARGET_API: number = 23;  // HarmonyOS 6.1.0
  private static readonly MIN_API: number = 17;     // HarmonyOS 5.0.5
  private static cachedApiVersion: number = -1;

  /**
   * 获取设备 API 版本号（带缓存）
   * @returns {number} SDK API 版本号
   */
  static getApiVersion(): number {
    if (ApiCompat.cachedApiVersion < 0) {
      try {
        ApiCompat.cachedApiVersion = deviceInfo.sdkApiVersion ?? 0;
        hilog.info(DOMAIN, 'ApiCompat', 'Device API version: %{public}d', ApiCompat.cachedApiVersion);
      } catch (error) {
        hilog.error(DOMAIN, 'ApiCompat', 'Failed to read API version: %{public}s',
          error instanceof Error ? error.message : String(error));
        ApiCompat.cachedApiVersion = 0;
      }
    }
    return ApiCompat.cachedApiVersion;
  }

  /**
   * 检查是否为API 23+ (HarmonyOS 6.1.0+)
   * @returns {boolean} 是否为API 23+
   */
  static isApi23OrHigher(): boolean {
    return ApiCompat.getApiVersion() >= 23;
  }

  /**
   * 检查是否为API 17+ (HarmonyOS 5.0.5+)
   * @returns {boolean} 是否为API 17+
   */
  static isApi17OrHigher(): boolean {
    return ApiCompat.getApiVersion() >= 17;
  }

  /**
   * 安全调用API 23+特性
   * 如果设备支持API 23+，则调用新特性实现；否则调用降级实现
   *
   * @param {Function} api23Impl - API 23+的实现
   * @param {Function} fallbackImpl - 降级实现
   * @param {string} featureName - 特性名称（用于日志）
   */
  static safeCall(
    api23Impl: () => void,
    fallbackImpl: () => void,
    featureName: string = 'Unknown'
  ): void {
    try {
      if (ApiCompat.isApi23OrHigher()) {
        hilog.info(DOMAIN, 'ApiCompat', 'Using API 23+ implementation for: %{public}s', featureName);
        api23Impl();
      } else {
        hilog.warn(DOMAIN, 'ApiCompat', 'Using fallback for: %{public}s', featureName);
        fallbackImpl();
      }
    } catch (error) {
      hilog.error(DOMAIN, 'ApiCompat', 'Error in safeCall for %{public}s: %{public}s',
        featureName, error instanceof Error ? error.message : String(error));
      // 发生错误时尝试降级
      try {
        fallbackImpl();
      } catch (fallbackError) {
        hilog.error(DOMAIN, 'ApiCompat', 'Fallback also failed for %{public}s: %{public}s',
          featureName, fallbackError instanceof Error ? fallbackError.message : String(fallbackError));
      }
    }
  }

  /**
   * 安全调用可能返回Promise的API 23+特性
   *
   * @param {Function} api23Impl - API 23+的实现（可能返回Promise）
   * @param {Function} fallbackImpl - 降级实现（可能返回Promise）
   * @param {string} featureName - 特性名称（用于日志）
   * @returns {Promise<void>}
   */
  static async safeCallAsync(
    api23Impl: () => Promise<void> | void,
    fallbackImpl: () => Promise<void> | void,
    featureName: string = 'Unknown'
  ): Promise<void> {
    try {
      if (ApiCompat.isApi23OrHigher()) {
        hilog.info(DOMAIN, 'ApiCompat', 'Using API 23+ implementation for: %{public}s', featureName);
        await api23Impl();
      } else {
        hilog.warn(DOMAIN, 'ApiCompat', 'Using fallback for: %{public}s', featureName);
        await fallbackImpl();
      }
    } catch (error) {
      hilog.error(DOMAIN, 'ApiCompat', 'Error in safeCallAsync for %{public}s: %{public}s',
        featureName, error instanceof Error ? error.message : String(error));
      // 发生错误时尝试降级
      try {
        await fallbackImpl();
      } catch (fallbackError) {
        hilog.error(DOMAIN, 'ApiCompat', 'Fallback also failed for %{public}s: %{public}s',
          featureName, fallbackError instanceof Error ? fallbackError.message : String(fallbackError));
      }
    }
  }

  /**
   * 获取API版本描述信息（用于日志/UI显示）
   * @returns {string} API版本描述
   */
  static getApiVersionInfo(): string {
    const version = ApiCompat.getApiVersion();
    if (version >= 23) {
      return `API ${version} (HarmonyOS 6.1.0+)`;
    } else if (version >= 17) {
      return `API ${version} (HarmonyOS 5.0.5+)`;
    } else if (version > 0) {
      return `API ${version}`;
    }
    return 'Unknown API version';
  }
}
