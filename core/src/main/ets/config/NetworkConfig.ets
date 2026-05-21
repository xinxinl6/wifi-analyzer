// 网络配置常量 - 集中管理所有硬编码的网络配置值
// 便于维护和国际化配置

import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

/**
 * 公网IP查询API配置
 * 支持多个备选服务，避免单点故障
 * 注意：使用国内可访问的API服务
 */
export class PublicIpConfig {
  // 主API - IPIP.NET（国内服务，速度快、可靠）
  static readonly PRIMARY_API: string = 'https://myip.ipip.net'

  // 备选API - 傲宇科技
  static readonly FALLBACK_API: string = 'https://ip.3322.net'

  // 第三备选 - 搜狐
  static readonly THIRD_API: string = 'https://pv.sohu.com/ipimsg'

  // 请求超时时间（毫秒）
  static readonly TIMEOUT_MS: number = 5000

  // 重试次数
  static readonly MAX_RETRIES: number = 2
}

/**
 * DNS预设配置项
 */
interface DnsPresetItem {
  name: string
  server: string
}

/**
 * DNS服务器配置
 */
export class DnsConfig {
  // 默认DNS（广东电信 - 作为备选值）
  static readonly DEFAULT_DNS: string = '202.96.128.86'

  // 阿里DNS
  static readonly ALI_DNS: string = '223.5.5.5'

  // 腾讯DNS
  static readonly TENCENT_DNS: string = '119.29.29.29'

  // 114 DNS
  static readonly DNS_114: string = '114.114.114.114'

  // Google DNS
  static readonly GOOGLE_DNS: string = '8.8.8.8'

  /**
   * 获取预设DNS服务器列表
   */
  static getPresetList(): DnsPresetItem[] {
    return [
      { name: '系统默认', server: 'auto' },
      { name: '阿里DNS', server: DnsConfig.ALI_DNS },
      { name: '腾讯DNS', server: DnsConfig.TENCENT_DNS },
      { name: '114DNS', server: DnsConfig.DNS_114 },
      { name: 'Google DNS', server: DnsConfig.GOOGLE_DNS }
    ]
  }
}

/**
 * 网络诊断默认值配置
 */
export class DiagnosticsConfig {
  // 默认网关（仅作备选，实际应从系统获取）
  static readonly DEFAULT_GATEWAY: string = '192.168.1.1'

  // 加载中占位符
  static readonly LOADING_PLACEHOLDER: string = '获取中...'

  // 无法获取时的占位符
  static readonly UNAVAILABLE_PLACEHOLDER: string = '--'
}

/**
 * 端口配置项
 */
interface PortItem {
  name: string
  port: number
}

/**
 * 扫描预设方案项
 */
interface PresetItem {
  name: string
  ports: number[]
}

/**
 * 端口扫描配置
 */
export class PortScanConfig {
  // 常用端口列表（按服务分类）
  static readonly COMMON_PORTS: PortItem[] = [
    { name: 'HTTP', port: 80 },
    { name: 'HTTPS', port: 443 },
    { name: 'SSH', port: 22 },
    { name: 'FTP', port: 21 },
    { name: 'SMTP', port: 25 },
    { name: 'DNS', port: 53 },
    { name: 'MySQL', port: 3306 },
    { name: 'RDP', port: 3389 },
    { name: 'Redis', port: 6379 },
    { name: 'MongoDB', port: 27017 }
  ]

  // 扫描预设方案
  static readonly PRESETS: PresetItem[] = [
    {
      name: '常用端口',
      ports: [21, 22, 23, 25, 53, 80, 110, 143, 443, 465, 587, 993, 995, 3306, 3389, 5432, 6379, 8080, 8443, 27017]
    },
    {
      name: 'Web服务',
      ports: [80, 443, 800, 808, 844, 888, 8888, 3000, 4000, 5000, 7000, 8000, 8080, 8443, 9000]
    },
    {
      name: '数据库',
      ports: [1433, 1521, 3306, 5432, 6379, 27017, 27018, 9042, 5433, 5555]
    },
    {
      name: '快速扫描',
      ports: [21, 22, 80, 443, 3389, 8080]
    }
  ]

  // 端口探测超时（毫秒）
  static readonly PORT_TIMEOUT_MS: number = 2000

  // 每次并发探测数量
  static readonly CONCURRENCY: number = 50
}

