// DNS 查询引擎
// 支持 HTTP DNS (DoH) 多服务器查询 + 系统 DNS 兜底
// 适配 @kit.NetworkKit API

import { http, connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import preferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { NetworkTimeout } from '@wifi-analyzer/core'
import {
  DnsRecordType, IpFamily, DnsRecord, DnsResult, DnsLookupConfig,
  DnsServerPreset, DnsHistoryEntry
} from '../models/ToolModels'

// DoH 响应中的单条 Answer 条目（内部使用）
interface DoHAnswerItem {
  name: string
  type: number
  TTL: number
  data: string
}

// 历史记录持久化的内部存储格式
interface DnsSaveItem {
  domain: string
  server: string
  timestamp: number
  recordCount: number
  queryTime: number
}

export class DnsLookupEngine {
  // DNS 记录类型 -> RFC 数值映射
  private static readonly RECORD_TYPE_MAP: Record<string, number> = {
    'A': 1, 'NS': 2, 'CNAME': 5, 'MX': 15, 'TXT': 16, 'AAAA': 28,
  }

  // RFC 数值 -> 记录类型反向映射
  private static readonly TYPE_NUM_TO_RECORD: Record<number, DnsRecordType> = {
    1: 'A', 2: 'NS', 5: 'CNAME', 15: 'MX', 16: 'TXT', 28: 'AAAA',
  }

  // 常用 DNS 服务器预设（含 DoH API）
  // resKey 对应 string.json 中的多语言资源名称
  static readonly DNS_SERVERS: DnsServerPreset[] = [
    { name: '系统默认', resKey: 'dns_system_default', address: '', color: '#0066FF', apiUrl: '' },
    { name: '阿里DNS', resKey: 'dns_alibaba', address: '223.5.5.5', color: '#10B981', apiUrl: 'https://dns.alidns.com/resolve' },
    { name: '腾讯DNS', resKey: 'dns_tencent', address: '119.29.29.29', color: '#14B8A6', apiUrl: 'https://doh.pub/dns-query' },
    { name: '百度DNS', resKey: 'dns_baidu', address: '180.76.76.76', color: '#F59E0B', apiUrl: 'https://dns.baidu.com/resolve' },
    { name: 'Google DNS', resKey: 'dns_google', address: '8.8.8.8', color: '#8B5CF6', apiUrl: 'https://dns.google/resolve' },
    { name: 'Cloudflare', resKey: 'dns_cloudflare', address: '1.1.1.1', color: '#EC4899', apiUrl: 'https://cloudflare-dns.com/dns-query' },
  ]

  // 常用域名
  static readonly POPULAR_DOMAINS: string[] = [
    'baidu.com', 'taobao.com', 'qq.com', 'jd.com', 'weibo.com', 'zhihu.com',
  ]

  /**
   * 获取默认配置
   */
  static getDefaultConfig(domain: string): DnsLookupConfig {
    const config: DnsLookupConfig = {
      domain: domain,
      dnsServer: '',
      timeout: NetworkTimeout.DNS_QUERY_MS,
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
   */
  async lookup(config: DnsLookupConfig): Promise<DnsResult> {
    const startTime: number = Date.now()
    const domain: string = config.domain.trim()
    const dnsServer: string = config.dnsServer || '系统默认'

    if (domain.length === 0) {
      return this.makeErrorResult(domain, dnsServer, '域名不能为空', startTime)
    }

    try {
      // 中文域名转换
      let resolvedDomain: string = domain
      const chinesePattern: RegExp = /[\u4e00-\u9fa5]/
      if (chinesePattern.test(domain)) {
        resolvedDomain = connection.getDnsAscii(domain)
      }

      // 判断走哪种查询方式
      const apiUrl: string = DnsLookupEngine.getApiUrlByServer(config.dnsServer)

      if (apiUrl && apiUrl.length > 0) {
        return await this.lookupViaHttpDns(resolvedDomain, config, startTime, apiUrl)
      } else {
        return await this.lookupViaSystemDns(resolvedDomain, config, startTime)
      }
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      return this.makeErrorResult(domain, dnsServer, errorMsg, startTime)
    }
  }

  /**
   * 通过 HTTP DNS (DoH) 接口查询
   */
  private async lookupViaHttpDns(
    domain: string,
    config: DnsLookupConfig,
    startTime: number,
    apiUrl: string
  ): Promise<DnsResult> {
    try {
      const recordTypes: DnsRecordType[] = ['A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT']
      const allRecords: DnsRecord[] = []

      const promises: Array<Promise<DnsRecord[]>> = []
      for (let i = 0; i < recordTypes.length; i++) {
        promises.push(this.querySingleRecordViaHttpDns(domain, recordTypes[i], apiUrl, config.timeout))
      }
      const results: DnsRecord[][] = await Promise.all(promises)

      for (let r = 0; r < results.length; r++) {
        const records: DnsRecord[] = results[r]
        for (let j = 0; j < records.length; j++) {
          allRecords.push(records[j])
        }
      }

      const queryTime: number = Date.now() - startTime
      const serverName: string = this.getServerNameByAddress(config.dnsServer)

      if (allRecords.length > 0) {
        const result: DnsResult = {
          domain: config.domain,
          records: allRecords,
          queryTime: queryTime,
          server: serverName || config.dnsServer,
          status: 'success',
          errorMessage: '',
        }
        return result
      } else {
        const result: DnsResult = {
          domain: config.domain,
          records: [],
          queryTime: queryTime,
          server: serverName || config.dnsServer,
          status: 'error',
          errorMessage: '未找到DNS记录',
        }
        return result
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

      let fullUrl: string = baseUrl + '?name=' + encodeURIComponent(domain) + '&type=' + String(typeNum)

      const req = http.createHttp()
      const result: http.HttpResponse = await new Promise<http.HttpResponse>(
        (resolve: (v: http.HttpResponse) => void, reject: (e: Error) => void) => {
          const timerId: number = setTimeout((): void => {
            req.destroy()
            reject(new Error('DNS查询超时'))
          }, timeout)

          const headerObj: Record<string, string> = {}
          // Cloudflare 需要 Accept 头返回 JSON
          if (baseUrl.indexOf('cloudflare') >= 0) {
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
        }
      )

      if (result.responseCode !== 200 || !result.result) {
        return []
      }

      const responseStr: string = result.result.toString()
      return this.parseDoHJson(responseStr, recordType)
    } catch (e) {
      return []
    }
  }

  /**
   * 解析 DoH JSON 响应
   */
  private parseDoHJson(jsonStr: string, expectType: DnsRecordType): DnsRecord[] {
    const records: DnsRecord[] = []
    try {
      const parsed: Record<string, Object | string | number | boolean | null> =
        JSON.parse(jsonStr) as Record<string, Object | string | number | boolean | null>
      const statusVal: Object | string | number | boolean | null | undefined = parsed['Status']
      const status: number = typeof statusVal === 'number' ? statusVal : 0

      if (status !== 0) {
        return records
      }

      const answerRaw: Object | string | number | boolean | null | undefined = parsed['Answer']
      if (!answerRaw || typeof answerRaw !== 'object') {
        return records
      }

      const answers: DoHAnswerItem[] = answerRaw as DoHAnswerItem[]
      if (answers.length === 0) {
        return records
      }

      for (let i = 0; i < answers.length; i++) {
        const item: DoHAnswerItem = answers[i]
        const typeNum: number = item.type
        const recordType: DnsRecordType | undefined = DnsLookupEngine.TYPE_NUM_TO_RECORD[typeNum]

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
      return records
    }
  }

  /**
   * 通过系统 connection API 查询 DNS（兜底方案）
   */
  private async lookupViaSystemDns(
    domain: string,
    config: DnsLookupConfig,
    startTime: number
  ): Promise<DnsResult> {
    const records: DnsRecord[] = []

    try {
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (!netHandle || netHandle.netId === 0) {
        return this.makeErrorResult(domain, '系统默认', '无网络连接', startTime)
      }

      let addresses: string[] = []
      if (config.family && config.family !== 'All') {
        addresses = await this.resolveAddressesByFamily(domain, config.family, config.timeout)
      } else {
        addresses = await this.resolveAddressesAll(domain, config.timeout)
      }

      for (let i = 0; i < addresses.length; i++) {
        const addr: string = addresses[i]
        const isIPv6: boolean = addr.indexOf(':') >= 0
        const record: DnsRecord = {
          type: isIPv6 ? 'AAAA' : 'A',
          value: addr,
          ttl: 300,
        }
        records.push(record)
      }

      const queryTime: number = Date.now() - startTime

      const result: DnsResult = {
        domain: domain,
        records: records,
        queryTime: queryTime,
        server: '系统默认',
        status: records.length > 0 ? 'success' : 'error',
        errorMessage: records.length > 0 ? '' : '未找到DNS记录',
      }
      return result
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      return this.makeErrorResult(domain, '系统默认', errorMsg, startTime)
    }
  }

  /**
   * 获取所有地址
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
   * 按 IP 族解析
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

  /**
   * 批量查询多个域名
   */
  async batchLookup(domains: string[], timeout: number): Promise<DnsResult[]> {
    const promises: Array<Promise<DnsResult>> = []
    for (let i = 0; i < domains.length; i++) {
      const cfg: DnsLookupConfig = {
        domain: domains[i],
        dnsServer: '',
        timeout: timeout,
      }
      promises.push(this.lookup(cfg))
    }
    const results: DnsResult[] = await Promise.all(promises)
    return results
  }

  // 辅助方法

  private getServerNameByAddress(address: string): string {
    for (let i = 0; i < DnsLookupEngine.DNS_SERVERS.length; i++) {
      if (DnsLookupEngine.DNS_SERVERS[i].address === address) {
        return DnsLookupEngine.DNS_SERVERS[i].name
      }
    }
    return address
  }

  private makeErrorResult(domain: string, server: string, message: string, startTime: number): DnsResult {
    const result: DnsResult = {
      domain: domain,
      records: [],
      queryTime: Date.now() - startTime,
      server: server,
      status: 'error',
      errorMessage: message,
    }
    return result
  }

  // ==================== 历史记录持久化 ====================

  private static readonly PREF_NAME: string = 'dns_lookup_history'
  private static readonly PREF_KEY: string = 'dns_history_list'
  private static readonly MAX_HISTORY: number = 50

  /** 加载历史记录 */
  static async loadHistory(context: common.Context): Promise<DnsHistoryEntry[]> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(context, DnsLookupEngine.PREF_NAME)
      const jsonStr: string | null = await pref.get(DnsLookupEngine.PREF_KEY, '[]') as string
      if (!jsonStr || jsonStr === '[]') return []
      const parsed: Array<Record<string, Object | string | number>> = JSON.parse(jsonStr) as Array<Record<string, Object | string | number>>
      const entries: DnsHistoryEntry[] = []
      for (let i = 0; i < parsed.length; i++) {
        entries.push({
          domain: String(parsed[i]['domain'] || ''),
          server: String(parsed[i]['server'] || ''),
          timestamp: Number(parsed[i]['timestamp'] || 0),
          recordCount: Number(parsed[i]['recordCount'] || 0),
          queryTime: Number(parsed[i]['queryTime'] || 0),
        })
      }
      return entries
    } catch (e) {
      hilog.warn(0x0000, 'DnsLookup', 'loadHistory error: ' + e)
      return []
    }
  }

  /** 添加一条历史记录 */
  static async addHistoryEntry(context: common.Context, entry: DnsHistoryEntry): Promise<void> {
    try {
      const existing: DnsHistoryEntry[] = await DnsLookupEngine.loadHistory(context)
      const filtered: DnsHistoryEntry[] = []
      for (let i = 0; i < existing.length; i++) {
        if (!(existing[i].domain === entry.domain && existing[i].server === entry.server)) {
          filtered.push(existing[i])
        }
      }
      filtered.unshift(entry)
      if (filtered.length > DnsLookupEngine.MAX_HISTORY) { filtered.length = DnsLookupEngine.MAX_HISTORY }
      const saveList: DnsSaveItem[] = []
      for (let i = 0; i < filtered.length; i++) {
        const item: DnsSaveItem = {
          domain: filtered[i].domain,
          server: filtered[i].server,
          timestamp: filtered[i].timestamp,
          recordCount: filtered[i].recordCount,
          queryTime: filtered[i].queryTime,
        }
        saveList.push(item)
      }
      const jsonStr: string = JSON.stringify(saveList)
      const pref: preferences.Preferences = await preferences.getPreferences(context, DnsLookupEngine.PREF_NAME)
      await pref.put(DnsLookupEngine.PREF_KEY, jsonStr)
      await pref.flush()
    } catch (e) {
      hilog.warn(0x0000, 'DnsLookup', 'addHistoryEntry error: ' + e)
    }
  }

  /** 清空历史记录 */
  static async clearHistory(context: common.Context): Promise<void> {
    try {
      const pref: preferences.Preferences = await preferences.getPreferences(context, DnsLookupEngine.PREF_NAME)
      await pref.delete(DnsLookupEngine.PREF_KEY)
      await pref.flush()
    } catch (e) {
      hilog.warn(0x0000, 'DnsLookup', 'clearHistory error: ' + e)
    }
  }

  /** 删除单条历史记录 */
  static async removeHistoryEntry(context: common.Context, timestamp: number): Promise<void> {
    try {
      const existing: DnsHistoryEntry[] = await DnsLookupEngine.loadHistory(context)
      const filtered: DnsHistoryEntry[] = []
      for (let i = 0; i < existing.length; i++) {
        if (existing[i].timestamp !== timestamp) { filtered.push(existing[i]) }
      }
      const saveList: DnsSaveItem[] = []
      for (let i = 0; i < filtered.length; i++) {
        const item: DnsSaveItem = {
          domain: filtered[i].domain,
          server: filtered[i].server,
          timestamp: filtered[i].timestamp,
          recordCount: filtered[i].recordCount,
          queryTime: filtered[i].queryTime,
        }
        saveList.push(item)
      }
      const jsonStr: string = JSON.stringify(saveList)
      const pref: preferences.Preferences = await preferences.getPreferences(context, DnsLookupEngine.PREF_NAME)
      await pref.put(DnsLookupEngine.PREF_KEY, jsonStr)
      await pref.flush()
    } catch (e) {
      hilog.warn(0x0000, 'DnsLookup', 'removeHistoryEntry error: ' + e)
    }
  }
}
