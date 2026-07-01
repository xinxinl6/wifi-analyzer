// =============================================
// ChannelSection — HM7 沉浸光感信道分析 v4.0
// 柱状图 · 光谱评分 · 推荐信道 · 拥堵热力
// v4.0：接入真实 WiFi 扫描数据，动态计算信道占用
// =============================================

import {
  RADIUS_2XL, RADIUS_XL, RADIUS_FULL,
  adaptiveTextPrimary, adaptiveTextSecondary,
  adaptivePrimaryLight, adaptivePrimaryBg, adaptivePrimary,
  adaptiveCardDarkGlass, adaptiveDivider, adaptiveBackgroundList,
  adaptiveSuccess, adaptiveInfo, adaptiveWarning, adaptiveDanger,
  adaptiveBtnBg,
} from '@wifi-analyzer/design-system'
import {
  WifiItem, WifiDataManager, SharedWifiState
} from '@wifi-analyzer/core'

interface Ch { channel: number; count: number }

@ComponentV2
export struct ChannelSection {
  @Param isDark: boolean = true
  @Param deviceWidth: number = 360
  @Local band: string = '2.4g'
  @Local selectedChannel: number = 1
  @Local wifiList: WifiItem[] = []
  @Local isLoaded: boolean = false
  private wifiDataManager: WifiDataManager = WifiDataManager.getInstance()

  aboutToAppear(): void {
    const state = this.wifiDataManager.getInitialState()
    this.wifiDataManager.scanAndUpdate(state, (s: SharedWifiState) => {
      this.wifiList = s.wifiList
      this.isLoaded = s.isLoaded
    })
  }

  // ── 从真实 WiFi 列表计算信道占用 ──
  private get channelCounts(): Map<number, number> {
    const map = new Map<number, number>()
    for (const item of this.wifiList) {
      const ch = item.channel
      if (ch > 0) {
        map.set(ch, (map.get(ch) ?? 0) + 1)
      }
    }
    return map
  }

  // 各频段信道列表 + 动态数据
  private readonly CH24: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  private readonly CH52: number[] = [36, 40, 44, 48, 52, 56, 60, 64]
  private readonly CH58: number[] = [100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 149, 153, 157, 161, 165]

  private bandChs(b: string): number[] {
    if (b === '5.2g') return this.CH52
    if (b === '5.8g') return this.CH58
    return this.CH24
  }

  get chs(): Ch[] {
    const chs = this.bandChs(this.band)
    const map = this.channelCounts
    const r: Ch[] = []
    for (let i = 0; i < chs.length; i++) {
      r.push({ channel: chs[i], count: map.get(chs[i]) || 0 })
    }
    return r
  }

  get best(): number {
    let b = this.chs[0].channel
    let m = this.chs[0].count
    for (const c of this.chs) {
      if (c.count < m) { m = c.count; b = c.channel }
    }
    return b
  }

  get worstStr(): string {
    let m1 = 0, m2 = 0, c1 = 0, c2 = 0
    for (const c of this.chs) {
      if (c.count >= m1) { m2 = m1; c2 = c1; m1 = c.count; c1 = c.channel }
      else if (c.count > m2) { m2 = c.count; c2 = c.channel }
    }
    return `CH ${c1} & ${c2}`
  }

  get bestText(): string {
    try {
      const idleText: string = getContext().resourceManager.getStringByNameSync('ch_best_idle')
      return 'CH ' + this.best + ' \u2014 ' + idleText
    } catch (_e) {
      return 'CH ' + this.best + ' \u2014 Most idle'
    }
  }

  get avgText(): string {
    try {
      const perCh: string = getContext().resourceManager.getStringByNameSync('ch_per_channel')
      return `${this.avgCount} ${perCh}`
    } catch (_e) {
      return `${this.avgCount} /channel`
    }
  }

  get score(): number {
    let t = 0
    for (const c of this.chs) t += c.count
    return Math.max(10, Math.round(100 - (t / Math.max(1, this.chs.length)) * 8))
  }

  get avgCount(): number {
    let t = 0
    for (const c of this.chs) t += c.count
    return this.chs.length > 0 ? Math.round(t / this.chs.length) : 0
  }

  // ── 响应式图表尺寸 ──
  private get isWide(): boolean { return this.deviceWidth >= 600 }

  private get chartHeight(): number {
    if (this.deviceWidth >= 900) return 180
    if (this.deviceWidth >= 600) return 150
    return 90
  }

  private get barMaxH(): number {
    if (this.deviceWidth >= 900) return 142
    if (this.deviceWidth >= 600) return 116
    return 68
  }

  private get chartColW(): number {
    return this.band === '2.4g' ? (this.isWide ? 34 : 22)
      : this.band === '5.2g' ? (this.isWide ? 42 : 24)
      : (this.isWide ? 32 : 16)
  }

