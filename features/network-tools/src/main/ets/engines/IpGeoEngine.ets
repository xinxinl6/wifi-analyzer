// IP 归属查询引擎
// 使用公开 API 查询 IP 地理位置信息

import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { IpGeoResult } from '../models/ToolModels'

// HTTP 请求选项接口（内部使用）
interface IpGeoHttpOptions {
  method: http.RequestMethod
  connectTimeout: number
  readTimeout: number
}

// 公网IP查询API条目（内部使用）
interface IpQueryApiEntry {
  url: string
  parser: (text: string) => string
}

export class IpGeoEngine {
  // 查询历史
  private history: string[] = []

  /**
   * 验证 IP 地址格式
   */
  static isValidIp(ip: string): boolean {
    const trimmed: string = ip.trim()
    const octets: string[] = trimmed.split('.')
    if (octets.length !== 4) return false
    for (let i = 0; i < 4; i++) {
      const num: number = parseInt(octets[i], 10)
      if (isNaN(num) || num < 0 || num > 255 || octets[i] !== String(num)) return false
    }
    return true
  }

  /**
   * 查询当前设备公网 IP（多API降级）
   */
  async queryMyIp(): Promise<string> {
    const apis: IpQueryApiEntry[] = [
      {
        url: 'https://myip.ipip.net',
        parser: function (t: string): string {
          const m: RegExpMatchArray | null = t.match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)
          return m ? m[1] : ''
        }
      },
      {
        url: 'https://ip.sb/ip',
        parser: function (t: string): string { return t.trim() }
      },
      {
        url: 'https://ip.3322.net',
        parser: function (t: string): string { return t.trim() }
      },
      {
        url: 'https://pv.sohu.com/ipimsg',
        parser: function (t: string): string {
          const m: RegExpMatchArray | null = t.match(/(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/)
          return m ? m[1] : ''
        }
      },
      {
        url: 'https://ipinfo.io/json',
        parser: function (t: string): string {
          try {
            const j: Record<string, string> = JSON.parse(t) as Record<string, string>
            return j['ip'] || ''
          } catch (e) { return '' }
        }
      },
      {
        url: 'https://api.ipify.org?format=json',
        parser: function (t: string): string {
          try {
            const j: Record<string, string> = JSON.parse(t) as Record<string, string>
            return j['ip'] || ''
          } catch (e) { return '' }
        }
      }
    ]

    for (let i = 0; i < apis.length; i++) {
      try {
        const req = http.createHttp()
        const result: http.HttpResponse = await req.request(apis[i].url, {
          method: http.RequestMethod.GET,
          connectTimeout: 4000,
          readTimeout: 4000,
        })
        req.destroy()

        if (result.responseCode === 200 && result.result) {
          const ip: string = apis[i].parser(result.result.toString())
          if (ip && ip !== '0.0.0.0' && ip.indexOf('::') < 0) {
            return ip
          }
        }
      } catch (e) {
        // 继续尝试下一个 API
      }
    }

    return ''
  }

  /**
   * 查询 IP 归属信息
   */
  async query(ip: string): Promise<IpGeoResult> {
    const startTime: number = Date.now()
    const trimmedIp: string = ip.trim()

    if (trimmedIp.length === 0) {
      return this.makeErrorResult('', 'IP地址不能为空', 0)
    }

    if (!IpGeoEngine.isValidIp(trimmedIp)) {
      return this.makeErrorResult(trimmedIp, 'IP地址格式不正确', 0)
    }

    try {
      // 优先使用 ipapi.co
      const result: IpGeoResult = await this.queryFromIpApi(trimmedIp, startTime)
      if (result.status === 'success') {
        this.addHistory(trimmedIp)
        return result
      }

      // 备用：使用 ipinfo.io
      const fallback: IpGeoResult = await this.queryFromIpInfo(trimmedIp, startTime)
      if (fallback.status === 'success') {
        this.addHistory(trimmedIp)
        return fallback
      }

      return this.makeErrorResult(trimmedIp, '所有查询接口均不可用', Date.now() - startTime)
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      return this.makeErrorResult(trimmedIp, errorMsg, Date.now() - startTime)
    }
  }

