// DNS 查询结果视图组件

import {
  COLOR_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY, COLOR_DANGER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_TAG_BG,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BackButtonCapsule } from '@wifi-analyzer/design-system'
import { DnsLookupResult, DnsRecord, DnsRecordType } from '../dnslookup/DnsLookupEngine'

// ==================== 组件 ====================

@Component
export struct DnsResultView {
  @Prop isDarkMode: boolean = false
  @Prop result: DnsLookupResult = {
    domain: '',
    records: [],
    queryTime: 0,
    server: '',
    status: 'error',
    errorMessage: '',
  }
  @Prop filterType: string = 'all'
  @Prop recordTypes: Resource[] = []
  @Prop recordTypeValues: string[] = []
  @Prop filteredRecords: DnsRecord[] = []

  onBack: () => void = () => {}
  onReQuery: () => void = () => {}
  onFilterChange: (index: number) => void = () => {}

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.DomainInfoCard()
        if (this.result.records.length > 0) {
          this.FilterTags()
        }
        if (this.result.status === 'success') {
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
          .fill(this.isDarkMode ? COLOR_GLASS_AURORA : '#EEF6FE')
        Image($r('app.media.ic_dns')).width(22).height(22).fillColor(COLOR_PRIMARY)
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
          .backgroundColor(this.filterType === this.recordTypeValues[index] ? COLOR_PRIMARY : (this.isDarkMode ? 'rgba(255,255,255,0.06)' : COLOR_GLASS_SKY_LIGHT))
          .borderRadius(999)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.onFilterChange(index))
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
          Span(String(this.filteredRecords.length))
          Span(' ')
          Span($r('app.string.records_count'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_PRIMARY)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      // 记录行
      Column({ space: 0 }) {
        ForEach(this.filteredRecords, (record: DnsRecord, index: number) => {
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
        .fontSize(FONT_SIZE_XS).fontColor(COLOR_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor(COLOR_PRIMARY + '15')
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

    if (index < this.filteredRecords.length - 1) {
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
    }
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => this.onBack() })

      Button($r('app.string.re_query'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_PRIMARY)
        .borderRadius(999).height(42).layoutWeight(1)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.onReQuery())
    }
    .width('100%')
  }
}
