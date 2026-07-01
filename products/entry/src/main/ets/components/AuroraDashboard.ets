import { connection } from '@kit.NetworkKit'
import { wifiManager } from '@kit.ConnectivityKit'
import {
  RADIUS_2XL, RADIUS_XL,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptivePrimaryLight,
  adaptivePrimaryBg, adaptiveCardDarkGlass, adaptiveDivider,
  adaptiveBackgroundList, adaptiveSuccess, adaptiveInfo,
  adaptiveWarning, adaptiveDanger,
  COLOR_PURPLE,
} from '@wifi-analyzer/design-system';
import { WifiDataManager, WifiItem, SharedWifiState } from '@wifi-analyzer/core';
import { GatewayInfo } from './GatewayInfo';
import { LinkSpeedStat, LatencyStat } from './NetworkStats';
import { RouterManager, RouteName } from '@wifi-analyzer/core';
import { WifiConnectionCard } from './WifiConnectionCard';

interface ToolItem { name: Resource; letter: string; color: string; res: string }
const TOOLS: ToolItem[] = [
  { name: $r('app.string.tool_ping'), letter: 'P', color: 'rgba(49,122,247,0.12)', res: 'ping' },
  { name: $r('app.string.tool_traceroute'), letter: 'T', color: 'rgba(49,122,247,0.12)', res: 'route' },
  { name: $r('app.string.tool_dns'), letter: 'D', color: 'rgba(139,92,246,0.12)', res: 'dns' },
  { name: $r('app.string.tab_speed'), letter: 'S', color: 'rgba(219,107,66,0.12)', res: 'speed' },
  { name: $r('app.string.tool_portscan'), letter: 'P', color: 'rgba(139,92,246,0.12)', res: 'port' },
  { name: $r('app.string.tool_subnet'), letter: 'S', color: 'rgba(91,168,84,0.12)', res: 'subnet' },
  { name: $r('app.string.tool_ipgeo'), letter: 'G', color: 'rgba(219,107,66,0.12)', res: 'geo' },
  { name: $r('app.string.tool_lan'), letter: 'L', color: 'rgba(139,92,246,0.12)', res: 'lan' },
  { name: $r('app.string.tool_settings'), letter: '⚙', color: 'rgba(255,255,255,0.06)', res: 'settings' },
]

function sigCol(dbm: number, isDark: boolean): string {
  return dbm >= -50 ? adaptiveSuccess(isDark)
    : dbm >= -65 ? adaptiveInfo(isDark)
    : dbm >= -80 ? adaptiveWarning(isDark)
    : adaptiveDanger(isDark)
}

@ComponentV2
export struct AuroraDashboard {
  @Param isDark: boolean = true
  @Local wifiList: WifiItem[] = []
  @Local ssid: string = '—'
  @Local signal: number = -100
  @Local isConnected: boolean = false
  @Local ipAddress: string = 'Fetching...'
  @Local dns: string = 'Fetching...'
  @Local channel: number = 0
  @Local security: string = '—'
  @Local freqVal: number = 0
  private wifiDataManager: WifiDataManager = WifiDataManager.getInstance()
  private scanTimerId: number = -1

  aboutToAppear(): void {
    this.fetchNetworkInfo()
    // 立即开始首次扫描（不等延迟），让卡片数据尽快填充
    this.scanWifiList()
    // 每 5 秒持续刷新 WiFi 列表
    this.scanTimerId = setInterval(() => {
      this.scanWifiList()
    }, 5000) as number
  }

  aboutToDisappear(): void {
    if (this.scanTimerId !== -1) {
      clearInterval(this.scanTimerId)
      this.scanTimerId = -1
    }
  }

