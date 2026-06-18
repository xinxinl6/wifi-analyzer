// 端口扫描引擎
// 使用 HTTP 请求探测端口状态

import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { PortScanResult, PortScanCallbacks, PortPreset } from '../models/ToolModels'

// HTTP 请求选项接口（内部使用）
interface PortHttpOptions {
  method: http.RequestMethod
  connectTimeout: number
  readTimeout: number
}

export class PortScanEngine {
  // 端口预设方案
  static readonly PRESETS: PortPreset[] = [
    {
      name: '常用端口',
      description: '常见服务端口（20个）',
      ports: [21, 22, 23, 25, 53, 80, 110, 143, 443, 445, 993, 995, 1433, 3306, 3389, 5432, 5900, 6379, 8080, 8443],
    },
    {
      name: 'Web端口',
      description: 'HTTP/HTTPS 服务',
      ports: [80, 443, 8000, 8008, 8080, 8443, 8888, 9000, 9090, 3000, 5000],
    },
    {
      name: '数据库端口',
      description: '常见数据库服务',
      ports: [1433, 1521, 2181, 3306, 3389, 5432, 5900, 6379, 7001, 9200, 9300, 27017],
    },
    {
      name: '远程管理',
      description: 'SSH/RDP/Telnet',
      ports: [22, 23, 3389, 5900, 5901, 5902, 623, 4443, 4444],
    },
    {
      name: '全部扫描',
      description: 'Top 50 常见端口',
      ports: [21, 22, 23, 25, 53, 67, 68, 69, 80, 110, 119, 123, 135, 137, 138, 139, 143, 161, 162, 179,
        194, 389, 443, 445, 465, 514, 548, 587, 636, 873, 993, 995, 1433, 1521, 1702, 1723, 1863, 2049,
        3306, 3389, 5432, 5900, 6379, 8000, 8080, 8443, 8888, 9900, 27017],
    },
  ]

  // 端口号对应服务名
  private static readonly SERVICE_MAP: Record<string, string> = {
    '21': 'FTP', '22': 'SSH', '23': 'Telnet', '25': 'SMTP', '53': 'DNS',
    '67': 'DHCP', '68': 'DHCP', '69': 'TFTP', '80': 'HTTP', '110': 'POP3',
    '119': 'NNTP', '123': 'NTP', '135': 'RPC', '137': 'NetBIOS', '138': 'NetBIOS',
    '139': 'NetBIOS', '143': 'IMAP', '161': 'SNMP', '162': 'SNMP', '179': 'BGP',
    '194': 'IRC', '389': 'LDAP', '443': 'HTTPS', '445': 'SMB', '465': 'SMTPS',
    '514': 'Syslog', '548': 'AFP', '587': 'SMTP', '636': 'LDAPS', '873': 'Rsync',
    '993': 'IMAPS', '995': 'POP3S', '1433': 'MSSQL', '1521': 'Oracle', '1702': 'L2TP',
    '1723': 'PPTP', '1863': 'MSN', '2049': 'NFS', '3306': 'MySQL', '3389': 'RDP',
    '5432': 'PostgreSQL', '5900': 'VNC', '5901': 'VNC', '5902': 'VNC',
    '6379': 'Redis', '8000': 'HTTP-Alt', '8080': 'HTTP-Proxy', '8443': 'HTTPS-Alt',
    '8888': 'HTTP-Alt', '9090': 'Prometheus', '9200': 'Elasticsearch',
    '9300': 'ES-Transport', '9900': 'VNC', '27017': 'MongoDB', '3000': 'Dev-Server',
    '5000': 'Dev-Server',
  }

  // 扫描控制
  private abortController: boolean = false

  /**
   * 获取端口服务名
   */
  static getServiceName(port: number): string {
    const name: string | undefined = PortScanEngine.SERVICE_MAP[String(port)]
    return name || 'Unknown'
  }

  /**
   * 获取默认预设端口列表
   */
  static getDefaultPorts(): number[] {
    const ports: number[] = []
    const defaultPorts: number[] = PortScanEngine.PRESETS[0].ports
    for (let i = 0; i < defaultPorts.length; i++) {
      ports.push(defaultPorts[i])
    }
    return ports
  }

  /**
   * 停止扫描
   */
  stopScan(): void {
    this.abortController = true
  }

  /**
   * 探测单个端口
   */
  private async probePort(address: string, port: number, timeout: number): Promise<PortScanResult> {
    const startTime: number = Date.now()
    const service: string = PortScanEngine.getServiceName(port)
    const url: string = 'http://' + address + ':' + String(port)

    try {
      const req = http.createHttp()
      const options: PortHttpOptions = {
        method: http.RequestMethod.HEAD,
        connectTimeout: timeout,
        readTimeout: timeout,
      }

      let timeoutTimerId: number = -1

      await new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
        req.request(
          url,
          options,
          (err: BusinessError, resp: http.HttpResponse): void => {
            if (timeoutTimerId >= 0) {
              clearTimeout(timeoutTimerId)
              timeoutTimerId = -1
            }
            req.destroy()
            if (err) {
              const errCode: number = err.code || 0
              if (errCode === 61 || errCode === 111) {
                reject(new Error('closed'))
              } else if (errCode === 60 || errCode === 10060 || errCode === -1) {
                reject(new Error('timeout'))
              } else {
                resolve()
              }
            } else {
              resolve()
            }
          }
        )
        timeoutTimerId = setTimeout((): void => {
          req.destroy()
          reject(new Error('timeout'))
        }, timeout + 500)
      })

      const result: PortScanResult = {
        port: port,
        status: 'open',
        service: service,
        latency: Date.now() - startTime,
      }
      return result
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      let status: 'open' | 'closed' | 'filtered' | 'error' = 'closed'
      if (errorMsg === 'timeout') {
        status = 'filtered'
      } else if (errorMsg === 'closed') {
        status = 'closed'
      }

      const result: PortScanResult = {
        port: port,
        status: status,
        service: service,
        latency: Date.now() - startTime,
      }
      return result
    }
  }

  /**
   * 执行端口扫描（并行探测，控制并发数）
   */
  async scan(address: string, ports: number[], timeout: number, callbacks: PortScanCallbacks): Promise<void> {
    // 基础目标验证
    const trimmed: string = address.trim()
    if (trimmed.length === 0) {
      callbacks.onError('无效的目标地址')
      return
    }

    this.abortController = false
    const results: PortScanResult[] = []
    const total: number = ports.length
    const maxConcurrency: number = 20

    for (let batchStart = 0; batchStart < ports.length; batchStart += maxConcurrency) {
      if (this.abortController) {
        callbacks.onError('扫描已停止')
        return
      }

      const batchEnd: number = Math.min(batchStart + maxConcurrency, ports.length)
      const batchPorts: number[] = []
      for (let p = batchStart; p < batchEnd; p++) {
        batchPorts.push(ports[p])
      }

      const batchPromises: Array<Promise<PortScanResult>> = []
      for (let i = 0; i < batchPorts.length; i++) {
        batchPromises.push(this.probePort(address, batchPorts[i], timeout))
      }

      const batchResults: PortScanResult[] = await Promise.all(batchPromises)

      for (let j = 0; j < batchResults.length; j++) {
        const result: PortScanResult = batchResults[j]
        results.push(result)
        callbacks.onProgress(results.length, total, result.port)

        if (result.status === 'open') {
          callbacks.onPortFound(result)
        }
      }
    }

    callbacks.onComplete(results)
  }
}
