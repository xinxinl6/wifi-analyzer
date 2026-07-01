// =============================================
// WifiListSection — HM7 沉浸光感信号列表 v4.0
// 信号柱 · 材质列表项 · 安全标签 · 边缘光感
// v4.0：接入真实 WiFi 扫描数据 (WifiDataManager)
// =============================================

import {
  RADIUS_XL, RADIUS_FULL,
  adaptiveTextPrimary, adaptiveTextSecondary,
  adaptivePrimaryLight, adaptivePrimaryBg,
  adaptiveCardDarkGlass, adaptiveDivider, adaptiveBackgroundList,
  adaptiveSuccess, adaptiveInfo, adaptiveWarning, adaptiveDanger,
  adaptiveBtnBg,
} from '@wifi-analyzer/design-system'
import {
  WifiItem, WifiDataManager, SharedWifiState
} from '@wifi-analyzer/core'

// ── 安全类型徽章 ──
interface SecBadge { label: string; color: string; bg: string }
function secInfo(t: string, isDark: boolean): SecBadge {
  switch (t) {
    case 'WPA3': case 'SAE': return { label: 'WPA3', color: adaptiveSuccess(isDark), bg: 'rgba(91,168,84,0.12)' }
    case 'WPA2': case 'PSK': case 'EAP': return { label: 'WPA2', color: adaptiveInfo(isDark), bg: 'rgba(94,161,255,0.12)' }
    case 'WPA': return { label: 'WPA', color: adaptiveWarning(isDark), bg: 'rgba(219,107,66,0.12)' }
    case 'WEP': return { label: 'WEP', color: adaptiveDanger(isDark), bg: 'rgba(217,72,56,0.12)' }
    default: return { label: 'OPEN', color: adaptiveTextSecondary(isDark), bg: 'rgba(255,255,255,0.06)' }
  }
}

// ── 信号色 ──
function sigCol(dbm: number, isDark: boolean): string {
  return dbm >= -50 ? adaptiveSuccess(isDark)
    : dbm >= -65 ? adaptiveInfo(isDark)
    : dbm >= -80 ? adaptiveWarning(isDark)
    : adaptiveDanger(isDark)
}

@ComponentV2
export struct WifiListSection {
  @Param isDark: boolean = true
  @Param deviceWidth: number = 360
  @Local filter: string = 'all'
  @Local isScanning: boolean = false
  @Local wifiList: WifiItem[] = []
  @Local connectedSsid: string = ''
  @Local errorMsg: string = ''
  @Local isLoaded: boolean = false
  @Local isPullRefreshing: boolean = false
  private wifiDataManager: WifiDataManager = WifiDataManager.getInstance()
  private scanMinTimer: number = -1

  aboutToAppear(): void {
    this.doScan()
  }

  aboutToDisappear(): void {
    if (this.scanMinTimer !== -1) {
      clearTimeout(this.scanMinTimer)
      this.scanMinTimer = -1
    }
  }

  async doScan(): Promise<void> {
    if (this.isScanning) return
    this.isScanning = true
    this.isLoaded = false
    this.isPullRefreshing = true
    const scanStartTime: number = Date.now()

    try {
      await this.wifiDataManager.scanAndUpdate(
        this.wifiDataManager.getInitialState(),
        (s: SharedWifiState) => {
          this.wifiList = s.wifiList
          this.connectedSsid = s.connectedSsid
          this.errorMsg = String(s.error || '')
          this.isLoaded = s.isLoaded
        }
      )
    } catch (e) {
      // 扫描异常，静默恢复
    }

    // 最小扫描动画显示 600ms，确保用户能看到刷新反馈
    const elapsed: number = Date.now() - scanStartTime
    if (elapsed < 600) {
      await new Promise<void>((resolve: () => void) => {
        this.scanMinTimer = setTimeout(resolve, 600 - elapsed)
      })
    }

    // 无论如何都重置，保证按钮不会卡死
    this.isScanning = false
    this.isPullRefreshing = false
  }

