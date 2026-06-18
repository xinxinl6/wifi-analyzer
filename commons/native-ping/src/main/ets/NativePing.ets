/**
 * WiFi分析仪 — Native Ping 封装层
 *
 * 此模块提供 Ping 探测的类型定义和回退方案。
 * 
 * 架构说明：
 * - commons/native-ping/: 纯 ArkTS 模块，只含类型定义 + TCP 回退
 * - products/phone/ 有 C++ 本机代码，编译后提供 libpingnative.so
 * - phone 产品中的 PhoneNativePing 使用 import 'libpingnative.so' 加载
 * - 此模块的 getProvider() 自动选择最优实现
 */

import { http } from '@kit.NetworkKit';

// ==================== 类型定义 ====================

export interface NativeProbeResult {
  minRtt: number;
  maxRtt: number;
  avgRtt: number;
  stdRtt: number;
  lossRate: number;
  error: number;
}

export enum PingMode {
  FAST = 'fast',
  ACCURATE = 'accurate',
}

export interface IPingProvider {
  probe(address: string, mode?: PingMode): Promise<NativeProbeResult>;
  isSupported(): boolean;
  isNative(): boolean;
}

// ==================== 工具函数 ====================

export function usToMs(us: number): number {
  if (us < 0) return -1;
  return Math.round(us / 1000);
}

export function getDuration(mode: PingMode): number {
  return mode === PingMode.FAST ? 1 : 3;
}

// ==================== TCP 回退 Ping ====================

class TcpFallbackPing implements IPingProvider {
  isSupported(): boolean {
    return true;
  }

  isNative(): boolean {
    return false;
  }

  async probe(address: string, mode: PingMode = PingMode.FAST): Promise<NativeProbeResult> {
    const count = mode === PingMode.FAST ? 3 : 5;
    const samples: number[] = [];
    let lossCount = 0;

    for (let i = 0; i < count; i++) {
      try {
        const t0 = Date.now();
        const httpRequest = http.createHttp();
        await httpRequest.request(`http://${address}`, {
          method: http.RequestMethod.GET,
          connectTimeout: 3000,
          readTimeout: 2000,
        });
        httpRequest.destroy();
        const elapsed = (Date.now() - t0) * 1000;
        samples.push(elapsed);
      } catch {
        lossCount++;
      }
    }

    const total = count - lossCount;
    if (total === 0) {
      return {
        minRtt: -1, maxRtt: -1, avgRtt: -1, stdRtt: -1,
        lossRate: 100, error: 1,
      };
    }

    // 手动计算统计值（不使用 spread/箭头函数，兼容 ArkTS）
    let minRtt = samples[0];
    let maxRtt = samples[0];
    let sum = 0;
    for (let i = 0; i < total; i++) {
      const v = samples[i];
      if (v < minRtt) minRtt = v;
      if (v > maxRtt) maxRtt = v;
      sum += v;
    }
    const avgRtt = sum / total;
    let sqSum = 0;
    for (let i = 0; i < total; i++) {
      sqSum += (samples[i] - avgRtt) * (samples[i] - avgRtt);
    }
    const stdRtt = Math.sqrt(sqSum / total);

    return {
      minRtt: minRtt,
      maxRtt: maxRtt,
      avgRtt: Math.round(avgRtt),
      stdRtt: Math.round(stdRtt),
      lossRate: Math.round((lossCount / count) * 100),
      error: 0,
    };
  }
}

// ==================== 统一入口 ====================

export class NativePing {
  private static provider: IPingProvider | null = null;

  static setProvider(p: IPingProvider): void {
    NativePing.provider = p;
  }

  static getProvider(): IPingProvider {
    if (NativePing.provider === null) {
      NativePing.provider = new TcpFallbackPing();
    }
    return NativePing.provider;
  }

  static isSupported(): boolean {
    return NativePing.getProvider().isSupported();
  }

  static isNative(): boolean {
    return NativePing.getProvider().isNative();
  }

  static async probe(address: string, mode: PingMode = PingMode.FAST): Promise<NativeProbeResult> {
    return NativePing.getProvider().probe(address, mode);
  }
}
