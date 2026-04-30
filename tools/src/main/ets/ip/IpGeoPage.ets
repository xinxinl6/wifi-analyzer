// IP 归属查询页面组件
// 界面：搜索栏 + 我的IP + 查询结果卡片（地理位置+运营商+地图坐标）

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
import { BackButtonCapsule } from '@wifi-analyzer/design-system'
import {
  IpGeoEngine, IpGeoResult,
} from '../ipgeo/IpGeoEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import promptAction from '@ohos.promptAction'

// ==================== 组件 ====================

@Component
export struct IpGeoPage {
  // 输入
  @State inputText: string = ''

  // UI 状态：'idle' | 'querying' | 'result'
  @State viewMode: string = 'idle'
  @State isQuerying: boolean = false

  // 查询结果
  @State result: IpGeoResult = {
    ip: '', country: '', province: '', city: '', isp: '',
    district: '', latitude: 0, longitude: 0, timezone: '',
    queryTime: 0, status: 'error', errorMessage: '',
  }

  // 我的IP
  @State myIp: string = ''
  @State isDetectingMyIp: boolean = true

  // 引擎
  private engine: IpGeoEngine = new IpGeoEngine()

  // 查询历史
  @State queryHistory: string[] = []

  aboutToAppear(): void {
    this.myIp = ''
    this.detectMyIp()
  }

  // 检测本机公网IP
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

  // 获取完整地理位置文字
  getLocationText(): string {
    if (this.result.country.length === 0 && this.result.city.length === 0) return '--'
    const parts: string[] = []
    if (this.result.country.length > 0) parts.push(this.result.country)
    if (this.result.province.length > 0 && this.result.province !== this.result.country) parts.push(this.result.province)
    if (this.result.city.length > 0 && this.result.city !== this.result.province) parts.push(this.result.city)
    if (this.result.district.length > 0) parts.push(this.result.district)
    return parts.join(' · ')
  }

  // ==================== 业务逻辑 ====================

  // ==================== 输入验证 ====================
  private validateInput(ip: string): string {
    const trimmed = ip.trim()
    if (trimmed.length === 0) {
      return $r('app.string.err_empty_input').toString()
    }
    if (trimmed.length > 45) { // IPv6 最大长度
      return $r('app.string.err_input_too_long').toString()
    }
    // 支持IPv4或域名
    if (!ValidationPatterns.isValidIpv4(trimmed) && !ValidationPatterns.isValidDomain(trimmed)) {
      return $r('app.string.err_invalid_ip_or_domain').toString()
    }
    return ''
  }

