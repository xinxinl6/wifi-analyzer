// DNS 查询页面组件
// 界面：搜索栏 + DNS服务器选择 + 记录类型标签 + 查询结果列表

import promptAction from '@ohos.promptAction'
import {
  COLOR_PRIMARY, COLOR_PRIMARY_LIGHT, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE, COLOR_PINK, COLOR_CYAN, COLOR_INDIGO,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_SM, BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
} from '@wifi-analyzer/design-system'
import { DnsLookupEngine, DnsLookupResult, DnsRecord, DnsRecordType, DnsServerPreset, DnsLookupConfig } from '../dnslookup/DnsLookupEngine'
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

  // 筛选记录类型
  @State filterType: string = 'all' // 'all' | 'A' | 'AAAA' | 'CNAME' | 'MX' | 'NS' | 'TXT'

  // 记录类型标签（Resource 数组用于 i18n）
  private recordTypes: Resource[] = [$r('app.string.all_types'), $r('app.string.dns_type_a'), $r('app.string.dns_type_aaaa'), $r('app.string.dns_type_cname'), $r('app.string.dns_type_mx'), $r('app.string.dns_type_ns'), $r('app.string.text_record')]

  // 记录类型对应索引（用于筛选逻辑）
  private recordTypeValues: string[] = ['all', 'A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT']

  aboutToAppear(): void {
    this.loadServers()
    this.popularDomains = DnsLookupEngine.POPULAR_DOMAINS
  }

  // 加载 DNS 服务器列表
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

  // 获取筛选后的记录
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

  // 获取记录类型颜色
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

  // 验证域名输入
  private validateDomain(domain: string): string {
    const trimmed: string = domain.trim()

    // 检查是否为空
    if (trimmed.length === 0) {
      return $r('app.string.err_empty_input').toString()
    }

    // 检查长度限制（域名最大253字符）
    if (trimmed.length > 253) {
      return $r('app.string.err_input_too_long').toString()
    }

    // 验证域名格式
    if (!ValidationPatterns.isValidDomain(trimmed)) {
      return $r('app.string.err_invalid_domain').toString()
    }

    return ''
  }

  async doQuery(): Promise<void> {
    const domain: string = this.inputText.trim()

    // 输入验证
    const errorMsg: string = this.validateDomain(domain)
    if (errorMsg !== '') {
      promptAction.showToast({
        message: errorMsg,
        duration: 2000
      })
      return
    }

    this.isQuerying = true
    this.viewMode = 'querying'

    const config: DnsLookupConfig = DnsLookupEngine.getDefaultConfig(domain)
    config.dnsServer = this.serverList[this.selectedServerIndex].address

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
    Column() {
      if (this.viewMode === 'idle') {
        this.IdleView()
      } else {
        this.ResultView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
    .padding({ top: SAFE_AREA_TOP, bottom: SAFE_AREA_BOTTOM })
  }

  // ==================== 初始视图 ====================
  @Builder IdleView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.SearchBarSection()
        this.ServerSelector()
        this.RecordTypeSection()
        this.PopularDomainsSection()
        this.FeatureCard()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_dns')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_SUCCESS)

      TextInput({ placeholder: $r('app.string.input_domain_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.inputText = value })

      Button($r('app.string.query_action'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_SUCCESS)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_SM)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.doQuery())
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // DNS 服务器选择
  @Builder ServerSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.dns_server')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.serverList, (server: ServerItem, index: number) => {
          Text(server.name)
            .fontSize(FONT_SIZE_XS)
            .fontColor(this.selectedServerIndex === index ? Color.White : server.color)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.selectedServerIndex === index ? server.color : server.color + '15')
            .borderRadius(RADIUS_3XL)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onServerTap(index))
        }, (server: ServerItem, index: number): string => String(index))
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // 记录类型说明
  @Builder RecordTypeSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.record_type')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Column({ space: SPACE_XS }) {
        this.RecordTypeDesc('A', $r('app.string.ipv4_address'), COLOR_PRIMARY)
        this.RecordTypeDesc('AAAA', $r('app.string.ipv6_address'), COLOR_SUCCESS)
        this.RecordTypeDesc('CNAME', $r('app.string.alias_record'), COLOR_WARNING)
        this.RecordTypeDesc('MX', $r('app.string.mail_server'), COLOR_CYAN)
        this.RecordTypeDesc('NS', $r('app.string.name_server'), COLOR_INFO)
        this.RecordTypeDesc('TXT', $r('app.string.text_record'), COLOR_PINK)
      }
      .width('100%')
      .padding(SPACE_MD)
      .backgroundColor(COLOR_SURFACE)
      .borderRadius(RADIUS_2XL)
      .border({ width: 1, color: COLOR_BORDER })
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder RecordTypeDesc(type: string, desc: Resource, color: string) {
    Row({ space: SPACE_SM }) {
      Text(type)
        .fontSize(FONT_SIZE_XS).fontColor(color).fontWeight(FONT_WEIGHT_BOLD)
        .width(36)
      Text(desc)
        .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_SECONDARY)
    }
    .width('100%')
  }

  // 常用域名
  @Builder PopularDomainsSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_domains')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.popularDomains, (domain: string) => {
          Text(domain)
            .fontSize(FONT_SIZE_SM).fontColor(COLOR_SUCCESS)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor('#ECFDF5').borderRadius(RADIUS_3XL)
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
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#ECFDF5')
          Image($r('app.media.ic_dns')).width(18).height(18).fillColor(COLOR_SUCCESS)
        }
        Column({ space: 2 }) {
          Text($r('app.string.dns_query_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.dns_query_intro_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_2XL).border({ width: 1, color: COLOR_BORDER })
  }

  // ==================== 结果视图 ====================
  @Builder ResultView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 域名信息卡
        this.DomainInfoCard()

        // 记录类型筛选标签
        if (this.result.records.length > 0) {
          this.FilterTags()
        }

        // 查询结果
        if (this.isQuerying) {
          this.QueryingState()
        } else if (this.result.status === 'success') {
          this.RecordsList()
        } else {
          this.ErrorState()
        }

        // 操作按钮
        this.ActionButtons()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // 域名信息卡
  @Builder DomainInfoCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(40).height(40).fill('#ECFDF5')
        Image($r('app.media.ic_dns')).width(22).height(22).fillColor(COLOR_SUCCESS)
      }

      Column({ space: 2 }) {
        Text(this.result.domain)
          .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: SPACE_SM }) {
          Text(this.result.server).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
          Text(this.result.queryTime + 'ms').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
          Text() {
            Span(String(this.result.records.length))
            Span(' ')
            Span($r('app.string.records_count'))
          }.fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 筛选标签
  @Builder FilterTags() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.recordTypes, (type: Resource, index: number) => {
        Text(type)
          .fontSize(FONT_SIZE_XS)
          .fontColor(this.filterType === this.recordTypeValues[index] ? Color.White : COLOR_TEXT_SECONDARY)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.filterType === this.recordTypeValues[index] ? COLOR_SUCCESS : COLOR_DIVIDER)
          .borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.onFilterTap(index))
      }, (type: Resource, index: number): string => String(index))
    }
    .width('100%')
  }

  // 查询中状态
  @Builder QueryingState() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.querying_dns')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_TERTIARY)
    }
    .width('100%').height(180).justifyContent(FlexAlign.Center)
  }

  // 错误状态
  @Builder ErrorState() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(64).height(64).fill('#FEF2F2')
        Text('!').fontSize(FONT_SIZE_3XL).fontColor(COLOR_DANGER).fontWeight(FONT_WEIGHT_BOLD)
      }
      Text(this.result.errorMessage || $r('app.string.query_failed'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_DANGER)
    }
    .width('100%').height(200).justifyContent(FlexAlign.Center)
  }

  // 记录列表
  @Builder RecordsList() {
    Column({ space: 0 }) {
      // 标题
      Row() {
        Text($r('app.string.dns_records'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span(String(this.getFilteredRecords().length))
          Span(' ')
          Span($r('app.string.records_count'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      }
      .width('100%').padding({ bottom: SPACE_SM })

      // 表头
      Row() {
        Text('类型').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY).width(48)
        Text('值').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY).layoutWeight(1)
        Text('TTL').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY).width(50).textAlign(TextAlign.End)
      }
      .width('100%').padding({ top: SPACE_XS, bottom: SPACE_XS })
      Divider().color(COLOR_DIVIDER)

      // 记录行
      ForEach(this.getFilteredRecords(), (record: DnsRecord, index: number) => {
        Column({ space: 0 }) {
          Row() {
            // 类型标签
            Text(record.type)
              .fontSize(FONT_SIZE_XS).fontColor(this.getRecordTypeColor(record.type)).fontWeight(FONT_WEIGHT_BOLD)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.getRecordTypeColor(record.type) + '15')
              .borderRadius(RADIUS_SM)
              .width(48).textAlign(TextAlign.Center)

            // 值
            Text(record.value)
              .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_PRIMARY)
              .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })

            // TTL
            Text(record.ttl + 's')
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
              .width(50).textAlign(TextAlign.End)
          }
          .width('100%').padding({ top: SPACE_SM, bottom: SPACE_SM })

          if (index < this.getFilteredRecords().length - 1) {
            Divider().color(COLOR_DIVIDER)
          }
        }
      }, (record: DnsRecord, index: number): string => String(index + '_' + record.type + '_' + record.value))
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      Button($r('app.string.back'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_SECONDARY).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(Color.Transparent).borderWidth(1).borderColor(COLOR_BORDER)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => RouterManager.goBack())

      Button($r('app.string.re_query'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_SUCCESS)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.doQuery())
    }
    .width('100%')
  }
}
