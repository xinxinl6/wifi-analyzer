import {
  COLOR_INDIGO,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  COLOR_SHADOW_GLASS_STRONG,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'

interface MacExampleItem {
  name: string | Resource
  mac: string
}

@Component
export struct MacIdleView {
  @Prop isDarkMode: boolean = false
  @Prop inputText: string = ''
  @Prop historyList: string[] = []
  onInputChange: (value: string) => void = () => {}
  onSubmit: () => void = () => {}
  onQuickTap: (mac: string) => void = () => {}
  onHistoryTap: (mac: string) => void = () => {}

  build() {
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
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.onInputChange(value) })

      Row() {
        Text($r('app.string.query_action')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_INDIGO)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.onSubmit())
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({
      radius: GLASS_SHADOW_XL,
      color: this.isDarkMode ? COLOR_SHADOW_GLASS_STRONG : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
  }

  // 格式提示
  @Builder FormatTip() {
    Text($r('app.string.mac_format_hint'))
      .fontSize(FONT_SIZE_XS)
      .fontColor(adaptiveTextTertiary(this.isDarkMode))
      .alignSelf(ItemAlign.Start)
      .padding({ left: SPACE_MD })
  }

  // 快速示例
  @Builder QuickExamples() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_vendor_examples'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        ForEach([
          { name: 'Apple', mac: 'A4:B1:97:00:AB:CD' },
          { name: $r('app.string.huawei'), mac: '20:A6:CD:56:78:90' },
          { name: $r('app.string.xiaomi'), mac: '78:11:0B:AB:CD:EF' },
          { name: 'TP-Link', mac: 'A8:42:A1:DE:AD:BE' }
        ], (item: MacExampleItem, index: number) => {
          Row({ space: 5 }) {
            Text(index === 0 ? '🍎' : index === 1 ? '📱' : index === 2 ? '📱' : '🔌')
              .fontSize(12)
            Text(item.name)
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_INDIGO)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(this.isDarkMode ? 'rgba(99,102,241,0.3)' : COLOR_GLASS_SKY_TAG_BORDER)
          .onClick(() => this.onQuickTap(item.mac))
        }, (item: MacExampleItem, index: number): string => String(index))
      }
      .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  // 功能说明卡片
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.mac_lookup_intro'))
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('🔍', $r('app.string.mac_vendor_query'), $r('app.string.mac_vendor_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('🌍', $r('app.string.mac_country_info'), $r('app.string.mac_country_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', $r('app.string.mac_addr_type'), $r('app.string.mac_addr_type_desc'))
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({
        radius: GLASS_SHADOW_LG,
        color: this.isDarkMode ? COLOR_SHADOW_GLASS_STRONG : COLOR_GLASS_SKY_LIGHT,
        offsetX: 0,
        offsetY: 4
      })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(emoji: string, title: string | Resource, desc: string | Resource) {
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
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.historyList.slice(0, 6), (mac: string) => {
          Text(mac)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_INDIGO)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.isDarkMode ? 'rgba(99,102,241,0.15)' : COLOR_GLASS_SKY_TAG_BG)
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onHistoryTap(mac))
        }, (mac: string): string => mac)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
