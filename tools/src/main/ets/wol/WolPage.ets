// Wake On LAN 页面组件
// 界面：设备列表 + 添加设备表单 + 发送唤醒 + 唤醒历史

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_CYAN,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_SM, BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM,
} from '@wifi-analyzer/design-system'
import {
  WolEngine, WolDevice, WolResult, WolCallbacks,
} from '../wol/WolEngine'
import { RouterManager } from '@wifi-analyzer/core'

@Component
export struct WolPage {
  // UI 状态：'idle' | 'sending'
  @State viewMode: string = 'idle'
  @State sendingDeviceName: string = ''

  // 设备列表
  @State deviceList: WolDevice[] = []

  // 添加设备表单
  @State showAddForm: boolean = false
  @State newDeviceName: string = ''
  @State newDeviceMac: string = ''
  @State newDeviceIp: string = ''

  // 唤醒结果
  @State lastResult: WolResult | null = null
  @State showError: boolean = false
  @State errorMessage: string = ''

  // 引擎
  private engine: WolEngine = new WolEngine()

  // 脉冲动画
  @State pulseOpacity: number = 1.0
  private pulseTimerId: number = -1

  aboutToAppear(): void {
    this.deviceList = this.engine.getDevices()
  }

  aboutToDisappear(): void {
    this.stopPulse()
  }

  // 脉冲动画
  private startPulse(): void {
    this.pulseTimerId = setInterval((): void => {
      this.pulseOpacity = this.pulseOpacity === 1.0 ? 0.3 : 1.0
    }, 600)
  }

  private stopPulse(): void {
    if (this.pulseTimerId >= 0) {
      clearInterval(this.pulseTimerId)
      this.pulseTimerId = -1
    }
    this.pulseOpacity = 1.0
  }

  // ==================== 业务逻辑 ====================

  async sendWake(device: WolDevice): Promise<void> {
    this.sendingDeviceName = device.name
    this.viewMode = 'sending'
    this.showError = false
    this.startPulse()

    const callbacks: WolCallbacks = {
      onSuccess: (result: WolResult): void => {
        this.lastResult = result
        this.stopPulse()
        this.viewMode = 'idle'
        this.deviceList = this.engine.getDevices()
      },
      onError: (message: string): void => {
        this.errorMessage = message
        this.showError = true
        this.stopPulse()
        this.viewMode = 'idle'
      }
    }

    await this.engine.wake(device, callbacks)
  }

  addDevice(): void {
    const mac: string = WolEngine.normalizeMac(this.newDeviceMac)
    if (mac.length === 0) {
      this.errorMessage = 'MAC地址格式不正确'
      this.showError = true
      return
    }

    const device: WolDevice = {
      name: this.newDeviceName.length > 0 ? this.newDeviceName : '新设备',
      mac: mac,
      ip: this.newDeviceIp.trim(),
      port: 9,
      lastWakeTime: 0
    }

    this.engine.saveDevice(device)
    this.deviceList = this.engine.getDevices()
    this.showAddForm = false
    this.newDeviceName = ''
    this.newDeviceMac = ''
    this.newDeviceIp = ''
  }

  removeDevice(mac: string): void {
    this.engine.removeDevice(mac)
    this.deviceList = this.engine.getDevices()
  }

  addFromPreset(name: string): void {
    this.newDeviceName = name
    this.newDeviceMac = ''
    this.newDeviceIp = ''
    this.showAddForm = true
  }

