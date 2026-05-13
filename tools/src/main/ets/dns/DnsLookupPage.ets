// DNS 查询页面组件 — 天蓝色透明毛玻璃悬浮风格
// 使用 Aurora 渐变背景 + 毛玻璃卡片

import promptAction from '@ohos.promptAction'
import {
  COLOR_PRIMARY, COLOR_PRIMARY_LIGHT, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE, COLOR_PINK, COLOR_CYAN, COLOR_INDIGO,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_SOLID, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_LINE,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BackButtonGlass, BackButtonCapsule } from '@wifi-analyzer/design-system'
import { DnsLookupEngine, DnsLookupResult, DnsRecord, DnsRecordType, DnsServerPreset, DnsLookupConfig, IpFamily } from '../dnslookup/DnsLookupEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'

// ==================== 接口定义 ====================

interface ServerItem {
  name: string
  address: string
  color: string
}

// ==================== 组件 ====================

@Component
export struct DnsLookupPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  // 输入
  @State inputText: string = ''
  @State selectedServerIndex: number = 0

  // UI 状态
  @State viewMode: string = 'idle' // 'idle' | 'querying' | 'result'
  @State isQuerying: boolean = false

  // DNS 服务器列表
  @State serverList: ServerItem[] = []

  // 查询结果
  @State result: DnsLookupResult = {
    domain: '',
    records: [],
    queryTime: 0,
    server: '',
    status: 'error',
    errorMessage: '',
  }

  // 常用域名
  @State popularDomains: string[] = []

  // 引擎
  private engine: DnsLookupEngine = new DnsLookupEngine()

  // 获取资源字符串的辅助方法
  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch {
      return ''
    }
  }

  // 筛选记录类型
  @State filterType: string = 'all'

  // IP 类型筛选
  @State ipFamilyIndex: number = 0
  private ipFamilyOptions: IpFamily[] = ['All', 'IPv4', 'IPv6']
  private ipFamilyLabels: Resource[] = [$r('app.string.ip_family_all'), $r('app.string.ip_family_ipv4'), $r('app.string.ip_family_ipv6')]

  private recordTypes: Resource[] = [$r('app.string.all_types'), $r('app.string.dns_type_a'), $r('app.string.dns_type_aaaa'), $r('app.string.dns_type_cname'), $r('app.string.dns_type_mx'), $r('app.string.dns_type_ns'), $r('app.string.text_record')]
  private recordTypeValues: string[] = ['all', 'A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT']

  aboutToAppear(): void {
    this.loadServers()
    this.popularDomains = DnsLookupEngine.POPULAR_DOMAINS
  }

  private loadServers(): void {
    const presets: DnsServerPreset[] = DnsLookupEngine.DNS_SERVERS
    const list: ServerItem[] = []
    for (let i = 0; i < presets.length; i++) {
      const item: ServerItem = {
        name: presets[i].name,
        address: presets[i].address,
        color: presets[i].color,
      }
      list.push(item)
    }
    this.serverList = list
  }

  getFilteredRecords(): DnsRecord[] {
    if (this.result.records.length === 0) return []
    if (this.filterType === 'all') return this.result.records
    const filtered: DnsRecord[] = []
    for (let i = 0; i < this.result.records.length; i++) {
      if (this.result.records[i].type === this.filterType) {
        filtered.push(this.result.records[i])
      }
    }
    return filtered
  }

  getRecordTypeColor(type: DnsRecordType): string {
    switch (type) {
      case 'A': return COLOR_PRIMARY
      case 'AAAA': return COLOR_SUCCESS
      case 'CNAME': return COLOR_WARNING
      case 'MX': return COLOR_CYAN
      case 'NS': return COLOR_INFO
      case 'TXT': return COLOR_PINK
      default: return COLOR_TEXT_TERTIARY
    }
  }

  // ==================== 业务逻辑 ====================

  private validateDomain(domain: string): string {
    const trimmed: string = domain.trim()
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }
    if (trimmed.length > 253) {
      return this.getString($r('app.string.err_input_too_long'))
    }
    if (!ValidationPatterns.isValidDomain(trimmed)) {
      return this.getString($r('app.string.err_invalid_domain'))
    }
    return ''
  }

  async doQuery(): Promise<void> {
    const domain: string = this.inputText.trim()
    const errorMsg: string = this.validateDomain(domain)
    if (errorMsg !== '') {
      promptAction.showToast({ message: errorMsg, duration: 2000 })
      return
    }
    this.isQuerying = true
    this.viewMode = 'querying'
    const config: DnsLookupConfig = DnsLookupEngine.getDefaultConfig(domain)
    config.dnsServer = this.serverList[this.selectedServerIndex].address
    // 设置 IP 类型筛选
    config.family = this.ipFamilyOptions[this.ipFamilyIndex]
    const queryResult: DnsLookupResult = await this.engine.lookup(config)
    this.result = queryResult
    this.isQuerying = false
    this.viewMode = 'result'
  }

  onDomainTap(domain: string): void {
    this.inputText = domain
    this.doQuery()
  }

  onServerTap(index: number): void {
    this.selectedServerIndex = index
  }

  onFilterTap(index: number): void {
    this.filterType = this.recordTypeValues[index]
  }

  // ==================== 页面入口 ====================
  build() {
    Stack() {
      // ===== Aurora 天蓝渐变背景 =====
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })

      // 主内容
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          this.IdleView()
        } else {
          this.ResultView()
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

  // ==================== 初始视图 ====================
  @Builder IdleView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.SearchBarSection()
        this.IpFamilySection()
        this.ServerSelector()
        this.RecordTypeSection()
        this.PopularDomainsSection()
        this.FeatureCard()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // IP 类型选择
  @Builder IpFamilySection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.ip_family_label')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.ipFamilyLabels, (label: Resource, index: number) => {
          Text(label)
            .fontSize(FONT_SIZE_XS)
            .fontColor(this.ipFamilyIndex === index ? Color.White : COLOR_PRIMARY)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.ipFamilyIndex === index ? COLOR_PRIMARY : (this.isDarkMode ? 'rgba(255,255,255,0.08)' : COLOR_GLASS_SKY_LIGHT))
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => { this.ipFamilyIndex = index })
        }, (label: Resource, index: number): string => String(index))
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_dns')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_SUCCESS)

      TextInput({ placeholder: $r('app.string.input_domain_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.inputText = value })

      Button($r('app.string.query_action'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_SUCCESS)
        .borderRadius(999)
        .height(36)
        .padding({ left: 18, right: 18 })
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.doQuery())
    }
    .width('100%').padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // DNS 服务器选择
  @Builder ServerSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.dns_server')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.serverList, (server: ServerItem, index: number) => {
          Text(server.name)
            .fontSize(FONT_SIZE_XS)
            .fontColor(this.selectedServerIndex === index ? Color.White : server.color)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.selectedServerIndex === index ? server.color : (this.isDarkMode ? 'rgba(255,255,255,0.08)' : server.color + '15'))
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onServerTap(index))
        }, (server: ServerItem, index: number): string => String(index))
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  // 记录类型说明
  @Builder RecordTypeSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.record_type')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Column({ space: 0 }) {
        this.RecordTypeDesc('A', $r('app.string.ipv4_address'), COLOR_PRIMARY)
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('AAAA', $r('app.string.ipv6_address'), COLOR_SUCCESS)
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('CNAME', $r('app.string.alias_record'), COLOR_WARNING)
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('MX', $r('app.string.mail_server'), COLOR_CYAN)
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('NS', $r('app.string.name_server'), COLOR_INFO)
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('TXT', $r('app.string.text_record'), COLOR_PINK)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder RecordTypeDesc(type: string, desc: Resource, color: string) {
    Row({ space: SPACE_SM }) {
      Text(type)
        .fontSize(FONT_SIZE_XS).fontColor(color).fontWeight(FONT_WEIGHT_BOLD)
        .width(36)
      Text(desc)
        .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
  }

  // 常用域名
  @Builder PopularDomainsSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_domains')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.popularDomains, (domain: string) => {
          Text(domain)
            .fontSize(FONT_SIZE_SM).fontColor(COLOR_SUCCESS)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.isDarkMode ? 'rgba(16,185,129,0.15)' : '#ECFDF5')
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onDomainTap(domain))
        }, (domain: string): string => domain)
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // 功能说明卡片
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.dns_query_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('🔍', 'DNS 查询', '查询域名解析记录')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', '多服务器', '支持多个DNS服务器')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📈', '记录类型', 'A/AAAA/CNAME/MX/NS/TXT')
      }
      .padding({ left: 16, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(emoji: string, title: string, desc: string) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? 'rgba(16,185,129,0.15)' : COLOR_GLASS_SKY_ACTIVE)
        Text(emoji).fontSize(16)
      }

      Column({ space: 3 }) {
        Text(title)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
  }

  // ==================== 结果视图 ====================
  @Builder ResultView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.DomainInfoCard()
        if (this.result.records.length > 0) {
          this.FilterTags()
        }
        if (this.isQuerying) {
          this.QueryingState()
        } else if (this.result.status === 'success') {
          this.RecordsList()
        } else {
          this.ErrorState()
        }
        this.ActionButtons()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 域名信息卡
  @Builder DomainInfoCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? 'rgba(16,185,129,0.15)' : '#ECFDF5')
        Image($r('app.media.ic_dns')).width(22).height(22).fillColor(COLOR_SUCCESS)
      }

      Column({ space: 4 }) {
        Text(this.result.domain)
          .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: SPACE_SM }) {
          Text(this.result.server).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(adaptiveDivider(this.isDarkMode))
          Text(this.result.queryTime + 'ms').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(adaptiveDivider(this.isDarkMode))
          Text() {
            Span(String(this.result.records.length))
            Span(' ')
            Span($r('app.string.records_count'))
          }.fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 筛选标签
  @Builder FilterTags() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.recordTypes, (type: Resource, index: number) => {
        Text(type)
          .fontSize(FONT_SIZE_XS)
          .fontColor(this.filterType === this.recordTypeValues[index] ? Color.White : adaptiveTextSecondary(this.isDarkMode))
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.filterType === this.recordTypeValues[index] ? COLOR_SUCCESS : (this.isDarkMode ? 'rgba(255,255,255,0.06)' : COLOR_GLASS_SKY_LIGHT))
          .borderRadius(999)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.onFilterTap(index))
      }, (type: Resource, index: number): string => String(index))
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 10, bottom: 10 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_MD)
  }

  // 查询中状态
  @Builder QueryingState() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.querying_dns')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%').height(180).justifyContent(FlexAlign.Center)
  }

  // 错误状态
  @Builder ErrorState() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(64).height(64).fill(this.isDarkMode ? 'rgba(239,68,68,0.15)' : '#FEF2F2')
        Text('!').fontSize(FONT_SIZE_3XL).fontColor(COLOR_DANGER).fontWeight(FONT_WEIGHT_BOLD)
      }
      Text(this.result.errorMessage || $r('app.string.query_failed'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_DANGER)
    }
    .width('100%').height(200).justifyContent(FlexAlign.Center)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
  }

  // 记录列表
  @Builder RecordsList() {
    Column({ space: 0 }) {
      // 标题
      Row() {
        Row({ space: 6 }) {
          Text('📊').fontSize(14)
          Text($r('app.string.dns_records'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        Text() {
          Span(String(this.getFilteredRecords().length))
          Span(' ')
          Span($r('app.string.records_count'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.isDarkMode ? 'rgba(16,185,129,0.15)' : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      // 记录行
      Column({ space: 0 }) {
        ForEach(this.getFilteredRecords(), (record: DnsRecord, index: number) => {
          this.RecordItem(record, index)
        }, (record: DnsRecord, index: number): string => String(index + '_' + record.type + '_' + record.value))
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  // 记录项
  @Builder RecordItem(record: DnsRecord, index: number) {
    Row({ space: SPACE_SM }) {
      // 类型标签
      Text(record.type)
        .fontSize(FONT_SIZE_XS).fontColor(this.getRecordTypeColor(record.type)).fontWeight(FONT_WEIGHT_BOLD)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor(this.getRecordTypeColor(record.type) + '15')
        .borderRadius(SPACE_SM)
        .width(48).textAlign(TextAlign.Center)

      // 值
      Text(record.value)
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextPrimary(this.isDarkMode))
        .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

      // TTL
      Text(record.ttl + 's')
        .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .width(50).textAlign(TextAlign.End)
    }
    .width('100%').padding({ top: 8, bottom: 8 })

    if (index < this.getFilteredRecords().length - 1) {
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
    }
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      Button($r('app.string.re_query'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_SUCCESS)
        .borderRadius(999).height(42).layoutWeight(1)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.doQuery())
    }
    .width('100%')
  }
}