  /**
   * 使用 ipapi.co 查询
   */
  private async queryFromIpApi(ip: string, startTime: number): Promise<IpGeoResult> {
    try {
      const req = http.createHttp()
      const options: IpGeoHttpOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000,
      }

      const result: IpGeoResult = await new Promise<IpGeoResult>((resolve: (v: IpGeoResult) => void) => {
        req.request(
          'https://ipapi.co/' + ip + '/json/',
          options,
          (err: BusinessError, resp: http.HttpResponse): void => {
            req.destroy()
            if (err) {
              resolve(this.makeErrorResult(ip, err.message, Date.now() - startTime))
              return
            }
            try {
              const resultStr: string = resp.result as string
              const data: Record<string, string> = JSON.parse(resultStr) as Record<string, string>
              const hasError: boolean = data['error'] !== undefined && data['error'] !== null

              if (!hasError) {
                const geoResult: IpGeoResult = {
                  ip: data['ip'] || ip,
                  country: data['country_name'] || data['country'] || '',
                  province: data['region'] || '',
                  city: data['city'] || '',
                  isp: data['org'] || '',
                  district: '',
                  latitude: parseFloat(data['latitude'] || '0'),
                  longitude: parseFloat(data['longitude'] || '0'),
                  timezone: data['timezone'] || '',
                  queryTime: Date.now() - startTime,
                  status: 'success',
                  errorMessage: '',
                }
                resolve(geoResult)
              } else {
                const errMsg: string = data['reason'] || '查询失败'
                resolve(this.makeErrorResult(ip, errMsg, Date.now() - startTime))
              }
            } catch (e2) {
              resolve(this.makeErrorResult(ip, 'JSON解析失败', Date.now() - startTime))
            }
          }
        )
        setTimeout((): void => {
          resolve(this.makeErrorResult(ip, '查询超时', Date.now() - startTime))
        }, 6000)
      })

      return result
    } catch (e) {
      return this.makeErrorResult(ip, '查询异常', Date.now() - startTime)
    }
  }

  /**
   * 使用 ipinfo.io 查询
   */
  private async queryFromIpInfo(ip: string, startTime: number): Promise<IpGeoResult> {
    try {
      const req = http.createHttp()
      const options: IpGeoHttpOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000,
      }

      const result: IpGeoResult = await new Promise<IpGeoResult>((resolve: (v: IpGeoResult) => void) => {
        req.request(
          'https://ipinfo.io/' + ip + '/json',
          options,
          (err: BusinessError, resp: http.HttpResponse): void => {
            req.destroy()
            if (err) {
              resolve(this.makeErrorResult(ip, err.message, Date.now() - startTime))
              return
            }
            try {
              const resultStr: string = resp.result as string
              const data: Record<string, string> = JSON.parse(resultStr) as Record<string, string>

              const locStr: string = data['loc'] || ''
              const latLng: string[] = locStr.split(',')
              const lat: number = latLng.length > 0 ? parseFloat(latLng[0]) : 0
              const lng: number = latLng.length > 1 ? parseFloat(latLng[1]) : 0

              const geoResult: IpGeoResult = {
                ip: data['ip'] || ip,
                country: '',
                province: '',
                city: data['city'] || '',
                isp: data['org'] || '',
                district: '',
                latitude: lat,
                longitude: lng,
                timezone: data['timezone'] || '',
                queryTime: Date.now() - startTime,
                status: 'success',
                errorMessage: '',
              }
              resolve(geoResult)
            } catch (e2) {
              resolve(this.makeErrorResult(ip, 'JSON解析失败', Date.now() - startTime))
            }
          }
        )
        setTimeout((): void => {
          resolve(this.makeErrorResult(ip, '查询超时', Date.now() - startTime))
        }, 6000)
      })

      return result
    } catch (e) {
      return this.makeErrorResult(ip, '查询异常', Date.now() - startTime)
    }
  }

  /**
   * 构建错误结果
   */
  private makeErrorResult(ip: string, message: string, queryTime: number): IpGeoResult {
    const result: IpGeoResult = {
      ip: ip,
      country: '', province: '', city: '', isp: '', district: '',
      latitude: 0, longitude: 0, timezone: '',
      queryTime: queryTime,
      status: 'error',
      errorMessage: message,
    }
    return result
  }

  /**
   * 添加历史
   */
  addHistory(ip: string): void {
    const idx: number = this.history.indexOf(ip)
    if (idx >= 0) {
      this.history.splice(idx, 1)
    }
    this.history.unshift(ip)
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
