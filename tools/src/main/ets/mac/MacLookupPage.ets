// MAC 地址查询页面组件
// 界面：搜索栏 + 快速查询示例 + 查询结果卡片（厂商/国家/类型）

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_INDIGO,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_SM, BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM,
} from '@wifi-analyzer/design-system'
import {
  MacLookupEngine, MacLookupResult,
} from '../maclookup/MacLookupEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import promptAction from '@ohos.promptAction'

@Component
export struct MacLookupPage {
  // 输入
  @State inputText: string = ''

  // UI 状态：'idle' | 'querying' | 'result'
  @State viewMode: string = 'idle'

  // 查询结果
  @State result: MacLookupResult = {
    mac: '', vendor: '', country: '', address: '',
    prefix: '', type: 'unknown', status: 'error',
    errorMessage: '', queryTime: 0, source: 'local'
  }

  // 查询历史
  @State historyList: string[] = []

  // 引擎
  private engine: MacLookupEngine = new MacLookupEngine()

  aboutToAppear(): void {
    this.historyList = this.engine.getHistory()
  }

  // ==================== 业务逻辑 ====================

  // ==================== 输入验证 ====================
  private validateInput(mac: string): string {
    const trimmed = mac.trim()
    if (trimmed.length === 0) {
      return $r('app.string.err_empty_input').toString()
    }
    if (trimmed.length > 17) { // 标准 MAC 地址最大长度
      return $r('app.string.err_input_too_long').toString()
    }
    if (!ValidationPatterns.isValidMac(trimmed)) {
      return $r('app.string.err_invalid_mac').toString()
    }
    return ''
  }

  async doQuery(): Promise<void> {
    const mac: string = this.inputText.trim()
    // 输入验证
    const errorMsg = this.validateInput(mac)
    if (errorMsg !== '') {
      promptAction.showToast({ message: errorMsg, duration: 2000 })
      return
    }

    this.viewMode = 'querying'
    const queryResult: MacLookupResult = await this.engine.lookup(mac)
    this.result = queryResult
    this.viewMode = 'result'
    this.historyList = this.engine.getHistory()
  }

  onHistoryTap(mac: string): void {
    this.inputText = mac
    this.doQuery()
  }

  onQuickTap(mac: string): void {
    this.inputText = mac
    this.doQuery()
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
    .padding({ top: SPACE_LG, bottom: SAFE_AREA_BOTTOM })
    .onBackPress(() => {
      RouterManager.goBack()
      return true
    })
  }

