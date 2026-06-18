/**
 * WiFi分析仪 — 日志封装
 * 统一 hilog 输出，支持脱敏处理
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'WiFiAnalyzer';

export class Logger {
  /**
   * 调试日志（仅 debug 模式输出）
   */
  static debug(msg: string): void {
    hilog.debug(DOMAIN, TAG, '%{public}s', msg);
  }

  /**
   * 信息日志
   */
  static info(msg: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', msg);
  }

  /**
   * 警告日志
   */
  static warn(msg: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', msg);
  }

  /**
   * 错误日志
   */
  static error(msg: string): void {
    hilog.error(DOMAIN, TAG, '%{public}s', msg);
  }

  /**
   * 脱敏日志 — 对敏感信息（如IP地址）进行脱敏处理
   */
  static safeLog(category: string, message: string): void {
    const sanitized = message.replace(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/g, '***.***.***.***');
    hilog.info(DOMAIN, TAG, '[%{public}s] %{public}s', category, sanitized);
  }
}