  private fetchNetworkInfo(): void {
    // 1. 从 WiFi 驱动同步获取连接信息（SSID/信号/频段/信道/安全）— 立即填充，不等扫描
    try {
      const linkInfo = wifiManager.getLinkedInfoSync()
      if (linkInfo) {
        const ssidVal: string = (linkInfo.ssid || '').trim()
        if (ssidVal !== '' && !ssidVal.toLowerCase().includes('virtwifi')) {
          this.ssid = ssidVal
          this.isConnected = true
        }
        if (typeof linkInfo.rssi === 'number') {
          this.signal = linkInfo.rssi
        }
        if (linkInfo.band === 2) this.freqVal = 5.0
        else if (linkInfo.band === 1) this.freqVal = 2.4
        const freq: number = linkInfo.frequency
        if (freq > 0) {
          if (freq >= 2412 && freq <= 2484) this.channel = Math.round((freq - 2412) / 5 + 1)
          else if (freq >= 5170 && freq <= 5825) this.channel = Math.round((freq - 5170) / 5 + 34)
        }
        // securityType 在当前 SDK 中不可用，等 scanWifiList 回调更新
      }
    } catch (_e) {}

    // 2. 从网络属性获取 IP / DNS / 网关
    try {
      const netHandle = connection.getDefaultNetSync()
      if (!netHandle || netHandle.netId === 0) {
        this.dns = '--'
        this.ipAddress = '--'
        return
      }
      const props: connection.ConnectionProperties = connection.getConnectionPropertiesSync(netHandle)
      if (!props) return
      if (props.dnses) {
        for (let i = 0; i < props.dnses.length; i++) {
          const d = props.dnses[i]
          if (d && d.address && !d.address.startsWith('::') && d.address !== '0.0.0.0') {
            this.dns = d.address
            break
          }
        }
      }
      if (props.linkAddresses) {
        for (let i = 0; i < props.linkAddresses.length; i++) {
          const addr = props.linkAddresses[i]
          const addrStr: string = addr?.address?.address || ''
          if (addrStr && !addrStr.startsWith('fe80') && !addrStr.startsWith('::') && !addrStr.startsWith('169.254')) {
            this.ipAddress = addrStr
            break
          }
        }
      }
      this.isConnected = true
    } catch (_e) {
      this.dns = '--'
      this.ipAddress = '--'
    }
  }

  private scanWifiList(): void {
    try {
      const state = this.wifiDataManager.getInitialState()
      this.wifiDataManager.scanAndUpdate(state, (s: SharedWifiState) => {
        this.wifiList = s.wifiList

        // ① 从扫描器获取频段/信道（可能为 0）
        this.freqVal = s.connectedFreq
        this.channel = s.connectedChannel

        // ② 从 wifiList 中找已连接项，获取 SSID/信号/安全/频段/信道
        let updated = false
        for (let i = 0; i < s.wifiList.length; i++) {
          const item = s.wifiList[i]
          if (item.isConnected || item.ssid === s.connectedSsid) {
            this.ssid = item.ssid
            this.signal = item.signal || this.signal
            this.security = item.security || '—'
            if (item.freq > 0) this.freqVal = item.freq
            if (item.channel > 0) this.channel = item.channel
            updated = true
            break
          }
        }

        // ③ 用扫描器的 connectedSsid/connectedSignal 兜底
        if (!updated && s.connectedSsid && s.connectedSsid !== '') {
          this.ssid = s.connectedSsid
          this.signal = s.connectedSignal > -200 ? s.connectedSignal : this.signal
          updated = true
        }

        // ④ 最终兜底：wifiList 不为空时取第一项（fallback 模式下的最佳可用数据）
        if (!updated && s.wifiList.length > 0) {
          const first = s.wifiList[0]
          this.ssid = first.ssid
          this.signal = first.signal || this.signal
          this.security = first.security || '—'
          if (first.freq > 0) this.freqVal = first.freq
          if (first.channel > 0) this.channel = first.channel
        }

        // ⑤ 有任何 WiFi 数据 → 标记为已连接
        if (this.ssid && this.ssid !== '—' && this.ssid !== '<隐藏网络>') {
          this.isConnected = true
        }
      })
    } catch (_e) {
      // 扫描失败时保持默认值，不做任何操作
    }
  }

