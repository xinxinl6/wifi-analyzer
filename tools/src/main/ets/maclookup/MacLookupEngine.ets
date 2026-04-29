// MAC 地址查询引擎
// 通过公开 API 查询 MAC 地址对应的厂商信息
// 本地内置常用厂商前缀表，支持离线查询

import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

// MAC 查询结果
export interface MacLookupResult {
  mac: string              // 标准化 MAC 地址
  vendor: string           // 厂商名称
  country: string          // 国家/地区
  address: string          // 厂商地址
  prefix: string           // MAC 前缀 (前6位)
  type: string             // 类型 (unicast/multicast)
  status: 'success' | 'not_found' | 'error'
  errorMessage: string
  queryTime: number
  source: string           // 'local' | 'api'
}

// 厂商预设数据（常用前缀，覆盖常见设备厂商）
interface VendorEntry {
  prefix: string
  vendor: string
  country: string
}

export class MacLookupEngine {
  // 常见厂商本地数据库（前缀 → 厂商）
  private static readonly VENDOR_DB: VendorEntry[] = [
    // Apple
    { prefix: 'A4B197', vendor: 'Apple Inc.', country: 'US' },
    { prefix: 'A4B3E2', vendor: 'Apple Inc.', country: 'US' },
    { prefix: '3C22FB', vendor: 'Apple Inc.', country: 'US' },
    { prefix: 'AC87A3', vendor: 'Apple Inc.', country: 'US' },
    { prefix: 'F0F6C0', vendor: 'Apple Inc.', country: 'US' },
    { prefix: 'DC2B2A', vendor: 'Apple Inc.', country: 'US' },
    { prefix: 'DC5583', vendor: 'Apple Inc.', country: 'US' },
    { prefix: '8C8590', vendor: 'Apple Inc.', country: 'US' },
    { prefix: '68A80C', vendor: 'Apple Inc.', country: 'US' },
    // Samsung
    { prefix: '9C3AAF', vendor: 'Samsung Electronics', country: 'KR' },
    { prefix: 'A0CBFD', vendor: 'Samsung Electronics', country: 'KR' },
    { prefix: '40D357', vendor: 'Samsung Electronics', country: 'KR' },
    { prefix: 'B47443', vendor: 'Samsung Electronics', country: 'KR' },
    { prefix: 'E4BEED', vendor: 'Samsung Electronics', country: 'KR' },
    { prefix: '48DF37', vendor: 'Samsung Electronics', country: 'KR' },
    // Huawei
    { prefix: '20A6CD', vendor: 'Huawei Technologies', country: 'CN' },
    { prefix: 'CC96A0', vendor: 'Huawei Technologies', country: 'CN' },
    { prefix: 'E0191D', vendor: 'Huawei Technologies', country: 'CN' },
    { prefix: '78112C', vendor: 'Huawei Technologies', country: 'CN' },
    { prefix: 'B4A984', vendor: 'Huawei Technologies', country: 'CN' },
    // Xiaomi
    { prefix: '78110B', vendor: 'Xiaomi Communications', country: 'CN' },
    { prefix: '9C99A0', vendor: 'Xiaomi Communications', country: 'CN' },
    { prefix: '5C7D5E', vendor: 'Xiaomi Communications', country: 'CN' },
    { prefix: '28E31F', vendor: 'Xiaomi Communications', country: 'CN' },
    { prefix: '64B473', vendor: 'Xiaomi Communications', country: 'CN' },
    // OPPO / vivo
    { prefix: 'E4A749', vendor: 'OPPO Mobile', country: 'CN' },
    { prefix: '9C99BF', vendor: 'OPPO Mobile', country: 'CN' },
    { prefix: 'A076C1', vendor: 'vivo Mobile', country: 'CN' },
    { prefix: 'CC2D5B', vendor: 'vivo Mobile', country: 'CN' },
    // Honor
    { prefix: '70FDE5', vendor: 'Honor Device Co.', country: 'CN' },
    { prefix: '5C628B', vendor: 'Honor Device Co.', country: 'CN' },
    // TP-Link
    { prefix: 'A842A1', vendor: 'TP-Link Technologies', country: 'CN' },
    { prefix: 'E848B8', vendor: 'TP-Link Technologies', country: 'CN' },
    { prefix: 'B0A7B9', vendor: 'TP-Link Technologies', country: 'CN' },
    { prefix: '5C628B', vendor: 'TP-Link Technologies', country: 'CN' },
    // Intel
    { prefix: '3C970E', vendor: 'Intel Corporation', country: 'US' },
    { prefix: '70B5E8', vendor: 'Intel Corporation', country: 'US' },
    { prefix: 'F8B156', vendor: 'Intel Corporation', country: 'US' },
    { prefix: 'B4D5BD', vendor: 'Intel Corporation', country: 'US' },
    // Realtek
    { prefix: 'B827EB', vendor: 'Realtek Semiconductor', country: 'TW' },
    { prefix: '00E04C', vendor: 'Realtek Semiconductor', country: 'TW' },
    { prefix: 'D8CB8A', vendor: 'Realtek Semiconductor', country: 'TW' },
    // Qualcomm
    { prefix: 'C8F76C', vendor: 'Qualcomm Technologies', country: 'US' },
    { prefix: 'A4C494', vendor: 'Qualcomm Technologies', country: 'US' },
    { prefix: '6CA15C', vendor: 'Qualcomm Technologies', country: 'US' },
    // Lenovo
    { prefix: 'A4C494', vendor: 'Lenovo Group', country: 'CN' },
    { prefix: '408BFD', vendor: 'Lenovo Group', country: 'CN' },
    { prefix: '606C66', vendor: 'Lenovo Group', country: 'CN' },
    // Dell
    { prefix: 'F8BC12', vendor: 'Dell Inc.', country: 'US' },
    { prefix: 'B88303', vendor: 'Dell Inc.', country: 'US' },
    { prefix: '001E4F', vendor: 'Dell Inc.', country: 'US' },
    // Microsoft
    { prefix: '001DD8', vendor: 'Microsoft Corporation', country: 'US' },
    { prefix: '7CED8D', vendor: 'Microsoft Corporation', country: 'US' },
    // Google
    { prefix: 'F8A9D0', vendor: 'Google Inc.', country: 'US' },
    { prefix: 'A4C0E1', vendor: 'Google Inc.', country: 'US' },
    // Amazon
    { prefix: '40B4CD', vendor: 'Amazon Technologies', country: 'US' },
    { prefix: '747548', vendor: 'Amazon Technologies', country: 'US' },
    { prefix: 'FCA183', vendor: 'Amazon Technologies', country: 'US' },
    // Cisco
    { prefix: '00C584', vendor: 'Cisco Systems', country: 'US' },
    { prefix: '5C5AB5', vendor: 'Cisco Systems', country: 'US' },
    { prefix: 'B4A984', vendor: 'Cisco Systems', country: 'US' },
    // D-Link
    { prefix: 'C03F65', vendor: 'D-Link International', country: 'TW' },
    { prefix: '1CBFCE', vendor: 'D-Link International', country: 'TW' },
    // Netgear
    { prefix: '6038E0', vendor: 'Netgear Inc.', country: 'US' },
    { prefix: '9C3DCF', vendor: 'Netgear Inc.', country: 'US' },
    // ASUS
    { prefix: '1CBFCE', vendor: 'ASUSTek Computer', country: 'TW' },
    { prefix: '2CFDA1', vendor: 'ASUSTek Computer', country: 'TW' },
    { prefix: '3085A9', vendor: 'ASUSTek Computer', country: 'TW' },
    // ESP32 / Espressif (IoT devices)
    { prefix: '240AC4', vendor: 'Espressif Systems', country: 'CN' },
    { prefix: '30AEA4', vendor: 'Espressif Systems', country: 'CN' },
    { prefix: 'BCDDC2', vendor: 'Espressif Systems', country: 'CN' },
    { prefix: '7CDFA1', vendor: 'Espressif Systems', country: 'CN' },
    // Shenzhen (generic IoT)
    { prefix: 'DC4F22', vendor: 'Shenzhen Generic', country: 'CN' },
    { prefix: '244BFE', vendor: 'Shenzhen Generic', country: 'CN' },
    { prefix: 'E8E532', vendor: 'Shenzhen Generic', country: 'CN' },
  ]