  // ==================== 初始视图 ====================
  @Builder IdleView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.SearchBarSection()
        this.FormatTip()
        this.QuickExamples()
        this.FeatureCard()
        if (this.historyList.length > 0) {
          this.HistorySection()
        }
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
      Image($r('app.media.ic_mac')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_INDIGO)
      TextInput({ placeholder: $r('app.string.input_mac_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.inputText = value })
      Button($r('app.string.query_action'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_INDIGO)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_SM)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.doQuery())
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 格式提示
  @Builder FormatTip() {
    Text($r('app.string.mac_format_hint'))
      .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      .alignSelf(ItemAlign.Start)
      .padding({ left: SPACE_MD })
  }

  // 快速示例
  @Builder QuickExamples() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_vendor_examples'))
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        Text('Apple')
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_INDIGO)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor('#EEF2FF').borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.onQuickTap('A4:B1:97:00:AB:CD'))
        Text('华为')
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_INDIGO)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor('#EEF2FF').borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.onQuickTap('20:A6:CD:56:78:90'))
        Text('小米')
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_INDIGO)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor('#EEF2FF').borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.onQuickTap('78:11:0B:AB:CD:EF'))
        Text('TP-Link')
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_INDIGO)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor('#EEF2FF').borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.onQuickTap('A8:42:A1:DE:AD:BE'))
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
          Circle().width(36).height(36).fill('#EEF2FF')
          Image($r('app.media.ic_mac')).width(18).height(18).fillColor(COLOR_INDIGO)
        }
        Column({ space: 2 }) {
          Text($r('app.string.mac_query_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.mac_query_intro_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_2XL).border({ width: 1, color: COLOR_BORDER })
  }

  // 历史记录
  @Builder HistorySection() {
    Column({ space: SPACE_SM }) {
      Row() {
        Text($r('app.string.query_history'))
          .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)
        Blank()
        Text($r('app.string.clear_history'))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_DANGER)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => {
            this.engine.clearHistory()
            this.historyList = []
          })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.historyList, (mac: string) => {
          Text(mac)
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_INDIGO)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor('#EEF2FF').borderRadius(RADIUS_3XL)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onHistoryTap(mac))
        }, (mac: string): string => mac)
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // ==================== 结果视图 ====================
  @Builder ResultView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // MAC 信息卡
        this.MacInfoCard()

        if (this.viewMode === 'querying') {
          this.QueryingState()
        } else if (this.result.status === 'success' || this.result.status === 'not_found') {
          this.VendorCard()
          this.DetailTable()
        } else {
          this.ErrorState()
        }

        this.ActionButtons()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // MAC 信息卡
  @Builder MacInfoCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(40).height(40).fill('#EEF2FF')
        Image($r('app.media.ic_mac')).width(22).height(22).fillColor(COLOR_INDIGO)
      }
      Column({ space: 2 }) {
        Text(this.result.mac)
          .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: SPACE_SM }) {
          Text(this.result.queryTime + 'ms').fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
          Text(this.result.source === 'local' ? $r('app.string.local_database') : $r('app.string.online_query')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 厂商信息卡
  @Builder VendorCard() {
    Column({ space: SPACE_MD }) {
      if (this.result.status === 'success') {
        Row({ space: SPACE_MD }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle().width(48).height(48).fill('#EEF2FF')
            Text(this.result.vendor.charAt(0)).fontSize(FONT_SIZE_2XL).fontColor(COLOR_INDIGO).fontWeight(FONT_WEIGHT_BOLD)
          }
          Column({ space: SPACE_XS }) {
            Text(this.result.vendor)
              .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
            Text(this.result.country !== '' ? this.result.country : '--')
              .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
      } else {
        Row({ space: SPACE_MD }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle().width(48).height(48).fill(COLOR_DIVIDER)
            Text('?').fontSize(FONT_SIZE_2XL).fontColor(COLOR_TEXT_TERTIARY).fontWeight(FONT_WEIGHT_BOLD)
          }
          Column({ space: SPACE_XS }) {
            Text($r('app.string.unknown_vendor')).fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_TERTIARY).fontWeight(FONT_WEIGHT_MEDIUM)
            Text($r('app.string.not_in_database')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 详细信息表
  @Builder DetailTable() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.detail_info')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%').padding({ bottom: SPACE_SM })

      this.DetailRow($r('app.string.mac_address_label'), this.result.mac, COLOR_PRIMARY)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.oui_prefix'), this.result.prefix, COLOR_INFO)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.address_type'), this.result.type === 'unicast' ? $r('app.string.unicast') : $r('app.string.multicast'), this.result.type === 'unicast' ? COLOR_SUCCESS : COLOR_WARNING)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.data_source'), this.result.source === 'local' ? $r('app.string.local_database') : $r('app.string.online_api'), COLOR_TEXT_SECONDARY)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.query_time'), String(this.result.queryTime) + 'ms', COLOR_TEXT_SECONDARY)
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  @Builder DetailRow(label: Resource | string, value: Resource | string, valueColor: string) {
    Row() {
      Text(label).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY)
      Blank()
      Text(value).fontSize(FONT_SIZE_SM).fontColor(valueColor).fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .width('100%').padding({ top: SPACE_SM, bottom: SPACE_SM })
  }

  // 查询中
  @Builder QueryingState() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.querying_mac')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_TERTIARY)
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
      Text(this.result.errorMessage || $r('app.string.query_fail'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_DANGER)
    }
    .width('100%').height(200).justifyContent(FlexAlign.Center)
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
      Button($r('app.string.retry_query'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_INDIGO)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.doQuery())
    }
    .width('100%')
  }
}
