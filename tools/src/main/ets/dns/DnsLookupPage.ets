// DNS 查询页面 — 状态管理 + 容器编排

import promptAction from '@ohos.promptAction'
import { SPACE_LG, SAFE_AREA_TOP, adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium } from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { DnsLookupEngine, DnsLookupResult, DnsServerPreset, DnsLookupConfig, IpFamily, DnsHistoryEntry, DnsRecord } from '../dnslookup/DnsLookupEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import { DnsHistoryModal } from './DnsHistoryModal'
import { DnsIdleView, ServerItem } from './DnsIdleView'
import { DnsResultView } from './DnsResultView'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

@Component
export struct DnsLookupPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State inputText: string = ''
  @State selectedServerIndex: number = 0
  @State ipFamilyIndex: number = 0
  @State viewMode: string = 'idle'
  @State isQuerying: boolean = false
  @State filterType: string = 'all'
  @State serverList: ServerItem[] = []
  @State result: DnsLookupResult = { domain: '', records: [], queryTime: 0, server: '', status: 'error', errorMessage: '' }
  @State popularDomains: string[] = []
  @State showHistoryModal: boolean = false
  @State dnsHistory: DnsHistoryEntry[] = []
  private engine: DnsLookupEngine = new DnsLookupEngine()
  private ipFamilyOptions: IpFamily[] = ['All', 'IPv4', 'IPv6']
  private recordTypes: Resource[] = [$r('app.string.all_types'), $r('app.string.dns_type_a'), $r('app.string.dns_type_aaaa'), $r('app.string.dns_type_cname'), $r('app.string.dns_type_mx'), $r('app.string.dns_type_ns'), $r('app.string.text_record')]
  private recordTypeValues: string[] = ['all', 'A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT']

  aboutToAppear(): void {
    this.loadServers()
    this.popularDomains = DnsLookupEngine.POPULAR_DOMAINS
    this.loadDnsHistory()
  }

  private getFilteredRecords(): DnsRecord[] {
    if (this.result.records.length === 0) return []
    return this.filterType === 'all' ? this.result.records : this.result.records.filter((r) => r.type === this.filterType)
  }

  private async loadDnsHistory(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext()
      if (ctx) this.dnsHistory = await DnsLookupEngine.loadHistory(ctx)
    } catch (e) { hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupPage] loadDnsHistory error: ' + e) }
  }

  private loadServers(): void {
    const items: ServerItem[] = []
    for (let i = 0; i < DnsLookupEngine.DNS_SERVERS.length; i++) {
      const p = DnsLookupEngine.DNS_SERVERS[i]
      const item: ServerItem = { name: p.name, address: p.address, color: p.color, apiUrl: p.apiUrl }
      items.push(item)
    }
    this.serverList = items
  }

  handleBack(): void {
    if (this.viewMode === 'result' || this.viewMode === 'querying') { this.viewMode = 'idle'; this.isQuerying = false }
    else RouterManager.goBack()
  }

  private validateDomain(domain: string): string {
    const t = domain.trim()
    if (t.length === 0) return this.getString($r('app.string.err_empty_input'))
    if (t.length > 253) return this.getString($r('app.string.err_input_too_long'))
    return ValidationPatterns.isValidDomain(t) ? '' : this.getString($r('app.string.err_invalid_domain'))
  }

  private getString(str: Resource): string {
    try { const ctx = this.getUIContext().getHostContext(); return ctx ? ctx.resourceManager.getStringSync(str.id) : '' } catch (e) { return '' }
  }

  async doQuery(): Promise<void> {
    const errorMsg = this.validateDomain(this.inputText.trim())
    if (errorMsg !== '') { promptAction.showToast({ message: errorMsg, duration: 2000 }); return }
    this.isQuerying = true; this.viewMode = 'querying'
    const config: DnsLookupConfig = DnsLookupEngine.getDefaultConfig(this.inputText.trim())
    config.dnsServer = this.serverList[this.selectedServerIndex].address
    config.family = this.ipFamilyOptions[this.ipFamilyIndex]
    const queryResult = await this.engine.lookup(config)
    this.result = queryResult; this.isQuerying = false; this.viewMode = 'result'
    if (queryResult.status === 'success' && queryResult.records.length > 0) this.saveHistoryEntry(queryResult)
  }

  private async saveHistoryEntry(result: DnsLookupResult): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext()
      if (!ctx) return
      await DnsLookupEngine.addHistoryEntry(ctx, { domain: result.domain, server: result.server, timestamp: Date.now(), recordCount: result.records.length, queryTime: result.queryTime })
      this.dnsHistory = await DnsLookupEngine.loadHistory(ctx)
    } catch (e) { hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DnsLookupPage] saveHistoryEntry error: ' + e) }
  }

  build() {
    Stack() {
      Column() {}.width('100%').height('100%').linearGradient({ direction: GradientDirection.Bottom, colors: adaptiveBackgroundList(this.isDarkMode) })
      Circle().width(280).height(280).fill(adaptiveGlowLarge(this.isDarkMode)).position({ x: -60, y: -60 })
      Circle().width(180).height(180).fill(adaptiveGlowMedium(this.isDarkMode)).position({ x: '68%', y: '45%' })
      Column() {
        Row() { BackButtonGlass({ onBack: () => this.handleBack() }); Blank() }.width('100%').padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP }).alignItems(VerticalAlign.Center)
        if (this.viewMode === 'idle') {
          DnsIdleView({ isDarkMode: this.isDarkMode, inputText: this.inputText, selectedServerIndex: this.selectedServerIndex, ipFamilyIndex: this.ipFamilyIndex, serverList: this.serverList, popularDomains: this.popularDomains,
            onInputChange: (v: string) => this.inputText = v, onSubmit: () => this.doQuery(), onServerChange: (i: number) => this.selectedServerIndex = i,
            onIpFamilyChange: (i: number) => this.ipFamilyIndex = i, onDomainTap: (d: string) => { this.inputText = d; this.doQuery() }, onOpenHistory: () => this.showHistoryModal = true })
          .transition(TransitionEffect.asymmetric(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 })).animation({ duration: 300, curve: Curve.FastOutSlowIn }), TransitionEffect.OPACITY.animation({ duration: 200 })))
        } else {
          DnsResultView({ isDarkMode: this.isDarkMode, result: this.result, filterType: this.filterType, recordTypes: this.recordTypes, recordTypeValues: this.recordTypeValues, filteredRecords: this.getFilteredRecords(),
            onBack: () => this.handleBack(), onReQuery: () => this.doQuery(), onFilterChange: (i: number) => this.filterType = this.recordTypeValues[i] })
          .transition(TransitionEffect.asymmetric(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 })).animation({ duration: 300, curve: Curve.FastOutSlowIn }), TransitionEffect.OPACITY.animation({ duration: 200 })))
        }
      }.width('100%').height('100%')
      if (this.showHistoryModal) {
        DnsHistoryModal({ isDarkMode: this.isDarkMode, history: this.dnsHistory, onClose: () => this.showHistoryModal = false,
          onClearHistory: async () => { const ctx = this.getUIContext().getHostContext(); if (ctx) { await DnsLookupEngine.clearHistory(ctx); this.dnsHistory = [] } },
          onItemClick: (entry: DnsHistoryEntry) => { this.inputText = entry.domain; this.doQuery() } })
      }
    }.width('100%').height('100%')
  }
}
