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
import { WolInfoCard } from './WolInfoCard'
import { WolDeviceList } from './WolDeviceList'
import { WolSendingState, WolErrorTip } from './WolSendingState'
import { WolLastResult } from './WolLastResult'

@Component
export struct WolPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  @State viewMode: string = 'idle'
  @State sendingDeviceName: string = ''
  @State deviceList: WolDevice[] = []
  @State showAddForm: boolean = false
  @State newDeviceName: string = ''
  @State newDeviceMac: string = ''
  @State newDeviceIp: string = ''
  @State lastResult: WolResult | null = null
  @State showError: boolean = false
  @State errorMessage: string | Resource = ''

  private engine: WolEngine = new WolEngine()

  aboutToAppear(): void {
    this.deviceList = this.engine.getDevices()
  }

  // ==================== 业务逻辑 ====================

  async sendWake(device: WolDevice): Promise<void> {
    this.sendingDeviceName = device.name
    this.viewMode = 'sending'
    this.showError = false

    const callbacks: WolCallbacks = {
      onSuccess: (result: WolResult): void => {
        this.lastResult = result
        this.viewMode = 'idle'
        this.deviceList = this.engine.getDevices()
      },
      onError: (message: string): void => {
        this.errorMessage = message
        this.showError = true
        this.viewMode = 'idle'
      }
    }

    await this.engine.wake(device, callbacks)
  }

  addDevice(): void {
    const mac: string = WolEngine.normalizeMac(this.newDeviceMac)
    if (mac.length === 0) {
      this.errorMessage = $r('app.string.wol_mac_invalid')
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

  addFromPreset(name: string): void {
    this.newDeviceName = name
    this.newDeviceMac = ''
    this.newDeviceIp = ''
    this.showAddForm = true
  }

  // ==================== 页面入口 ====================
  build() {
    Stack() {
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

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

      Column() {
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column({ space: SPACE_LG }) {
            WolInfoCard({ isDarkMode: this.isDarkMode, onAddFromPreset: (name: string) => this.addFromPreset(name) })

            WolDeviceList({
              isDarkMode: this.isDarkMode,
              deviceList: this.deviceList,
              showAddForm: this.showAddForm,
              newDeviceName: this.newDeviceName,
              newDeviceMac: this.newDeviceMac,
              newDeviceIp: this.newDeviceIp,
              onSendWake: (device: WolDevice) => this.sendWake(device),
              onToggleAddForm: () => { this.showAddForm = !this.showAddForm },
              onCancelAdd: () => { this.showAddForm = false },
              onConfirmAdd: () => this.addDevice(),
              onNameChange: (value: string) => { this.newDeviceName = value },
              onMacChange: (value: string) => { this.newDeviceMac = value },
              onIpChange: (value: string) => { this.newDeviceIp = value }
            })

            if (this.viewMode === 'sending') {
              WolSendingState({ isDarkMode: this.isDarkMode, sendingDeviceName: this.sendingDeviceName })
            }

            if (this.showError) {
              WolErrorTip({ isDarkMode: this.isDarkMode, errorMessage: this.errorMessage })
            }

            if (this.lastResult) {
              WolLastResult({ isDarkMode: this.isDarkMode, lastResult: this.lastResult })
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

  // ==================== 功能说明卡片（内联） ====================
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.usage_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('🔮', $r('app.string.wol_network_wake'), $r('app.string.wol_wake_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📡', $r('app.string.wol_broadcast_support'), $r('app.string.wol_broadcast_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('💾', $r('app.string.wol_device_save'), $r('app.string.wol_device_save_desc'))
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

  @Builder FeatureItem(emoji: string, title: string | Resource, desc: string | Resource) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? COLOR_GLASS_SKY_ACTIVE : '#E0F7FE')
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
