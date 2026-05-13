// MAC 地址查询页面组件 — 天蓝色透明毛玻璃悬浮风格

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_INDIGO,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
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
import { MacLookupEngine, MacLookupResult } from '../maclookup/MacLookupEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import promptAction from '@ohos.promptAction'

@Component
export struct MacLookupPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State inputText: string = ''
  @State viewMode: string = 'idle'
  @State result: MacLookupResult = {
    mac: '', vendor: '', country: '', address: '',
    prefix: '', type: 'unknown', status: 'error',
    errorMessage: '', queryTime: 0, source: 'local'
  }
  @State historyList: string[] = []
  private engine: MacLookupEngine = new MacLookupEngine()

  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch {
      return ''
    }
  }

  aboutToAppear(): void {
    this.historyList = this.engine.getHistory()
  }

  private validateInput(mac: string): string {
    const trimmed = mac.trim()
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }
    if (trimmed.length > 17) {
      return this.getString($r('app.string.err_input_too_long'))
    }
    if (!ValidationPatterns.isValidMac(trimmed)) {
      return this.getString($r('app.string.err_invalid_mac'))
    }
    return ''
  }

  async doQuery(): Promise<void> {
    const mac: string = this.inputText.trim()
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
        this.FormatTip()
        this.QuickExamples()
        this.FeatureCard()
        if (this.historyList.length > 0) {
          this.HistorySection()
        }
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_mac')).width(20).height(20).fillColor(COLOR_INDIGO)

      TextInput({ placeholder: $r('app.string.input_mac_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.inputText = value })

      Row() {
        Text($r('app.string.query_action')).fontSize(FONT_SIZE_SM).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_INDIGO)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
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

  // 格式提示
  @Builder FormatTip() {
    Text($r('app.string.mac_format_hint'))
      .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
      .alignSelf(ItemAlign.Start)
      .padding({ left: SPACE_MD })
  }

  // 快速示例
  @Builder QuickExamples() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_vendor_examples'))
        .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        ForEach(['Apple', '华为', '小米', 'TP-Link'], (name: string, index: number) => {
          Row({ space: 5 }) {
            Text(index === 0 ? '🍎' : index === 1 ? '📱' : index === 2 ? '📱' : '🔌')
              .fontSize(12)
            Text(name)
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_INDIGO)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(this.isDarkMode ? 'rgba(99,102,241,0.25)' : COLOR_GLASS_SKY_TAG_BORDER)
          .onClick(() => this.onQuickTap(
            index === 0 ? 'A4:B1:97:00:AB:CD' :
            index === 1 ? '20:A6:CD:56:78:90' :
            index === 2 ? '78:11:0B:AB:CD:EF' :
            'A8:42:A1:DE:AD:BE'
          ))
        }, (name: string, index: number): string => String(index))
      }
      .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  // 功能说明卡片
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.mac_lookup_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('🔍', '厂商查询', '查询MAC地址对应的厂商信息')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('🌍', '国家归属', '查看设备产地归属')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', '地址类型', '识别设备类型(UAA/LAA)')
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
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
          .fill(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_ACTIVE)
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

  // 历史记录
  @Builder HistorySection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.recent_lookups'))
        .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.historyList.slice(0, 6), (mac: string) => {
          Text(mac)
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_INDIGO)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_TAG_BG)
            .borderRadius(999)
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
        this.ResultInfoCard()
        this.VendorInfoCard()
        this.ActionButtons()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 结果信息卡
  @Builder ResultInfoCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_LIGHT)
        Image($r('app.media.ic_mac')).width(22).height(22).fillColor(COLOR_INDIGO)
      }

      Column({ space: 4 }) {
        Text(this.result.mac)
          .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: SPACE_SM }) {
          Text(this.result.type === 'UAA' ? '通用唯一标识' : this.result.type === 'LAA' ? '本地管理' : '未知')
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(adaptiveDivider(this.isDarkMode))
          Text(this.result.queryTime + 'ms').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row() {
        Text('🔍').fontSize(14)
      }
      .width(34).height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(10)
      .onClick(() => {
        this.viewMode = 'idle'
      })
    }
    .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 厂商信息卡
  @Builder VendorInfoCard() {
    Column({ space: 0 }) {
      Row() {
        Row({ space: 6 }) {
          Text('🏭').fontSize(14)
          Text('厂商信息').fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        if (this.result.vendor.length > 0) {
          Text(this.result.vendor)
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_INDIGO)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_TAG_BG)
            .borderRadius(999)
        }
      }
      .width('100%').padding({ bottom: SPACE_SM })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      Column({ space: SPACE_SM }) {
        if (this.result.prefix.length > 0)
          this.DetailRow('MAC前缀', this.result.prefix)
        if (this.result.country.length > 0)
          this.DetailRow('国家', this.result.country)
        if (this.result.address.length > 0)
          this.DetailRow('详细地址', this.result.address)
        if (this.result.source.length > 0)
          this.DetailRow('数据来源', this.result.source === 'local' ? '本地数据库' : '在线查询')
      }
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
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

  @Builder DetailRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(70)
      Text(value)
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextPrimary(this.isDarkMode))
        .layoutWeight(1).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      Row() {
        Text('重新查询').fontSize(FONT_SIZE_MD).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(COLOR_INDIGO)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
      .onClick(() => this.doQuery())
    }
    .width('100%')
  }
}
