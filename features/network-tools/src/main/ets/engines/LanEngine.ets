// 局域网扫描引擎
// 三策略探测：mDNS 服务发现（主） + NetBIOS 广播 + TCP 端口连接
// 适配 @kit.NetworkKit API

import { hilog } from '@kit.PerformanceAnalysisKit'
import { http, connection, mdns, socket } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import {
  LanDevice, LanScanCallbacks, LanNetworkInfo
} from '../models/ToolModels'
import { NetworkTimeout, ScanConcurrency, NetworkPort } from '@wifi-analyzer/core'

// 内部接口
interface AddressConfig {
  address: string
  port?: number
  family?: number
}

interface UdpMessageValue {
  message: ArrayBuffer
  remoteInfo: socket.SocketRemoteInfo
}

interface UdpSendOptions {
  data: ArrayBuffer
  address: AddressConfig
}

// 端口特征映射
const PORT_SIG = new Map<number, string>([
  [22, 'SSH/服务器'], [23, 'Telnet/路由'], [80, 'HTTP/Web'],
  [139, 'NetBIOS/Win'], [443, 'HTTPS/Web'], [445, 'SMB/Win共享'],
  [548, 'AFP/Mac'], [1900, 'UPnP/智能设备'], [5353, 'mDNS/Bonjour'],
  [5900, 'VNC/远程桌面'], [6379, 'Redis/服务器'], [7547, 'TR-069/光猫'],
  [7681, 'HarmonyOS'], [8080, 'HTTP-Alt/Web'], [8443, 'HTTPS-Alt'], [9100, '打印机'],
])

function deviceHint(port: number): string {
  return PORT_SIG.get(port) || ''
}

const MDNS_SERVICES: string[] = [
  '_http._tcp', '_https._tcp', '_ipp._tcp', '_printer._tcp',
  '_smb._tcp', '_airplay._tcp', '_raop._tcp', '_hap._tcp',
  '_companion-link._tcp',
]

const MDNS_DEVICE_MAP: Record<string, string> = {
  '_http._tcp': 'HTTP/Web服务器',
  '_https._tcp': 'HTTPS/Web服务器',
  '_ipp._tcp': '打印机(IPP)',
  '_printer._tcp': '打印机',
  '_smb._tcp': '文件共享(SMB)',
  '_airplay._tcp': 'Apple AirPlay/AppleTV',
  '_raop._tcp': 'AirPlay音频',
  '_hap._tcp': 'HomeKit/智能家居',
  '_companion-link._tcp': '手机/投屏设备',
}

function mdnsDeviceHint(serviceType: string): string {
  return MDNS_DEVICE_MAP[serviceType] || 'mDNS设备'
}

export class LanEngine {
  private abortController: boolean = false
  private cachedNetworkInfo: LanNetworkInfo | null = null
  private discoveryServices: mdns.DiscoveryService[] = []
  private mdnsFoundIps: Set<string> = new Set<string>()

  // ==================== 网络信息检测 ====================

  async detectNetworkInfo(): Promise<LanNetworkInfo> {
    if (this.cachedNetworkInfo) return this.cachedNetworkInfo

    try {
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (!netHandle) {
        return this.fallback()
      }

      const info: LanNetworkInfo = await new Promise<LanNetworkInfo>(
        (resolve: (v: LanNetworkInfo) => void) => {
          connection.getConnectionProperties(
            netHandle,
            (err: BusinessError, data: connection.ConnectionProperties): void => {
              if (err || !data) {
                resolve(this.fallback())
                return
              }

              let localIp: string = ''
              let netPrefix: string = ''

              if (data.linkAddresses && data.linkAddresses.length > 0) {
                localIp = data.linkAddresses[0].address.address || ''
                if (localIp.length > 0) {
                  const parts: string[] = localIp.split('.')
                  if (parts.length === 4) {
                    netPrefix = parts[0] + '.' + parts[1] + '.' + parts[2]
                  }
                }
              }

              let gwFromRoute: string = ''
              if (data.routes && data.routes.length > 0) {
                for (let r = 0; r < data.routes.length; r++) {
                  const route = data.routes[r]
                  if (route.gateway !== undefined &&
                    route.gateway.address !== undefined &&
                    route.gateway.address !== '0.0.0.0') {
                    gwFromRoute = route.gateway.address
                    if (route.isDefaultRoute === true) break
                  }
                }
              }

              let gwIp: string = gwFromRoute
              if (!gwIp || gwIp === '0.0.0.0') {
                if (localIp.length > 0 && localIp !== '0.0.0.0') {
                  gwIp = netPrefix + '.1'
                } else {
                  gwIp = '192.168.1.1'
                }
              }

              const result: LanNetworkInfo = {
                localIp: localIp,
                gateway: gwIp,
                subnetMask: '255.255.255.0',
                networkPrefix: netPrefix,
                hostCount: 254
              }
              resolve(result)
            }
          )
        }
      )

      this.cachedNetworkInfo = info
      return info
    } catch (e) {
      return this.fallback()
    }
  }

