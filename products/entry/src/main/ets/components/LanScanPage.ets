// LanScanPage — 从 ToolPages.ets 拆分
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveTextCyan,
  adaptiveCardBg, adaptiveCardDarkGlass, adaptiveBorderCyan,
  adaptiveBackgroundList, adaptiveBtnBg, adaptivePrimaryBg,
  adaptiveSuccess, adaptiveDanger, adaptiveInfo,
  RADIUS_MD
} from '@wifi-analyzer/design-system';
import { RouterManager, NetworkTimeout, ScanConcurrency } from '@wifi-analyzer/core';
import socket from '@ohos.net.socket';
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { readArpTable, lookupVendor, NUD_REACHABLE, NativePing } from 'native-ping';

const TAG = '[LanScanPage]'

interface LanDeviceEntry { name: string; ip: string; mac: string; status: string; color: string }
interface ProbeHit { ip: string; port: number }

@Builder
export function LanScanPageBuilder() { NavDestination() { LanScanPage() }.title($r('app.string.tool_lan')).hideTitleBar(true) }

@Component
export struct LanScanPage {
  @StorageLink('isDarkMode') isDark: boolean = false
  @State subnet: string = ''
  @State devices: LanDeviceEntry[] = []
  @State isScanning: boolean = false
  @State statusText: string = ''
  @State hasScanned: boolean = false
  private stopScan: boolean = false

  private resStr(name: string): string { try { return getContext().resourceManager.getStringByNameSync(name) } catch (_e) { return name } }

  aboutToAppear(): void {
    try {
      const netHandle = connection.getDefaultNetSync()
      if (!netHandle) return
      const props = connection.getConnectionPropertiesSync(netHandle)
      if (props && props.linkAddresses && props.linkAddresses.length > 0) {
        const ip = props.linkAddresses[0].address.address
        if (ip) { const parts = ip.split('.'); if (parts.length === 4) this.subnet = parts[0] + '.' + parts[1] + '.' + parts[2] + '.0/24' }
      }
    } catch (_e) { this.subnet = '192.168.1.0/24' }
  }

  aboutToDisappear(): void {
    // 离开页面时停止扫描，防止异步回调访问已销毁状态
    this.stopScan = true
    this.isScanning = false
  }

  private async startScan(): Promise<void> {
    if (this.isScanning) return
    this.isScanning = true; this.stopScan = false; this.devices = []; this.hasScanned = false

    await this.scanArpTable()
    if (!this.stopScan) {
      await this.scanWithTcp()
    }

    this.isScanning = false; this.hasScanned = true
    this.statusText = this.devices.length > 0 ? 'Found ' + String(this.devices.length) + ' devices' : 'No devices found'
  }

  // ========== ARP 表扫描 ==========
  private async scanArpTable(): Promise<void> {
    this.statusText = 'ARP scanning...'
    let arpCount: number = 0
    try {
      const arpResult = await readArpTable()
      if (!this.stopScan && arpResult.error === 0 && arpResult.entryCount > 0) {
        for (const e of arpResult.entries) {
          const vendor: string = lookupVendor(e.mac)
          this.devices.push({
            name: vendor || 'Unknown Device', ip: e.ip, mac: e.mac,
            status: (e.state & NUD_REACHABLE) !== 0 ? 'Online' : 'Offline',
            color: (e.state & NUD_REACHABLE) !== 0 ? adaptiveInfo(this.isDark) : adaptiveTextTertiary(this.isDark)
          })
          arpCount++
        }
        this.statusText = 'ARP found ' + String(arpCount) + ' devices'
      }
    } catch (e) { hilog.warn(0x0000, TAG, 'ARP scan error: %{public}s', JSON.stringify(e)) }
  }

  // ========== TCP 端口探测 ==========
  private async scanWithTcp(): Promise<void> {
    this.statusText = 'Probing network...'
    const parts: string[] = this.subnet.split('.')
    const prefix: string = parts.length >= 3 ? parts[0] + '.' + parts[1] + '.' + parts[2] : '192.168.1'
    const hosts: number[] = []; for (let h = 1; h <= 254; h++) hosts.push(h)
    const COMMON_PORTS: number[] = [80, 443, 22, 23, 8080]
    const BATCH: number = ScanConcurrency.LAN_TCP_BATCH

    for (let b = 0; b < hosts.length && !this.stopScan; b += BATCH) {
      const batch: number[] = hosts.slice(b, b + BATCH)
      const results: (ProbeHit | null)[] = await Promise.all(batch.map((h: number): Promise<ProbeHit | null> => {
        const ip: string = prefix + '.' + String(h)
        if (this.devices.some((d: LanDeviceEntry): boolean => d.ip === ip)) return Promise.resolve<ProbeHit | null>(null)
        return new Promise<ProbeHit | null>(async (resolve: (v: ProbeHit | null) => void) => {
          try { const ping = await NativePing.probe(ip); if (ping.minRtt >= 0) { resolve({ ip, port: 0 }); return } } catch (e) {}
          for (let p = 0; p < COMMON_PORTS.length; p++) {
            if (this.stopScan) { resolve(null); return }
            try {
              const ok: boolean = await new Promise<boolean>((r: (v: boolean) => void) => {
                const tcp = socket.constructTCPSocketInstance()
                const t = setTimeout(() => { try { tcp.close(() => {}) } catch (_e) {}; r(false) }, NetworkTimeout.LAN_HOST_SETTIMEOUT_MS)
                tcp.connect({ address: { address: ip, port: COMMON_PORTS[p] }, timeout: NetworkTimeout.LAN_HOST_PROBE_MS }, (err: BusinessError) => { clearTimeout(t); tcp.close(() => {}); r(!err) })
              })
              if (ok) { resolve({ ip, port: COMMON_PORTS[p] }); return }
            } catch (e) {}
          }
          resolve(null)
        })
      }))
      for (let i = 0; i < results.length && !this.stopScan; i++) {
        const hit = results[i]
        if (hit) {
          const svc = hit.port === 80 ? 'HTTP' : hit.port === 443 ? 'HTTPS' : hit.port === 22 ? 'SSH' : hit.port === 23 ? 'Telnet' : 'Web'
          this.devices.push({ name: svc + ' Service', ip: hit.ip, mac: '', status: 'Online', color: adaptiveInfo(this.isDark) })
        }
      }
      this.statusText = 'Scanning ' + String(Math.min(b + BATCH, 254)) + '/254'
    }
  }

