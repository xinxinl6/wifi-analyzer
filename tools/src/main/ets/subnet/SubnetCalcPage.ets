// 子网换算页面组件 — Aurora WiFi V2 天蓝极光设计
// 轻量容器：状态管理 + 容器编排 + 业务逻辑

import {
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD,
  FONT_WEIGHT_BOLD,
  SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  SAFE_AREA_TOP,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider,
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { SubnetCalculator, SubnetResult, IpAddressInfo, SubnetPreset } from '../subnet/SubnetCalculator'
import { RouterManager } from '@wifi-analyzer/core'
import { SubnetInputSection } from './SubnetInputSection'
import { SubnetPresetSection } from './SubnetPresetSection'
import { SubnetResultSection } from './SubnetResultSection'
import { SubnetErrorTip } from './SubnetErrorTip'

@Component
export struct SubnetCalcPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  // 输入
  @State inputText: string = '192.168.1.1/24'

  // 预设子网
  @State presets: SubnetPreset[] = []

  // 计算结果
  @State hasResult: boolean = false
  @State result: SubnetResult = {
    networkAddress: '', broadcastAddress: '', subnetMask: '', wildcardMask: '',
    firstHost: '', lastHost: '', totalHosts: 0, prefixLength: 24,
    ipClass: '', isPrivate: false, binaryMask: '', ipType: '',
  }

  // 输入验证
  @State inputValid: boolean = true
  @State inputError: string = ''

  aboutToAppear(): void {
    this.presets = SubnetCalculator.SUBNET_PRESETS
    this.doCalculate()
  }

  // ==================== 业务逻辑 ====================

  doCalculate(): void {
    const input: string = this.inputText.trim()
    if (input.length === 0) {
      this.hasResult = false
      this.inputValid = true
      this.inputError = ''
      return
    }

    const info: IpAddressInfo = SubnetCalculator.parseInput(input)
    if (!info.isValid) {
      this.inputValid = false
      this.inputError = info.errorMessage
      this.hasResult = false
      return
    }

    this.inputValid = true
    this.inputError = ''
    this.result = SubnetCalculator.calculate(info.address, info.prefixLength)
    this.hasResult = true
  }

  onPresetTap(preset: SubnetPreset): void {
    const info: IpAddressInfo = SubnetCalculator.parseInput(this.inputText)
    if (info.isValid) {
      this.inputText = info.address + '/' + String(preset.prefix)
    } else {
      this.inputText = '192.168.1.1/' + String(preset.prefix)
    }
    this.doCalculate()
  }

  onInputChanged(value: string): void {
    this.inputText = value
    if (value.trim().length > 0) {
      this.doCalculate()
    } else {
      this.hasResult = false
    }
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
            SubnetInputSection({
              isDarkMode: this.isDarkMode,
              inputText: this.inputText,
              inputValid: this.inputValid,
              inputError: this.inputError,
              onInputChange: (value: string) => this.onInputChanged(value),
              onCalculate: () => this.doCalculate(),
            })

            SubnetPresetSection({
              isDarkMode: this.isDarkMode,
              presets: this.presets,
              onPresetTap: (preset: SubnetPreset) => this.onPresetTap(preset),
            })

            if (this.hasResult) {
              SubnetResultSection({
                isDarkMode: this.isDarkMode,
                result: this.result,
              })
            } else if (!this.inputValid) {
              SubnetErrorTip({
                isDarkMode: this.isDarkMode,
                errorMessage: this.inputError,
              })
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

  // ==================== 功能说明 ====================
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.subnet_calc_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('\u{1F522}', $r('app.string.subnet_calc_title'), $r('app.string.subnet_calc_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('\u{1F4CA}', $r('app.string.subnet_binary_title'), $r('app.string.subnet_binary_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('\u{1F3F7}\u{FE0F}', $r('app.string.subnet_preset_title'), $r('app.string.subnet_preset_desc'))
      }
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  @Builder FeatureItem(emoji: string, title: string | Resource, desc: string | Resource) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? 'rgba(245,158,11,0.15)' : '#FEF3C7')
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