  private fallback(): LanNetworkInfo {
    const info: LanNetworkInfo = {
      localIp: '',
      gateway: '192.168.1.1',
      subnetMask: '255.255.255.0',
      networkPrefix: '192.168.1',
      hostCount: 254
    }
    return info
  }

  // ==================== TCP 端口探测 ====================

  private tcpConnect(ip: string, port: number, timeout: number): Promise<boolean> {
    return new Promise<boolean>((resolve: (v: boolean) => void) => {
      let done: boolean = false
      const timer: number = setTimeout((): void => {
        if (!done) {
          done = true
          resolve(false)
        }
      }, timeout)

      try {
        const tcp = socket.constructTCPSocketInstance()
        if (!tcp) {
          if (!done) { done = true; clearTimeout(timer); resolve(false) }
          return
        }

        tcp.connect({
          address: { address: ip, port: port }
        }, (err: BusinessError): void => {
          if (!done) {
            done = true
            clearTimeout(timer)
            try { tcp.close() } catch (_e) { /* ignore */ }
            resolve(!err)
          }
        })

        // 超时保险
        setTimeout((): void => {
          if (!done) {
            done = true
            clearTimeout(timer)
          }
          try { tcp.close(() => {}) } catch (_e) { /* ignore */ }
        }, timeout + NetworkTimeout.LAN_TCP_OFFSET_MS)
      } catch (e) {
        if (!done) { done = true; clearTimeout(timer); resolve(false) }
      }
    })
  }

  // ==================== NetBIOS 广播发现 ====================

  private buildNbnsQuery(): Uint8Array {
    const encodedName: string = 'CK' + 'CA'.repeat(14) + 'AA'
    const pkt: Uint8Array = new Uint8Array(50)
    pkt[0] = 0x82; pkt[1] = 0x28
    pkt[4] = 0x00; pkt[5] = 0x01
    pkt[12] = 0x20
    for (let i = 0; i < 32; i++) {
      pkt[13 + i] = encodedName.charCodeAt(i)
    }
    pkt[45] = 0x00
    pkt[46] = 0x00; pkt[47] = 0x21
    pkt[48] = 0x00; pkt[49] = 0x01
    return pkt
  }

  private parseNbnsHostname(data: ArrayBuffer): string {
    const buf: Uint8Array = new Uint8Array(data)
    if (buf.length < 57) return ''
    const nameCount: number = buf[56]
    if (nameCount < 1) return ''
    const endIdx: number = 57 + Math.min(15, buf.length - 57)
    let hostname: string = ''
    for (let i = 57; i < endIdx; i++) {
      if (buf[i] >= 32 && buf[i] < 127) {
        hostname += String.fromCharCode(buf[i])
      }
    }
    return hostname.trim()
  }

