// POE 计算器页面组件 — Aurora WiFi V2 天蓝极光设计
// 界面：PoE标准选择 + 线缆参数 + 设备功率 + 计算结果（损耗/预算/效率）

import {
  COLOR_PRIMARY, COLOR_PRIMARY_LIGHT, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE, COLOR_PINK, COLOR_CYAN, COLOR_INDIGO, COLOR_SHADOW_DARK,
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
  PoeCalculator, PoeCalcConfig, PoeCalcResult, PoeStandard, CableSpec, DevicePreset,
} from '../poe/PoeCalculator'
import { RouterManager } from '@wifi-analyzer/core'
import { StandardDisplayItem } from './PoeStandardSelector'
import { PoeStandardSelector } from './PoeStandardSelector'
import { PoeParamSection, PoeDevicePresets } from './PoeParamSection'
import { PoeResultSection } from './PoeResultSection'

@Component
export struct PoeCalcPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  @State selectedStandard: number = 1
  @State standardItems: StandardDisplayItem[] = []
  @State cableLength: number = 100
  @State selectedGauge: number = 24
  @State devicePower: number = 12.95
  @State cableSpecs: CableSpec[] = []
  @State devicePresets: DevicePreset[] = []
  @State hasResult: boolean = true
  @State result: PoeCalcResult = {
    standard: PoeCalculator.STANDARDS[1],
    cableLoss: 0,
    cableLossPercent: 0,
    powerDelivered: 0,
    remainingBudget: 0,
    isSufficient: false,
    maxCableLength: 0,
    efficiency: 0,
    voltageDrop: 0,
    currentFlow: 0,
    powerAtPse: 0,
  }

  aboutToAppear(): void {
    this.loadStandards()
    this.cableSpecs = PoeCalculator.CABLE_SPECS
    this.devicePresets = PoeCalculator.DEVICE_PRESETS
    this.recalculate()
  }

  // 获取字符串资源的辅助方法
  private getStringSync(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
      return ''
    }
  }

  private loadStandards(): void {
    const standards: PoeStandard[] = PoeCalculator.STANDARDS
    const items: StandardDisplayItem[] = []
    for (let i = 0; i < standards.length; i++) {
      const item: StandardDisplayItem = {
        name: standards[i].name,
        type: standards[i].type,
        powerPse: String(standards[i].powerAtPse) + 'W',
        powerPd: String(standards[i].powerAtPd) + 'W',
        description: standards[i].description,
      }
      items.push(item)
    }
    this.standardItems = items
  }

  // ==================== 业务逻辑 ====================

  recalculate(): void {
    const config: PoeCalcConfig = {
      cableLength: this.cableLength,
      cableGauge: this.selectedGauge,
      standardIndex: this.selectedStandard,
      devicePower: this.devicePower,
    }
    this.result = PoeCalculator.calculate(config)
    this.hasResult = true
  }

  onStandardTap(index: number): void {
    this.selectedStandard = index
    this.devicePower = PoeCalculator.STANDARDS[index].powerAtPd
    this.recalculate()
  }

  onGaugeTap(gauge: number): void {
    this.selectedGauge = gauge
    this.recalculate()
  }

  onDeviceTap(preset: DevicePreset): void {
    this.devicePower = preset.power
    this.recalculate()
  }

  onCableLengthChanged(value: string): void {
    const num: number = parseFloat(value)
    if (!isNaN(num) && num >= 0 && num <= 500) {
      this.cableLength = num
      this.recalculate()
    }
  }

  onDevicePowerChanged(value: string): void {
    const num: number = parseFloat(value)
    if (!isNaN(num) && num >= 0 && num <= 100) {
      this.devicePower = num
      this.recalculate()
    }
  }

  getEfficiencyColor(eff: number): string {
    if (eff >= 90) return COLOR_SUCCESS
    if (eff >= 80) return COLOR_WARNING
    return COLOR_DANGER
  }

  getStatusText(isSufficient: boolean): string {
    return this.getStringSync(isSufficient ? $r('app.string.power_sufficient') : $r('app.string.power_insufficient'))
  }

  getStatusDesc(isSufficient: boolean): string {
    return this.getStringSync(isSufficient ? $r('app.string.config_can_meet') : $r('app.string.upgrade_poe_hint'))
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
            PoeStandardSelector({
              isDarkMode: this.isDarkMode,
              standardItems: this.standardItems,
              selectedStandard: this.selectedStandard,
              onStandardTap: (index: number) => this.onStandardTap(index)
            })

            PoeParamSection({
              isDarkMode: this.isDarkMode,
              cableLength: this.cableLength,
              selectedGauge: this.selectedGauge,
              devicePower: this.devicePower,
              cableSpecs: this.cableSpecs,
              onCableLengthChanged: (value: string) => this.onCableLengthChanged(value),
              onGaugeTap: (gauge: number) => this.onGaugeTap(gauge),
              onDevicePowerChanged: (value: string) => this.onDevicePowerChanged(value)
            })

            PoeDevicePresets({
              isDarkMode: this.isDarkMode,
              devicePresets: this.devicePresets,
              onDeviceTap: (preset: DevicePreset) => this.onDeviceTap(preset)
            })

            if (this.hasResult) {
              PoeResultSection({
                isDarkMode: this.isDarkMode,
                result: this.result,
                devicePower: this.devicePower,
                cableLength: this.cableLength,
                getEfficiencyColor: (eff: number) => this.getEfficiencyColor(eff),
                getStatusText: (isSufficient: boolean) => this.getStatusText(isSufficient),
                getStatusDesc: (isSufficient: boolean) => this.getStatusDesc(isSufficient)
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

  // ==================== 功能说明（内联） ====================
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.poe_feature_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('⚡', $r('app.string.poe_power_calc_title'), $r('app.string.poe_power_calc_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', $r('app.string.poe_loss_analysis_title'), $r('app.string.poe_loss_analysis_desc'))
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('💡', $r('app.string.poe_smart_suggest_title'), $r('app.string.poe_smart_suggest_desc'))
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
      color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
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