/**
 * 输入验证正则表达式
 */
export class ValidationPatterns {
  // IPv4 地址格式
  static readonly IPV4: RegExp = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/

  // IPv6 地址格式（简化版）
  static readonly IPV6: RegExp = /^(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::1$|^::$/

  // 域名格式
  static readonly DOMAIN: RegExp = /^(?:(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z]{2,})$/

  // MAC 地址格式（标准格式 xx:xx:xx:xx:xx:xx 或 xx-xx-xx-xx-xx-xx）
  static readonly MAC: RegExp = /^(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/

  // IP地址或域名（通用）
  static readonly IP_OR_DOMAIN: RegExp = /^(?:(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)|(?:(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z]{2,}))$/

  // 端口号范围
  static readonly PORT: RegExp = /^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/

  /**
   * 验证IPv4地址
   */
  static isValidIpv4(ip: string): boolean {
    return ValidationPatterns.IPV4.test(ip)
  }

  /**
   * 验证域名
   */
  static isValidDomain(domain: string): boolean {
    return ValidationPatterns.DOMAIN.test(domain)
  }

  /**
   * 验证IP或域名
   */
  static isValidIpOrDomain(input: string): boolean {
    return ValidationPatterns.IP_OR_DOMAIN.test(input)
  }

  /**
   * 验证端口号
   */
  static isValidPort(port: number): boolean {
    return ValidationPatterns.PORT.test(String(port)) && port >= 1 && port <= 65535
  }

  /**
   * 验证MAC地址
   */
  static isValidMac(mac: string): boolean {
    return ValidationPatterns.MAC.test(mac)
  }

  /**
   * 检查是否为内网IP（不可公网访问的IP）
   * 包含：10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8
   */
  static isPrivateIp(ip: string): boolean {
    if (!ValidationPatterns.IPV4.test(ip)) return false

    const parts: number[] = ip.split('.').map(Number)
    const first: number = parts[0]
    const second: number = parts[1]

    // 10.0.0.0 - 10.255.255.255
    if (first === 10) return true

    // 172.16.0.0 - 172.31.255.255
    if (first === 172 && second >= 16 && second <= 31) return true

    // 192.168.0.0 - 192.168.255.255
    if (first === 192 && second === 168) return true

    // 127.0.0.0 - 127.255.255.255 (loopback)
    if (first === 127) return true

    return false
  }
}

/**
 * 输出日志级别
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  NONE = 4
}

/**
 * 日志配置
 */
export class LoggerConfig {
  // 当前日志级别（发布时设置为 INFO，开发调试可改为 DEBUG）
  static level: LogLevel = LogLevel.INFO

  // 是否启用控制台输出
  static enableConsole: boolean = true

  /**
   * 输出日志
   */
  static log(level: LogLevel, tag: string, message: string, ...args: Object[]): void {
    if (level < LoggerConfig.level || !LoggerConfig.enableConsole) return

    const prefix: string = `[${tag}]`
    const fullMessage: string = args.length > 0 ? `${message} ${JSON.stringify(args)}` : message

    switch (level) {
      case LogLevel.DEBUG:
        hilog.debug(DOMAIN, 'testTag', '%{public}s', `${prefix} ${fullMessage}`)
        break
      case LogLevel.INFO:
        hilog.info(DOMAIN, 'testTag', '%{public}s', `${prefix} ${fullMessage}`)
        break
      case LogLevel.WARN:
        hilog.warn(DOMAIN, 'testTag', '%{public}s', `${prefix} ${fullMessage}`)
        break
      case LogLevel.ERROR:
        hilog.error(DOMAIN, 'testTag', '%{public}s', `${prefix} ${fullMessage}`)
        break
    }
  }

  static debug(tag: string, message: string, ...args: Object[]): void {
    LoggerConfig.log(LogLevel.DEBUG, tag, message, ...args)
  }

  static info(tag: string, message: string, ...args: Object[]): void {
    LoggerConfig.log(LogLevel.INFO, tag, message, ...args)
  }

  static warn(tag: string, message: string, ...args: Object[]): void {
    LoggerConfig.log(LogLevel.WARN, tag, message, ...args)
  }

  static error(tag: string, message: string, ...args: Object[]): void {
    LoggerConfig.log(LogLevel.ERROR, tag, message, ...args)
  }
}