  // 查询历史
  private history: string[] = []

  /**
   * 标准化 MAC 地址格式
   * 支持输入: AA:BB:CC:DD:EE:FF, AA-BB-CC-DD-EE-FF, AABBCCDDEEFF
   */
  static normalizeMac(input: string): string {
    // 去除所有分隔符
    const cleaned: string = input.replace(/[:\-\.]/g, '').toUpperCase()
    if (cleaned.length !== 12) return ''
    // 验证是否为有效十六进制
    for (let i = 0; i < cleaned.length; i++) {
      const c: string = cleaned[i]
      if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F'))) return ''
    }
    // 格式化为 AA:BB:CC:DD:EE:FF
    return cleaned.substring(0, 2) + ':' + cleaned.substring(2, 4) + ':' +
      cleaned.substring(4, 6) + ':' + cleaned.substring(6, 8) + ':' +
      cleaned.substring(8, 10) + ':' + cleaned.substring(10, 12)
  }

  /**
   * 判断 MAC 类型
   */
  static getMacType(mac: string): string {
    if (mac.length < 2) return 'unknown'
    const firstByte: number = parseInt(mac.substring(0, 2), 16)
    // 组播地址: 第一字节最低位为1
    if (firstByte & 0x01) return 'multicast'
    return 'unicast'
  }

