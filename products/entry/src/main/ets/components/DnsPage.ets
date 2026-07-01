// DnsPage — 完整参照旧版：多服务器 DoH + 系统 DNS 兜底 + 历史记录 + 记录筛选
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveTextCyan, adaptiveTextGreen, adaptiveTextAmber,
  adaptiveCardBg, adaptiveCardDarkGlass,
  adaptiveBorderCyan, adaptiveBackgroundList, adaptiveBtnBg,
  adaptivePrimaryBg, adaptiveSuccess, adaptiveInfo, adaptiveDanger, adaptiveWarning,
  RADIUS_MD
} from '@wifi-analyzer/design-system';
import { RouterManager, NetworkTimeout } from '@wifi-analyzer/core';
import { DnsLookupEngine, DnsLookupResult, DnsRecord, DnsServerPreset, DnsHistoryEntry } from '@wifi-analyzer/network-tools';
import { common } from '@kit.AbilityKit';

const TAG = '[DnsPage]'

@Builder
export function DnsPageBuilder() {
  NavDestination() {
    DnsPage()
  }
  .title($r('app.string.tool_dns'))
  .hideTitleBar(true)
}

@Component
export struct DnsPage {
  @StorageLink('isDarkMode') isDark: boolean = false
  @State viewMode: string = 'idle' // idle | querying | result
  @State inputText: string = ''
  @State selectedServerIndex: number = 0
  @State filterType: string = 'all'
  @State result: DnsLookupResult = { domain: '', records: [], queryTime: 0, server: '', status: 'error', errorMessage: '' }
  @State dnsHistory: DnsHistoryEntry[] = []
  @State showHistory: boolean = false
  private engine: DnsLookupEngine = new DnsLookupEngine()
  private serverName(s: DnsServerPreset): string {
    try {
      return getContext().resourceManager.getStringByNameSync(s.resKey)
    } catch (_e) {
      return s.name
    }
  }

  private resolveServer(server: string): string {
    for (let i = 0; i < DnsLookupEngine.DNS_SERVERS.length; i++) {
      if (DnsLookupEngine.DNS_SERVERS[i].name === server) {
        return this.serverName(DnsLookupEngine.DNS_SERVERS[i])
      }
    }
    return server
  }

  private recordTypeValues: string[] = ['all', 'A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT']
  private recordTypeLabels: Resource[] = [
    $r('app.string.filter_all'), $r('app.string.rec_type_a'), $r('app.string.rec_type_aaaa'),
    $r('app.string.rec_type_cname'), $r('app.string.rec_type_mx'), $r('app.string.rec_type_ns'), $r('app.string.rec_type_txt')
  ]
  private popularDomains: string[] = ['baidu.com', 'taobao.com', 'qq.com', 'jd.com', 'weibo.com', 'zhihu.com', 'github.com', 'google.com']

  aboutToAppear(): void {
    this.loadDnsHistory()
  }

  aboutToDisappear(): void {
    // 清理异步查询可能导致的过期状态更新
    this.viewMode = 'idle'
  }