  private get chartBarW(): number {
    return this.band === '2.4g' ? (this.isWide ? 24 : 18)
      : this.band === '5.2g' ? (this.isWide ? 32 : 18)
      : (this.isWide ? 22 : 12)
  }

  private barCol(n: number): string {
    return n <= 1 ? adaptiveSuccess(this.isDark)
      : n <= 3 ? adaptiveInfo(this.isDark)
      : n <= 5 ? adaptiveWarning(this.isDark)
      : adaptiveDanger(this.isDark)
  }

  private scoreCol(): string {
    const s = this.score
    return s >= 80 ? adaptiveSuccess(this.isDark) : s >= 60 ? adaptiveWarning(this.isDark) : adaptiveDanger(this.isDark)
  }

  private scoreLabel(): Resource {
    const s = this.score
    return s >= 85 ? $r('app.string.signal_excellent')
      : s >= 70 ? $r('app.string.signal_good')
      : s >= 50 ? $r('app.string.ch_congested')
      : $r('app.string.ch_severe_congested')
  }

  private bandLabel(): string {
    if (this.band === '2.4g') return '2.4GHz'
    if (this.band === '5.2g') return '5.2GHz'
    return '5.8GHz'
  }
  private bandToVal(b: string): string {
    if (b === '2.4GHz') return '2.4g'
    if (b === '5.2GHz') return '5.2g'
    return '5.8g'
  }
  private isBandActive(b: string): boolean {
    if (b === '2.4GHz') return this.band === '2.4g'
    if (b === '5.2GHz') return this.band === '5.2g'
    return this.band === '5.8g'
  }