  /**
   * 提取 MAC 前缀 (OUI)
   */
  static extractPrefix(mac: string): string {
    return mac.replace(/[:\-\.]/g, '').toUpperCase().substring(0, 6)
  }

  /**
   * 查询 MAC 地址厂商信息
   */
  async lookup(macInput: string): Promise<MacLookupResult> {
    const startTime: number = Date.now()
    const normalized: string = MacLookupEngine.normalizeMac(macInput)

    if (normalized.length === 0) {
      const errorResult: MacLookupResult = {
        mac: macInput, vendor: '', country: '', address: '',
        prefix: '', type: 'unknown', status: 'error',
        errorMessage: 'MAC地址格式不正确', queryTime: 0, source: 'local'
      }
      return errorResult
    }

    const prefix: string = MacLookupEngine.extractPrefix(normalized)
    const macType: string = MacLookupEngine.getMacType(normalized)

    // 先查本地数据库
    const localResult: MacLookupResult = this.lookupLocal(normalized, prefix, macType, startTime)
    if (localResult.status === 'success') {
      this.addHistory(normalized)
      return localResult
    }

    // 尝试 API 查询
    const apiResult: MacLookupResult = await this.lookupFromApi(normalized, prefix, macType, startTime)
    if (apiResult.status === 'success') {
      this.addHistory(normalized)
      return apiResult
    }

    // 都没找到
    const notFoundResult: MacLookupResult = {
      mac: normalized, vendor: '未知厂商', country: '--', address: '--',
      prefix: prefix, type: macType, status: 'not_found',
      errorMessage: '未找到该MAC地址的厂商信息', queryTime: Date.now() - startTime, source: 'local'
    }
    return notFoundResult
  }

  /**
   * 本地数据库查询
   */
  private lookupLocal(mac: string, prefix: string, macType: string, startTime: number): MacLookupResult {
    for (let i = 0; i < MacLookupEngine.VENDOR_DB.length; i++) {
      if (MacLookupEngine.VENDOR_DB[i].prefix === prefix) {
        const entry: VendorEntry = MacLookupEngine.VENDOR_DB[i]
        const result: MacLookupResult = {
          mac: mac, vendor: entry.vendor, country: entry.country,
          address: '', prefix: prefix, type: macType,
          status: 'success', errorMessage: '',
          queryTime: Date.now() - startTime, source: 'local'
        }
        return result
      }
    }

    const failResult: MacLookupResult = {
      mac: mac, vendor: '', country: '', address: '',
      prefix: prefix, type: macType, status: 'not_found',
      errorMessage: '本地数据库中未找到', queryTime: 0, source: 'local'
    }
    return failResult
  }