  get filtered(): WifiItem[] {
    if (this.filter === '5g') return this.wifiList.filter((i: WifiItem): boolean => i.freq >= 5)
    if (this.filter === '2.4g') return this.wifiList.filter((i: WifiItem): boolean => i.freq >= 2 && i.freq < 5)
    return this.wifiList
  }

  get scanCount(): number { return this.filtered.length }

  // ── 响应式断点 ──
  get columns(): number {
    if (this.deviceWidth >= 900) return 3
    if (this.deviceWidth >= 600) return 2
    return 1
  }
  get contentPadding(): number {
    if (this.deviceWidth >= 900) return 32
    if (this.deviceWidth >= 600) return 24
    return 16
  }
  get gridTemplate(): string {
    if (this.columns === 3) return '1fr 1fr 1fr'
    if (this.columns === 2) return '1fr 1fr'
    return '1fr'
  }
  get isGrid(): boolean { return this.columns > 1 }

  build() {
    Column() {
      // 标题行（固定，不随列表滚动）
      Row() {
        Column({ space: 2 }) {
          Text($r('app.string.nearby'))
            .fontSize(28).fontWeight(800)
            .fontColor(adaptiveTextPrimary(this.isDark)).letterSpacing(-0.5)
        }
        Blank()
        // 扫描按钮
        Row({ space: 4 }) {
          Text('⌕')
            .fontSize(14)
            .fontColor(adaptivePrimaryLight(this.isDark))
          Text(this.isScanning ? $r('app.string.scanning') : $r('app.string.scan_btn'))
            .fontSize(12).fontWeight(500)
            .fontColor(adaptivePrimaryLight(this.isDark))
        }
        .padding({ left: 14, right: 16, top: 8, bottom: 8 })
        .borderRadius(RADIUS_FULL)
        .backgroundColor(adaptivePrimaryBg(this.isDark))
        .onClick(() => this.doScan())
        .animation({ duration: 200, curve: Curve.Friction })
      }.width('100%')
        .padding({ left: this.contentPadding, right: this.contentPadding, top: 56, bottom: 6 })

      // 筛选 + 统计（固定）
      Row({ space: 8 }) {
        Row({ space: 6 }) {
          this.pill($r('app.string.filter_all'), 'all')
          this.pill($r('app.string.band_5g'), '5g')
          this.pill($r('app.string.band_24g'), '2.4g')
        }
        Blank()
        Text() {
          Span(this.scanCount.toString())
          Span($r('app.string.networks_count'))
        }
          .fontSize(10).fontColor(adaptiveTextSecondary(this.isDark))
      }.width('100%')
        .padding({ left: this.contentPadding, right: this.contentPadding, top: 6, bottom: 16 })

      // ── 下拉刷新 + 可滚动列表 ──
      Refresh({ refreshing: $$this.isPullRefreshing }) {
        Scroll() {
          Column() {
            if (!this.isLoaded && this.wifiList.length === 0) {
              this.loadingView()
            } else if (this.filtered.length === 0) {
              this.emptyView()
            } else {
              Grid() {
                ForEach(this.filtered, (item: WifiItem, idx: number) => {
                  GridItem() { this.wifiCard(item) }
                }, (item: WifiItem, idx: number): string => item.bssid + String(idx))
              }
              .columnsTemplate(this.gridTemplate)
              .columnsGap(this.isGrid ? 10 : 0)
              .rowsGap(8)
              .width('100%')
            }
            Row().height(this.isGrid ? 60 : 80)
          }.width('100%')
          .padding({ left: this.contentPadding, right: this.contentPadding })
        }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off).width('100%')
          .edgeEffect(EdgeEffect.Spring)
      }
      .onStateChange((refreshState: RefreshStatus) => {
        if (refreshState === RefreshStatus.Refresh) {
          this.doScan()
        } else if (refreshState === RefreshStatus.Done) {
          this.isPullRefreshing = false
        }
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: adaptiveBackgroundList(this.isDark)
    })
  }