  private async netBiosDiscover(
    networkPrefix: string, callbacks: LanScanCallbacks
  ): Promise<LanDevice[]> {
    const devices: LanDevice[] = []
    const broadcastIp: string = networkPrefix + '.255'
    const queryPkt: Uint8Array = this.buildNbnsQuery()

    let udp: socket.UDPSocket | null = null

    try {
      udp = socket.constructUDPSocketInstance()
      const bindAddr: AddressConfig = { address: '0.0.0.0', port: 0, family: 1 }

      await new Promise<void>((resolveBind: () => void) => {
        udp!.bind(bindAddr, (_err: BusinessError): void => {
          resolveBind()
        })
      })

      const seenIps: Set<string> = new Set<string>()
      udp.on('message', (value: UdpMessageValue): void => {
        const respIp: string = value.remoteInfo && value.remoteInfo.address ? value.remoteInfo.address : ''
        if (!respIp || respIp === '127.0.0.1' || seenIps.has(respIp)) return
        seenIps.add(respIp)

        const hostname: string = this.parseNbnsHostname(value.message)
        const device: LanDevice = {
          ip: respIp, mac: '', hostname: hostname,
          status: 'online', vendor: 'Windows/NetBIOS', port: NetworkPort.NETBIOS_NS,
          latency: 0, firstSeen: Date.now(), lastSeen: Date.now(),
          probeMethod: 'netbios',
        }
        devices.push(device)
        callbacks.onDeviceFound(device)
      })

      try {
        const sendAddr: AddressConfig = { address: broadcastIp, port: NetworkPort.NETBIOS_NS, family: 1 }
        const sendOpts: UdpSendOptions = {
          data: queryPkt.buffer as ArrayBuffer,
          address: sendAddr
        }
        await udp.send(sendOpts)
      } catch (sendErr) {
        // NetBIOS 发送失败，忽略
      }

      await new Promise<void>((r: () => void) => { setTimeout(r, NetworkTimeout.NETBIOS_WAIT_MS) })
    } catch (e) {
      // NetBIOS 异常，忽略
    } finally {
      try { if (udp) udp.close() } catch (_e) { /* ignore */ }
    }

    return devices
  }

  // ==================== mDNS 服务发现 ====================

  startMdnsDiscovery(context: common.UIAbilityContext, callbacks: LanScanCallbacks): void {
    if (!context) {
      return
    }

    this.mdnsFoundIps.clear()

    for (let s = 0; s < MDNS_SERVICES.length; s++) {
      const serviceType: string = MDNS_SERVICES[s]
      const ds: mdns.DiscoveryService | null =
        mdns.createDiscoveryService(context, serviceType)

      if (!ds) {
        continue
      }

      ds.on('discoveryStart', (data: mdns.DiscoveryEventInfo): void => {
        // 发现启动
      })

      ds.on('discoveryStop', (data: mdns.DiscoveryEventInfo): void => {
        // 发现停止
      })

      ds.on('serviceFound', (data: mdns.LocalServiceInfo): void => {
        const rawPort: number = (data.port !== undefined && data.port > 0) ? data.port : 0

        mdns.resolveLocalService(context, data).then(
          (resolvedData: mdns.LocalServiceInfo): void => {
            const resolvedIp: string = resolvedData.host && resolvedData.host.address ? resolvedData.host.address : ''
            if (!resolvedIp || resolvedIp === '127.0.0.1' || resolvedIp === '::1') return
            if (this.mdnsFoundIps.has(resolvedIp)) return
            this.mdnsFoundIps.add(resolvedIp)

            const device: LanDevice = {
              ip: resolvedIp,
              mac: '',
              hostname: resolvedData.serviceName || data.serviceName || '',
              status: 'online',
              vendor: mdnsDeviceHint(serviceType),
              port: resolvedData.port || rawPort,
              latency: 0,
              firstSeen: Date.now(),
              lastSeen: Date.now(),
              probeMethod: 'mdns',
            }
            callbacks.onDeviceFound(device)
          }
        ).catch((err: BusinessError): void => {
          const fallbackIp: string = data.host && data.host.address ? data.host.address : ''
          if (fallbackIp && fallbackIp !== '127.0.0.1' && fallbackIp !== '::1') {
            if (this.mdnsFoundIps.has(fallbackIp)) return
            this.mdnsFoundIps.add(fallbackIp)
            const device: LanDevice = {
              ip: fallbackIp, mac: '',
              hostname: data.serviceName || '',
              status: 'online',
              vendor: mdnsDeviceHint(serviceType),
              port: rawPort, latency: 0,
              firstSeen: Date.now(), lastSeen: Date.now(),
              probeMethod: 'mdns',
            }
            callbacks.onDeviceFound(device)
          }
        })
      })

      ds.on('serviceLost', (data: mdns.LocalServiceInfo): void => {
        // 服务丢失
      })

      try {
        ds.startSearchingMDNS()
        this.discoveryServices.push(ds)
      } catch (e) {
        // mDNS 启动失败
      }
    }
  }

