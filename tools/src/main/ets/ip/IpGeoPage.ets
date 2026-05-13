// IP 归属查询页面组件 — 天蓝色透明毛玻璃悬浮风格

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE, COLOR_PINK, COLOR_CYAN, COLOR_INDIGO,
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
import { IpGeoEngine, IpGeoResult } from '../ipgeo/IpGeoEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import promptAction from '@ohos.promptAction'

@Component
export struct IpGeoPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State inputText: string = ''
  @State viewMode: string = 'idle'
  @State isQuerying: boolean = false
  @State result: IpGeoResult = {
    ip: '', country: '', province: '', city: '', isp: '',
    district: '', latitude: 0, longitude: 0, timezone: '',
    queryTime: 0, status: 'error', errorMessage: '',
  }
  @State myIp: string = ''
  @State isDetectingMyIp: boolean = true
  private engine: IpGeoEngine = new IpGeoEngine()
  @State queryHistory: string[] = []

  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch {
      return ''
    }
  }

  aboutToAppear(): void {
    this.myIp = ''
    this.detectMyIp()
  }

  private async detectMyIp(): Promise<void> {
    this.isDetectingMyIp = true
    const ip: string = await this.engine.queryMyIp()
    if (ip.length > 0) {
      this.myIp = ip
    } else {
      this.myIp = ''
    }
    this.isDetectingMyIp = false
  }

  getLocationText(): string {
    if (this.result.country.length === 0 && this.result.city.length === 0) return '--'
    const parts: string[] = []
    if (this.result.country.length > 0) parts.push(this.result.country)
    if (this.result.province.length > 0 && this.result.province !== this.result.country) parts.push(this.result.province)
    if (this.result.city.length > 0 && this.result.city !== this.result.province) parts.push(this.result.city)
    if (this.result.district.length > 0) parts.push(this.result.district)
    return parts.join(' · ')
  }

  private validateInput(ip: string): string {
    const trimmed = ip.trim()
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }
    if (trimmed.length > 45) {
      return this.getString($r('app.string.err_input_too_long'))
    }
    if (!ValidationPatterns.isValidIpv4(trimmed) && !ValidationPatterns.isValidDomain(trimmed)) {
      return this.getString($r('app.string.err_invalid_ip_or_domain'))
    }
    return ''
  }

  async doQuery(): Promise<void> {
    const ip: string = this.inputText.trim()
    const errorMsg = this.validateInput(ip)
    if (errorMsg !== '') {
      promptAction.showToast({ message: errorMsg, duration: 2000 })
      return
    }
    this.isQuerying = true
    this.viewMode = 'querying'
    const queryResult: IpGeoResult = await this.engine.query(ip)
    this.result = queryResult
    this.isQuerying = false
    this.viewMode = 'result'
  }

  queryMyIpGeo(): void {
    if (typeof this.myIp === 'string') {
      this.inputText = this.myIp
    }
    this.doQuery()
  }

  onHistoryTap(ip: string): void {
    this.inputText = ip
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
        this.MyIpCard()
        this.SearchBarSection()
        this.FeatureCard()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 我的IP卡片
  @Builder MyIpCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? 'rgba(236,72,153,0.15)' : COLOR_GLASS_SKY_ACTIVE)
        Image($r('app.media.ic_ip')).width(22).height(22).fillColor(COLOR_PINK)
      }

      Column({ space: 2 }) {
        Text($r('app.string.my_public_ip'))
          .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        Row({ space: SPACE_SM }) {
          if (this.isDetectingMyIp) {
            Text($r('app.string.fetching'))
              .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextTertiary(this.isDarkMode))
            Text($r('app.string.detecting'))
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_PINK)
          } else if (this.myIp.length === 0) {
            Text($r('app.string.fetch_failed'))
              .fontSize(FONT_SIZE_LG).fontColor(COLOR_DANGER)
          } else {
            Text(this.myIp)
              .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row() {
        Text($r('app.string.query_action')).fontSize(FONT_SIZE_SM).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_PINK)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.queryMyIpGeo())
    }
    .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_ip')).width(20).height(20).fillColor(COLOR_PINK)

      TextInput({ placeholder: $r('app.string.input_ip_address'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .type(InputType.Normal)
        .onChange((value: string) => { this.inputText = value })

      Row() {
        Text($r('app.string.query_action')).fontSize(FONT_SIZE_SM).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_PINK)
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

  // 功能说明
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.ip_geo_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('📍', '归属地查询', '查询IP的地理位置')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📡', '运营商信息', '查看ISP和网络运营商')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', '坐标定位', '获取经纬度坐标')
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
          .fill(this.isDarkMode ? 'rgba(236,72,153,0.15)' : COLOR_GLASS_SKY_ACTIVE)
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
        this.ResultInfoCard()
        if (this.isQuerying) {
          this.QueryingState()
        } else if (this.result.status === 'success') {
          this.GeoDetailCard()
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

  // 结果信息卡
  @Builder ResultInfoCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? 'rgba(236,72,153,0.15)' : COLOR_GLASS_SKY_LIGHT)
        Image($r('app.media.ic_ip')).width(22).height(22).fillColor(COLOR_PINK)
      }

      Column({ space: 4 }) {
        Text(this.result.ip)
          .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: SPACE_SM }) {
          Text(this.getLocationText()).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
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
      .backgroundColor(this.isDarkMode ? 'rgba(236,72,153,0.15)' : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(10)
      .onClick(() => {
        this.viewMode = 'idle'
        this.inputText = this.result.ip
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

  // 地理位置详情
  @Builder GeoDetailCard() {
    Column({ space: 0 }) {
      Row() {
        Row({ space: 6 }) {
          Text('📍').fontSize(14)
          Text('地理位置').fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        if (this.result.country.length > 0) {
          Text(this.result.country).fontSize(FONT_SIZE_XS).fontColor(COLOR_PINK)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(this.isDarkMode ? 'rgba(236,72,153,0.15)' : COLOR_GLASS_SKY_TAG_BG)
            .borderRadius(999)
        }
      }
      .width('100%').padding({ bottom: SPACE_SM })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      Column({ space: SPACE_SM }) {
        if (this.result.province.length > 0)
          this.DetailRow('省份', this.result.province)
        if (this.result.city.length > 0)
          this.DetailRow('城市', this.result.city)
        if (this.result.isp.length > 0)
          this.DetailRow('运营商', this.result.isp)
        if (this.result.latitude !== 0 || this.result.longitude !== 0)
          this.DetailRow('坐标', this.result.latitude.toFixed(2) + ', ' + this.result.longitude.toFixed(2))
        if (this.result.timezone.length > 0)
          this.DetailRow('时区', this.result.timezone)
      }
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
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
      Text(label).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(60)
      Text(value)
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextPrimary(this.isDarkMode))
        .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%').padding({ top: 6, bottom: 6 })
  }

  // 查询中状态
  @Builder QueryingState() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.querying_ip')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextTertiary(this.isDarkMode))
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

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      Row() {
        Text($r('app.string.re_query')).fontSize(FONT_SIZE_MD).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(COLOR_PINK)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
      .onClick(() => this.doQuery())
    }
    .width('100%')
  }
}
