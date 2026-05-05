// Wake On LAN 页面组件 — Aurora WiFi V2 天蓝极光设计
// 界面：设备列表 + 添加设备表单 + 发送唤醒 + 唤醒历史

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_CYAN, COLOR_PURPLE, COLOR_PINK, COLOR_INDIGO,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_SOLID, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_LINE,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import {
  WolEngine, WolDevice, WolResult, WolCallbacks,
} from '../wol/WolEngine'
import { RouterManager } from '@wifi-analyzer/core'

@Component
export struct WolPage {
  @Consume isDarkMode: boolean = false

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
    Stack() {
      // ===== Aurora 天蓝渐变背景 =====
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })

      // 主内容
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

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
          .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
          .width('100%')
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

  // 提示信息卡
  @Builder InfoCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(44).height(44)
            .fill(this.isDarkMode ? 'rgba(34,211,238,0.15)' : '#E0F7FE')
          Image($r('app.media.ic_wol')).width(24).height(24).fillColor(COLOR_CYAN)
        }
        Column({ space: 4 }) {
          Text($r('app.string.remote_wake'))
            .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          Text($r('app.string.remote_wake_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
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
    .clip(true)
  }

  // 快速添加预设
  @Builder QuickPresets() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.quick_add'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(WolEngine.DEVICE_PRESETS, (preset: WolDevice) => {
          Text(preset.name)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_CYAN)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.isDarkMode ? 'rgba(34,211,238,0.15)' : '#E0F7FE')
            .borderRadius(999)
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
            ? (this.isDarkMode ? 'rgba(16,185,129,0.15)' : '#ECFDF5')
            : (this.isDarkMode ? 'rgba(255,255,255,0.08)' : COLOR_GLASS_WHITE))
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
        .onClick(() => this.sendWake(device))
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
    .clip(true)
  }

  // 添加设备按钮
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
    .backgroundColor(this.isDarkMode ? 'rgba(34,211,238,0.12)' : '#E0F7FE')
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? 'rgba(34,211,238,0.3)' : COLOR_CYAN)
    .stateStyles({ pressed: { opacity: 0.8 } })
    .onClick(() => { this.showAddForm = !this.showAddForm })
  }

  // 添加设备表单
  @Builder AddDeviceForm() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.add_device_action'))
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text($r('app.string.cancel_action'))
          .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
          .onClick(() => { this.showAddForm = false })
      }
      .width('100%')

      // 设备名称
      this.FormInput(
        $r('app.string.device_name'),
        $r('app.string.device_name_placeholder'),
        this.newDeviceName,
        (value: string) => { this.newDeviceName = value }
      )

      // MAC地址
      this.FormInput(
        $r('app.string.mac_label'),
        $r('app.string.mac_placeholder'),
        this.newDeviceMac,
        (value: string) => { this.newDeviceMac = value }
      )

      // 广播地址
      this.FormInput(
        $r('app.string.ip_label'),
        $r('app.string.ip_optional_placeholder'),
        this.newDeviceIp,
        (value: string) => { this.newDeviceIp = value }
      )

      Button($r('app.string.confirm_add'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_CYAN)
        .borderRadius(999).height(48)
        .width('100%')
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.addDevice())
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

  // 发送中状态
  @Builder SendingState() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(40).height(40).fill(COLOR_CYAN).opacity(this.pulseOpacity)
        Image($r('app.media.ic_wol')).width(20).height(20).fillColor(Color.White)
      }
      Text() {
        Span($r('app.string.sending_wake_packet'))
        Span(' ' + this.sendingDeviceName + ' ')
        Span($r('app.string.sending_wake_packet_suffix'))
      }
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_CYAN)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? 'rgba(34,211,238,0.12)' : '#E0F7FE')
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? 'rgba(34,211,238,0.3)' : COLOR_CYAN)
    .clip(true)
  }

  // 错误提示
  @Builder ErrorTip() {
    Row({ space: SPACE_SM }) {
      Text('!')
        .fontSize(FONT_SIZE_SM).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
        .width(24).height(24).textAlign(TextAlign.Center)
        .backgroundColor(COLOR_DANGER).borderRadius(12)
      Text(this.errorMessage).fontSize(FONT_SIZE_SM).fontColor(COLOR_DANGER)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? 'rgba(239,68,68,0.12)' : '#FEF2F2')
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? 'rgba(239,68,68,0.3)' : COLOR_DANGER)
    .clip(true)
  }

  // 最近唤醒结果
  @Builder LastResultCard() {
    if (this.lastResult) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(40).height(40)
            .fill(this.lastResult.success
              ? (this.isDarkMode ? 'rgba(16,185,129,0.15)' : '#ECFDF5')
              : (this.isDarkMode ? 'rgba(239,68,68,0.15)' : '#FEF2F2'))
          Text(this.lastResult.success ? '✓' : '!').fontSize(FONT_SIZE_LG)
            .fontColor(this.lastResult.success ? COLOR_SUCCESS : COLOR_DANGER)
        }
        Column({ space: 4 }) {
          Text(this.lastResult.success ? $r('app.string.wake_success') : $r('app.string.wake_failed'))
            .fontSize(FONT_SIZE_MD).fontColor(this.lastResult.success ? COLOR_SUCCESS : COLOR_DANGER)
            .fontWeight(FONT_WEIGHT_MEDIUM)
          Text(this.lastResult.deviceName + ' (' + this.lastResult.mac + ')')
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.lastResult.success
        ? (this.isDarkMode ? 'rgba(16,185,129,0.3)' : 'rgba(16,185,129,0.3)')
        : (this.isDarkMode ? 'rgba(239,68,68,0.3)' : 'rgba(239,68,68,0.3)'))
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({
        radius: GLASS_SHADOW_LG,
        color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
        offsetX: 0,
        offsetY: 4
      })
      .clip(true)
    }
  }

  // 功能说明卡片
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.usage_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('🔮', '网络唤醒', '通过Magic Packet远程开启电脑')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📡', '广播支持', '向255.255.255.255广播地址发送')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('💾', '设备保存', '常用设备自动保存，快速唤醒')
      }
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

  @Builder FeatureItem(emoji: string, title: string, desc: string) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? 'rgba(34,211,238,0.12)' : '#E0F7FE')
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