  private async loadDnsHistory(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.Context
      if (ctx) this.dnsHistory = await DnsLookupEngine.loadHistory(ctx)
    } catch (e) { hilog.warn(0x0000, TAG, 'loadDnsHistory error: %{public}s', JSON.stringify(e)) }
  }

  private async doQuery(): Promise<void> {
    const domain: string = this.inputText.trim()
    if (!domain) return
    this.viewMode = 'querying'
    const queryResult: DnsLookupResult = await this.engine.lookup({
      domain: domain,
      dnsServer: DnsLookupEngine.DNS_SERVERS[this.selectedServerIndex].address,
      timeout: NetworkTimeout.DNS_QUERY_MS
    })
    this.result = queryResult
    this.viewMode = 'result'
    this.filterType = 'all'
    if (queryResult.status === 'success' && queryResult.records.length > 0) {
      this.saveHistoryEntry(queryResult)
    }
  }

  private async saveHistoryEntry(result: DnsLookupResult): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.Context
      if (!ctx) return
      await DnsLookupEngine.addHistoryEntry(ctx, {
        domain: result.domain,
        server: result.server,
        timestamp: Date.now(),
        recordCount: result.records.length,
        queryTime: result.queryTime
      })
      this.dnsHistory = await DnsLookupEngine.loadHistory(ctx)
    } catch (e) { hilog.warn(0x0000, TAG, 'saveHistoryEntry error: %{public}s', JSON.stringify(e)) }
  }

  private async clearHistory(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.Context
      if (ctx) { await DnsLookupEngine.clearHistory(ctx); this.dnsHistory = [] }
    } catch (e) { hilog.warn(0x0000, TAG, 'clearHistory error: %{public}s', JSON.stringify(e)) }
  }

  private getFilteredRecords(): DnsRecord[] {
    if (this.result.records.length === 0) return []
    if (this.filterType === 'all') return this.result.records
    return this.result.records.filter((r: DnsRecord): boolean => r.type === this.filterType)
  }

  private formatServerName(idx: number): string {
    const s = DnsLookupEngine.DNS_SERVERS[idx]
    return s ? s.name : ''
  }

  build() {
    Stack() {
      Column().width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Bottom, colors: adaptiveBackgroundList(this.isDark) })
      Circle().width(280).height(280)
        .fill(this.isDark ? 'rgba(59,130,246,0.06)' : 'rgba(59,130,246,0.04)')
        .position({ x: -60, y: -60 })
      Circle().width(180).height(180)
        .fill(this.isDark ? 'rgba(59,130,246,0.04)' : 'rgba(59,130,246,0.03)')
        .position({ x: '68%', y: '45%' })
      Column() {
        Row() {
          Row() { Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark)) }
            .width(34).height(34).justifyContent(FlexAlign.Center).borderRadius(10)
            .backgroundColor(adaptiveBtnBg(this.isDark))
            .onClick(() => {
              if (this.viewMode === 'result' || this.viewMode === 'querying') {
                this.viewMode = 'idle'; this.result = { domain: '', records: [], queryTime: 0, server: '', status: 'error', errorMessage: '' }
              } else { RouterManager.goBack() }
            })
          Blank()
          if (this.viewMode === 'idle') {
            Row() { Text($r('app.string.history_tab')).fontSize(11).fontWeight(600).fontColor(adaptiveTextCyan(this.isDark)) }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(this.isDark ? 'rgba(59,130,246,0.12)' : 'rgba(59,130,246,0.08)').borderRadius(6)
              .onClick(() => { this.showHistory = !this.showHistory })
          }
        }.width('100%').padding({ left: 20, right: 20, top: 44 }).alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          this.IdleView()
        } else if (this.viewMode === 'querying') {
          this.QueryingView()
        } else if (this.viewMode === 'result') {
          this.ResultView()
        }

        if (this.showHistory) {
          this.HistoryModal()
        }
      }.width('100%').height('100%')
    }.width('100%').height('100%')
  }

  // ═══════════════ idle 状态 ═══════════════

  @Builder IdleView() {
    Scroll() {
      Column({ space: 14 }) {
        // 搜索栏
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            TextInput({ text: this.inputText, placeholder: $r('app.string.input_domain_placeholder') })
              .fontColor(adaptiveTextPrimary(this.isDark)).placeholderColor(adaptiveTextTertiary(this.isDark))
              .fontSize(14).layoutWeight(1).height(42)
              .backgroundColor(adaptiveBtnBg(this.isDark)).borderRadius(8)
              .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).padding({ left: 14 })
              .onChange((v: string) => { this.inputText = v })
              .onSubmit(() => { this.doQuery() })
            Row() { Text($r('app.string.query_btn')).fontSize(12).fontWeight(700).fontColor(Color.White) }
              .height(42).justifyContent(FlexAlign.Center).padding({ left: 16, right: 16 })
              .linearGradient({ angle: 135, colors: [['rgba(49,122,247,0.4)', 0], ['rgba(49,122,247,0.8)', 1]] }).borderRadius(8)
              .onClick(() => { this.doQuery() })
          }
        }.width('100%').padding(16)
          .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] })
          .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)

        // DNS 服务器选择
        Column({ space: 8 }) {
          Text($r('app.string.dns_server_list')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(700).width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(DnsLookupEngine.DNS_SERVERS, (s: DnsServerPreset, idx: number) => {
              Row() {
                Circle().width(6).height(6).fill(s.color)
                Text(this.serverName(s)).fontSize(10).fontWeight(600).fontColor(idx === this.selectedServerIndex ? s.color : adaptiveTextTertiary(this.isDark)).margin({ left: 4 })
              }.padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(idx === this.selectedServerIndex
                  ? (this.isDark ? s.color + '22' : s.color + '15')
                  : adaptiveBtnBg(this.isDark))
                .borderRadius(6).margin({ bottom: 4, right: 6 })
                .onClick(() => { this.selectedServerIndex = idx })
            }, (s: DnsServerPreset, idx: number): string => s.resKey + String(idx))
          }.width('100%')
        }.width('100%').padding(16)
          .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] })
          .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)

        // 常用域名
        Column({ space: 8 }) {
          Text($r('app.string.common_domains_title')).fontSize(11).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(700).width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.popularDomains, (d: string) => {
              Row() { Text(d).fontSize(10).fontWeight(600).fontColor(adaptiveTextCyan(this.isDark)) }
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor(adaptivePrimaryBg(this.isDark)).borderRadius(6).margin({ bottom: 4, right: 6 })
                .onClick(() => { this.inputText = d; this.doQuery() })
            }, (d: string): string => d)
          }.width('100%')
        }.width('100%').padding(16)
          .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] })
          .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)

        // 功能说明
        this.FeatureCard()
      }.padding({ left: 20, right: 20, top: 8, bottom: 20 })
    }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off)
  }

  // ═══════════════ 查询中 ═══════════════

  @Builder QueryingView() {
    Column({ space: 14 }) {
      Text($r('app.string.querying')).fontSize(14).fontColor(adaptiveInfo(this.isDark))
        .width('100%').textAlign(TextAlign.Center).padding({ top: 20 })
      Text($r('app.string.querying_with') + ' ' + this.formatServerName(this.selectedServerIndex) + ' ' + $r('app.string.query_suffix')).fontSize(11).fontColor(adaptiveTextTertiary(this.isDark))
        .width('100%').textAlign(TextAlign.Center)
    }.width('100%').height(180).justifyContent(FlexAlign.Center)
  }

  // ═══════════════ 结果视图 ═══════════════

  @Builder ResultView() {
    Scroll() {
      Column({ space: 14 }) {
        // 域名信息卡
        Row({ space: 12 }) {
          Row() { Text('🌐').fontSize(20) }
            .width(44).height(44).justifyContent(FlexAlign.Center)
            .backgroundColor(adaptivePrimaryBg(this.isDark)).borderRadius(22)
          Column({ space: 2 }) {
            Text(this.result.domain).fontSize(14).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
            Row({ space: 6 }) {
              Row() { Text(this.resolveServer(this.result.server) || this.serverName(DnsLookupEngine.DNS_SERVERS[0])).fontSize(9).fontWeight(600).fontColor(adaptiveInfo(this.isDark)) }
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(this.isDark ? 'rgba(49,122,247,0.12)' : 'rgba(49,122,247,0.08)').borderRadius(4)
              Text(String(this.result.queryTime) + 'ms').fontSize(9).fontColor(adaptiveTextTertiary(this.isDark))
            }
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        }.width('100%').padding(16)
          .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] })
          .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)

        // 记录类型筛选
        if (this.result.records.length > 0) {
          Row({ space: 6 }) {
            ForEach(this.recordTypeValues, (t: string, idx: number) => {
              if (t === 'all' || this.result.records.some((r: DnsRecord): boolean => r.type === t)) {
                Row() { Text(this.recordTypeLabels[idx]).fontSize(9).fontWeight(700)
                  .fontColor(t === this.filterType ? adaptiveTextCyan(this.isDark) : adaptiveTextTertiary(this.isDark)) }
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor(t === this.filterType ? adaptivePrimaryBg(this.isDark) : adaptiveBtnBg(this.isDark))
                  .border({ width: 1, color: t === this.filterType ? adaptiveBorderCyan(this.isDark) : 'transparent', style: BorderStyle.Solid }).borderRadius(6)
                  .onClick(() => { this.filterType = t })
              }
            }, (t: string): string => t)
          }.width('100%')
        }

        // 记录列表
        if (this.result.status === 'success' && this.result.records.length > 0) {
          ForEach(this.getFilteredRecords(), (r: DnsRecord) => {
            this.recordCard(r.type, r.value, r.ttl)
          }, (r: DnsRecord): string => r.type + '_' + r.value + '_' + String(r.ttl))
        } else {
          // 错误状态
          Column({ space: 12 }) {
            Row() { Text('!').fontSize(24).fontWeight(800).fontColor(adaptiveDanger(this.isDark)) }
              .width(56).height(56).justifyContent(FlexAlign.Center)
              .backgroundColor(this.isDark ? 'rgba(217,72,56,0.12)' : 'rgba(217,72,56,0.08)').borderRadius(28)
            Text(this.result.errorMessage || $r('app.string.query_failed')).fontSize(13).fontColor(adaptiveDanger(this.isDark))
          }.width('100%').height(180).justifyContent(FlexAlign.Center)
            .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] })
            .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
        }

        // 操作按钮
        Row({ space: 10 }) {
          Row() { Text($r('app.string.back_btn')).fontSize(12).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark)) }
            .height(36).justifyContent(FlexAlign.Center).padding({ left: 16, right: 16 })
            .backgroundColor(adaptiveBtnBg(this.isDark)).borderRadius(8).layoutWeight(1)
            .onClick(() => { this.viewMode = 'idle' })
          Row() { Text($r('app.string.re_query')).fontSize(12).fontWeight(700).fontColor(Color.White) }
            .height(36).justifyContent(FlexAlign.Center).padding({ left: 16, right: 16 })
            .linearGradient({ angle: 135, colors: [['rgba(49,122,247,0.4)', 0], ['rgba(49,122,247,0.8)', 1]] }).borderRadius(8).layoutWeight(1)
            .onClick(() => { this.doQuery() })
        }.width('100%')
      }.padding({ left: 20, right: 20, top: 8, bottom: 20 })
    }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off)
  }

  // ═══════════════ 历史记录 ═══════════════

  @Builder HistoryModal() {
    Column({ space: 10 }) {
      Row() {
        Text($r('app.string.query_history')).fontSize(13).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
        Blank()
        if (this.dnsHistory.length > 0) {
          Text($r('app.string.clear')).fontSize(10).fontColor(adaptiveDanger(this.isDark))
            .onClick(() => { this.clearHistory() })
        }
        Text('✕').fontSize(14).fontColor(adaptiveTextTertiary(this.isDark)).margin({ left: 12 })
          .onClick(() => { this.showHistory = false })
      }.width('100%')
      if (this.dnsHistory.length > 0) {
        ForEach(this.dnsHistory.slice(0, 20), (h: DnsHistoryEntry) => {
          Row({ space: 10 }) {
            Text('🌐').fontSize(14)
            Column({ space: 2 }) {
              Text(h.domain).fontSize(12).fontWeight(600).fontColor(adaptiveTextPrimary(this.isDark))
              Row({ space: 8 }) {
                Text(h.server).fontSize(9).fontColor(adaptiveInfo(this.isDark))
                Text(this.formatTime(h.timestamp)).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark))
                Text(String(h.recordCount) + ' records').fontSize(9).fontColor(adaptiveTextAmber(this.isDark))
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          }.width('100%').padding(12)
            .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).borderRadius(10)
            .onClick(() => { this.inputText = h.domain; this.showHistory = false; this.doQuery() })
        }, (h: DnsHistoryEntry): string => String(h.timestamp))
      } else {
        Text($r('app.string.no_history')).fontSize(11).fontColor(adaptiveTextTertiary(this.isDark)).width('100%').textAlign(TextAlign.Center).padding({ top: 12, bottom: 12 })
      }
    }.width('100%').padding(16)
      .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] })
      .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
      .margin({ left: 20, right: 20 })
  }

  // ═══════════════ 功能说明 ═══════════════

  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.feature_guide')).fontSize(11).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark))
        .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 12 })
      Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
      this.featureItem('🔍', $r('app.string.dns_real_query'), $r('app.string.dns_real_query_desc'))
      Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
      this.featureItem('🌐', $r('app.string.dns_multi_server_title'), $r('app.string.dns_server_list_desc'))
      Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
      this.featureItem('📋', $r('app.string.dns_all_types'), $r('app.string.dns_all_types_desc'))
    }.width('100%')
      .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] })
      .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD).clip(true)
  }

  @Builder featureItem(emoji: string, title: Resource, desc: Resource) {
    Row({ space: 12 }) {
      Row() { Text(emoji).fontSize(14) }
        .width(32).height(32).justifyContent(FlexAlign.Center)
        .backgroundColor(this.isDark ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)').borderRadius(16)
      Column({ space: 2 }) {
        Text(title).fontSize(12).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
        Text(desc).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }.width('100%').padding({ left: 14, right: 14, top: 12, bottom: 12 })
  }

  // ═══════════════ 记录卡片 ═══════════════

  @Builder recordCard(type: string, value: string, ttl: number) {
    Row({ space: 10 }) {
      // 类型标签
      Row() { Text(type).fontSize(9).fontWeight(800).fontColor(adaptiveTextCyan(this.isDark)) }
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor(adaptivePrimaryBg(this.isDark)).borderRadius(4)
      // 值 + TTL
      Column({ space: 2 }) {
        Text(value).fontSize(12).fontWeight(600).fontColor(adaptiveTextPrimary(this.isDark))
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          Text('TTL').fontSize(8).fontColor(adaptiveTextTertiary(this.isDark))
          Text(this.formatTtl(ttl)).fontSize(10).fontWeight(600).fontColor(adaptiveTextAmber(this.isDark))
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').padding(12)
      .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).borderRadius(10)
  }

  private formatTtl(sec: number): string {
    if (sec < 60) return String(sec) + 's'
    if (sec < 3600) return String(Math.floor(sec / 60)) + 'm'
    return String(Math.floor(sec / 3600)) + 'h'
  }

  private formatTime(ts: number): string {
    const d = new Date(ts)
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0')
  }
}
