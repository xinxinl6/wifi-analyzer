// 端口扫描空闲视图组件

import {
  COLOR_PURPLE, COLOR_SHADOW_DARK,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG,
  COLOR_GLASS_SKY_SHADOW_MED,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'

interface PresetItem {
  name: string
  description: string
  portCount: number
}

@Component
export struct PortIdleView {
  @Prop isDarkMode: boolean = false
  @Prop inputText: string = ''
  @Prop presetItems: PresetItem[] = []
  @Prop selectedPresetIndex: number = 0

  onInputChange: (value: string) => void = () => {}
  onPresetSelect: (index: number) => void = () => {}
  onStartScan: () => void = () => {}

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.SearchBarSection()
        this.PresetSelector()
        this.FeatureCard()
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
      Image($r('app.media.ic_port')).width(20).height(20).fillColor(COLOR_PURPLE)

      TextInput({ placeholder: $r('app.string.input_ip_hint'), text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.onInputChange(value) })

      Row() {
        Text($r('app.string.scan_action'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_PURPLE)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.onStartScan())
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 预设方案选择
  @Builder PresetSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.scan_preset'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Column({ space: 0 }) {
        ForEach(this.presetItems, (preset: PresetItem, index: number) => {
          this.PresetRow(preset, index)
        }, (preset: PresetItem, index: number): string => String(index))
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
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder PresetRow(preset: PresetItem, index: number) {
    Row({ space: SPACE_MD }) {
      Circle()
        .width(20).height(20)
        .fill(this.selectedPresetIndex === index ? COLOR_PURPLE : Color.Transparent)
        .border({ width: 2, color: this.selectedPresetIndex === index ? COLOR_PURPLE : adaptiveDivider(this.isDarkMode) })

      Column({ space: 2 }) {
        Text(preset.name)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_MEDIUM)
        Text() {
          Span(preset.description + ' (')
          Span(String(preset.portCount))
          Span(' ')
          Span($r('app.string.port_count_ports'))
          Span(')')
        }
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .border({
      width: index < this.presetItems.length - 1 ? 0.5 : 0,
      color: adaptiveDivider(this.isDarkMode)
    })
    .stateStyles({ pressed: { opacity: 0.8 } })
    .onClick(() => { this.onPresetSelect(index) })
  }

  // 功能说明
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.port_scan_intro'))
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('🔍', $r('app.string.port_detection'), $r('app.string.port_detection_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', $r('app.string.security_scan'), $r('app.string.security_scan_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📈', $r('app.string.result_export'), $r('app.string.result_export_desc'))
      }
      .padding({ left: 14, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(emoji: string, title: string | Resource, desc: string | Resource) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? 'rgba(147,51,234,0.15)' : COLOR_GLASS_SKY_ACTIVE)
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
}
