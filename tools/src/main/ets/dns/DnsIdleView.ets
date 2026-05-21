// DNS 查询空闲状态视图组件

import {
  COLOR_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_MD,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL,
  COLOR_GLASS_WHITE, COLOR_GLASS_AURORA, COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_BORDER,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'

// ==================== 接口定义 ====================

export interface ServerItem {
  name: string
  address: string
  color: string
  apiUrl: string
}

// ==================== 组件 ====================

@Component
export struct DnsIdleView {
  @Prop isDarkMode: boolean = false
  @Prop inputText: string = ''
  @Prop selectedServerIndex: number = 0
  @Prop ipFamilyIndex: number = 0
  @Prop serverList: ServerItem[] = []
  @Prop popularDomains: string[] = []

  onInputChange: (value: string) => void = () => {}
  onSubmit: () => void = () => {}
  onServerChange: (index: number) => void = () => {}
  onIpFamilyChange: (index: number) => void = () => {}
  onDomainTap: (domain: string) => void = () => {}
  onOpenHistory: () => void = () => {}

  private ipFamilyLabels: Resource[] = [$r('app.string.ip_family_all'), $r('app.string.ip_family_ipv4'), $r('app.string.ip_family_ipv6')]

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.SearchBarSection()
        this.IpFamilySection()
        this.ServerSelector()
        this.RecordTypeSection()
        this.PopularDomainsSection()
        this.FeatureCard()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // IP 类型选择
  @Builder IpFamilySection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.ip_family_label')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.ipFamilyLabels, (label: Resource, index: number) => {
          Text(label)
            .fontSize(FONT_SIZE_XS)
            .fontColor(this.ipFamilyIndex === index ? Color.White : COLOR_PRIMARY)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.ipFamilyIndex === index ? COLOR_PRIMARY : (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT))
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onIpFamilyChange(index))
        }, (label: Resource, index: number): string => String(index))
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_dns')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_PRIMARY)

      TextInput({ placeholder: $r('app.string.input_domain_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => this.onInputChange(value))

      Button($r('app.string.query_action'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_PRIMARY)
        .borderRadius(999)
        .height(36)
        .padding({ left: 18, right: 18 })
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.onSubmit())
    }
    .width('100%').padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // DNS 服务器选择
  @Builder ServerSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.dns_server')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.serverList, (server: ServerItem, index: number) => {
          Text(server.name)
            .fontSize(FONT_SIZE_XS)
            .fontColor(this.selectedServerIndex === index ? Color.White : adaptiveTextSecondary(this.isDarkMode))
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.selectedServerIndex === index ? COLOR_PRIMARY : (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT))
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onServerChange(index))
        }, (server: ServerItem, index: number): string => String(index))
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  // 记录类型说明
  @Builder RecordTypeSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.record_type')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Column({ space: 0 }) {
        this.RecordTypeDesc('A', $r('app.string.ipv4_address'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('AAAA', $r('app.string.ipv6_address'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('CNAME', $r('app.string.alias_record'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('MX', $r('app.string.mail_server'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('NS', $r('app.string.name_server'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.RecordTypeDesc('TXT', $r('app.string.text_record'))
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 10, bottom: 10 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder RecordTypeDesc(type: string, desc: Resource) {
    Row({ space: SPACE_SM }) {
      Text(type)
        .fontSize(FONT_SIZE_XS).fontColor(COLOR_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        .width(36)
      Text(desc)
        .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
  }

  // 常用域名
  @Builder PopularDomainsSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_domains')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.popularDomains, (domain: string) => {
          Text(domain)
            .fontSize(FONT_SIZE_SM).fontColor(COLOR_PRIMARY)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : '#EEF6FE')
            .borderRadius(999)
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
    Column({ space: 0 }) {
      Text($r('app.string.dns_query_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 8 })

      Column({ space: 0 }) {
        this.FeatureItem($r('app.media.ic_dns'), $r('app.string.dns_query_title'), $r('app.string.dns_query_intro_desc'), true)
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem($r('app.media.ic_route'), $r('app.string.dns_multi_server'), $r('app.string.dns_multi_server_desc'), false)
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem($r('app.media.ic_ip'), $r('app.string.record_type'), $r('app.string.dns_record_types'), false)
      }
      .padding({ left: 16, right: 14, top: 14, bottom: 14 })
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

  @Builder FeatureItem(icon: Resource, title: string | Resource, desc: string | Resource, clickable: boolean = false) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_ACTIVE)
        Image(icon).width(18).height(18).fillColor(COLOR_PRIMARY)
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

      if (clickable) {
        Text('>')
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .stateStyles({ pressed: { opacity: clickable ? 0.7 : 1 } })
    .onClick(() => { if (clickable) this.onOpenHistory() })
  }
}