  async doQuery(): Promise<void> {
    const ip: string = this.inputText.trim()
    // 输入验证
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
        this.MyIpCard()
        this.SearchBarSection()
        this.FeatureCard()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // 我的IP卡片
  @Builder MyIpCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44).fill('#FDF2F8')
        Image($r('app.media.ic_ip')).width(22).height(22).fillColor(COLOR_PINK)
      }

      Column({ space: 2 }) {
        Text($r('app.string.my_public_ip'))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        Row({ space: SPACE_SM }) {
          if (this.isDetectingMyIp) {
            Text($r('app.string.fetching'))
              .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_TERTIARY)
            Text($r('app.string.detecting'))
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_PINK)
          } else if (this.myIp.length === 0) {
            Text($r('app.string.fetch_failed'))
              .fontSize(FONT_SIZE_LG).fontColor(COLOR_DANGER)
          } else {
            Text(this.myIp)
              .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button($r('app.string.query_action'))
        .fontSize(FONT_SIZE_SM).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_PINK)
        .borderRadius(RADIUS_3XL).height(28)
        .padding({ left: SPACE_MD, right: SPACE_MD })
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.queryMyIpGeo())
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_ip')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_PINK)

      TextInput({ placeholder: $r('app.string.input_ip_address'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
        .backgroundColor(Color.Transparent)
        .type(InputType.Number)
        .onChange((value: string) => { this.inputText = value })

      Button($r('app.string.query_action'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_PINK)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_SM)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.doQuery())
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 功能说明
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#FDF2F8')
          Image($r('app.media.ic_ip')).width(18).height(18).fillColor(COLOR_PINK)
        }
        Column({ space: 2 }) {
          Text($r('app.string.ip_geo_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.ip_geo_intro_desc'))
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
        // IP信息卡
        this.IpInfoCard()

        // 查询中
        if (this.isQuerying) {
          this.QueryingState()
        } else if (this.result.status === 'success') {
          // 地理位置
          this.LocationCard()
          // 网络信息
          this.NetworkInfoCard()
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

  // IP 信息卡
  @Builder IpInfoCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(40).height(40).fill('#FDF2F8')
        Image($r('app.media.ic_ip')).width(22).height(22).fillColor(COLOR_PINK)
      }

      Column({ space: 2 }) {
        Text(this.result.ip)
          .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Row({ space: SPACE_SM }) {
          Text() {
          Span($r('app.string.query_latency'))
          Span(' ' + String(this.result.queryTime) + 'ms')
        }
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 地理位置卡
  @Builder LocationCard() {
    Column({ space: SPACE_MD }) {
      // 标题行
      Row() {
        Text($r('app.string.geographic_location'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text('📍').fontSize(FONT_SIZE_XL)
      }
      .width('100%')

      // 位置信息
      Column({ space: SPACE_SM }) {
        Row({ space: SPACE_MD }) {
          Stack({ alignContent: Alignment.Center }) {
            Circle().width(36).height(36).fill('#FDF2F8')
            Text('🌐').fontSize(FONT_SIZE_MD)
          }

          Column({ space: 2 }) {
            Text(this.getLocationText())
              .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
            if (this.result.timezone.length > 0) {
              Text() {
                Span($r('app.string.timezone_colon'))
                Span(this.result.timezone)
              }
                .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(SPACE_MD)
        .backgroundColor('#FDF2F8')
        .borderRadius(RADIUS_MD)

        // 坐标信息
        if (this.result.latitude !== 0 || this.result.longitude !== 0) {
          Row() {
            this.CoordCell($r('app.string.latitude'), String(this.result.latitude))
            this.CoordCell($r('app.string.longitude'), String(this.result.longitude))
          }
          .width('100%')
        }
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  @Builder CoordCell(label: Resource | string, value: string) {
    Column({ space: SPACE_XS }) {
      Text(label).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      Text(value).fontSize(FONT_SIZE_MD).fontColor(COLOR_PINK).fontWeight(FONT_WEIGHT_BOLD)
    }
    .layoutWeight(1)
    .padding(SPACE_SM)
    .backgroundColor(COLOR_BACKGROUND)
    .borderRadius(RADIUS_SM)
    .alignItems(HorizontalAlign.Center)
  }

  // 网络信息卡
  @Builder NetworkInfoCard() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.network_info')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%').padding({ bottom: SPACE_SM })

      if (this.result.isp.length > 0) {
        this.DetailRow($r('app.string.vendor'), this.result.isp, COLOR_PINK)
        Divider().color(COLOR_DIVIDER)
      }
      if (this.result.country.length > 0) {
        this.DetailRow($r('app.string.country_region'), this.result.country, COLOR_TEXT_PRIMARY)
        Divider().color(COLOR_DIVIDER)
      }
      if (this.result.province.length > 0) {
        this.DetailRow($r('app.string.province'), this.result.province, COLOR_TEXT_PRIMARY)
        Divider().color(COLOR_DIVIDER)
      }
      if (this.result.city.length > 0) {
        this.DetailRow($r('app.string.city'), this.result.city, COLOR_TEXT_PRIMARY)
        Divider().color(COLOR_DIVIDER)
      }
      if (this.result.district.length > 0) {
        this.DetailRow($r('app.string.district'), this.result.district, COLOR_TEXT_PRIMARY)
        Divider().color(COLOR_DIVIDER)
      }
      if (this.result.timezone.length > 0) {
        this.DetailRow($r('app.string.timezone'), this.result.timezone, COLOR_TEXT_SECONDARY)
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  @Builder DetailRow(label: Resource | string, value: string, valueColor: string) {
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
      Text($r('app.string.querying_ip_info')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_TERTIARY)
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
        .textAlign(TextAlign.Center)
    }
    .width('100%').height(200).justifyContent(FlexAlign.Center)
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      Button($r('app.string.query_my_ip'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_PINK)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.queryMyIpGeo())
    }
    .width('100%')
  }
}