  stopMdnsDiscovery(): void {
    for (let d = 0; d < this.discoveryServices.length; d++) {
      try {
        const ds: mdns.DiscoveryService = this.discoveryServices[d]
        ds.stopSearchingMDNS()
        // 显式移除监听器，防止闭包引用泄漏
        ds.off('discoveryStart')
        ds.off('discoveryStop')
        ds.off('serviceFound')
        ds.off('serviceLost')
      } catch (e) {
        // ignore
      }
    }
    this.discoveryServices = []
    this.mdnsFoundIps.clear()
  }

  // ==================== 单 IP 探测 ====================

  private async probeSingle(
    ip: string, _ports: number[], timeout: number
  ): Promise<LanDevice | null> {
    const start: number = Date.now()

    const results: boolean[] = await Promise.all([
      this.tcpConnect(ip, NetworkPort.HTTP, timeout),
      this.tcpConnect(ip, NetworkPort.SMB, timeout)
    ])

    if (results[0]) {
      const device: LanDevice = {
        ip: ip, mac: '', hostname: '', status: 'online',
        vendor: deviceHint(NetworkPort.HTTP), port: NetworkPort.HTTP,
        latency: Date.now() - start,
        firstSeen: Date.now(), lastSeen: Date.now(),
        probeMethod: 'tcp',
      }
      return device
    }
    if (results[1]) {
      const device: LanDevice = {
        ip: ip, mac: '', hostname: '', status: 'online',
        vendor: deviceHint(NetworkPort.SMB), port: NetworkPort.SMB,
        latency: Date.now() - start,
        firstSeen: Date.now(), lastSeen: Date.now(),
        probeMethod: 'tcp',
      }
      return device
    }

    return null
  }

  // ==================== 网关探针 ====================

  private async probeGateway(gateway: string, timeout: number): Promise<boolean> {
    const gatewayPorts: number[] = [80, 443, 445, 22, 8080, 8443]
    for (let p = 0; p < gatewayPorts.length; p++) {
      const up: boolean = await this.tcpConnect(gateway, gatewayPorts[p], timeout)
      if (up) {
        return true
      }
    }
    return false
  }

  // ==================== 批量扫描 ====================

  async scan(callbacks: LanScanCallbacks): Promise<void> {
    this.abortController = false
    const devices: LanDevice[] = []

    const networkInfo: LanNetworkInfo = await this.detectNetworkInfo()
    const prefix: string = networkInfo.networkPrefix
    const gateway: string = networkInfo.gateway

    // 步骤 1：网关探针
    const gwOnline: boolean = await this.probeGateway(gateway, NetworkTimeout.LAN_GATEWAY_PROBE_MS)
    if (gwOnline) {
      const gwDevice: LanDevice = {
        ip: gateway, mac: '', hostname: '网关/路由器',
        status: 'online', vendor: '路由器(网关)',
        port: 0, latency: 0,
        firstSeen: Date.now(), lastSeen: Date.now(),
        probeMethod: 'tcp',
      }
      devices.push(gwDevice)
      callbacks.onDeviceFound(gwDevice)
    }

    // 步骤 2：NetBIOS 广播（并行发起）
    const netBiosPromise: Promise<LanDevice[]> =
      this.netBiosDiscover(prefix, callbacks)

    // 步骤 3：批量 TCP 扫描
    await this.scanTcpBatches(prefix, devices, callbacks)

    // 合并 NetBIOS 结果 + 排序
    this.mergeNetBiosDevices(await netBiosPromise, devices)
    devices.sort((a: LanDevice, b: LanDevice): number =>
      this.ipToNumber(a.ip) - this.ipToNumber(b.ip))

    callbacks.onComplete(devices)
  }

