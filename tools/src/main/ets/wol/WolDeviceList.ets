// WOL 设备列表 + 添加表单 — Aurora WiFi V2

import {
  COLOR_CYAN, COLOR_SUCCESS, COLOR_SHADOW_DARK,
  FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XS,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER,
  COLOR_GLASS_SKY_LIGHT, COLOR_GLASS_SKY_ACTIVE,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { WolDevice, WolEngine } from '../wol/WolEngine'

// ==================== 设备列表区 ====================
@Component
export struct WolDeviceList {
  @Prop isDarkMode: boolean = false
  @Prop deviceList: WolDevice[] = []
  @Prop showAddForm: boolean = false
  @Prop newDeviceName: string = ''
  @Prop newDeviceMac: string = ''
  @Prop newDeviceIp: string = ''
  onSendWake: (device: WolDevice) => void = () => {}
  onToggleAddForm: () => void = () => {}
  onCancelAdd: () => void = () => {}
  onConfirmAdd: () => void = () => {}
  onNameChange: (value: string) => void = () => {}
  onMacChange: (value: string) => void = () => {}
  onIpChange: (value: string) => void = () => {}

  build() {
    Column({ space: 0 }) {
      // 设备列表
      if (this.deviceList.length > 0) {
        this.DeviceListSection()
      }

      // 添加设备按钮
      this.AddDeviceButton()

      // 添加表单
      if (this.showAddForm) {
        this.AddDeviceForm()
      }
    }
  }

  // ==================== 设备列表 ====================
  @Builder DeviceListSection() {
    Column({ space: SPACE_SM }) {
      Row() {
        Text($r('app.string.saved_devices'))
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span(String(this.deviceList.length))
          Span(' ')
          Span($r('app.string.devices_count'))
        }.fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .width('100%')

      ForEach(this.deviceList, (device: WolDevice, index: number) => {
        this.DeviceRow(device, index)
      }, (device: WolDevice, index: number): string => device.mac)
    }
    .width('100%')
  }

  @Builder DeviceRow(device: WolDevice, index: number) {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(40).height(40)
          .fill(device.lastWakeTime > 0
            ? COLOR_SUCCESS
            : (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_WHITE))
        Image($r('app.media.ic_wol')).width(20).height(20)
          .fillColor(device.lastWakeTime > 0 ? COLOR_SUCCESS : adaptiveTextTertiary(this.isDarkMode))
      }

      Column({ space: 4 }) {
        Text(device.name)
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_MEDIUM)
        Row({ space: SPACE_SM }) {
          Text(device.mac).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          if (device.lastWakeTime > 0) {
            Text(' | ').fontSize(FONT_SIZE_XS).fontColor(adaptiveDivider(this.isDarkMode))
            Text(WolEngine.formatLastWakeTime(device.lastWakeTime)).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Button($r('app.string.wake_action'))
        .fontSize(FONT_SIZE_SM).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_CYAN)
        .borderRadius(999).height(32)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.onSendWake(device))
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

  // ==================== 添加设备按钮 ====================
  @Builder AddDeviceButton() {
    Button() {
      Row({ space: 6 }) {
        Text('+')
          .fontSize(FONT_SIZE_LG)
          .fontColor(COLOR_CYAN)
        Text() {
          Span($r('app.string.add_device_action'))
        }
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_CYAN).fontWeight(FONT_WEIGHT_MEDIUM)
      }
    }
    .width('100%').height(48)
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_SKY_ACTIVE : COLOR_GLASS_SKY_ACTIVE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? 'rgba(34,211,238,0.3)' : COLOR_CYAN)
    .stateStyles({ pressed: { opacity: 0.8 } })
    .onClick(() => { this.onToggleAddForm() })
  }

  // ==================== 添加设备表单 ====================
  @Builder AddDeviceForm() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.add_device_action'))
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text($r('app.string.cancel_action'))
          .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
          .onClick(() => { this.onCancelAdd() })
      }
      .width('100%')

      // 设备名称
      this.FormInput(
        $r('app.string.device_name'),
        $r('app.string.device_name_placeholder'),
        this.newDeviceName,
        (value: string) => { this.onNameChange(value) }
      )

      // MAC地址
      this.FormInput(
        $r('app.string.mac_label'),
        $r('app.string.mac_placeholder'),
        this.newDeviceMac,
        (value: string) => { this.onMacChange(value) }
      )

      // 广播地址
      this.FormInput(
        $r('app.string.ip_label'),
        $r('app.string.ip_optional_placeholder'),
        this.newDeviceIp,
        (value: string) => { this.onIpChange(value) }
      )

      Button($r('app.string.confirm_add'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_CYAN)
        .borderRadius(999).height(48)
        .width('100%')
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.onConfirmAdd())
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

  @Builder FormInput(label: ResourceStr, placeholder: ResourceStr, value: string, onChange: (value: string) => void) {
    Row({ space: SPACE_SM }) {
      Text(label)
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode)).width(70)
      TextInput({ placeholder: placeholder, text: value })
        .layoutWeight(1).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((val: string) => onChange(val))
    }
    .width('100%')
    .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_SM, bottom: SPACE_SM })
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.02)')
    .borderRadius(12)
  }
}
