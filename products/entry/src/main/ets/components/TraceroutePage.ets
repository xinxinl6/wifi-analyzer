// TraceroutePage — 专业路由追踪面板
// 设计灵感：爱快路由追踪 — 数据面板 + 路径可视化 + 分层跳点列表
// 实现：优先 Native C++ (POSIX socket + IP_TTL + ICMP 错误队列)
//      回退 TCP 连接时序分析
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveTextCyan, adaptiveTextAmber, adaptiveTextGreen,
  adaptiveCardBg, adaptiveCardDarkGlass, adaptiveBorderCyan,
  adaptiveBackgroundList, adaptiveBtnBg, adaptiveDivider,
  adaptiveInfo, adaptiveWarning, adaptiveDanger, adaptiveSuccess,
  SPACE_MD, RADIUS_MD
} from '@wifi-analyzer/design-system'
import { RouterManager } from '@wifi-analyzer/core'
import { nativeTraceRoute, tcpFallbackTraceRoute, TracerouteHopResult, TracerouteResult } from 'native-ping'
import promptAction from '@ohos.promptAction'

interface HopRecord {
  hop: number
  ip: string
  timeMs: number
  status: 'success' | 'timeout'
}

function timeColor(t: number, dark: boolean): string {
  if (t < 0) return adaptiveDanger(dark)
  if (t <= 50) return adaptiveSuccess(dark)
  if (t <= 150) return adaptiveTextAmber(dark)
  return adaptiveDanger(dark)
}

function statusIcon(s: string): string {
  return s === 'success' ? '✓' : '✗'
}

@Builder
export function TraceroutePageBuilder() {
  NavDestination() {
    TraceroutePage()
  }
  .title($r('app.string.tool_traceroute'))
  .hideTitleBar(true)
}

@Component
export struct TraceroutePage {
  @StorageLink('isDarkMode') isDark: boolean = false
  @State host: string = 'github.com'
  @State hops: HopRecord[] = []
  @State isRunning: boolean = false
  @State targetIp: string = ''
  @State statusText: string = ''
  @State useFallback: boolean = false
  @State hopsFail: number = 0
  @State hopsOk: number = 0
  @State avgTimems: string = '0'
  @State minTime: number = 0
  @State maxTime: number = 0
  private stopFlag: boolean = false
  private recommendList: Resource[] = [$r('app.string.trace_gateway'), $r('app.string.trace_preferred_dns'), $r('app.string.trace_alternate_dns'), $r('app.string.trace_github'), $r('app.string.trace_baidu')]

  private async startTrace(): Promise<void> {
    if (this.isRunning) return
    const target: string = this.host.trim()
    if (!target) {
      promptAction.showToast({ message: 'Please enter a target address', duration: 1500 })
      return
    }
    this.isRunning = true
    this.stopFlag = false
    this.hops = []
    this.targetIp = ''
    this.useFallback = false
    this.hopsFail = 0
    this.hopsOk = 0
    this.avgTimems = '0'
    this.minTime = 0
    this.maxTime = 0
    this.statusText = 'Resolving DNS...'

    this.statusText = 'ICMP probing...'
    let result: TracerouteResult = await nativeTraceRoute(target, 30, 2, 45000)
    if (this.stopFlag) return

    if (result.hopCount === 0 || result.error !== 0) {
      this.useFallback = true
      this.statusText = 'TCP timing probing...'
      result = await tcpFallbackTraceRoute(target, 30, 3000)
      if (this.stopFlag) return
    }

    const records: HopRecord[] = []
    for (const h of result.hops) {
      records.push({
        hop: h.ttl,
        ip: h.ip,
        timeMs: h.timeMs,
        status: h.timeMs >= 0 ? 'success' : 'timeout'
      })
      if (h.ip !== '*') this.targetIp = h.ip
    }
    this.hops = records
    this.calcStats()
    this.isRunning = false
    this.statusText = ''

    if (records.length === 0) {
      promptAction.showToast({ message: 'No route path detected, please check address', duration: 2000 })
    }
  }

  stopTrace(): void {
    this.stopFlag = true
    this.isRunning = false
    this.statusText = 'Stopped'
    setTimeout(() => { this.statusText = '' }, 2000)
  }

  private calcStats(): void {
    const failed: HopRecord[] = this.hops.filter(h => h.status === 'timeout')
    const ok: HopRecord[] = this.hops.filter(h => h.timeMs >= 0)
    this.hopsFail = failed.length
    this.hopsOk = ok.length
    if (ok.length === 0) {
      this.avgTimems = '0'
      this.minTime = 0
      this.maxTime = 0
    } else {
      let sum: number = 0
      let mn: number = ok[0].timeMs
      let mx: number = ok[0].timeMs
      for (const h of ok) {
        sum += h.timeMs
        if (h.timeMs < mn) mn = h.timeMs
        if (h.timeMs > mx) mx = h.timeMs
      }
      this.avgTimems = (sum / ok.length).toFixed(1)
      this.minTime = Math.round(mn)
      this.maxTime = Math.round(mx)
    }
  }