  // ---------- TCP 批量扫描 ----------
  private async scanTcpBatches(
    prefix: string, devices: LanDevice[], callbacks: LanScanCallbacks
  ): Promise<void> {
    const maxConcurrency: number = ScanConcurrency.LAN_BATCH
    const timeout: number = NetworkTimeout.LAN_TCP_DEFAULT_MS
    const scanPorts: number[] = [NetworkPort.HTTP, NetworkPort.SMB]
    const total: number = ScanConcurrency.LAN_HOST_COUNT

    for (let batchStart = 0; batchStart < total; batchStart += maxConcurrency) {
      if (this.abortController) {
        callbacks.onError('扫描已停止')
        return
      }

      const batchEnd: number = Math.min(batchStart + maxConcurrency, total)
      const batchPromises: Array<Promise<LanDevice | null>> = []

      for (let host = batchStart + 1; host <= batchEnd; host++) {
        const ip: string = prefix + '.' + String(host)
        callbacks.onProgress(host, total, ip)
        batchPromises.push(this.probeSingle(ip, scanPorts, timeout))
      }

      const batchResults: Array<LanDevice | null> =
        await Promise.all(batchPromises)

      for (let j = 0; j < batchResults.length; j++) {
        if (batchResults[j]) {
          devices.push(batchResults[j] as LanDevice)
          callbacks.onDeviceFound(batchResults[j] as LanDevice)
        }
      }
    }
  }

  // ---------- 合并 NetBIOS 结果 ----------
  private mergeNetBiosDevices(nbDevices: LanDevice[], devices: LanDevice[]): void {
    for (let i = 0; i < nbDevices.length; i++) {
      const nb: LanDevice = nbDevices[i]
      let duplicateFound: boolean = false
      for (let d = 0; d < devices.length; d++) {
        if (devices[d].ip === nb.ip) {
          duplicateFound = true
          break
        }
      }
      if (!duplicateFound) {
        devices.push(nb)
      }
    }
  }

  // ==================== 控制 ====================

  stopScan(): void {
    this.abortController = true
  }

  // ==================== 工具 ====================

  private ipToNumber(ip: string): number {
    const octets: string[] = ip.split('.')
    if (octets.length !== 4) return 0
    return ((parseInt(octets[0], 10) << 24) |
      (parseInt(octets[1], 10) << 16) |
      (parseInt(octets[2], 10) << 8) |
      parseInt(octets[3], 10)) >>> 0
  }

  static isGateway(ip: string, gateway: string): boolean {
    return ip === gateway
  }

  static isLocalHost(ip: string, localIp: string): boolean {
    return ip === localIp || ip === '127.0.0.1'
  }

  static guessDeviceType(device: LanDevice): string {
    if (device.vendor.indexOf('路由') >= 0 || device.vendor.indexOf('光猫') >= 0) return 'router'
    if (device.vendor.indexOf('SSH') >= 0) return 'server'
    if (device.vendor.indexOf('Win') >= 0 || device.vendor.indexOf('SMB') >= 0 ||
      device.vendor.indexOf('Mac') >= 0) return 'computer'
    if (device.vendor.indexOf('HarmonyOS') >= 0 || device.port === 7681) return 'phone'
    if (device.vendor.indexOf('打印机') >= 0) return 'printer'
    if (device.vendor.indexOf('UPnP') >= 0 || device.vendor.indexOf('mDNS') >= 0) return 'iot'
    if (device.port === 80 || device.port === 443 || device.port === 8080) return 'server'
    return 'device'
  }
}