  @Builder pill(label: Resource, value: string) {
    Text(label)
      .fontSize(11).fontWeight(this.filter === value ? 600 : 400)
      .fontColor(this.filter === value ? adaptivePrimaryLight(this.isDark) : adaptiveTextSecondary(this.isDark))
      .padding({ left: 16, right: 16, top: 7, bottom: 7 })
      .backgroundColor(this.filter === value ? adaptivePrimaryBg(this.isDark) : adaptiveBtnBg(this.isDark))
      .borderRadius(RADIUS_FULL)
      .onClick(() => { this.filter = value })
      .animation({ duration: 250, curve: Curve.Friction })
  }

  @Builder wifiCard(item: WifiItem) {
    Row({ space: 14 }) {
      this.sigBars(item.signal)
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(item.ssid || '(Hidden Network)')
            .fontSize(15).fontWeight(600)
            .fontColor(adaptiveTextPrimary(this.isDark))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          if (item.isConnected) {
            Text($r('app.string.connected'))
              .fontSize(9).fontWeight(600)
              .fontColor(adaptiveSuccess(this.isDark))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('rgba(91,168,84,0.12)')
              .borderRadius(4)
          }
        }.width('100%')
        Row({ space: 6 }) {
          Text(`CH ${item.channel}`)
            .fontSize(10).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(500)
          Circle().width(2).height(2).fill(adaptiveDivider(this.isDark))
          Text(item.freq >= 5 ? '5GHz' : '2.4GHz')
            .fontSize(10).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(500)
          Circle().width(2).height(2).fill(adaptiveDivider(this.isDark))
          Text(secInfo(item.security, this.isDark).label)
            .fontSize(9).fontWeight(600)
            .fontColor(secInfo(item.security, this.isDark).color)
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .backgroundColor(secInfo(item.security, this.isDark).bg)
            .borderRadius(3)
          Circle().width(2).height(2).fill(adaptiveDivider(this.isDark))
          Text(item.bssid)
            .fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
            .fontFamily('HarmonyOS Sans Mono')
            .maxLines(1)
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Column() {
        Text(`${item.signal}`)
          .fontSize(15).fontWeight(700)
          .fontColor(sigCol(item.signal, this.isDark))
          .fontFamily('HarmonyOS Sans Mono')
        Text('dBm')
          .fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
      }.alignItems(HorizontalAlign.Center).width(52)
    }
    .width('100%').padding(14).margin({ bottom: 8 })
    .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
    .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
    .clip(true)
    .onClick(() => {})
    .animation({ duration: 200, curve: Curve.Friction })
  }

  @Builder sigBars(signal: number) {
    Row({ space: 2 }) {
      ForEach([1, 2, 3, 4], (lv: number) => {
        Column()
          .width(3.5).height(2 * lv + 5)
          .borderRadius(2)
          .backgroundColor(
            (signal >= -50) ||
            (signal >= -65 && lv <= 3) ||
            (signal >= -80 && lv <= 2) ||
            (signal < -80 && lv <= 1)
            ? sigCol(signal, this.isDark)
            : 'rgba(255,255,255,0.10)'
          )
      }, (lv: number): string => `bar${lv}`)
    }
    .width(24).height(22).alignItems(VerticalAlign.Bottom)
  }

  @Builder loadingView() {
    Column({ space: 10 }) {
      LoadingProgress().width(28).height(28).color(adaptivePrimaryLight(this.isDark))
      Text($r('app.string.scanning'))
        .fontSize(14).fontWeight(500)
        .fontColor(adaptiveTextSecondary(this.isDark))
    }
    .width('100%').height(260).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder emptyView() {
    Column({ space: 10 }) {
      Text('—')
        .fontSize(36)
        .fontColor(adaptiveTextSecondary(this.isDark))
      Text($r('app.string.no_networks'))
        .fontSize(15).fontWeight(600)
        .fontColor(adaptiveTextSecondary(this.isDark))
      Text(this.errorMsg || $r('app.string.scan_hint'))
        .fontSize(13)
        .fontColor(adaptiveTextSecondary(this.isDark))
    }
    .width('100%').height(260).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .padding(16)
  }
}
