// PingPage — 双目标持续监测（独立子组件版）
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveTextCyan, adaptiveTextAmber,
  adaptiveCardBg, adaptiveCardDarkGlass, adaptiveBorderCyan,
  adaptiveBackgroundList, adaptiveBtnBg, adaptiveDivider,
  adaptiveInfo, adaptiveWarning, adaptiveSuccess
} from '@wifi-analyzer/design-system'
import { socket, connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import { PingStorage, StoredSessionSummary, PingDetail } from '../utils/PingStorage'
import { RouterManager } from '@wifi-analyzer/core'
import { IpCard, PingItem } from './IpCard'

const TAG = '[PingPage]'

@Builder
export function PingPageBuilder() {
  NavDestination() { PingPage() }
  .hideTitleBar(true)
}

interface PingItemData {
  host: string
  resolvedIp: string
  sent: number
  received: number
  lost: number
  lossRate: number
  minTime: number
  maxTime: number
  avgTime: number
  totalTime: number
  results: PingItem[]
}

interface DetailGroup {
  target: string
  items: PingDetail[]
}

function makePingData(host: string, ip: string): PingItemData {
  return { host, resolvedIp: ip, sent: 0, received: 0, lost: 0, lossRate: 0, minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0, results: [] } as PingItemData
}

// ==================== 主页面 ====================
@Component
export struct PingPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  @State pingCount: number = 10
  @State pingCountStr: string = '10'
  @State gatewayHost: string = 'qq.com'
  @State customHost: string = 'baidu.com'
  @State detectingGateway: boolean = false  // 不需要自动检测了

  @State summaries: StoredSessionSummary[] = []
  @State isRunning: boolean = false
  @State elapsedSec: number = 0
  @State showDetail: boolean = false
  @State detailOffset: number = 320
  @State detailOpacity: number = 0
  @State detailData: StoredSessionSummary = {
    timestamp: 0, targetHost: '', avgTime: 0, lossRate: 0, jitter: 0, stabilityScore: 0, pingCount: 0
  }
  private timerId: number = -1
  private pingTimeoutId: number = -1
  private currentTarget: number = 1
  private hasTarget2: boolean = true
  private rt1Done: boolean = false  // 网关 ICMP 批量探测是否已完成

  // 运行时数据
  private rt1: PingItemData = { host: '', resolvedIp: '—', sent: 0, received: 0, lost: 0, lossRate: 0, minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0, results: [] }
  private rt2: PingItemData = { host: '', resolvedIp: '—', sent: 0, received: 0, lost: 0, lossRate: 0, minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0, results: [] }

  // UI 数据
  @State t1_ip: string = '—'
  @State t1_sent: number = 0
  @State t1_received: number = 0
  @State t1_lost: number = 0
  @State t1_lossRate: number = 0
  @State t1_min: number = 0
  @State t1_max: number = 0
  @State t1_avg: number = 0
  @State t1_results: string = '[]'

  @State t2_ip: string = '—'
  @State t2_sent: number = 0
  @State t2_received: number = 0
  @State t2_lost: number = 0
  @State t2_lossRate: number = 0
  @State t2_min: number = 0
  @State t2_max: number = 0
  @State t2_avg: number = 0
  @State t2_results: string = '[]'

  /** 将域名解析为 IP */
  private async resolveHost(host: string): Promise<string> {
    // 已是 IPv4 地址则直接返回
    const ipv4Regex = /^(\d{1,3}\.){3}\d{1,3}$/
    if (ipv4Regex.test(host)) return host
    try {
      const netHandle = await connection.getDefaultNet()
      if (netHandle && netHandle.netId !== 0) {
        const addresses = await netHandle.getAddressesByName(host)
        if (addresses && addresses.length > 0 && addresses[0].address) {
          return addresses[0].address
        }
      }
    } catch (e) { hilog.warn(0x0000, TAG, 'resolveHost error: %{public}s', JSON.stringify(e)) }
    return host
  }

  aboutToAppear(): void {
    PingStorage.getLastConfig().then((cfg) => {
      if (cfg && cfg.customHost) {
        this.customHost = cfg.customHost
      }
    })
    PingStorage.loadSessionSummaries().then((list) => {
      if (list && list.length > 0) {
        this.summaries = list
      }
    })
    this.t1_ip = this.gatewayHost
    this.t2_ip = this.customHost
    this.detectingGateway = false
  }

  aboutToDisappear(): void { this.stopPing() }

  private async tcpPingOnce(address: string, timeout: number = 3000): Promise<number> {
    const ports: number[] = [443, 80, 53]
    for (let i = 0; i < ports.length; i++) {
      const t: number = await this.tryConnectPort(address, ports[i], timeout)
      if (t >= 0) return t
    }
    return -1
  }

  // 尝试连接到指定端口，超时返回 -1（通用 TCP 连接函数）
  private tryConnectPort(address: string, port: number, timeout: number): Promise<number> {
    return new Promise<number>((resolve: (v: number) => void) => {
      const t0: number = Date.now()
      const tcpSocket: socket.TCPSocket = socket.constructTCPSocketInstance()
      let tid: number = -1
      let resolved: boolean = false
      const cleanup = (): void => {
        if (!resolved) {
          resolved = true
          clearTimeout(tid)
          try { tcpSocket.close(() => {}) } catch (e) { hilog.warn(0x0000, TAG, 'tcpSocket close error: %{public}s', JSON.stringify(e)) }
        }
      }
      tid = setTimeout(() => { cleanup(); resolve(-1) }, timeout)
      tcpSocket.connect({ address: { address: address, port: port }, timeout: timeout },
        (err: BusinessError) => {
          if (resolved) return
          cleanup()
          resolve(err ? -1 : Date.now() - t0)
        })
    })
  }

  async startPing(): Promise<void> {
    if (this.isRunning) return
    if (this.detectingGateway) return
    const gw = this.gatewayHost.trim()
    const cu = this.customHost.trim()
    if (!gw && !cu) {
      promptAction.showToast({ message: 'Please enter at least one address to monitor', duration: 2000 })
      return
    }
    const hasGw: boolean = !!gw
    const hasCu: boolean = !!cu
    this.hasTarget2 = hasCu

    // 预解析 DNS（域名为 IP），确保 tcpSocket.connect 不会失败
    let resolvedIp2: string = cu
    if (hasCu) {
      this.t2_ip = cu  // 先显示域名，等解析完再更新
      resolvedIp2 = await this.resolveHost(cu)
      this.t2_ip = resolvedIp2 !== cu ? resolvedIp2 : cu
    }

    this.isRunning = true
    this.elapsedSec = 0
    this.rt1Done = false
    this.currentTarget = hasGw ? 1 : 2

    // reset 运行时数据
    this.rt1 = { host: gw, resolvedIp: gw, sent: 0, received: 0, lost: 0, lossRate: 0, minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0, results: [] }
    this.rt2 = { host: cu, resolvedIp: resolvedIp2, sent: 0, received: 0, lost: 0, lossRate: 0, minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0, results: [] }
    if (hasGw) {
      this.t1_sent = 0; this.t1_received = 0; this.t1_lost = 0; this.t1_lossRate = 0
      this.t1_min = 0; this.t1_max = 0; this.t1_avg = 0; this.t1_results = '[]'
    }
    if (hasCu) {
      this.t2_sent = 0; this.t2_received = 0; this.t2_lost = 0; this.t2_lossRate = 0
      this.t2_min = 0; this.t2_max = 0; this.t2_avg = 0; this.t2_results = '[]'
    }

    PingStorage.saveLastConfig({ pingCount: this.pingCount, customHost: cu, timestamp: Date.now() })
    this.timerId = setInterval(() => { if (this.isRunning) this.elapsedSec++ }, 1000)
    this.scheduleNext()
  }

  private static isValidIpv4(addr: string): boolean {
    return /^(\d{1,3}\.){3}\d{1,3}$/.test(addr)
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  /** 网关 TCP ping（端口 53），逐个发包 */
  private async doTickGateway(): Promise<void> {
    const addr = this.rt1.resolvedIp
    const count = this.pingCount > 0 ? this.pingCount : 10

    for (let i = 0; i < count; i++) {
      if (!this.isRunning) break
      const t = await this.tcpPingOnce(addr)
      if (t >= 0) {
        this.rt1.results.push(new PingItem(i + 1, t, 'success'))
        this.rt1.received++; this.rt1.totalTime += t
        if (this.rt1.minTime === 0 || t < this.rt1.minTime) this.rt1.minTime = t
        if (t > this.rt1.maxTime) this.rt1.maxTime = t
      } else {
        this.rt1.results.push(new PingItem(i + 1, -1, 'timeout'))
        this.rt1.lost++
      }
      this.rt1.sent = i + 1

      // 实时更新 UI
      this.rt1.lossRate = this.rt1.sent > 0 ? Math.round((this.rt1.lost / this.rt1.sent) * 1000) / 10 : 0
      this.rt1.avgTime = this.rt1.received > 0 ? Math.round(this.rt1.totalTime / this.rt1.received) : 0
      this.t1_sent = this.rt1.sent
      this.t1_received = this.rt1.received
      this.t1_lost = this.rt1.lost
      this.t1_lossRate = this.rt1.lossRate
      this.t1_min = this.rt1.minTime
      this.t1_max = this.rt1.maxTime
      this.t1_avg = this.rt1.avgTime
      this.t1_results = JSON.stringify(this.rt1.results.slice(-20))

      // 间隔 200ms
      if (i < count - 1 && this.isRunning) {
        await this.sleep(200)
      }
    }
  }

  private scheduleNext(): void {
    if (!this.isRunning) return
    if (this.pingCount > 0) {
      if (this.hasTarget2) {
        if (this.rt1.sent >= this.pingCount && this.rt2.sent >= this.pingCount) { this.finish(); return }
      } else {
        if (this.rt1.sent >= this.pingCount || this.rt2.sent >= this.pingCount) { this.finish(); return }
      }
    }
    this.pingTimeoutId = setTimeout(() => { this.doTick() }, 100)
  }

  private async doTick(): Promise<void> {
    if (!this.isRunning) return
    if (this.currentTarget === 1) {
      // 网关使用原生 ICMP 批量探测（一次完成，精确）
      if (!this.rt1Done) {
        this.rt1Done = true
        await this.doTickGateway()
        this.currentTarget = this.hasTarget2 ? 2 : 1
        this.scheduleNext()
        return
      }
      // 网关已完成，直接切换到目标 2
      this.currentTarget = this.hasTarget2 ? 2 : 1
    }
    if (this.currentTarget === 2) {
      const addr = PingPage.isValidIpv4(this.rt2.resolvedIp) ? this.rt2.resolvedIp : this.rt2.host
      const t = await this.tcpPingOnce(addr)
      if (this.isRunning) {
        this.rt2.sent++
        if (t >= 0) {
          this.rt2.received++; this.rt2.totalTime += t
          if (this.rt2.minTime === 0 || t < this.rt2.minTime) this.rt2.minTime = t
          if (t > this.rt2.maxTime) this.rt2.maxTime = t
          this.rt2.avgTime = Math.round(this.rt2.totalTime / this.rt2.received)
          this.rt2.results.push(new PingItem(this.rt2.sent, t, 'success'))
        } else {
          this.rt2.lost++; this.rt2.results.push(new PingItem(this.rt2.sent, -1, 'timeout'))
        }
        this.rt2.lossRate = this.rt2.sent > 0 ? Math.round((this.rt2.lost / this.rt2.sent) * 1000) / 10 : 0
        this.t2_sent = this.rt2.sent
        this.t2_received = this.rt2.received
        this.t2_lost = this.rt2.lost
        this.t2_lossRate = this.rt2.lossRate
        this.t2_min = this.rt2.minTime
        this.t2_max = this.rt2.maxTime
        this.t2_avg = this.rt2.avgTime
        this.t2_results = JSON.stringify(this.rt2.results.slice(-20))
      }
      this.currentTarget = this.hasTarget2 ? 1 : 2
    }
    this.scheduleNext()
  }

  private async finish(): Promise<void> {
    // 防止重复调用
    if (!this.isRunning) return
    this.isRunning = false
    if (this.timerId !== -1) { clearInterval(this.timerId); this.timerId = -1 }
    if (this.pingTimeoutId !== -1) { clearTimeout(this.pingTimeoutId); this.pingTimeoutId = -1 }
    const totalSent: number = this.rt1.sent + this.rt2.sent
    if (totalSent === 0) return  // 没发过包就不保存空记录

    // 分别计算两个目标的指标
    let avg = this.rt2.avgTime > 0 ? this.rt2.avgTime : this.rt1.avgTime > 0 ? this.rt1.avgTime : 0
    let lossRate = Math.max(this.rt1.lossRate, this.rt2.lossRate)
    let stabilityScore = 0
    // 稳定性 = 丢包较低的那个目标（有数据才计分）
    if (this.rt2.received > 0) {
      stabilityScore = Math.round((1 - this.rt2.lossRate / 100) * 100)
    } else if (this.rt1.received > 0) {
      stabilityScore = Math.round((1 - this.rt1.lossRate / 100) * 100)
    }

    // 收集详细数据
    const details: PingDetail[] = []
    for (const r of this.rt1.results) {
      details.push({ target: this.gatewayHost, index: r.index, timeMs: r.time, status: r.status })
    }
    for (const r of this.rt2.results) {
      details.push({ target: this.customHost, index: r.index, timeMs: r.time, status: r.status })
    }
    const hostLabel: string = this.gatewayHost && this.customHost
      ? this.gatewayHost + ' + ' + this.customHost
      : this.gatewayHost || this.customHost
    await PingStorage.addSessionSummary({
      timestamp: Date.now(),
      targetHost: hostLabel,
      avgTime: avg,
      lossRate: lossRate,
      jitter: 0,
      stabilityScore: stabilityScore,
      pingCount: totalSent,
      details: details
    })
    // 等上面的写入完成后，再重新加载列表
    const list = await PingStorage.loadSessionSummaries()
    if (list) this.summaries = list
  }

  stopPing(): void { this.finish() }

  private getDetailGroups(): DetailGroup[] {
    const details: PingDetail[] = this.detailData.details || []
    const groups: DetailGroup[] = []
    const seen: string[] = []
    for (const d of details) {
      if (seen.indexOf(d.target) === -1) {
        seen.push(d.target)
        groups.push({ target: d.target, items: [] })
      }
    }
    for (const g of groups) {
      for (const d of details) {
        if (d.target === g.target) g.items.push(d)
      }
      // 只保留最新5条
      if (g.items.length > 5) {
        g.items = g.items.slice(-5)
      }
    }
    return groups
  }

  private fmtDate(ts: number): string {
    const d = new Date(ts)
    const h = String(d.getHours()).padStart(2, '0')
    const m = String(d.getMinutes()).padStart(2, '0')
    return `${d.getMonth() + 1}/${d.getDate()} ${h}:${m}`
  }

  private formatElapsed(sec: number): string {
    const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 装饰光晕（与路由追踪页面统一）
      Circle().width(300).height(300)
        .fill(this.isDarkMode ? 'rgba(59,130,246,0.06)' : 'rgba(59,130,246,0.04)')
        .position({ x: -80, y: -80 })
      Circle().width(200).height(200)
        .fill(this.isDarkMode ? 'rgba(59,130,246,0.04)' : 'rgba(59,130,246,0.03)')
        .position({ x: '70%', y: '50%' })
      Column() {
        // 顶部栏
      Row({ space: 12 }) {
        Row() {
          Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .width(36).height(36).justifyContent(FlexAlign.Center).borderRadius(8)
        .backgroundColor(adaptiveBtnBg(this.isDarkMode))
        .onClick(() => { RouterManager.goBack() })
        Text($r('app.string.network_monitor')).fontSize(20).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDarkMode)).layoutWeight(1)
      }
      .width('100%').padding({ left: 16, right: 16, top: 44, bottom: 8 })

      Scroll() {
        Column({ space: 12 }) {
          // 配置区域
          Column({ space: 10 }) {
            Row() {
              Text($r('app.string.monitor_config')).fontSize(12).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDarkMode))
              Blank()
            }.width('100%')
            Row({ space: 4 }) {
              Text($r('app.string.ping_count')).fontSize(12).fontWeight(600).fontColor(adaptiveTextSecondary(this.isDarkMode))
              Text($r('app.string.infinite_hint')).fontSize(10).fontColor(adaptiveTextTertiary(this.isDarkMode))
            }
            TextInput({ text: $$this.pingCountStr })
              .fontSize(14).fontColor(adaptiveTextPrimary(this.isDarkMode)).type(InputType.Number)
              .width('100%').height(38)
              .backgroundColor(adaptiveBtnBg(this.isDarkMode)).borderRadius(8)
              .border({ width: 1, color: adaptiveBorderCyan(this.isDarkMode) })
              .onChange((v: string) => {
                const n = parseInt(v)
                this.pingCount = isNaN(n) ? 0 : Math.max(0, Math.min(9999, n))
                this.pingCountStr = String(this.pingCount)
              })
            Row({ space: 4 }) {
              Text($r('app.string.addr_gateway')).fontSize(12).fontWeight(600).fontColor(adaptiveTextSecondary(this.isDarkMode))
              Text($r('app.string.auto_detect')).fontSize(10).fontColor(adaptiveTextTertiary(this.isDarkMode))
            }
            TextInput({ text: $$this.gatewayHost, placeholder: 'qq.com' })
              .fontSize(14).fontColor(adaptiveTextPrimary(this.isDarkMode))
              .width('100%').height(38)
              .backgroundColor(adaptiveBtnBg(this.isDarkMode)).borderRadius(8)
              .border({ width: 1, color: adaptiveBorderCyan(this.isDarkMode) })
              .enabled(!this.isRunning)
            Row({ space: 4 }) {
              Text($r('app.string.addr_custom')).fontSize(12).fontWeight(600).fontColor(adaptiveTextSecondary(this.isDarkMode))
              Text($r('app.string.recommend_baidu')).fontSize(10).fontColor(adaptiveTextTertiary(this.isDarkMode))
            }
            TextInput({ text: $$this.customHost, placeholder: $r('app.string.input_domain_or_ip') })
              .fontSize(14).fontColor(adaptiveTextPrimary(this.isDarkMode))
              .width('100%').height(38)
              .backgroundColor(adaptiveBtnBg(this.isDarkMode)).borderRadius(8)
              .border({ width: 1, color: adaptiveBorderCyan(this.isDarkMode) })
              .enabled(!this.isRunning)
            Row({ space: 10 }) {
              if (this.isRunning) {
                Button($r('app.string.stop_monitor')).fontSize(14).fontWeight(600).fontColor(Color.White)
                  .backgroundColor('#D94838').borderRadius(10).layoutWeight(1).height(42)
                  .onClick(() => { this.stopPing() })
              }
              Button(this.detectingGateway ? $r('app.string.detect_gateway') : (this.isRunning ? $r('app.string.monitoring') : $r('app.string.start_monitor')))
                .fontSize(14).fontWeight(600).fontColor(Color.White)
                .backgroundColor(this.isRunning ? 'rgba(49,122,247,0.5)' : '#317AF7')
                .borderRadius(10).layoutWeight(1).height(42)
                .enabled(!this.isRunning && !this.detectingGateway)
                .onClick(() => { this.startPing() })
            }.width('100%')
          }
          .width('100%').padding(16)
          .linearGradient({ angle: 135, colors: [[adaptiveCardBg(this.isDarkMode), 0], [adaptiveCardDarkGlass(this.isDarkMode), 1]] })
          .border({ width: 1, color: adaptiveBorderCyan(this.isDarkMode), style: BorderStyle.Solid })
          .borderRadius(16)

          // 状态栏
          Row({ space: 12 }) {
            Row({ space: 4 }) {
              Circle().width(6).height(6).fill(this.isRunning ? '#5BA854' : adaptiveTextTertiary(this.isDarkMode))
              Text(this.isRunning ? $r('app.string.monitoring') : $r('app.string.standby')).fontSize(12).fontWeight(500).fontColor(adaptiveTextSecondary(this.isDarkMode))
            }
            Blank()
            Text() {
              Span($r('app.string.elapsed_time'))
              Span(' ' + this.formatElapsed(this.elapsedSec))
            }
              .fontSize(12).fontWeight(500).fontColor(adaptiveTextTertiary(this.isDarkMode)).fontFamily('HarmonyOS Sans Mono')
          }.width('100%').padding({ left: 4, right: 4 })

          // 双目标结果 — 独立子组件
          Row({ space: 8 }) {
            IpCard({
              idx: 1, isDark: this.isDarkMode,
              ip: this.t1_ip, sent: this.t1_sent, received: this.t1_received,
              lost: this.t1_lost, lossRate: this.t1_lossRate,
              minTime: this.t1_min, maxTime: this.t1_max, avgTime: this.t1_avg,
              resultsJson: this.t1_results
            })
            IpCard({
              idx: 2, isDark: this.isDarkMode,
              ip: this.t2_ip, sent: this.t2_sent, received: this.t2_received,
              lost: this.t2_lost, lossRate: this.t2_lossRate,
              minTime: this.t2_min, maxTime: this.t2_max, avgTime: this.t2_avg,
              resultsJson: this.t2_results
            })
          }.width('100%')

          // ── 历史记录 ──
          if (this.summaries.length > 0) {
            Column({ space: 10 }) {
              Row() {
                Text($r('app.string.history')).fontSize(12).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDarkMode))
                Blank()
                Text($r('app.string.clear')).fontSize(11).fontColor('#D94838')
                  .onClick(() => {
                    PingStorage.clearSessionSummaries()
                    this.summaries = []
                  })
              }.width('100%')

              ForEach(this.summaries.slice(0, 10), (s: StoredSessionSummary) => {
                Row({ space: 8 }) {
                  Column({ space: 4 }) {
                    Text(this.fmtDate(s.timestamp)).fontSize(10).fontColor(adaptiveTextTertiary(this.isDarkMode))
                    Text(s.targetHost).fontSize(10).fontColor(adaptiveTextSecondary(this.isDarkMode)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  Column({ space: 2 }) {
                    Text(`${s.avgTime} ms`).fontSize(13).fontWeight(700).fontColor(adaptiveTextCyan(this.isDarkMode)).fontFamily('HarmonyOS Sans Mono')
                    Text($r('app.string.average')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDarkMode))
                  }.width(56).alignItems(HorizontalAlign.Center)
                  Column({ space: 2 }) {
                    Text(`${s.lossRate}%`).fontSize(13).fontWeight(700)
                      .fontColor(s.lossRate > 5 ? '#D94838' : '#5BA854').fontFamily('HarmonyOS Sans Mono')
                    Text($r('app.string.packet_loss')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDarkMode))
                  }.width(48).alignItems(HorizontalAlign.Center)
                  Column({ space: 2 }) {
                    Text(`${s.stabilityScore}`).fontSize(13).fontWeight(700)
                      .fontColor(s.stabilityScore >= 80 ? '#5BA854' : s.stabilityScore >= 60 ? '#E8A838' : '#D94838')
                      .fontFamily('HarmonyOS Sans Mono')
                    Text($r('app.string.stability')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDarkMode))
                  }.width(48).alignItems(HorizontalAlign.Center)
                }.width('100%').padding(10)
                .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDarkMode), 0], [adaptiveCardBg(this.isDarkMode), 1]] })
                .border({ width: 1, color: adaptiveBorderCyan(this.isDarkMode), style: BorderStyle.Solid }).borderRadius(10)
                .onClick(() => {
                  this.detailData = s;
                  this.showDetail = true;
                  this.detailOffset = 320;
                  this.detailOpacity = 0;
                  this.getUIContext().animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, () => {
                    this.detailOffset = 0;
                    this.detailOpacity = 1;
                  })
                })
              })
            }
            .width('100%').padding(16)
            .linearGradient({ angle: 135, colors: [[adaptiveCardBg(this.isDarkMode), 0], [adaptiveCardDarkGlass(this.isDarkMode), 1]] })
            .border({ width: 1, color: adaptiveBorderCyan(this.isDarkMode), style: BorderStyle.Solid }).borderRadius(16)
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 80 })
      }
      .align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%')

    // ── 详情弹窗（滑入滑出转场）──
    if (this.showDetail) {
      Column() {
        Column({ space: 6 }) {
          Row() {
            Button() {
              Text('←').fontSize(16).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDarkMode))
            }
            .width(32).height(32).borderRadius(6)
            .backgroundColor(adaptiveBtnBg(this.isDarkMode))
            .onClick(() => {
              this.getUIContext().animateTo({ duration: 250, curve: Curve.FastOutSlowIn }, () => {
                this.detailOffset = 320;
                this.detailOpacity = 0;
              })
              setTimeout(() => { this.showDetail = false }, 280)
            })
            Blank()
            Text($r('app.string.monitor_detail')).fontSize(15).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDarkMode))
          }.width('100%')
          .padding({ top: 48 })
        Text(this.fmtDate(this.detailData.timestamp) + '  ' + this.detailData.targetHost)
          .fontSize(13).fontColor(adaptiveTextSecondary(this.isDarkMode))

        Row({ space: 12 }) {
          Column({ space: 2 }) {
            Text(this.detailData.avgTime + ' ms').fontSize(18).fontWeight(800)
              .fontColor(adaptiveTextCyan(this.isDarkMode)).fontFamily('HarmonyOS Sans Mono')
            Text($r('app.string.average')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDarkMode))
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          Column({ space: 2 }) {
            Text(this.detailData.lossRate + '%').fontSize(18).fontWeight(800)
              .fontColor(this.detailData.lossRate > 5 ? '#D94838' : '#5BA854').fontFamily('HarmonyOS Sans Mono')
            Text($r('app.string.packet_loss')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDarkMode))
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          Column({ space: 2 }) {
            Text(this.detailData.stabilityScore + '').fontSize(18).fontWeight(800)
              .fontColor(this.detailData.stabilityScore >= 80 ? '#5BA854' : this.detailData.stabilityScore >= 60 ? '#E8A838' : '#D94838').fontFamily('HarmonyOS Sans Mono')
            Text($r('app.string.stability')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDarkMode))
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        }

        Divider().height(1).color(adaptiveDivider(this.isDarkMode))

        Text($r('app.string.packet_data')).fontSize(14).fontWeight(600).fontColor(adaptiveTextSecondary(this.isDarkMode))
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.getDetailGroups(), (g: DetailGroup) => {
              Column({ space: 4 }) {
                Text(g.target).fontSize(14).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDarkMode))
                Column({ space: 2 }) {
                  ForEach(g.items, (d: PingDetail) => {
                    Row({ space: 8 }) {
                      Text('#' + d.index).fontSize(13).fontColor(adaptiveTextSecondary(this.isDarkMode))
                        .fontFamily('HarmonyOS Sans Mono').width(40)
                      Text(d.status === 'success' ? d.timeMs + ' ms' : 'Timeout').fontSize(13).fontWeight(500)
                        .fontColor(d.status === 'success' ? (d.timeMs < 30 ? adaptiveInfo(this.isDarkMode) : adaptiveWarning(this.isDarkMode)) : '#D94838')
                        .fontFamily('HarmonyOS Sans Mono').width(80).textAlign(TextAlign.End)
                      Rect()
                        .width(d.status === 'success' ? Math.min(100, d.timeMs * 2) : 4)
                        .height(8).radius(3)
                        .fill(d.status === 'success' ? (d.timeMs < 30 ? adaptiveInfo(this.isDarkMode) : adaptiveWarning(this.isDarkMode)) : 'rgba(128,128,128,0.3)')
                    }.width('100%').padding({ left: 10, top: 4, bottom: 4 })
                  })
                }.width('100%').backgroundColor(adaptiveCardDarkGlass(this.isDarkMode)).borderRadius(8).padding(10)
              }.width('100%')
            })
          }.width('100%')
        }.scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1).width('100%')
        }
        .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 12 })
        Blank()
      }
      .width('100%').height('100%')
      .backgroundColor(this.isDarkMode ? 'rgba(0,0,0,0.92)' : 'rgba(255,255,255,0.95)')
      .offset({ y: this.detailOffset })
      .opacity(this.detailOpacity)
    }
  }
  .width('100%').height('100%')
  .linearGradient({ direction: GradientDirection.Bottom, colors: adaptiveBackgroundList(this.isDarkMode) })
  }
}
