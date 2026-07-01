// IpGeoPage — 从 ToolPages.ets 拆分
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveTextCyan,
  adaptiveCardBg, adaptiveCardDarkGlass, adaptiveBorderCyan,
  adaptiveBackgroundList, adaptiveBtnBg,
  adaptiveSuccess, adaptiveDanger, adaptiveInfo, adaptiveWarning,
  RADIUS_MD
} from '@wifi-analyzer/design-system';
import { RouterManager } from '@wifi-analyzer/core';
import { IpGeoEngine, IpGeoResult } from '@wifi-analyzer/network-tools';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { initGeoipDb, geoipLookup } from 'native-ping';

const TAG = '[IpGeoPage]'

interface GeoResult {
  country: string; regionName: string; city: string
  isp: string; timezone: string; countryCode: string
  status: string; message: string
  lat: number; lon: number
  org: string; as: string; zip: string
  region: string; query: string
  mobile: boolean; proxy: boolean; hosting: boolean
}

@Builder
export function IpGeoPageBuilder() { NavDestination() { IpGeoPage() }.title($r('app.string.tool_ipgeo')).hideTitleBar(true) }

@Component
export struct IpGeoPage {
  @StorageLink('isDarkMode') isDark: boolean = false
  @State ip: string = ''
  @State geo: GeoResult | null = null
  @State loading: boolean = false
  @State errorMsg: string = ''

  private engine: IpGeoEngine = new IpGeoEngine()

  private res(name: string): string { try { return getContext().resourceManager.getStringByNameSync(name) } catch (_e) { return name } }

  aboutToAppear(): void {
    this.initialize()
  }

  private async initialize(): Promise<void> {
    try {
      const ctx: ESObject = this.getUIContext().getHostContext() as ESObject
      const rm: ESObject = ctx.resourceManager
      if (rm) await initGeoipDb(rm)
    } catch (e) {
      hilog.warn(0x0000, TAG, 'initGeoipDb failed: %{public}s', JSON.stringify(e))
    }
    await this.detectMyIp()
  }

  private async detectMyIp(): Promise<void> {
    this.loading = true; this.errorMsg = ''
    try {
      const myIp: string = await this.engine.queryMyIp()
      if (myIp) {
        this.ip = myIp
        await this.lookupIp(myIp)
      } else {
        this.errorMsg = this.res('geo_network_error')
      }
    } catch (e) {
      hilog.warn(0x0000, TAG, 'detectMyIp failed: %{public}s', JSON.stringify(e))
      this.errorMsg = this.res('geo_network_error')
    }
    this.loading = false
  }

  private async lookupIp(target: string): Promise<void> {
    const queryIp: string = target.trim()
    if (!queryIp) {
      await this.detectMyIp()
      return
    }
    this.loading = true; this.errorMsg = ''; this.geo = null
    try {
      const result: IpGeoResult = await this.engine.query(queryIp)
      if (result.status === 'success') {
        this.geo = this.mapToGeoResult(result)
        if (!this.ip) this.ip = result.ip
      } else {
        this.errorMsg = result.errorMessage || this.res('geo_query_failed')
      }
    } catch (e) {
      this.errorMsg = this.res('geo_network_error')
      hilog.warn(0x0000, TAG, 'lookupIp failed: %{public}s', JSON.stringify(e))
    }
    this.loading = false
  }

  private mapToGeoResult(result: IpGeoResult): GeoResult {
    const offline: string = geoipLookup(result.ip).country
    const countryCode: string = (offline !== '--' && offline !== '') ? offline : ''
    return {
      query: result.ip,
      country: result.country || this.countryName(countryCode),
      regionName: result.province || '',
      city: result.city || '',
      isp: result.isp || '',
      timezone: result.timezone || '',
      countryCode,
      lat: result.latitude,
      lon: result.longitude,
      org: result.isp || '',
      as: '',
      zip: '',
      region: '',
      status: 'success',
      message: '',
      mobile: false,
      proxy: false,
      hosting: false
    }
  }