  /**
   * API 查询 (macvendors.co)
   */
  private async lookupFromApi(mac: string, prefix: string, macType: string, startTime: number): Promise<MacLookupResult> {
    try {
      const req = http.createHttp()
      const options: MacLookupHttpOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000,
        header: { 'User-Agent': 'WiFi-Analyzer/1.0' } as MacLookupHttpHeaders
      }

      const result: MacLookupResult = await new Promise<MacLookupResult>((resolve: (v: MacLookupResult) => void) => {
        let timeoutTimerId: number = -1
        req.request(
          'https://api.macvendors.com/' + prefix,
          options,
          (err: BusinessError, resp: http.HttpResponse): void => {
            if (timeoutTimerId >= 0) {
              clearTimeout(timeoutTimerId)
              timeoutTimerId = -1
            }
            req.destroy()
            if (err) {
              resolve({
                mac: mac, vendor: '', country: '', address: '',
                prefix: prefix, type: macType, status: 'not_found',
                errorMessage: 'API查询失败', queryTime: Date.now() - startTime, source: 'api'
              })
              return
            }
            try {
              const vendorName: string = resp.result as string
              if (vendorName && vendorName.length > 0) {
                resolve({
                  mac: mac, vendor: vendorName.trim(), country: '', address: '',
                  prefix: prefix, type: macType, status: 'success',
                  errorMessage: '', queryTime: Date.now() - startTime, source: 'api'
                })
              } else {
                resolve({
                  mac: mac, vendor: '', country: '', address: '',
                  prefix: prefix, type: macType, status: 'not_found',
                  errorMessage: 'API未返回数据', queryTime: Date.now() - startTime, source: 'api'
                })
              }
            } catch (e2) {
              resolve({
                mac: mac, vendor: '', country: '', address: '',
                prefix: prefix, type: macType, status: 'not_found',
                errorMessage: 'API解析失败', queryTime: Date.now() - startTime, source: 'api'
              })
            }
          }
        )
        timeoutTimerId = setTimeout((): void => {
          req.destroy()
          resolve({
            mac: mac, vendor: '', country: '', address: '',
            prefix: prefix, type: macType, status: 'not_found',
            errorMessage: 'API查询超时', queryTime: Date.now() - startTime, source: 'api'
          })
        }, 6000)
      })

      return result
    } catch (e) {
      const errorResult: MacLookupResult = {
        mac: mac, vendor: '', country: '', address: '',
        prefix: prefix, type: macType, status: 'not_found',
        errorMessage: 'API查询异常', queryTime: Date.now() - startTime, source: 'api'
      }
      return errorResult
    }
  }

  /**
   * 批量查询 MAC 地址
   */
  async batchLookup(macs: string[]): Promise<MacLookupResult[]> {
    const promises: Array<Promise<MacLookupResult>> = []
    for (let i = 0; i < macs.length; i++) {
      promises.push(this.lookup(macs[i]))
    }
    const results: MacLookupResult[] = await Promise.all(promises)
    return results
  }

  /**
   * 获取快速查询列表（当前WiFi扫描结果中的MAC）
   */
  getQuickQueryList(): string[] {
    return [
      'A4B19700ABCD', // Apple
      '9C3AAF123456', // Samsung
      '20A6CD567890', // Huawei
      '78110BABCDEF', // Xiaomi
      'A842A1DEADBEEF', // TP-Link
    ]
  }

  /**
   * 添加历史
   */
  addHistory(mac: string): void {
    const idx: number = this.history.indexOf(mac)
    if (idx >= 0) {
      this.history.splice(idx, 1)
    }
    this.history.unshift(mac)
    if (this.history.length > 20) {
      this.history.pop()
    }
  }

  /**
   * 获取历史
   */
  getHistory(): string[] {
    const copy: string[] = []
    for (let i = 0; i < this.history.length; i++) {
      copy.push(this.history[i])
    }
    return copy
  }

  /**
   * 清空历史
   */
  clearHistory(): void {
    this.history = []
  }
}

// HTTP 请求选项接口
interface MacLookupHttpOptions {
  method: http.RequestMethod
  connectTimeout: number
  readTimeout: number
  header: MacLookupHttpHeaders
}

interface MacLookupHttpHeaders {
  'User-Agent': string
}