  private get freqLabel(): string {
    if (this.freqVal >= 5) return '5GHz'
    if (this.freqVal >= 2) return '2.4GHz'
    return '—'
  }

  /** 频段副标题：仅显示信道号 */
  private get bandChannelDisplay(): string {
    return this.channel > 0 ? 'CH ' + this.channel : ''
  }

  /** 频段卡片主文字颜色：有数据时用紫色，无数据时用中性色 */
  private get bandAccent(): string {
    return this.freqVal > 0 ? COLOR_PURPLE : adaptiveTextSecondary(this.isDark)
  }

  build() {
    Stack() {
      Stack().width('100%').height('100%').hitTestBehavior(HitTestMode.None)
      Circle().width(280).height(280)
        .fill(this.isDark ? 'rgba(49,122,247,0.05)' : 'rgba(0,102,255,0.03)')
        .position({ right: -100, top: -60 })
      Circle().width(180).height(180)
        .fill(this.isDark ? 'rgba(91,154,255,0.03)' : 'rgba(51,136,255,0.02)')
        .position({ left: -60, top: '30%' })
      Circle().width(200).height(200)
        .fill(this.isDark ? 'rgba(49,122,247,0.04)' : 'rgba(0,102,255,0.02)')
        .position({ right: 40, bottom: -40 })

      Column() {
        Scroll() {
          Column({ space: 0 }) {
            // ── 标题行 ──
            this.titleRow()
            // ── 连接卡片 ──
            this.connectCard()
            // ── 网络状态 ──
            this.sectionLabel($r('app.string.section_network_status'))
            this.statsGrid()
            // ── 快捷工具 ──
            this.sectionLabel($r('app.string.section_quick_tools'))
            this.toolsGrid()
            Row().height(80)
          }.width('100%').padding({ left: 16, right: 16 })
        }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off).width('100%')
          .edgeEffect(EdgeEffect.Spring)
      }
    }.width('100%').height('100%')
      .linearGradient({ direction: GradientDirection.Bottom, colors: adaptiveBackgroundList(this.isDark) })
  }

  @Builder titleRow() {
    Row() {
      Column({ space: 2 }) {
        Text('WLAN').fontSize(28).fontWeight(800).fontColor(adaptiveTextPrimary(this.isDark)).letterSpacing(-0.5)
        Text($r('app.string.brand_second')).fontSize(28).fontWeight(800).fontColor(adaptivePrimaryLight(this.isDark)).letterSpacing(-0.5)
      }
      Blank()
      // 独立 WiFi 连接状态指示组件
      WifiConnectionCard({ isDark: this.isDark })
    }.width('100%').padding({ top: 56, bottom: 16 })
  }

  @Builder sectionLabel(s: Resource) {
    Text(s).fontSize(12).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark))
      .letterSpacing(0.15).textCase(TextCase.UpperCase)
      .width('100%').padding({ top: 20, bottom: 12 })
  }

  @Builder connectCard() {
    Column() {
      Row() {
        Column() {
          Text('W').fontSize(20).fontWeight(800).fontColor(adaptivePrimaryLight(this.isDark))
        }.width(48).height(48).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          .backgroundColor(adaptivePrimaryBg(this.isDark)).borderRadius(14)

        Column({ space: 2 }) {
          Text(this.ssid).fontSize(17).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.security + ' · CH ' + (this.channel > 0 ? String(this.channel) : '—')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDark))
        }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 14 })

        Column() {
          Text(String(this.signal)).fontSize(26).fontWeight(800)
            .fontColor(sigCol(this.signal, this.isDark)).fontFamily('HarmonyOS Sans Mono')
          Text($r('app.string.dbm_unit')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDark))
        }.alignItems(HorizontalAlign.Center).width(68)
      }.width('100%').margin({ bottom: 14 })

      Row().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))

      Row() {
        this.mCell($r('app.string.ip_address'), this.ipAddress)
        this.mDiv()
        GatewayInfo({ isDark: this.isDark })
        this.mDiv()
        this.mCell($r('app.string.dns'), this.dns)
      }.width('100%').padding({ top: 14 })
    }.width('100%').padding(18)
      .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_2XL)
      .border({ width: 1, color: this.isDark ? 'rgba(49,122,247,0.12)' : 'rgba(0,102,255,0.10)', style: BorderStyle.Solid })
      .clip(true)
  }

  @Builder mCell(label: Resource, value: string) {
    Column({ space: 2 }) {
      Text(value).fontSize(12).fontWeight(600).fontColor(adaptiveTextPrimary(this.isDark))
        .fontFamily('HarmonyOS Sans Mono').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(label).fontSize(11).fontColor(adaptiveTextSecondary(this.isDark))
    }.layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder mDiv() {
    Column().width(1).height(28).backgroundColor(adaptiveDivider(this.isDark))
  }

  @Builder statsGrid() {
    Grid() {
      GridItem() {
        this.stat($r('app.string.signal_strength'), String(this.signal), this.sigLabel(this.signal), sigCol(this.signal, this.isDark))
      }
      GridItem() { LinkSpeedStat({ isDark: this.isDark }) }
      GridItem() { LatencyStat({ isDark: this.isDark }) }
      GridItem() {
        this.stat($r('app.string.current_band'), this.freqLabel, this.bandChannelDisplay, this.bandAccent)
      }
    }.columnsTemplate('1fr 1fr').columnsGap(10).rowsGap(10).width('100%')
  }

  @Builder stat(label: Resource, value: string, sub: ResourceStr, accent: string) {
    Column({ space: 2 }) {
      Text(value).fontSize(24).fontWeight(800).fontColor(accent).fontFamily('HarmonyOS Sans Mono').letterSpacing(-0.3)
      Text(label).fontSize(11).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(500)
      Text(sub).fontSize(10).fontColor(adaptiveTextSecondary(this.isDark))
    }.width('100%').height(86).padding(14).alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center)
      .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
      .border({ width: 1, color: adaptiveDivider(this.isDark), style: BorderStyle.Solid }).clip(true)
  }

  @Builder toolsGrid() {
    Grid() {
      ForEach(TOOLS, (t: ToolItem) => {
        GridItem() {
          Column({ space: 6 }) {
            Column() {
              Text(t.letter).fontSize(14).fontWeight(700).fontColor(adaptivePrimaryLight(this.isDark))
            }.width(44).height(44).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
              .backgroundColor(t.color).borderRadius(12)
            Text(t.name).fontSize(10).fontWeight(500).fontColor(adaptiveTextSecondary(this.isDark)).textAlign(TextAlign.Center)
          }.width('100%').padding({ top: 10, bottom: 10 }).alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center).onClick(() => { this.navigateTo(t.res) })
        }
      }, (t: ToolItem): string => t.res)
    }.columnsTemplate('1fr 1fr 1fr 1fr 1fr').columnsGap(0).rowsGap(0).width('100%').margin({ top: 4 })
  }

  private navigateTo(res: string): void {
    let route: RouteName
    switch (res) {
      case 'ping': route = 'ping'; break
      case 'route': route = 'traceroute'; break
      case 'dns': route = 'dns'; break
      case 'speed': route = 'speedtest'; break
      case 'port': route = 'portscan'; break
      case 'subnet': route = 'subnet'; break
      case 'geo': route = 'ipgeo'; break
      case 'lan': route = 'lanscan'; break
      case 'settings': route = 'settings'; break
      default: return
    }
    RouterManager.navigate(route)
  }

  private sigLabel(dbm: number): Resource {
    if (dbm >= -50) return $r('app.string.signal_excellent')
    if (dbm >= -65) return $r('app.string.signal_good')
    if (dbm >= -80) return $r('app.string.signal_average')
    return $r('app.string.signal_weak')
  }
}
