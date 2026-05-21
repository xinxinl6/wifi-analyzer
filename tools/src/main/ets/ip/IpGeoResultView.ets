// IP归属地查询 - 结果视图子组件

import {
  COLOR_PINK, COLOR_DANGER, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_3XL,
  FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_TAG_BG,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BackButtonCapsule } from '@wifi-analyzer/design-system'
import { IpGeoResult } from '../ipgeo/IpGeoEngine'

@Component
export struct IpGeoResultView {
  @Prop isDarkMode: boolean = false
  @Prop result: IpGeoResult = {
    ip: '', country: '', province: '', city: '', isp: '',
    district: '', latitude: 0, longitude: 0, timezone: '',
    queryTime: 0, status: 'error', errorMessage: ''
  }
  @Prop isQuerying: boolean = false
  onBack: () => void = () => {}
  onReQuery: () => void = () => {}
  onEdit: () => void = () => {}

  build() {
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
      .onClick(() => this.onEdit())
    }
    .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 地理位置详情
  @Builder GeoDetailCard() {
    Column({ space: 0 }) {
      Row() {
        Row({ space: 6 }) {
          Text('📍').fontSize(14)
          Text($r('app.string.ip_geo_location')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
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
          this.DetailRow($r('app.string.ip_province'), this.result.province)
        if (this.result.city.length > 0)
          this.DetailRow($r('app.string.ip_city'), this.result.city)
        if (this.result.isp.length > 0)
          this.DetailRow($r('app.string.ip_isp'), this.result.isp)
        if (this.result.latitude !== 0 || this.result.longitude !== 0)
          this.DetailRow($r('app.string.ip_coords'), this.result.latitude.toFixed(2) + ', ' + this.result.longitude.toFixed(2))
        if (this.result.timezone.length > 0)
          this.DetailRow($r('app.string.ip_timezone'), this.result.timezone)
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
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  @Builder DetailRow(label: string | Resource, value: string) {
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
      BackButtonCapsule({
        onBack: () => { this.onBack() }
      })

      Row() {
        Text($r('app.string.re_query')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(COLOR_PINK)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_PINK, offsetX: 0, offsetY: 5 })
      .onClick(() => this.onReQuery())
    }
    .width('100%')
  }

  // 获取位置文本
  private getLocationText(): string {
    if (this.result.country.length === 0 && this.result.city.length === 0) return '--'
    const parts: string[] = []
    if (this.result.country.length > 0) parts.push(this.result.country)
    if (this.result.province.length > 0 && this.result.province !== this.result.country) parts.push(this.result.province)
    if (this.result.city.length > 0 && this.result.city !== this.result.province) parts.push(this.result.city)
    if (this.result.district.length > 0) parts.push(this.result.district)
    return parts.join(' · ')
  }
}