  // ==================== 页面入口 ====================
  build() {
    Column() {
      this.MainContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
    .padding({ top: SPACE_LG, bottom: SAFE_AREA_BOTTOM })
  }

  // ==================== 主内容 ====================
  @Builder MainContent() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 提示信息
        this.InfoCard()

        // 快速添加预设
        this.QuickPresets()

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

        // 唤醒状态
        if (this.viewMode === 'sending') {
          this.SendingState()
        }

        // 错误提示
        if (this.showError) {
          this.ErrorTip()
        }

        // 最近唤醒结果
        if (this.lastResult) {
          this.LastResultCard()
        }

        this.FeatureCard()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // 提示信息卡
  @Builder InfoCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(40).height(40).fill('#E0F7FE')
          Image($r('app.media.ic_wol')).width(22).height(22).fillColor(COLOR_CYAN)
        }
        Column({ space: 2 }) {
          Text($r('app.string.remote_wake'))
            .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          Text($r('app.string.remote_wake_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 快速添加预设
  @Builder QuickPresets() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.quick_add'))
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(WolEngine.DEVICE_PRESETS, (preset: WolDevice) => {
          Text(preset.name)
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_CYAN)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor('#E0F7FE').borderRadius(RADIUS_3XL)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.addFromPreset(preset.name))
        }, (preset: WolDevice): string => preset.name)
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // 设备列表
  @Builder DeviceListSection() {
    Column({ space: SPACE_SM }) {
      Row() {
        Text($r('app.string.saved_devices'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text() {
          Span(String(this.deviceList.length))
          Span(' ')
          Span($r('app.string.devices_count'))
        }.fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
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
        Circle().width(36).height(36).fill(device.lastWakeTime > 0 ? '#ECFDF5' : COLOR_DIVIDER)
        Image($r('app.media.ic_wol')).width(18).height(18).fillColor(device.lastWakeTime > 0 ? COLOR_SUCCESS : COLOR_TEXT_TERTIARY)
      }

      Column({ space: 2 }) {
        Text(device.name).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
        Row({ space: SPACE_SM }) {
          Text(device.mac).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          if (device.lastWakeTime > 0) {
            Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
            Text(WolEngine.formatLastWakeTime(device.lastWakeTime)).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          }
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)

      Button($r('app.string.wake_action'))
        .fontSize(FONT_SIZE_SM).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_CYAN)
        .borderRadius(RADIUS_3XL).height(28)
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.sendWake(device))
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_MD)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 添加设备按钮
  @Builder AddDeviceButton() {
    Button() {
      Row({ space: 4 }) {
        Text('+')
        Text() {
          Span('  ')
          Span($r('app.string.add_device_action'))
        }
      }
    }
      .fontSize(FONT_SIZE_MD).fontColor(COLOR_CYAN).fontWeight(FONT_WEIGHT_MEDIUM)
      .width('100%').height(44)
      .backgroundColor('#E0F7FE')
      .borderRadius(RADIUS_2XL)
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => { this.showAddForm = !this.showAddForm })
  }

  // 添加设备表单
  @Builder AddDeviceForm() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.add_device_action')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text($r('app.string.cancel_action')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_TERTIARY)
          .onClick(() => { this.showAddForm = false })
      }
      .width('100%')

      Row({ space: SPACE_SM }) {
        Text($r('app.string.device_name')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).width(50)
        TextInput({ placeholder: $r('app.string.device_name_placeholder'), text: this.newDeviceName })
          .layoutWeight(1).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => { this.newDeviceName = value })
      }
      .width('100%').padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS }).backgroundColor(COLOR_SURFACE)
      .borderRadius(RADIUS_MD).border({ width: 1, color: COLOR_BORDER })

      Row({ space: SPACE_SM }) {
        Text($r('app.string.mac_label')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).width(50)
        TextInput({ placeholder: $r('app.string.mac_placeholder'), text: this.newDeviceMac })
          .layoutWeight(1).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => { this.newDeviceMac = value })
      }
      .width('100%').padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS }).backgroundColor(COLOR_SURFACE)
      .borderRadius(RADIUS_MD).border({ width: 1, color: COLOR_BORDER })

      Row({ space: SPACE_SM }) {
        Text($r('app.string.ip_label')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).width(50)
        TextInput({ placeholder: $r('app.string.ip_optional_placeholder'), text: this.newDeviceIp })
          .layoutWeight(1).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
          .backgroundColor(Color.Transparent)
          .type(InputType.Normal)
          .onChange((value: string) => { this.newDeviceIp = value })
      }
      .width('100%').padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS }).backgroundColor(COLOR_SURFACE)
      .borderRadius(RADIUS_MD).border({ width: 1, color: COLOR_BORDER })

      Button($r('app.string.confirm_add'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_CYAN)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD)
        .width('100%')
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.addDevice())
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 发送中状态
  @Builder SendingState() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(36).height(36).fill(COLOR_CYAN).opacity(this.pulseOpacity)
        Image($r('app.media.ic_wol')).width(18).height(18).fillColor(Color.White)
      }
      Text() {
        Span($r('app.string.sending_wake_packet'))
        Span(' ' + this.sendingDeviceName + ' ')
        Span($r('app.string.sending_wake_packet_suffix'))
      }
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_CYAN)
        .layoutWeight(1)
    }
    .width('100%').padding(SPACE_MD).backgroundColor('#E0F7FE').borderRadius(RADIUS_MD)
  }

  // 错误提示
  @Builder ErrorTip() {
    Row({ space: SPACE_SM }) {
      Text('!').fontSize(FONT_SIZE_SM).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
        .width(20).height(20).textAlign(TextAlign.Center)
        .backgroundColor(COLOR_DANGER).borderRadius(10)
      Text(this.errorMessage).fontSize(FONT_SIZE_SM).fontColor(COLOR_DANGER)
    }
    .width('100%').padding(SPACE_MD).backgroundColor('#FEF2F2').borderRadius(RADIUS_MD)
  }

  // 最近唤醒结果
  @Builder LastResultCard() {
    if (this.lastResult) {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(32).height(32).fill('#ECFDF5')
        Text(this.lastResult.success ? '✓' : '!').fontSize(FONT_SIZE_MD)
          .fontColor(this.lastResult.success ? COLOR_SUCCESS : COLOR_DANGER)
      }
      Column({ space: 2 }) {
        Text(this.lastResult.success ? $r('app.string.wake_success') : $r('app.string.wake_failed'))
          .fontSize(FONT_SIZE_SM).fontColor(this.lastResult.success ? COLOR_SUCCESS : COLOR_DANGER)
          .fontWeight(FONT_WEIGHT_MEDIUM)
        Text(this.lastResult.deviceName + ' (' + this.lastResult.mac + ')')
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_MD)
    .border({ width: 1, color: COLOR_BORDER })
    }
  }

  // 功能说明卡片
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#E0F7FE')
          Image($r('app.media.ic_wol')).width(18).height(18).fillColor(COLOR_CYAN)
        }
        Column({ space: 2 }) {
          Text($r('app.string.usage_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.wol_hint'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_2XL).border({ width: 1, color: COLOR_BORDER })
  }
}