  build() {
    Column() {
      Column() {
        Scroll() {
          Column({ space: 0 }) {
            // 标题
            Row() {
              Column({ space: 2 }) {
                Text($r('app.string.ch_analysis'))
                  .fontSize(28).fontWeight(800)
                  .fontColor(adaptiveTextPrimary(this.isDark)).letterSpacing(-0.5)
              }
              Blank()
              Text(this.bandLabel())
                .fontSize(13).fontWeight(500)
                .fontColor(adaptiveTextSecondary(this.isDark))
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(adaptiveBtnBg(this.isDark))
                .borderRadius(RADIUS_FULL)
            }.width('100%').padding({ top: 56, bottom: 14 })

            // 频段切换
            Row({ space: 6 }) {
              ForEach(['2.4GHz', '5.2GHz', '5.8GHz'] as string[], (b: string) => {
                Text(b).fontSize(11)
                  .fontWeight(this.isBandActive(b) ? 600 : 400)
                  .fontColor(this.isBandActive(b)
                    ? adaptivePrimaryLight(this.isDark)
                    : adaptiveTextSecondary(this.isDark))
                  .padding({ left: 16, right: 16, top: 7, bottom: 7 })
                  .backgroundColor(this.isBandActive(b)
                    ? adaptivePrimaryBg(this.isDark)
                    : adaptiveBtnBg(this.isDark))
                  .borderRadius(RADIUS_FULL)
                  .onClick(() => { this.band = this.bandToVal(b) })
                  .animation({ duration: 250, curve: Curve.Friction })
              }, (b: string): string => b)
            }.width('100%').padding({ bottom: 14 })

            if (!this.isLoaded) {
              this.loadingView()
            } else {
              this.chartCard()
              this.scoreCard()
              this.detailCard()
            }

            Row().height(80)
          }.width('100%').padding({ left: 16, right: 16 })
        }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off).width('100%')
          .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: adaptiveBackgroundList(this.isDark)
    })
  }

  @Builder loadingView() {
    Column({ space: 10 }) {
      LoadingProgress().width(28).height(28).color(adaptivePrimaryLight(this.isDark))
      Text($r('app.string.ch_fetching'))
        .fontSize(14).fontWeight(500)
        .fontColor(adaptiveTextSecondary(this.isDark))
    }
    .width('100%').height(300).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder chartCard() {
    Column({ space: 8 }) {
      // 图例
      Row({ space: 12 }) {
        Row({ space: 4 }) {
          Circle().width(6).height(6).fill(adaptiveSuccess(this.isDark))
          Text($r('app.string.ch_idle')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
        }
        Row({ space: 4 }) {
          Circle().width(6).height(6).fill(adaptiveInfo(this.isDark))
          Text($r('app.string.ch_normal')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
        }
        Row({ space: 4 }) {
          Circle().width(6).height(6).fill(adaptiveWarning(this.isDark))
          Text($r('app.string.ch_busy')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
        }
        Row({ space: 4 }) {
          Circle().width(6).height(6).fill(adaptiveDanger(this.isDark))
          Text($r('app.string.ch_congested')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
        }
      }.width('100%')

      Scroll() {
        Row() {
          ForEach(this.chs, (ch: Ch) => {
            Column({ space: 2 }) {
              Column()
                .width(this.chartBarW)
                .height(this.barH(ch.count) + 'px')
                .backgroundColor(this.barCol(ch.count))
                .borderRadius({ topLeft: 3, topRight: 3 })
                .animation({ duration: 400, curve: Curve.Friction })
              Text(String(ch.channel))
                .fontSize(10)
                .fontColor(this.selectedChannel === ch.channel
                  ? adaptivePrimaryLight(this.isDark)
                  : adaptiveTextSecondary(this.isDark))
                .fontWeight(this.selectedChannel === ch.channel ? 600 : 400)
                .textAlign(TextAlign.Center)
            }
            .width(this.chartColW)
            .alignItems(HorizontalAlign.Center)
          }, (ch: Ch): string => String(ch.channel))
        }
        .alignItems(VerticalAlign.Bottom)
        .height(this.chartHeight)
        .padding({ left: 4, right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%').padding(14)
    .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_2XL)
    .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
    .clip(true)
  }

  @Builder scoreCard() {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Column({ space: 2 }) {
          Stack() {
            Circle().width(72).height(72)
              .fill(Color.Transparent)
              .stroke(this.isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)')
              .strokeWidth(5)
            Circle().width(72).height(72)
              .fill(Color.Transparent)
              .stroke(this.scoreCol())
              .strokeWidth(5)
              .strokeDashArray([this.score / 100 * Math.PI * 72, Math.PI * 72])
              .strokeLineCap(LineCapStyle.Round)
              .rotate({ angle: -90 })
            Column() {
              Text(`${this.score}`)
                .fontSize(26).fontWeight(800)
                .fontColor(this.scoreCol())
                .fontFamily('HarmonyOS Sans Mono')
              Text(`/100`)
                .fontSize(10).fontWeight(500)
                .fontColor(adaptiveTextSecondary(this.isDark))
                .offset({ y: -2 })
            }
          }.width(72).height(72)
          Text(this.scoreLabel())
            .fontSize(10).fontWeight(600)
            .fontColor(this.scoreCol())
        }.width(100).height(110)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
        .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)

        Column({ space: 8 }) {
          Column({ space: 3 }) {
            Row({ space: 5 }) {
              Circle().width(6).height(6).fill(adaptiveSuccess(this.isDark))
              Text($r('app.string.ch_recommended'))
                .fontSize(11).fontWeight(600)
                .fontColor(adaptiveSuccess(this.isDark))
            }
            Text(this.bestText)
              .fontSize(13).fontWeight(500)
              .fontColor(adaptiveTextPrimary(this.isDark))
          }.alignItems(HorizontalAlign.Start)

          Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))

          Column({ space: 3 }) {
            Row({ space: 5 }) {
              Circle().width(6).height(6).fill(adaptiveDanger(this.isDark))
              Text($r('app.string.ch_congested_title'))
                .fontSize(11).fontWeight(600)
                .fontColor(adaptiveDanger(this.isDark))
            }
            Text(this.worstStr)
              .fontSize(12).fontColor(adaptiveTextSecondary(this.isDark))
          }.alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1).height(110).padding(14)
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Start)
        .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
        .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
      }.width('100%')
    }.width('100%').padding({ top: 16 })
  }

  @Builder detailCard() {
    Column() {
      Row() {
        Text($r('app.string.ch_detail'))
          .fontSize(11).fontWeight(700)
          .fontColor(adaptiveTextSecondary(this.isDark))
          .letterSpacing(0.15).textCase(TextCase.UpperCase)
      }.width('100%')

      Column({ space: 2 }) {
        Row() {
          Text($r('app.string.ch_count'))
            .fontSize(12).fontColor(adaptiveTextSecondary(this.isDark))
          Blank()
          Text(`${this.chs.length}`)
            .fontSize(13).fontWeight(600)
            .fontColor(adaptiveTextPrimary(this.isDark))
        }.width('100%').padding({ top: 10, bottom: 10 })
        Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))
        Row() {
          Text($r('app.string.ch_avg_usage'))
            .fontSize(12).fontColor(adaptiveTextSecondary(this.isDark))
          Blank()
          Text(this.avgText)
            .fontSize(13).fontWeight(600)
            .fontColor(adaptiveTextPrimary(this.isDark))
        }.width('100%').padding({ top: 10, bottom: 10 })
        Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))
        Row() {
          Text($r('app.string.ch_band'))
            .fontSize(12).fontColor(adaptiveTextSecondary(this.isDark))
          Blank()
          Text(this.bandLabel())
            .fontSize(13).fontWeight(600)
            .fontColor(adaptiveTextPrimary(this.isDark))
        }.width('100%').padding({ top: 10, bottom: 10 })
      }
    }
    .width('100%').padding(14).margin({ top: 16 })
    .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
    .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
    .clip(true)
  }

  private barH(c: number): number {
    let mx = 1
    for (const ch of this.chs) {
      if (ch.count > mx) mx = ch.count
    }
    return Math.max(8, (c / mx) * this.barMaxH)
  }
}