  private onQuickTarget(idx: number): void {
    const targets: string[] = ['Gateway', '223.5.5.5', '114.114.114.114', 'github.com', 'baidu.com']
    this.host = targets[idx]
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景
      Column()
        .width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Bottom, colors: adaptiveBackgroundList(this.isDark) })

      // 装饰光晕
      Circle().width(300).height(300).fill(glowLarge(this.isDark)).position({ x: -80, y: -80 })
      Circle().width(200).height(200).fill(glowMedium(this.isDark)).position({ x: '70%', y: '50%' })

      Column() {
        // ===== 顶栏 =====
        Row({ space: 12 }) {
          Row() { Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark)) }
            .width(34).height(34).justifyContent(FlexAlign.Center).borderRadius(10)
            .backgroundColor(adaptiveBtnBg(this.isDark))
            .onClick(() => { RouterManager.goBack() })
          Text($r('app.string.tool_traceroute')).fontSize(20).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
        }
        .width('100%').padding({ left: 20, right: 20, top: 44, bottom: 8 })

        // 内容：闲置态无滚动，运行态/有结果时滚动
        if (this.hops.length === 0 && !this.isRunning) {
          // 紧凑展示，不撑满，从顶部开始
          Column({ space: 10 }) {
            this.SearchCard()
            this.QuickTargetsSection()
            this.GuideSection()
          }
          .padding({ left: 16, right: 16 })
          .width('100%')
        } else {
          // 有结果/运行中时滚动
          Scroll() {
            Column({ space: 14 }) {
              this.SearchCard()
              if (this.isRunning) this.StatusBar()
              if (this.hops.length > 0 && !this.isRunning) this.SummaryPanel()
              if (this.hops.length > 0) this.PathVisualization()
            }
            .padding({ left: 16, right: 16, bottom: 36 })
            .width('100%')
          }
          .edgeEffect(EdgeEffect.Fade)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

  // ===== 搜索卡片 =====
  @Builder SearchCard() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        TextInput({ text: $$this.host, placeholder: 'Domain or IP address' })
          .fontColor(adaptiveTextPrimary(this.isDark))
          .placeholderColor(adaptiveTextTertiary(this.isDark))
          .fontSize(15).layoutWeight(1).height(44)
          .backgroundColor(Color.Transparent)
          .padding({ left: 4 })

        if (!this.isRunning) {
          Row() {
            Text($r('app.string.trace_route'))
              .fontSize(13).fontWeight(700).fontColor(Color.White)
          }
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .linearGradient({ angle: 135, colors: [['#3B82F6', 0], ['#1D4ED8', 1]] })
            .borderRadius(22)
            .shadow({ radius: 8, color: 'rgba(59,130,246,0.35)', offsetY: 3 })
            .onClick(() => { this.startTrace() })
        } else {
          Row() {
            Circle().width(8).height(8).fill('#EF4444')
            Text($r('app.string.trace_stop')).fontSize(13).fontWeight(700).fontColor(Color.White)
          }
            .padding({ left: 18, right: 18, top: 10, bottom: 10 })
            .linearGradient({ angle: 135, colors: [['#EF4444', 0], ['#B91C1C', 1]] })
            .borderRadius(22).onClick(() => { this.stopTrace() })
        }
      }
      .width('100%')
    }
    .width('100%').padding({ left: 16, right: 14, top: 12, bottom: 12 })
    .linearGradient({
      angle: 135,
      colors: [[this.isDark ? 'rgba(30,41,59,0.7)' : 'rgba(255,255,255,0.7)', 0],
               [this.isDark ? 'rgba(15,23,42,0.5)' : 'rgba(255,255,255,0.4)', 1]]
    })
    .borderRadius(16)
    .border({ width: 1, color: this.isDark ? 'rgba(59,130,246,0.25)' : 'rgba(59,130,246,0.2)' })
    .backdropBlur(20)
  }

  // ===== 快速目标 =====
  @Builder QuickTargetsSection() {
    Column({ space: 8 }) {
      Text($r('app.string.trace_quick_target')).fontSize(11).fontWeight(700).fontColor(adaptiveTextTertiary(this.isDark))
        .letterSpacing(0.8).textCase(TextCase.UpperCase).width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignContent: FlexAlign.Start }) {
        ForEach(this.recommendList, (item: Resource, idx: number) => {
          Row({ space: 5 }) {
            Text(['🏠', '🌐', '🌐', '🐙', '🌏'][idx]).fontSize(13)
            Text(item).fontSize(12).fontWeight(500).fontColor(adaptiveTextCyan(this.isDark))
          }
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.isDark ? 'rgba(59,130,246,0.1)' : 'rgba(59,130,246,0.07)')
            .borderRadius(20)
            .border({ width: 1, color: this.isDark ? 'rgba(59,130,246,0.2)' : 'rgba(59,130,246,0.15)' })
            .margin({ bottom: 6, right: 6 })
            .onClick(() => { this.onQuickTarget(idx) })
        })
      }.width('100%')
    }
    .width('100%')
  }

  // ===== 功能介绍 =====
  @Builder GuideSection() {
    Row({ space: 10 }) {
      Column({ space: 4 }) { Text('📡').fontSize(22); Text($r('app.string.trace_path_discovery')).fontSize(10).fontWeight(600).fontColor(adaptiveTextSecondary(this.isDark)) }.alignItems(HorizontalAlign.Center)

      Column().width(1).height(28).backgroundColor(adaptiveDivider(this.isDark))

      Column({ space: 4 }) { Text('⏱').fontSize(22); Text($r('app.string.trace_latency_analysis')).fontSize(10).fontWeight(600).fontColor(adaptiveTextSecondary(this.isDark)) }.alignItems(HorizontalAlign.Center)

      Column().width(1).height(28).backgroundColor(adaptiveDivider(this.isDark))

      Column({ space: 4 }) { Text('🔍').fontSize(22); Text($r('app.string.trace_fault_location')).fontSize(10).fontWeight(600).fontColor(adaptiveTextSecondary(this.isDark)) }.alignItems(HorizontalAlign.Center)
    }
    .width('100%').padding(14).justifyContent(FlexAlign.SpaceEvenly)
    .backgroundColor(this.isDark ? 'rgba(30,41,59,0.3)' : 'rgba(255,255,255,0.3)')
    .borderRadius(14)
    .border({ width: 1, color: this.isDark ? 'rgba(100,116,139,0.15)' : 'rgba(0,0,0,0.06)' })
  }

  // ===== 状态栏 =====
  @Builder StatusBar() {
    Row({ space: 10 }) {
      PulseDot({ color: adaptiveInfo(this.isDark) })
      Text(this.statusText).fontSize(12).fontColor(adaptiveInfo(this.isDark)).fontWeight(500)
      Blank()
      Text($r('app.string.trace_click_stop')).fontSize(11).fontColor(adaptiveDanger(this.isDark)).fontWeight(600)
        .onClick(() => { this.stopTrace() })
    }
    .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.isDark ? 'rgba(30,41,59,0.5)' : 'rgba(255,255,255,0.5)')
    .borderRadius(12)
    .border({ width: 1, color: this.isDark ? 'rgba(59,130,246,0.2)' : 'rgba(59,130,246,0.12)' })
  }

  // ===== 摘要面板 =====
  @Builder SummaryPanel() {
    Column({ space: 12 }) {
      // 标题 + 回退提示
      if (this.useFallback) {
        Text($r('app.string.trace_tcp_fallback_hint'))
          .fontSize(10).fontColor(adaptiveWarning(this.isDark)).width('100%')
      }

      // 指标行 — 仿爱快数据面板
      Row({ space: 0 }) {
        this.MetricCell(String(this.hops.length), $r('app.string.trace_total_hops'))
        Column().width(1).height(36).backgroundColor(adaptiveDivider(this.isDark))
        this.MetricCell(String(this.hopsOk), $r('app.string.trace_success'))
        Column().width(1).height(36).backgroundColor(adaptiveDivider(this.isDark))
        this.MetricCell(String(this.hopsFail), $r('app.string.trace_timeout'))
        Column().width(1).height(36).backgroundColor(adaptiveDivider(this.isDark))
        this.MetricCell(this.avgTimems, $r('app.string.trace_avg'))
      }
      .width('100%')

      // 时延范围
      if (this.hopsOk > 0) {
        Row({ space: 14 }) {
          Row({ space: 4 }) {
            Text($r('app.string.trace_slowest')).fontSize(10).fontColor(adaptiveTextTertiary(this.isDark))
            Text(this.maxTime + ' ms').fontSize(13).fontWeight(700).fontColor(timeColor(this.maxTime, this.isDark))
          }
          Row({ space: 4 }) {
            Text($r('app.string.trace_fastest')).fontSize(10).fontColor(adaptiveTextTertiary(this.isDark))
            Text(this.minTime + ' ms').fontSize(13).fontWeight(700).fontColor(adaptiveSuccess(this.isDark))
          }
          if (this.targetIp) {
            Blank()
            Text(this.targetIp).fontSize(10).fontColor(adaptiveTextTertiary(this.isDark))
              .fontFamily('HarmonyOS Sans Mono')
          }
        }.width('100%')
      }
    }
    .width('100%').padding(16)
    .linearGradient({
      angle: 135,
      colors: [[this.isDark ? 'rgba(15,23,42,0.6)' : 'rgba(255,255,255,0.6)', 0],
               [this.isDark ? 'rgba(30,41,59,0.4)' : 'rgba(248,250,252,0.4)', 1]]
    })
    .borderRadius(16)
    .border({ width: 1, color: this.isDark ? 'rgba(59,130,246,0.15)' : 'rgba(59,130,246,0.1)' })
  }

  @Builder MetricCell(value: string, label: Resource) {
    Column({ space: 2 }) {
      Text(value).fontSize(20).fontWeight(800).fontColor(adaptiveTextPrimary(this.isDark))
      Text(label).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)).textCase(TextCase.UpperCase)
    }.layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  // ===== 路径可视化：爱快风格跳点列表 =====
  @Builder PathVisualization() {
    Column({ space: 0 }) {
      Text($r('app.string.trace_route_path')).fontSize(11).fontWeight(700).fontColor(adaptiveTextCyan(this.isDark))
        .letterSpacing(0.8).textCase(TextCase.UpperCase).width('100%').margin({ bottom: 10 })

      ForEach(this.hops, (h: HopRecord) => {
        this.HopRow(h)
      })
    }
    .width('100%')
  }

  @Builder HopRow(h: HopRecord) {
    Row({ space: 12 }) {
      // 跳数圆标 + 连线
      Column({ space: 0 }) {
        Circle()
          .width(28).height(28)
          .fill(h.status === 'success'
            ? (h.timeMs <= 50 ? 'rgba(34,197,94,0.85)' : h.timeMs <= 150 ? 'rgba(234,179,8,0.85)' : 'rgba(239,68,68,0.85)')
            : 'rgba(100,116,139,0.5)')
        Text(String(h.hop))
          .fontSize(10).fontWeight(800).fontColor(Color.White)
      }.width(28).alignItems(HorizontalAlign.Center)

      // IP + 状态图标
      Column({ space: 2 }) {
        Row({ space: 6 }) {
          Text(h.ip === '*' ? $r('app.string.trace_timeout') : h.ip)
            .fontSize(14).fontWeight(600)
            .fontColor(h.ip === '*' ? adaptiveTextTertiary(this.isDark) : adaptiveTextPrimary(this.isDark))
            .fontFamily('HarmonyOS Sans Mono')
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          if (h.ip !== '*') {
            Text(statusIcon(h.status))
              .fontSize(10).fontColor(h.status === 'success' ? adaptiveSuccess(this.isDark) : adaptiveDanger(this.isDark))
          }
        }.width('100%')

        Text(this.getHopHint(h))
          .fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)).maxLines(1)
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)

      // 时延
      if (h.timeMs >= 0) {
        Text(Math.round(h.timeMs) + ' ms')
          .fontSize(13).fontWeight(700)
          .fontColor(timeColor(h.timeMs, this.isDark))
      } else {
        Text('—').fontSize(13).fontWeight(700).fontColor(adaptiveTextTertiary(this.isDark))
      }
    }
    .width('100%').padding({ top: 6, bottom: 6, left: 12, right: 12 })
    .backgroundColor(this.isDark ? 'rgba(30,41,59,0.3)' : 'rgba(255,255,255,0.3)')
    .borderRadius(10)
    .margin({ bottom: 6 })
  }

  private getHopHint(h: HopRecord): string {
    if (h.status === 'timeout') return 'No Response'
    if (h.timeMs <= 20) return 'Excellent'
    if (h.timeMs <= 50) return 'Good'
    if (h.timeMs <= 150) return 'Average'
    return 'High Latency'
  }
}

// ===== 脉冲点 =====
@Component
struct PulseDot {
  private color: string = '#3B82F6'
  @State o: number = 1.0
  @State timer: number = -1

  aboutToAppear(): void { this.start() }
  aboutToDisappear(): void { clearInterval(this.timer) }

  private start(): void {
    let d: number = -1
    this.timer = setInterval(() => {
      let n: number = this.o + d * 0.07
      if (n <= 0.3) { d = 1; n = 0.3 }
      if (n >= 1.0) { d = -1; n = 1.0 }
      this.o = n
    }, 40)
  }

  build() {
    Circle().width(7).height(7).fill(this.color).opacity(this.o)
  }
}

// ===== 装饰光晕 =====
function glowLarge(dark: boolean): string {
  return dark ? 'rgba(59,130,246,0.06)' : 'rgba(59,130,246,0.04)'
}
function glowMedium(dark: boolean): string {
  return dark ? 'rgba(59,130,246,0.04)' : 'rgba(59,130,246,0.03)'
}
