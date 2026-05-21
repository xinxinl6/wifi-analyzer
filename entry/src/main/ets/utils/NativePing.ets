// Native Ping 封装层 — 调用 C++ NAPI 接口执行 ICMP 探测
// 基于 OH_NetConn_QueryProbeResult，需要 API 20+ (HarmonyOS 6.0+)

import { BusinessError } from '@kit.BasicServicesKit'

// Native .so 库（CMake 编译产物）
import pingnative from 'libpingnative.so'

// ==================== 类型定义 ====================

export interface NativeProbeResult {
  minRtt: number       // 最小RTT (微秒)，-1 表示失败
  maxRtt: number       // 最大RTT (微秒)
  avgRtt: number       // 平均RTT (微秒)
  stdRtt: number       // 标准差 (微秒)
  lossRate: number     // 丢包率 (%)
  error: number        // 错误码，0=成功
}

// Ping 模式枚举
export enum PingMode {
  FAST = 'fast',       // 快速模式：duration=1s，每秒刷新
  ACCURATE = 'accurate' // 准确模式：duration=3s，数据更精确
}

// ==================== 工具函数 ====================

/**
 * 微秒 → 毫秒转换（四舍五入）
 * @param us 微秒值
 * @return 毫秒值，-1 输入返回 -1
 */
export function usToMs(us: number): number {
  if (us < 0) return -1
  return Math.round(us / 1000)
}

/**
 * 根据 PingMode 获取 duration 秒数
 */
export function getDuration(mode: PingMode): number {
  return mode === PingMode.FAST ? 1 : 3
}

// ==================== NativePing 类 ====================

export class NativePing {
  private static supported: boolean | null = null

  /**
   * 检测当前系统是否支持 Native Ping (API >= 20)
   * 通过 try-catch 加载 libpingnative.so 来判断
   */
  static isSupported(): boolean {
    if (NativePing.supported !== null) {
      return NativePing.supported
    }
    try {
      // 尝试访问 native 模块来验证可用性
      if (typeof pingnative !== 'undefined' && pingnative.nativeProbe) {
        NativePing.supported = true
        return true
      }
      NativePing.supported = false
      return false
    } catch (e) {
      NativePing.supported = false
      return false
    }
  }

  /**
   * 执行单次 ICMP 探测
   *
   * @param address 目标 IP 或域名（必须是已解析的 IP 地址）
   * @param mode 探测模式（快速/准确）
   * @returns Promise<NativeProbeResult> 探测结果
   *
   * @example
   * ```typescript
   * const result = await NativePing.probe('114.114.114.114', PingMode.FAST)
   * console.log(`延迟 ${usToMs(result.minRtt)}ms, 丢包 ${result.lossRate}%`)
   * ```
   */
  static async probe(address: string, mode: PingMode = PingMode.FAST):
    Promise<NativeProbeResult> {
    const duration = getDuration(mode)

    return new Promise<NativeProbeResult>((resolve, reject) => {
      try {
        pingnative.nativeProbe(address, duration)
          .then((resultStr: string) => {
            const parsed: NativeProbeResult = JSON.parse(resultStr)
            resolve(parsed)
          })
          .catch((err: BusinessError) => {
            reject(new Error(`Native probe failed: code=${err.code} msg=${err.message}`))
          })
      } catch (e) {
        reject(new Error('Failed to call native probe'))
      }
    })
  }
}
