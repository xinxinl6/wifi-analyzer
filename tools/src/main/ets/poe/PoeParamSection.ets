// PoE 参数输入 + 设备预设 — Aurora WiFi V2

import {
  COLOR_WARNING, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_MD, FONT_SIZE_SM,
  SPACE_SM, SPACE_MD,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { CableSpec, DevicePreset } from '../poe/PoeCalculator'

// ==================== 参数输入区 ====================
@Component
export struct PoeParamSection {
  @Prop isDarkMode: boolean = false
  @Prop cableLength: number = 100
  @Prop selectedGauge: number = 24
  @Prop devicePower: number = 12.95
  @Prop cableSpecs: CableSpec[] = []
  onCableLengthChanged: (value: string) => void = () => {}
  onGaugeTap: (gauge: number) => void = () => {}
  onDevicePowerChanged: (value: string) => void = () => {}

  build() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.param_settings'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Column({ space: SPACE_MD }) {
        // 线缆长度
        Row() {
          Text($r('app.string.poe_cable_length_label'))
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).layoutWeight(1)
          TextInput({ text: String(this.cableLength) })
            .type(InputType.Number)
            .width(80).textAlign(TextAlign.End)
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode))
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => this.onCableLengthChanged(value))
          Text($r('app.string.cable_meter'))
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .width('100%')

        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

        // 线缆规格
        Column({ space: SPACE_SM }) {
          Text($r('app.string.poe_cable_spec_label'))
            .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
            .alignSelf(ItemAlign.Start)
          Row({ space: SPACE_SM }) {
            ForEach(this.cableSpecs, (spec: CableSpec) => {
              Text(spec.label)
                .fontSize(FONT_SIZE_XS)
                .fontColor(this.selectedGauge === spec.gauge ? Color.White : adaptiveTextSecondary(this.isDarkMode))
                .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_SM, bottom: SPACE_SM })
                .backgroundColor(this.selectedGauge === spec.gauge ? COLOR_WARNING : adaptiveDivider(this.isDarkMode))
                .borderRadius(999)
                .stateStyles({ pressed: { opacity: 0.8 } })
                .onClick(() => this.onGaugeTap(spec.gauge))
            }, (spec: CableSpec): string => String(spec.gauge))
          }
        }
        .width('100%')

        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

        // 设备功率需求
        Row() {
          Text($r('app.string.poe_device_power_label'))
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).layoutWeight(1)
          TextInput({ text: String(this.devicePower) })
            .type(InputType.Number)
            .width(80).textAlign(TextAlign.End)
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode))
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => this.onDevicePowerChanged(value))
          Text($r('app.string.power_unit_w'))
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .width('100%')
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
        color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
        offsetX: 0,
        offsetY: 4
      })
      .clip(true)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }
}

// ==================== 设备快速选择 ====================
@Component
export struct PoeDevicePresets {
  @Prop isDarkMode: boolean = false
  @Prop devicePresets: DevicePreset[] = []
  onDeviceTap: (preset: DevicePreset) => void = () => {}

  build() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.poe_common_devices_label'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.devicePresets, (preset: DevicePreset) => {
          Text(preset.icon + ' ' + preset.name)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_WARNING)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_SM, bottom: SPACE_SM })
            .backgroundColor(this.isDarkMode ? 'rgba(245,158,11,0.15)' : '#FEF3C7')
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onDeviceTap(preset))
        }, (preset: DevicePreset): string => preset.name)
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
    .shadow({
      radius: GLASS_SHADOW_LG,
      color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .clip(true)
  }
}
