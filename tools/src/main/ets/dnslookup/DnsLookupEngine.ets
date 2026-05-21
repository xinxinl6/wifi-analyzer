// DNS 查询引擎
// 支持 HTTP DNS (DoH) 真实多服务器查询 + 系统 DNS 兜底 + 历史记录持久化
// 通过 HTTPS JSON 接口查询指定 DNS 服务器，支持 A/AAAA/CNAME/MX/NS/TXT 全部记录类型

import { http } from '@kit.NetworkKit'
import { connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

// ==================== 类型定义 ====================

// DNS 记录类型
export type DnsRecordType = 'A' | 'AAAA' | 'CNAME' | 'MX' | 'NS' | 'TXT'

// IP 地址族类型（用于指定解析类型）
export type IpFamily = 'IPv4' | 'IPv6' | 'All'

// 单条 DNS 记录
export interface DnsRecord {
  type: DnsRecordType
  value: string
  ttl: number
}

// DNS 查询结果
export interface DnsLookupResult {
  domain: string
  records: DnsRecord[]
  queryTime: number
  server: string
  status: 'success' | 'error'
  errorMessage: string
}

// DNS 查询配置
export interface DnsLookupConfig {
  domain: string
  dnsServer: string
  timeout: number
  /** 指定 IP 族：IPv4 / IPv6 / All（默认） */
  family?: IpFamily
  /** 指定网络类型：wifi / cellular / ''（默认网络） */
  networkType?: string
}

// DNS 服务器预设（含 DoH API 地址）
export interface DnsServerPreset {
  name: string
  address: string
  color: string
  apiUrl: string
}

// DoH 响应中的单条 Answer 条目（内部使用）
interface DoHAnswerItem {
  name: string
  type: number
  TTL: number
  data: string
}

// DoH 完整响应结构（内部使用）
interface DoHResponseStruct {
  Status: number
  Answer: DoHAnswerItem[]
}

// DNS 查询历史记录条目（持久化）
export interface DnsHistoryEntry {
  domain: string
  server: string
  timestamp: number
  recordCount: number
  queryTime: number
}

// ==================== 引擎实现 ====================

export class DnsLookupEngine {

  // ------------------ 常量 ------------------

  // DNS 记录类型 → RFC 数值映射
  private static readonly RECORD_TYPE_MAP: Record<string, number> = {
    'A': 1,
    'NS': 2,
    'CNAME': 5,
    'MX': 15,
    'TXT': 16,
    'AAAA': 28,
  }

  // RFC 数值 → 记录类型反向映射
  private static readonly TYPE_NUM_TO_RECORD: Record<number, DnsRecordType> = {
    1: 'A',
    2: 'NS',
    5: 'CNAME',
    15: 'MX',
    16: 'TXT',
    28: 'AAAA',
  }

  // 常用 DNS 服务器预设（含 DoH API）
  static readonly DNS_SERVERS: DnsServerPreset[] = [
    { name: '系统默认', address: '', color: '#0066FF', apiUrl: '' },
    { name: '阿里DNS', address: '223.5.5.5', color: '#10B981', apiUrl: 'https://dns.alidns.com/resolve' },
    { name: '腾讯DNS', address: '119.29.29.29', color: '#14B8A6', apiUrl: 'https://doh.pub/dns-query' },
    { name: '百度DNS', address: '180.76.76.76', color: '#F59E0B', apiUrl: 'https://dns.baidu.com/resolve' },
    { name: 'Google DNS', address: '8.8.8.8', color: '#8B5CF6', apiUrl: 'https://dns.google/resolve' },
    { name: 'Cloudflare', address: '1.1.1.1', color: '#EC4899', apiUrl: 'https://cloudflare-dns.com/dns-query' },
  ]

  // 常用域名
  static readonly POPULAR_DOMAINS: string[] = [
    'baidu.com',
    'taobao.com',
    'qq.com',
    'jd.com',
    'weibo.com',
    'zhihu.com',
  ]

  // ==================== 历史记录持久化 ====================

  private static readonly PREF_NAME: string = 'dns_lookup_history'
  private static readonly PREF_KEY: string = 'dns_history_list'
  private static readonly MAX_HISTORY: number = 50

  /**
   * 加载历史记录（从 DataPreferences）
   */
  static async loadHistory(context: common.Context): Promise<DnsHistoryEntry[]> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(context, DnsLookupEngine.PREF_NAME)
      const jsonStr: string | null = await pref.get(DnsLookupEngine.PREF_KEY, '[]') as string
      if (!jsonStr || jsonStr === '[]') {
        return []
      }
      const parsed: Array<Record<string, Object | string | number>> =
        JSON.parse(jsonStr) as Array<Record<string, Object | string | number>>
      const entries: DnsHistoryEntry[] = []
      for (let i = 0; i < parsed.length; i++) {
        const item: Record<string, Object | string | number> = parsed[i]
        const entry: DnsHistoryEntry = {
          domain: String(item['domain'] || ''),
          server: String(item['server'] || ''),
          timestamp: typeof item['timestamp'] === 'number' ? item['timestamp'] : 0,
          recordCount: typeof item['recordCount'] === 'number' ? item['recordCount'] : 0,
          queryTime: typeof item['queryTime'] === 'number' ? item['queryTime'] : 0,
        }
        entries.push(entry)
      }
      return entries
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupEngine] loadHistory error: ' + e)
      return []
    }
  }

  /**
   * 添加一条历史记录（写入 DataPreferences）
   */
  static async addHistoryEntry(context: common.Context, entry: DnsHistoryEntry): Promise<void> {
    try {
      // 先加载现有历史
      const existing: DnsHistoryEntry[] = await DnsLookupEngine.loadHistory(context)

      // 去重：相同域名+服务器则移除旧条目
      const filtered: DnsHistoryEntry[] = []
      for (let i = 0; i < existing.length; i++) {
        if (!(existing[i].domain === entry.domain && existing[i].server === entry.server)) {
          filtered.push(existing[i])
        }
      }

      // 插入到最前面
      filtered.unshift(entry)

      // 限制最大数量
      if (filtered.length > DnsLookupEngine.MAX_HISTORY) {
        filtered.length = DnsLookupEngine.MAX_HISTORY
      }

      // 序列化并保存（直接使用 DnsHistoryEntry 对象，避免无类型字面量）
      const saveList: DnsHistoryEntry[] = []
      for (let j = 0; j < filtered.length; j++) {
        saveList.push(filtered[j])
      }
      const jsonStr: string = JSON.stringify(saveList)
      const pref: preferences.Preferences = await preferences.getPreferences(context, DnsLookupEngine.PREF_NAME)
      await pref.put(DnsLookupEngine.PREF_KEY, jsonStr)
      await pref.flush()
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupEngine] addHistoryEntry error: ' + e)
    }
  }

  /**
   * 清空历史记录
   */
  static async clearHistory(context: common.Context): Promise<void> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(context, DnsLookupEngine.PREF_NAME)
      await pref.delete(DnsLookupEngine.PREF_KEY)
      await pref.flush()
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupEngine] clearHistory error: ' + e)
    }
  }

  /**
   * 删除单条历史记录
   */
  static async removeHistoryEntry(context: common.Context, timestamp: number): Promise<void> {
    try {
      const existing: DnsHistoryEntry[] = await DnsLookupEngine.loadHistory(context)
      const filtered: DnsHistoryEntry[] = []
      for (let i = 0; i < existing.length; i++) {
        if (existing[i].timestamp !== timestamp) {
          filtered.push(existing[i])
        }
      }
      const saveList: DnsHistoryEntry[] = []
      for (let j = 0; j < filtered.length; j++) {
        saveList.push(filtered[j])
      }
      const jsonStr: string = JSON.stringify(saveList)
      const pref: preferences.Preferences = await preferences.getPreferences(context, DnsLookupEngine.PREF_NAME)
      await pref.put(DnsLookupEngine.PREF_KEY, jsonStr)
      await pref.flush()
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupEngine] removeHistoryEntry error: ' + e)
    }
  }

  // ------------------ 公开方法 ------------------

  /**
   * 获取默认配置
   */
  static getDefaultConfig(domain: string): DnsLookupConfig {
    const config: DnsLookupConfig = {
      domain: domain,
      dnsServer: '',
      timeout: 5000,
    }
    return config
  }

  /**
   * 根据 DNS 服务器地址查找对应的 DoH API URL
   */
  static getApiUrlByServer(serverAddress: string): string {
    for (let i = 0; i < DnsLookupEngine.DNS_SERVERS.length; i++) {
      if (DnsLookupEngine.DNS_SERVERS[i].address === serverAddress) {
        return DnsLookupEngine.DNS_SERVERS[i].apiUrl
      }
    }
    return ''
  }

  /**
   * 执行 DNS 查询（主入口）
   *
   * 分流逻辑：
   * - 系统默认(空地址或无apiUrl) → 走系统 connection API（仅 A/AAAA）
   * - 有 DoH API URL → 走 HTTP DNS JSON 接口（全记录类型 + 真实指定服务器）
   */
  async lookup(config: DnsLookupConfig): Promise<DnsLookupResult> {
    const startTime: number = Date.now()
    const domain: string = config.domain.trim()

    // 1. 校验域名
    if (domain.length === 0) {
      return this.makeErrorResult(domain, '', '域名不能为空', startTime)
    }

    try {
      // 2. 中文域名转换
      let resolvedDomain: string = domain
      if (/[\u4e00-\u9fa5]/.test(domain)) {
        resolvedDomain = connection.getDnsAscii(domain)
      }

      // 3. 判断走哪种查询方式
      const apiUrl: string = DnsLookupEngine.getApiUrlByServer(config.dnsServer)

      if (apiUrl && apiUrl.length > 0) {
        // ====== HTTP DNS (DoH) 模式 ======
        return await this.lookupViaHttpDns(resolvedDomain, config, startTime, apiUrl)
      } else {
        // ====== 系统 DNS 模式（兜底）======
        return await this.lookupViaSystemDns(resolvedDomain, config, startTime)
      }
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      return this.makeErrorResult(domain, config.dnsServer || '系统默认', errorMsg, startTime)
    }
  }

  // ------------------ HTTP DNS (DoH) 实现 ------------------

  /**
   * 通过 HTTP DNS (DoH) 接口查询
   * 支持：阿里 / Google / Cloudflare 等 JSON 格式 DoH 接口
   */
  private async lookupViaHttpDns(
    domain: string,
    config: DnsLookupConfig,
    startTime: number,
    apiUrl: string
  ): Promise<DnsLookupResult> {
    try {
      // 构建请求 URL（先查全部类型，再按需筛选；或直接查指定类型）
      // 这里一次性查 A+AAAA+CNAME+MX+NS+TXT，减少请求数
      const recordTypes: DnsRecordType[] = ['A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT']
      const allRecords: DnsRecord[] = []

      // 并行查询所有记录类型（提升速度）
      const promises: Array<Promise<DnsRecord[]>> = []
      for (let i = 0; i < recordTypes.length; i++) {
        promises.push(this.querySingleRecordViaHttpDns(domain, recordTypes[i], apiUrl, config.timeout))
      }
      const results: DnsRecord[][] = await Promise.all(promises)

      for (let r = 0; r < results.length; r++) {
        const records: DnsRecord[] = results[r]
        if (records.length > 0) {
          for (let j = 0; j < records.length; j++) {
            allRecords.push(records[j])
          }
        }
      }

      // 保存历史（由调用方 DnsLookupPage 负责持久化）
      // this.addHistory 已移除，使用 DnsLookupEngine.addHistoryEntry(context, entry)

      const queryTime: number = Date.now() - startTime
      const serverName: string = this.getServerNameByAddress(config.dnsServer)

      if (allRecords.length > 0) {
        return {
          domain: config.domain,
          records: allRecords,
          queryTime: queryTime,
          server: serverName || config.dnsServer,
          status: 'success',
          errorMessage: '',
        }
      } else {
        return {
          domain: config.domain,
          records: [],
          queryTime: queryTime,
          server: serverName || config.dnsServer,
          status: 'error',
          errorMessage: '未找到DNS记录（可能域名不存在）',
        }
      }
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      return this.makeErrorResult(config.domain, config.dnsServer, 'DNS查询失败: ' + errorMsg, startTime)
    }
  }

  /**
   * 查询单种记录类型 via HTTP DNS
   */
  private async querySingleRecordViaHttpDns(
    domain: string,
    recordType: DnsRecordType,
    baseUrl: string,
    timeout: number
  ): Promise<DnsRecord[]> {
    try {
      const typeNum: number | undefined = DnsLookupEngine.RECORD_TYPE_MAP[recordType]
      if (typeNum === undefined) {
        return []
      }

      // 构建完整 URL
      let fullUrl: string = baseUrl + '?name=' + encodeURIComponent(domain) + '&type=' + String(typeNum)

      // 发送 HTTP GET 请求
      const req = http.createHttp()
      const result = await new Promise<http.HttpResponse>((resolve: (v: http.HttpResponse) => void, reject: (e: Error) => void) => {
        const timerId: number = setTimeout((): void => {
          req.destroy()
          reject(new Error('DNS查询超时'))
        }, timeout)

        // 根据不同提供商设置不同的 extra header
        const headerObj: Record<string, string> = {}

        // Cloudflare 需要 Accept 头返回 JSON
        if (baseUrl.includes('cloudflare')) {
          headerObj['Accept'] = 'application/dns-json'
        }

        req.request(fullUrl, {
          method: http.RequestMethod.GET,
          connectTimeout: timeout,
          readTimeout: timeout,
          header: headerObj,
        }, (err: BusinessError, resp: http.HttpResponse): void => {
          clearTimeout(timerId)
          req.destroy()
          if (err) {
            reject(new Error(err.message))
            return
          }
          resolve(resp)
        })
      })

      if (result.responseCode !== 200 || !result.result) {
        return []
      }

      // 解析 JSON 响应
      const responseStr: string = result.result.toString()
      return this.parseDoHJson(responseStr, recordType)
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupEngine] querySingleRecord ' + recordType + ' failed: ' + e)
      return []
    }
  }

  /**
   * 解析 DoH JSON 响应
   * 兼容 Google DNS / 阿里 DNS / Cloudflare(JSON模式) 的响应格式
   *
   * 标准格式：
   * { "Status": 0, "Answer": [ {"name": "xxx.", "type": 1, "TTL": 300, "data": "1.2.3.4"} ] }
   */
  private parseDoHJson(jsonStr: string, expectType: DnsRecordType): DnsRecord[] {
    const records: DnsRecord[] = []
    try {
      const parsed: Record<string, Object | string | number | boolean | null> =
        JSON.parse(jsonStr) as Record<string, Object | string | number | boolean | null>
      const statusVal: Object | string | number | boolean | null | undefined = parsed['Status']
      const status: number = typeof statusVal === 'number' ? statusVal : 0

      // Status 非 0 表示错误（如 NXDOMAIN = 3）
      if (status !== 0) {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupEngine] DoH status error: ' + status)
        return records
      }

      // 提取 Answer 数组
      const answerRaw: Object | string | number | boolean | null | undefined = parsed['Answer']
      if (!answerRaw || typeof answerRaw !== 'object') {
        return records
      }

      // 用类型断言后逐条处理（ArkTS 要求显式接口）
      const answers: DoHAnswerItem[] = answerRaw as DoHAnswerItem[]
      if (answers.length === 0) {
        return records
      }

      for (let i = 0; i < answers.length; i++) {
        const item: DoHAnswerItem = answers[i]
        const typeNum: number = item.type
        const recordType: DnsRecordType | undefined = DnsLookupEngine.TYPE_NUM_TO_RECORD[typeNum]

        // 只收集期望类型的记录（或者如果期望是 All 则全部收集）
        if (recordType === undefined) {
          continue
        }

        const record: DnsRecord = {
          type: recordType,
          value: item.data || '',
          ttl: item.TTL || 0,
        }
        records.push(record)
      }

      return records
    } catch (e) {
      hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupEngine] parseDoHJson error: ' + e)
      return records
    }
  }

  // ------------------ 系统 DNS 实现（兜底）------------------

  /**
   * 通过系统 connection API 查询 DNS（兜底方案，不支持指定服务器和全记录类型）
   */
  private async lookupViaSystemDns(
    domain: string,
    config: DnsLookupConfig,
    startTime: number
  ): Promise<DnsLookupResult> {
    const records: DnsRecord[] = []

    try {
      // 1. 检查网络连接
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (!netHandle || netHandle.netId === 0) {
        return this.makeErrorResult(domain, '系统默认', '无网络连接', startTime)
      }

      // 2. 使用系统 DNS 解析
      let addresses: string[] = []
      if (config.family && config.family !== 'All') {
        addresses = await this.resolveAddressesByFamily(domain, config.family, config.timeout)
      } else {
        addresses = await this.resolveAddressesAll(domain, config.timeout)
      }

      // 3. 将结果转换为 DNS 记录（只有 A 和 AAAA 两种）
      if (addresses.length > 0) {
        for (let i = 0; i < addresses.length; i++) {
          const isIPv6: boolean = addresses[i].includes(':')
          const record: DnsRecord = {
            type: isIPv6 ? 'AAAA' : 'A',
            value: addresses[i],
            ttl: 300,
          }
          records.push(record)
        }
      }

      // 4. 保存历史（由调用方 DnsLookupPage 负责持久化）
      // this.addHistory 已移除，使用 DnsLookupEngine.addHistoryEntry(context, entry)

      const queryTime: number = Date.now() - startTime
      return {
        domain: domain,
        records: records,
        queryTime: queryTime,
        server: '系统默认',
        status: records.length > 0 ? 'success' : 'error',
        errorMessage: records.length > 0 ? '' : '未找到DNS记录',
      }
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      return this.makeErrorResult(domain, '系统默认', errorMsg, startTime)
    }
  }

  /**
   * 获取所有地址（Promise 风格 API）
   * API: connection.getAddressesByName(name) → Promise<NetAddress[]>
   */
  private resolveAddressesAll(domain: string, timeout: number): Promise<string[]> {
    return new Promise<string[]>((resolve: (v: string[]) => void, reject: (e: Error) => void) => {
      const timerId: number = setTimeout((): void => {
        reject(new Error('DNS查询超时'))
      }, timeout)

      connection.getAddressesByName(domain)
        .then((addresses: Array<connection.NetAddress>): void => {
          clearTimeout(timerId)
          if (!addresses || addresses.length === 0) {
            resolve([])
            return
          }
          const results: string[] = []
          for (let i = 0; i < addresses.length; i++) {
            const addr: string | undefined = addresses[i].address
            if (addr) results.push(addr)
          }
          resolve(results)
        })
        .catch((err: BusinessError): void => {
          clearTimeout(timerId)
          reject(new Error(err.message))
        })
    })
  }

  /**
   * 按 IP 族解析（仅 IPv4 或 IPv6）
   */
  private resolveAddressesByFamily(domain: string, family: IpFamily, timeout: number): Promise<string[]> {
    return new Promise<string[]>((resolve: (v: string[]) => void, reject: (e: Error) => void) => {
      const timerId: number = setTimeout((): void => {
        reject(new Error('DNS查询超时'))
      }, timeout)

      const familyType: connection.FamilyType = family === 'IPv6'
        ? connection.FamilyType.FAMILY_TYPE_IPV6
        : connection.FamilyType.FAMILY_TYPE_IPV4

      const options: connection.QueryOptions = {
        family: familyType
      }

      connection.getAddressesByNameWithOptions(domain, options)
        .then((addresses: Array<connection.NetAddress>): void => {
          clearTimeout(timerId)
          if (!addresses || addresses.length === 0) {
            resolve([])
            return
          }
          const results: string[] = []
          for (let i = 0; i < addresses.length; i++) {
            const addr: string | undefined = addresses[i].address
            if (addr) results.push(addr)
          }
          resolve(results)
        })
        .catch((err: BusinessError): void => {
          clearTimeout(timerId)
          reject(new Error(err.message))
        })
    })
  }

  // ------------------ 辅助方法 ------------------

  /**
   * 根据服务器地址获取显示名称
   */
  private getServerNameByAddress(address: string): string {
    for (let i = 0; i < DnsLookupEngine.DNS_SERVERS.length; i++) {
      if (DnsLookupEngine.DNS_SERVERS[i].address === address) {
        return DnsLookupEngine.DNS_SERVERS[i].name
      }
    }
    return address
  }

  /**
   * 构建错误结果
   */
  private makeErrorResult(domain: string, server: string, message: string, startTime: number): DnsLookupResult {
    const result: DnsLookupResult = {
      domain: domain,
      records: [],
      queryTime: Date.now() - startTime,
      server: server,
      status: 'error',
      errorMessage: message,
    }
    return result
  }

  // ------------------ 批量查询（保留兼容）------------------

  /**
   * 在指定网络连接上解析（如仅使用 Wi-Fi 或蜂窝网络）
   */
  async lookupOnNetwork(domain: string, networkType: 'wifi' | 'cellular', timeout: number): Promise<string[]> {
    const netSpecifier: connection.NetSpecifier = {
      netCapabilities: {
        bearerTypes: [networkType === 'wifi'
          ? connection.NetBearType.BEARER_WIFI
          : connection.NetBearType.BEARER_CELLULAR],
        networkCap: [connection.NetCap.NET_CAPABILITY_INTERNET]
      }
    }

    return new Promise<string[]>((resolve: (v: string[]) => void, reject: (e: Error) => void) => {
      const conn: connection.NetConnection = connection.createNetConnection(netSpecifier)
      const timerId: number = setTimeout((): void => {
        reject(new Error('DNS查询超时'))
      }, timeout)

      conn.on('netAvailable', (handle: connection.NetHandle): void => {
        clearTimeout(timerId)
        this.resolveAddressesAll(domain, timeout)
          .then(resolve)
          .catch(reject)
      })

      conn.on('netUnavailable', (): void => {
        clearTimeout(timerId)
        reject(new Error('指定网络不可用'))
      })
    })
  }

  /**
   * 批量查询多个域名（并行执行）
   */
  async batchLookup(domains: string[], timeout: number): Promise<DnsLookupResult[]> {
    const promises: Array<Promise<DnsLookupResult>> = []
    for (let i = 0; i < domains.length; i++) {
      const cfg: DnsLookupConfig = {
        domain: domains[i],
        dnsServer: '',
        timeout: timeout,
      }
      promises.push(this.lookup(cfg))
    }
    const results: DnsLookupResult[] = await Promise.all(promises)
    return results
  }
}
