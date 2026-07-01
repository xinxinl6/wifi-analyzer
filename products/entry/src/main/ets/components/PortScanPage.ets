// PortScanPage — 从 ToolPages.ets 拆分
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveTextCyan, adaptiveTextAmber,
  adaptiveCardBg, adaptiveCardDarkGlass, adaptiveBorderCyan,
  adaptiveBackgroundList, adaptiveBtnBg, adaptivePrimaryBg,
  adaptiveSuccess, adaptiveDanger, adaptiveInfo,
  RADIUS_MD
} from '@wifi-analyzer/design-system';
import { RouterManager, NetworkTimeout, ScanConcurrency } from '@wifi-analyzer/core';
import socket from '@ohos.net.socket';
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = '[PortScanPage]'

interface PortResult { port: number; service: string; state: string; color: string }
interface ProbeResult { port: number; ok: boolean }

const PORT_SVC: Record<string, string> = {
  '21': 'FTP', '22': 'SSH', '23': 'Telnet', '25': 'SMTP', '53': 'DNS',
  '80': 'HTTP', '110': 'POP3', '135': 'RPC', '139': 'NetBIOS',
  '143': 'IMAP', '443': 'HTTPS', '445': 'SMB', '993': 'IMAPS',
  '995': 'POP3S', '1433': 'MSSQL', '1521': 'Oracle', '3306': 'MySQL',
  '3389': 'RDP', '5432': 'PostgreSQL', '5900': 'VNC', '6379': 'Redis',
  '8080': 'HTTP-Alt', '8443': 'HTTPS-Alt', '9090': 'Web Admin', '27017': 'MongoDB',
}

function buildPortList(mode: string): number[] {
  if (mode === 'common') {
    const keys: string[] = Object.keys(PORT_SVC)
    const nums: number[] = []
    for (let i = 0; i < keys.length; i++) nums.push(Number(keys[i]))
    nums.sort((a: number, b: number): number => a - b)
    return nums
  }
  const list: number[] = []
  for (let i = 1; i <= 1024; i++) list.push(i)
  return list
}

function probePort(target: string, port: number, timeout: number): Promise<ProbeResult> {
  return new Promise<ProbeResult>((resolve: (v: ProbeResult) => void) => {
    const tcp = socket.constructTCPSocketInstance()
    const t: number = setTimeout((): void => { try { tcp.close(() => {}) } catch (_e) {}; resolve({ port, ok: false }) }, timeout + NetworkTimeout.PORT_SCAN_OFFSET_MS)
    tcp.connect({ address: { address: target, port }, timeout }, (err: BusinessError) => {
      clearTimeout(t); try { tcp.close(() => {}) } catch (_e) {}; resolve({ port, ok: !err })
    })
  })
}

@Builder
export function PortScanPageBuilder() { NavDestination() { PortScanPage() }.title($r('app.string.tool_portscan')).hideTitleBar(true) }

@Component
export struct PortScanPage {
  @StorageLink('isDarkMode') isDark: boolean = false
  @State ip: string = ''
  @State ports: PortResult[] = []
  @State isScanning: boolean = false
  @State statusText: string = ''
  @State mode: string = 'common'
  private stopFlag: boolean = false

  aboutToAppear(): void {
    try {
      const netHandle = connection.getDefaultNetSync()
      if (!netHandle) return
      const props = connection.getConnectionPropertiesSync(netHandle)
      if (props && props.linkAddresses && props.linkAddresses.length > 0) {
        const ip = props.linkAddresses[0].address.address
        if (ip) this.ip = ip
      }
    } catch (_e) { this.ip = '192.168.1.1' }
  }

  aboutToDisappear(): void {
    // 离开页面时停止端口扫描
    this.stopFlag = true
    this.isScanning = false
  }

  private res(name: string): string { try { return getContext().resourceManager.getStringByNameSync(name) } catch (_e) { return name } }

  private async startScan(): Promise<void> {
    if (this.isScanning) return
    const target: string = this.ip.trim()
    if (!target) return
    this.isScanning = true; this.stopFlag = false; this.ports = []
    this.statusText = this.res('scanning')
    const portList: number[] = buildPortList(this.mode)
    const timeout: number = this.mode === 'common' ? NetworkTimeout.LAN_TCP_DEFAULT_MS : NetworkTimeout.LAN_HOST_SETTIMEOUT_MS
    let openCount: number = 0
    const BATCH: number = ScanConcurrency.PORT_SCAN_BATCH
    for (let b = 0; b < portList.length && !this.stopFlag; b += BATCH) {
      const batch: number[] = portList.slice(b, b + BATCH)
      const results: ProbeResult[] = await Promise.all(batch.map(p => probePort(target, p, timeout)))
      for (let i = 0; i < results.length; i++) {
        if (results[i].ok) {
          this.ports.push({ port: results[i].port, service: PORT_SVC[String(results[i].port)] || String(results[i].port), state: this.res('port_open_status'), color: adaptiveSuccess(this.isDark) })
          openCount++
        }
      }
      this.statusText = this.res('port_scan_progress') + ' ' + String(Math.min(b + BATCH, portList.length)) + '/' + String(portList.length) + ' · ' + this.res('port_scan_open_label') + ' ' + String(openCount)
    }
    this.isScanning = false
  }

