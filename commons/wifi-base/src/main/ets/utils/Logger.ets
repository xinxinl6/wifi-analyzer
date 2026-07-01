/**
 * WiFi分析仪 — 日志封装（v2 单例模式）
 * 参照 MultiFinancialManagement 的 export default new Logger() 模式
 * 统一 hilog 输出，支持脱敏处理
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'WiFiAnalyzer';

class Logger {
  private domain: number;
  private prefix: string;
  private format: string = '%{public}s';

  constructor(prefix: string) {
    this.prefix = prefix;
    this.domain = DOMAIN;
  }

  debug(msg: string): void {
    hilog.debug(this.domain, this.prefix, this.format, msg);
  }

  info(msg: string): void {
    hilog.info(this.domain, this.prefix, this.format, msg);
  }

  warn(msg: string): void {
    hilog.warn(this.domain, this.prefix, this.format, msg);
  }

  error(msg: string): void {
    hilog.error(this.domain, this.prefix, this.format, msg);
  }

  /**
   * 脱敏日志 — 对敏感信息（如IP地址）进行脱敏处理
   */
  safeLog(category: string, message: string): void {
    const sanitized = message.replace(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/g, '***.***.***.***');
    hilog.info(this.domain, this.prefix, '[%{public}s] %{public}s', category, sanitized);
  }
}

export default new Logger('[WiFiAnalyzer]');
