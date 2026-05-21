import {
  COLOR_INDIGO,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_TAG_BG,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BackButtonCapsule } from '@wifi-analyzer/design-system'
import { MacLookupResult } from '../maclookup/MacLookupEngine'

@Component
export struct MacResultView {
  @Prop isDarkMode: boolean = false
  @Prop result: MacLookupResult = {
    mac: '', vendor: '', country: '', address: '',
    prefix: '', type: 'unknown', status: 'error',
    errorMessage: '', queryTime: 0, source: 'local'
  }
  onBack: () => void = () => {}
  onReQuery: () => void = () => {}
  onEdit: () => void = () => {}

  build() {
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
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: SPACE_SM }) {
          Text(this.result.type === 'UAA' ? $r('app.string.mac_uaa') : this.result.type === 'LAA' ? $r('app.string.mac_laa') : $r('app.string.unknown'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
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
      .onClick(() => this.onEdit())
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({
      radius: GLASS_SHADOW_LG,
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
  }

  // 厂商信息卡
  @Builder VendorInfoCard() {
    Column({ space: 0 }) {
      Row() {
        Row({ space: 6 }) {
          Text('🏭').fontSize(14)
          Text($r('app.string.mac_vendor_info')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        if (this.result.vendor.length > 0) {
          Text(this.result.vendor)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_INDIGO)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_TAG_BG)
            .borderRadius(999)
        }
      }
      .width('100%')
      .padding({ bottom: SPACE_SM })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      Column({ space: SPACE_SM }) {
        if (this.result.prefix.length > 0)
          this.DetailRow($r('app.string.mac_prefix'), this.result.prefix)
        if (this.result.country.length > 0)
          this.DetailRow($r('app.string.mac_country'), this.result.country)
        if (this.result.address.length > 0)
          this.DetailRow($r('app.string.mac_detail_addr'), this.result.address)
        if (this.result.source.length > 0)
          this.DetailRow($r('app.string.mac_data_source'), this.result.source === 'local' ? $r('app.string.mac_local_db') : $r('app.string.mac_online_query'))
      }
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({
      radius: GLASS_SHADOW_LG,
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .clip(true)
  }

  @Builder DetailRow(label: string | Resource, value: string | Resource) {
    Row() {
      Text(label).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode)).width(70)
      Text(value)
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      BackButtonCapsule({ onBack: () => this.onBack() })

      Row() {
        Text($r('app.string.mac_re_query')).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
      }
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
      .padding({ top: 13, bottom: 13 })
      .backgroundColor(COLOR_INDIGO)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
      .onClick(() => this.onReQuery())
    }
    .width('100%')
  }
}