  build() {
    Stack() {
      Circle().width(300).height(300).fill(this.isDark ? 'rgba(59,130,246,0.06)' : 'rgba(59,130,246,0.04)').position({ x: -80, y: -80 })
      Circle().width(200).height(200).fill(this.isDark ? 'rgba(59,130,246,0.04)' : 'rgba(59,130,246,0.03)').position({ x: '70%', y: '50%' })
      Column() {
        Row({ space: 16 }) {
          Row() { Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark)) }.width(36).height(36).justifyContent(FlexAlign.Center).borderRadius(8).backgroundColor(adaptiveBtnBg(this.isDark)).onClick(() => { RouterManager.goBack() })
          Text($r('app.string.tool_portscan')).fontSize(20).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
          Blank()
          if (!this.isScanning) {
            Row() { Text(this.mode === 'common' ? $r('app.string.scan_mode_full') : $r('app.string.scan_mode_common')).fontSize(10).fontWeight(600).fontColor(adaptiveTextCyan(this.isDark)) }
              .padding({ left: 8, right: 8, top: 3, bottom: 3 }).backgroundColor(this.isDark ? 'rgba(59,130,246,0.12)' : 'rgba(59,130,246,0.08)').borderRadius(4)
              .onClick(() => { this.mode = this.mode === 'common' ? 'full' : 'common' })
          }
        }.width('100%').padding({ left: 20, right: 20, top: 44, bottom: 8 })
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                TextInput({ text: $$this.ip, placeholder: $r('app.string.ip_address') }).fontColor(adaptiveTextPrimary(this.isDark)).placeholderColor(adaptiveTextTertiary(this.isDark)).fontSize(14).layoutWeight(1).height(42).backgroundColor(adaptiveBtnBg(this.isDark)).borderRadius(8).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).padding({ left: 14 })
                if (!this.isScanning) {
                  Row() { Text('▶').fontSize(14).fontColor(Color.White) }.width(42).height(42).justifyContent(FlexAlign.Center).linearGradient({ angle: 135, colors: [['rgba(219,107,66,0.15)', 0], ['rgba(219,107,66,0.45)', 1]] }).borderRadius(8).onClick(() => { this.startScan() })
                } else {
                  Row() { Text('■').fontSize(12).fontColor(Color.White) }.width(42).height(42).justifyContent(FlexAlign.Center).linearGradient({ angle: 135, colors: [['rgba(217,72,56,0.15)', 0], ['rgba(217,72,56,0.40)', 1]] }).borderRadius(8).onClick(() => { this.stopFlag = true; this.isScanning = false })
                }
              }
              Row({ space: 6 }) { this.chip(this.mode === 'common' ? $r('app.string.scan_common_ports') : $r('app.string.scan_range_all')) }
            }.width('100%').padding(16).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)

            if (this.statusText !== '') {
              Row({ space: 6 }) { if (this.isScanning) Circle().width(7).height(7).fill(adaptiveInfo(this.isDark)).opacity(0.8); Text(this.statusText).fontSize(12).fontColor(adaptiveInfo(this.isDark)) }.width('100%')
            }

            if (this.ports.length > 0) {
              Text(this.res('open_ports_label') + ' (' + String(this.ports.length) + ')').fontSize(11).fontWeight(700).fontColor(adaptiveTextCyan(this.isDark)).width('100%')
              ForEach(this.ports, (p: PortResult) => {
                Row({ space: 10 }) {
                  Text(String(p.port)).fontSize(13).fontWeight(800).fontColor(adaptiveTextCyan(this.isDark)).width(50)
                  Text(p.service).fontSize(12).fontWeight(600).fontColor(adaptiveTextPrimary(this.isDark)).layoutWeight(1)
                  Text(p.state).fontSize(10).fontWeight(700).fontColor(p.color).padding({ left: 8, right: 8, top: 3, bottom: 3 }).backgroundColor(p.color === adaptiveTextAmber(this.isDark) ? 'rgba(219,107,66,0.10)' : 'rgba(91,168,84,0.12)').borderRadius(4)
                }.width('100%').padding(12).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).borderRadius(10)
              })
            } else if (!this.isScanning && this.statusText !== '') {
              Text($r('app.string.no_open_ports')).fontSize(12).fontColor(adaptiveTextTertiary(this.isDark)).width('100%').textAlign(TextAlign.Center).padding({ top: 12, bottom: 12 })
            }
          }.padding({ left: 20, right: 20, top: 8, bottom: 20 })
        }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off)
      }.width('100%').height('100%')
    }.width('100%').height('100%').linearGradient({ angle: 180, colors: adaptiveBackgroundList(this.isDark) })
  }

  @Builder chip(text: ResourceStr) {
    Row() { Text(text).fontSize(11).fontWeight(600).fontColor(adaptiveTextSecondary(this.isDark)) }.padding({ left: 12, right: 12, top: 5, bottom: 5 }).backgroundColor(adaptivePrimaryBg(this.isDark)).borderRadius(6)
  }
}