  build() {
    Stack() {
      Circle().width(300).height(300).fill(this.isDark ? 'rgba(59,130,246,0.06)' : 'rgba(59,130,246,0.04)').position({ x: -80, y: -80 })
      Circle().width(200).height(200).fill(this.isDark ? 'rgba(59,130,246,0.04)' : 'rgba(59,130,246,0.03)').position({ x: '70%', y: '50%' })
      Column() {
        Row({ space: 16 }) {
          Row() { Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark)) }.width(36).height(36).justifyContent(FlexAlign.Center).borderRadius(8).backgroundColor(adaptiveBtnBg(this.isDark)).onClick(() => { RouterManager.goBack() })
          Text($r('app.string.tool_ipgeo')).fontSize(20).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
        }.width('100%').padding({ left: 20, right: 20, top: 44, bottom: 8 })
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                TextInput({ text: $$this.ip, placeholder: $r('app.string.geo_placeholder') }).fontColor(adaptiveTextPrimary(this.isDark)).placeholderColor(adaptiveTextTertiary(this.isDark)).fontSize(14).layoutWeight(1).height(42).backgroundColor(adaptiveBtnBg(this.isDark)).borderRadius(8).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).padding({ left: 14 })
                if (!this.loading) {
                  Row() { Text('🔍').fontSize(14).fontColor(Color.White) }.width(42).height(42).justifyContent(FlexAlign.Center).linearGradient({ angle: 135, colors: [['rgba(49,122,247,0.15)', 0], ['rgba(49,122,247,0.40)', 1]] }).borderRadius(8).onClick(() => { this.lookupIp(this.ip) })
                } else {
                  Row() { Circle().width(14).height(14).fill(adaptiveInfo(this.isDark)).opacity(0.7) }.width(42).height(42).justifyContent(FlexAlign.Center).borderRadius(8).backgroundColor(adaptiveBtnBg(this.isDark))
                }
              }
            }.width('100%').padding(16).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)

            if (this.loading) { Text($r('app.string.geo_loading')).fontSize(12).fontColor(adaptiveInfo(this.isDark)).width('100%').textAlign(TextAlign.Center) }
            if (this.errorMsg !== '') { Text(this.errorMsg).fontSize(12).fontColor(adaptiveDanger(this.isDark)).width('100%').textAlign(TextAlign.Center) }

            if (this.geo) {
              this.heroCard(this.geo)
              this.sectionHeader($r('app.string.geo_location_section'))
              Grid() {
                GridItem() { this.infoItem($r('app.string.geo_city_label'), this.geo.city) }
                GridItem() { this.infoItem($r('app.string.geo_region_label'), this.geo.regionName) }
                GridItem() { this.infoItem($r('app.string.geo_zip_label'), this.geo.zip) }
                GridItem() {
                  Column({ space: 4 }) {
                    Text($r('app.string.geo_coords_label')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)).textCase(TextCase.UpperCase)
                    if (this.geo.lat !== 0 || this.geo.lon !== 0) Text(String(this.geo.lat.toFixed(4)) + ', ' + String(this.geo.lon.toFixed(4))).fontSize(13).fontWeight(600).fontColor(adaptiveTextCyan(this.isDark))
                    else Text('—').fontSize(13).fontWeight(600).fontColor(adaptiveTextTertiary(this.isDark))
                  }.width('100%').alignItems(HorizontalAlign.Start)
                }
              }.columnsTemplate('1fr 1fr').columnsGap(10).rowsGap(10)
              this.sectionHeader($r('app.string.geo_network_section'))
              Grid() {
                GridItem() { this.infoItem($r('app.string.geo_isp_label'), this.geo.isp) }
                GridItem() { this.infoItem($r('app.string.geo_org_label'), this.geo.org) }
              }.columnsTemplate('1fr 1fr').columnsGap(10).rowsGap(10)
              if (this.geo.as) { this.asnCard(this.geo.as) }
              this.sectionHeader($r('app.string.geo_additional_section'))
              Grid() {
                GridItem() { this.infoItem($r('app.string.geo_timezone_label'), this.geo.timezone) }
                GridItem() { this.infoItem($r('app.string.geo_country_code_label'), this.geo.countryCode) }
              }.columnsTemplate('1fr 1fr').columnsGap(10).rowsGap(10)
              this.typeBadges(this.geo)
            } else if (!this.loading && this.errorMsg === '') {
              Text($r('app.string.geo_empty_hint')).fontSize(12).fontColor(adaptiveTextTertiary(this.isDark)).width('100%').textAlign(TextAlign.Center).padding({ top: 20 })
            }
          }.padding({ left: 20, right: 20, top: 8, bottom: 20 })
        }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off)
      }.width('100%').height('100%')
    }.width('100%').height('100%').linearGradient({ angle: 180, colors: adaptiveBackgroundList(this.isDark) })
  }

  @Builder heroCard(g: GeoResult) {
    Column({ space: 12 }) {
      Text(this.flagEmoji(g.countryCode)).fontSize(52)
      Row({ space: 6 }) {
        Text('IP').fontSize(9).fontWeight(700).fontColor(adaptiveTextCyan(this.isDark)).padding({ left: 6, right: 6, top: 2, bottom: 2 }).backgroundColor(this.isDark ? 'rgba(59,130,246,0.12)' : 'rgba(59,130,246,0.08)').borderRadius(4)
        Text(g.query || this.ip).fontSize(16).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark)).fontFamily('monospace')
      }
      Text(g.country + (g.regionName ? ' · ' + g.regionName : '')).fontSize(14).fontColor(adaptiveTextSecondary(this.isDark))
      Row() { Circle().width(4).height(4).fill(adaptiveBorderCyan(this.isDark)); Row().width(80).height(1).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.4); Circle().width(4).height(4).fill(adaptiveBorderCyan(this.isDark)) }.width('100%').justifyContent(FlexAlign.Center)
      if (g.lat !== 0 || g.lon !== 0) { Row({ space: 6 }) { Text('📍').fontSize(14); Text(String(g.lat.toFixed(4)) + '°N, ' + String(g.lon.toFixed(4)) + '°E').fontSize(12).fontColor(adaptiveTextTertiary(this.isDark)).fontFamily('monospace') } }
    }.width('100%').padding(20).alignItems(HorizontalAlign.Center).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
  }

  @Builder sectionHeader(title: Resource) { Text(title).fontSize(11).fontWeight(700).fontColor(adaptiveTextCyan(this.isDark)).width('100%').textCase(TextCase.UpperCase).letterSpacing(1) }

  @Builder infoItem(label: Resource, value: string) {
    Column({ space: 4 }) {
      Text(label).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)).textCase(TextCase.UpperCase)
      if (value && value !== '') Text(value).fontSize(13).fontWeight(600).fontColor(adaptiveTextPrimary(this.isDark)).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      else Text('—').fontSize(13).fontWeight(600).fontColor(adaptiveTextTertiary(this.isDark))
    }.width('100%').alignItems(HorizontalAlign.Start).padding(14).height(68).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
  }

  @Builder asnCard(asn: string) {
    Column({ space: 4 }) { Text($r('app.string.geo_asn_label')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)).textCase(TextCase.UpperCase); Text(asn).fontSize(13).fontWeight(600).fontColor(adaptiveTextCyan(this.isDark)) }.width('100%').alignItems(HorizontalAlign.Start).padding(14).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
  }

  @Builder typeBadges(g: GeoResult) {
    Row({ space: 8 }) {
      if (g.mobile) { Row() { Text($r('app.string.badge_mobile')).fontSize(10).fontWeight(600).fontColor(adaptiveWarning(this.isDark)) }.padding({ left: 10, right: 10, top: 5, bottom: 5 }).backgroundColor(this.isDark ? 'rgba(219,107,66,0.12)' : 'rgba(219,107,66,0.08)').borderRadius(6) }
      if (g.proxy) { Row() { Text($r('app.string.badge_proxy')).fontSize(10).fontWeight(600).fontColor(adaptiveDanger(this.isDark)) }.padding({ left: 10, right: 10, top: 5, bottom: 5 }).backgroundColor(this.isDark ? 'rgba(217,72,56,0.12)' : 'rgba(217,72,56,0.08)').borderRadius(6) }
      if (g.hosting) { Row() { Text($r('app.string.badge_hosting')).fontSize(10).fontWeight(600).fontColor(adaptiveInfo(this.isDark)) }.padding({ left: 10, right: 10, top: 5, bottom: 5 }).backgroundColor(this.isDark ? 'rgba(49,122,247,0.12)' : 'rgba(49,122,247,0.08)').borderRadius(6) }
      if (!g.mobile && !g.proxy && !g.hosting) { Row() { Text($r('app.string.badge_normal')).fontSize(10).fontWeight(600).fontColor(adaptiveSuccess(this.isDark)) }.padding({ left: 10, right: 10, top: 5, bottom: 5 }).backgroundColor(this.isDark ? 'rgba(91,168,84,0.12)' : 'rgba(91,168,84,0.08)').borderRadius(6) }
    }.width('100%').padding(14).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
  }

  private countryName(code: string): string {
    const names: Record<string, string> = {
      'CN': '中国', 'US': '美国', 'JP': '日本', 'KR': '韩国', 'TW': '台湾',
      'HK': '香港', 'MO': '澳门', 'SG': '新加坡', 'GB': '英国', 'DE': '德国',
      'FR': '法国', 'CA': '加拿大', 'AU': '澳大利亚', 'RU': '俄罗斯',
      'IN': '印度', 'BR': '巴西', 'ZA': '南非', 'IT': '意大利', 'ES': '西班牙',
      'NL': '荷兰', 'SE': '瑞典', 'CH': '瑞士', 'NO': '挪威', 'FI': '芬兰',
      'DK': '丹麦', 'BE': '比利时', 'AT': '奥地利', 'IE': '爱尔兰', 'NZ': '新西兰',
      'IL': '以色列', 'AE': '阿联酋', 'SA': '沙特', 'TH': '泰国', 'VN': '越南',
      'MY': '马来西亚', 'PH': '菲律宾', 'ID': '印度尼西亚', 'PK': '巴基斯坦',
      'BD': '孟加拉', 'TR': '土耳其', 'PL': '波兰', 'UA': '乌克兰',
      'AR': '阿根廷', 'MX': '墨西哥', 'CL': '智利', 'CO': '哥伦比亚',
      'EG': '埃及', 'NG': '尼日利亚', 'KE': '肯尼亚',
    }
    return names[code] || code
  }

  private flagEmoji(code: string): string {
    if (!code || code.length !== 2) return '🌍'
    const base: number = 0x1F1E6
    return String.fromCodePoint(code.charCodeAt(0) - 65 + base) + String.fromCodePoint(code.charCodeAt(1) - 65 + base)
  }
}