  private stopScanAction(): void { this.stopScan = true; this.isScanning = false; this.statusText = this.resStr('lan_stopped_label'); setTimeout(() => { this.statusText = '' }, NetworkTimeout.LATENCY_PROBE_MS) }

  build() {
    Stack() {
      Circle().width(300).height(300).fill(this.isDark ? 'rgba(59,130,246,0.06)' : 'rgba(59,130,246,0.04)').position({ x: -80, y: -80 })
      Circle().width(200).height(200).fill(this.isDark ? 'rgba(59,130,246,0.04)' : 'rgba(59,130,246,0.03)').position({ x: '70%', y: '50%' })
      Column() {
        Row({ space: 16 }) {
          Row() { Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark)) }.width(36).height(36).justifyContent(FlexAlign.Center).borderRadius(8).backgroundColor(adaptiveBtnBg(this.isDark)).onClick(() => { RouterManager.goBack() })
          Text($r('app.string.tool_lan')).fontSize(20).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
        }.width('100%').padding({ left: 20, right: 20, top: 44, bottom: 8 })
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                TextInput({ text: $$this.subnet, placeholder: $r('app.string.lan_subnet_placeholder') }).fontColor(adaptiveTextPrimary(this.isDark)).placeholderColor(adaptiveTextTertiary(this.isDark)).fontSize(14).layoutWeight(1).height(42).backgroundColor(adaptiveBtnBg(this.isDark)).borderRadius(8).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).padding({ left: 14 })
                if (!this.isScanning) { Row() { Text('▶').fontSize(14).fontColor(Color.White) }.width(42).height(42).justifyContent(FlexAlign.Center).linearGradient({ angle: 135, colors: [['rgba(49,122,247,0.15)', 0], ['rgba(49,122,247,0.40)', 1]] }).borderRadius(8).onClick(() => { this.startScan() }) }
                else { Row() { Text('■').fontSize(12).fontColor(Color.White) }.width(42).height(42).justifyContent(FlexAlign.Center).linearGradient({ angle: 135, colors: [['rgba(217,72,56,0.15)', 0], ['rgba(217,72,56,0.40)', 1]] }).borderRadius(8).onClick(() => { this.stopScanAction() }) }
              }
            }.width('100%').padding(16).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)

            if (this.statusText !== '') { Text(this.statusText).fontSize(11).fontColor(adaptiveInfo(this.isDark)).width('100%') }

            if (this.devices.length > 0) {
              Text(this.resStr('lan_device_count') + ' (' + String(this.devices.length) + ')').fontSize(11).fontWeight(700).fontColor(adaptiveTextCyan(this.isDark)).width('100%')
              ForEach(this.devices, (d: LanDeviceEntry) => {
                Row({ space: 12 }) {
                  Row() { Rect({ width: 14, height: 12 }).radius(2).fill('none').stroke(adaptiveTextCyan(this.isDark)).strokeWidth(1.5) }.width(32).height(32).justifyContent(FlexAlign.Center).borderRadius(8).backgroundColor(adaptivePrimaryBg(this.isDark))
                  Column({ space: 2 }) { Text(d.name).fontSize(13).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark)); Text(d.ip).fontSize(10).fontColor(adaptiveTextTertiary(this.isDark)) }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  Text(d.status).fontSize(10).fontWeight(600).fontColor(adaptiveSuccess(this.isDark))
                }.width('100%').padding(14).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).borderRadius(10)
              })
            } else if (!this.isScanning && !this.hasScanned) {
              Text($r('app.string.lan_scan_hint')).fontSize(12).fontColor(adaptiveTextTertiary(this.isDark)).width('100%').textAlign(TextAlign.Center).padding({ top: 24, bottom: 24 })
            }
          }.padding({ left: 20, right: 20, top: 8, bottom: 20 })
        }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off)
      }.width('100%').height('100%')
    }.width('100%').height('100%').linearGradient({ angle: 180, colors: adaptiveBackgroundList(this.isDark) })
  }
}
