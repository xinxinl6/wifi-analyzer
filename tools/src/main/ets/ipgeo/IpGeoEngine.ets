// IP 归属查询引擎
// 使用公开 API 查询 IP 地理位置信息

import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'

// IP 归属查询结果
export interface IpGeoResult {
  ip: string
  country: string       // 国家
  province: string      // 省份
  city: string          // 城市
  isp: string           // 运营商
  district: string      // 区/县
  latitude: number      // 纬度
  longitude: number     // 经度
  timezone: string      // 时区
  queryTime: number     // 查询耗时(ms)
  status: 'success' | 'error'
  errorMessage: string
}

// HTTP 请求选项接口
interface IpGeoHttpOptions {
  method: http.RequestMethod
  connectTimeout: number
  readTimeout: number
}

// API 响应接口
interface IpApiResult {
  ip: string
  country: string
  prov: string
  city: string
  district: string
  isp: string
  lat: number
  lng: number
  timezone: string
}

// API 简化响应
interface IpSimpleResult {
  ip: string
  country: string
  prov: string
  city: string
  district: string
  isp: string
}

export class IpGeoEngine {
  // 备用 API 列表
  private static readonly API_URLS: string[] = [
    'http://ip-api.com/json/',
    'https://ipinfo.io/json',
  ]

  // 国内 API（支持中文）
  private static readonly CN_API_URL: string = 'http://whois.pconline.com.cn/ipJson.jsp?ip='

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
   * 查询当前设备公网 IP
   */
  async queryMyIp(): Promise<string> {
    try {
      const req = http.createHttp()
      const options: IpGeoHttpOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000,
      }

      const ipStr: string = await new Promise<string>((resolve: (v: string) => void, reject: (e: Error) => void) => {
        req.request(
          'https://api.ipify.org?format=json',
          options,
          (err: BusinessError, resp: http.HttpResponse): void => {
            req.destroy()
            if (err) {
              reject(new Error(err.message))
              return
            }
            try {
              const resultStr: string = resp.result as string
              const jsonObj: Record<string, string> = JSON.parse(resultStr) as Record<string, string>
              resolve(jsonObj['ip'] || '')
            } catch (e2) {
              reject(new Error('JSON解析失败'))
            }
          }
        )
        setTimeout((): void => reject(new Error('超时')), 6000)
      })

      return ipStr
    } catch (e) {
      return ''
    }
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
      // 优先使用 ip-api.com
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
   * 使用 ip-api.com 查询
   */
  private async queryFromIpApi(ip: string, startTime: number): Promise<IpGeoResult> {
    try {
      const req = http.createHttp()
      const options: IpGeoHttpOptions = {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000,
      }

      const result: IpGeoResult = await new Promise<IpGeoResult>((resolve: (v: IpGeoResult) => void, reject: (e: Error) => void) => {
        req.request(
          'http://ip-api.com/json/' + ip + '?lang=zh-CN',
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
              const status: string = data['status'] || 'fail'

              if (status === 'success') {
                const geoResult: IpGeoResult = {
                  ip: data['query'] || ip,
                  country: data['country'] || '',
                  province: data['regionName'] || '',
                  city: data['city'] || '',
                  isp: data['isp'] || '',
                  district: '',
                  latitude: parseFloat(data['lat'] || '0'),
                  longitude: parseFloat(data['lon'] || '0'),
                  timezone: data['timezone'] || '',
                  queryTime: Date.now() - startTime,
                  status: 'success',
                  errorMessage: '',
                }
                resolve(geoResult)
              } else {
                const errMsg: string = data['message'] || '查询失败'
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

      const result: IpGeoResult = await new Promise<IpGeoResult>((resolve: (v: IpGeoResult) => void, reject: (e: Error) => void) => {
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

              // 解析 "城市, 省份, 国家" 格式
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
