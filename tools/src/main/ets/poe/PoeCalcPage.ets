// POE 计算器页面组件 — Aurora WiFi V2 天蓝极光设计
// 界面：PoE标准选择 + 线缆参数 + 设备功率 + 计算结果（损耗/预算/效率）

import {
  COLOR_PRIMARY, COLOR_PRIMARY_LIGHT, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE, COLOR_PINK, COLOR_CYAN, COLOR_INDIGO,
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

// ==================== 接口定义 ====================

interface StandardDisplayItem {
  name: string
  type: string
  powerPse: string
  powerPd: string
  description: string
}

// ==================== 组件 ====================

@Component
export struct PoeCalcPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  // PoE 标准选择
  @State selectedStandard: number = 1 // 默认 PoE+
  @State standardItems: StandardDisplayItem[] = []

  // 线缆参数
  @State cableLength: number = 100
  @State selectedGauge: number = 24

  // 设备功率
  @State devicePower: number = 12.95

  // 线缆规格列表
  @State cableSpecs: CableSpec[] = []

  // 设备预设
  @State devicePresets: DevicePreset[] = []

  // 计算结果
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

  // 加载标准列表
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

  // 获取效率颜色
  getEfficiencyColor(eff: number): string {
    if (eff >= 90) return COLOR_SUCCESS
    if (eff >= 80) return COLOR_WARNING
    return COLOR_DANGER
  }

  // 获取供电状态文案
  getStatusText(isSufficient: boolean): string {
    return isSufficient ? '供电充足' : '供电不足'
  }

  // 获取供电状态描述
  getStatusDesc(isSufficient: boolean): string {
    return isSufficient ? '当前配置可满足设备需求' : '请升级PoE标准或减少线缆长度'
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
            // PoE 标准选择
            this.StandardSelector()

            // 参数输入区
            this.ParamSection()

            // 设备快速选择
            this.DevicePresetsSection()

            // 计算结果
            if (this.hasResult) {
              this.ResultSection()
            }

            // 功能说明
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

  // ==================== PoE 标准选择 ====================
  @Builder StandardSelector() {
    Column({ space: SPACE_SM }) {
      Text('PoE 标准')
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Column({ space: SPACE_SM }) {
        ForEach(this.standardItems, (item: StandardDisplayItem, index: number) => {
          this.StandardRow(item, index)
        }, (item: StandardDisplayItem, index: number): string => String(index))
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder StandardRow(item: StandardDisplayItem, index: number) {
    Column({ space: SPACE_XS }) {
      Row({ space: SPACE_MD }) {
        // 选中指示器
        Circle()
          .width(20).height(20)
          .fill(this.selectedStandard === index ? COLOR_WARNING : Color.Transparent)
          .border({ width: 2, color: this.selectedStandard === index ? COLOR_WARNING : adaptiveDivider(this.isDarkMode) })

        Column({ space: 2 }) {
          Row({ space: SPACE_SM }) {
            Text(item.name)
              .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_MEDIUM)
            Text(item.type)
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_WARNING)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor(this.isDarkMode ? 'rgba(245,158,11,0.15)' : '#FEF3C7')
              .borderRadius(999)
          }
          Text(item.description)
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 功率
        Column({ space: 2 }) {
          Text(item.powerPd)
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_WARNING).fontWeight(FONT_WEIGHT_BOLD)
          Text('PD端可用')
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.End)
      }
    }
    .width('100%')
    .padding(SPACE_MD)
    .backgroundColor(this.selectedStandard === index
      ? (this.isDarkMode ? 'rgba(245,158,11,0.12)' : 'rgba(245,158,11,0.08)')
      : (this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE))
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.selectedStandard === index ? COLOR_WARNING : (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER))
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({
      radius: GLASS_SHADOW_LG,
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .stateStyles({ pressed: { opacity: 0.8 } })
    .clip(true)
    .onClick(() => this.onStandardTap(index))
  }

  // ==================== 参数输入 ====================
  @Builder ParamSection() {
    Column({ space: SPACE_MD }) {
      Text('参数设置')
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Column({ space: SPACE_MD }) {
        // 线缆长度
        Row() {
          Text('线缆长度')
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).layoutWeight(1)
          TextInput({ text: String(this.cableLength) })
            .type(InputType.Number)
            .width(80).textAlign(TextAlign.End)
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode))
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => this.onCableLengthChanged(value))
          Text('米')
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .width('100%')

        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

        // 线缆规格
        Column({ space: SPACE_SM }) {
          Text('线缆规格')
            .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
            .alignSelf(ItemAlign.Start)
          Row({ space: SPACE_SM }) {
            ForEach(this.cableSpecs, (spec: CableSpec) => {
              Text(spec.label)
                .fontSize(FONT_SIZE_XS)
                .fontColor(this.selectedGauge === spec.gauge ? Color.White : adaptiveTextSecondary(this.isDarkMode))
                .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
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
          Text('设备功率')
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).layoutWeight(1)
          TextInput({ text: String(this.devicePower) })
            .type(InputType.Number)
            .width(80).textAlign(TextAlign.End)
            .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode))
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => this.onDevicePowerChanged(value))
          Text('W')
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
        color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
        offsetX: 0,
        offsetY: 4
      })
      .clip(true)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // ==================== 设备快速选择 ====================
  @Builder DevicePresetsSection() {
    Column({ space: SPACE_SM }) {
      Text('常用设备')
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.devicePresets, (preset: DevicePreset) => {
          Text(preset.icon + ' ' + preset.name)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_WARNING)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
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
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .clip(true)
  }

  // ==================== 结果区域 ====================
  @Builder ResultSection() {
    Column({ space: SPACE_LG }) {
      // 供电状态卡
      this.StatusCard()

      // 关键指标
      this.MetricsCard()

      // 详细数据
      this.DetailCard()

      // 建议
      this.SuggestionCard()
    }
    .width('100%')
  }

  // 供电状态
  @Builder StatusCard() {
    Column({ space: SPACE_MD }) {
      // 状态指示
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(48).height(48)
            .fill(this.result.isSufficient
              ? (this.isDarkMode ? 'rgba(16,185,129,0.15)' : '#ECFDF5')
              : (this.isDarkMode ? 'rgba(239,68,68,0.15)' : '#FEF2F2'))
          Text(this.result.isSufficient ? '✓' : '!')
            .fontSize(FONT_SIZE_XL)
            .fontColor(this.result.isSufficient ? COLOR_SUCCESS : COLOR_DANGER)
            .fontWeight(FONT_WEIGHT_BOLD)
        }

        Column({ space: 2 }) {
          Text(this.getStatusText(this.result.isSufficient))
            .fontSize(FONT_SIZE_LG)
            .fontColor(this.result.isSufficient ? COLOR_SUCCESS : COLOR_DANGER)
            .fontWeight(FONT_WEIGHT_BOLD)
          Text(this.getStatusDesc(this.result.isSufficient))
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.result.isSufficient
      ? (this.isDarkMode ? 'rgba(16,185,129,0.3)' : 'rgba(16,185,129,0.3)')
      : (this.isDarkMode ? 'rgba(239,68,68,0.3)' : 'rgba(239,68,68,0.3)'))
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({
      radius: GLASS_SHADOW_LG,
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
  }

  // 关键指标卡
  @Builder MetricsCard() {
    Row() {
      this.MetricCell('送达功率', String(this.result.powerDelivered) + 'W', COLOR_WARNING)
      this.MetricCell('线缆损耗', String(this.result.cableLoss) + 'W', COLOR_DANGER)
      this.MetricCell('供电效率', String(this.result.efficiency) + '%', this.getEfficiencyColor(this.result.efficiency))
    }
    .width('100%')
  }

  @Builder MetricCell(label: string, value: string, color: string) {
    Column({ space: SPACE_XS }) {
      Text(value)
        .fontSize(FONT_SIZE_XL)
        .fontColor(color)
        .fontWeight(FONT_WEIGHT_BOLD)
      Text(label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .layoutWeight(1)
    .padding({ left: 12, right: 10, top: 12, bottom: 12 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(16)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_MD)
    .shadow({
      radius: GLASS_SHADOW_SM,
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .alignItems(HorizontalAlign.Center)
  }

  // 详细数据
  @Builder DetailCard() {
    Column({ space: 0 }) {
      Row() {
        Text('详细数据')
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      this.DetailRow('PoE标准', this.result.standard.name, COLOR_WARNING)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('PSE输出', String(this.result.standard.powerAtPse) + 'W @ ' + String(this.result.standard.voltage) + 'V', adaptiveTextPrimary(this.isDarkMode))
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('PD可用功率', String(this.result.standard.powerAtPd) + 'W', adaptiveTextPrimary(this.isDarkMode))
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('线缆损耗', String(this.result.cableLoss) + 'W (' + String(this.result.cableLossPercent) + '%)', COLOR_DANGER)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('电压降', String(this.result.voltageDrop) + 'V', COLOR_INFO)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('工作电流', String(this.result.currentFlow) + 'A', COLOR_CYAN)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('设备需求', String(this.devicePower) + 'W', adaptiveTextPrimary(this.isDarkMode))
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('剩余预算', String(this.result.remainingBudget) + 'W',
        this.result.remainingBudget > 0 ? COLOR_SUCCESS : COLOR_DANGER)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('供电线对', this.result.standard.pairs, COLOR_PURPLE)
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 0, bottom: 14 })
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

  @Builder DetailRow(label: string, value: string, valueColor: string) {
    Row() {
      Text(label).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
      Blank()
      Text(value).fontSize(FONT_SIZE_SM).fontColor(valueColor).fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .width('100%').padding({ left: 16, right: 14, top: 12, bottom: 12 })
  }

  // 建议卡
  @Builder SuggestionCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text('优化建议')
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%')

      Column({ space: SPACE_SM }) {
        // 线缆长度建议
        this.SuggestionItem(
          '最大推荐长度',
          String(this.result.maxCableLength) + ' 米',
          this.cableLength <= this.result.maxCableLength ? '当前长度在安全范围内' : '⚠️ 超过推荐长度',
          COLOR_CYAN
        )

        // 供电效率
        if (this.result.efficiency < 85) {
          this.SuggestionItem(
            '效率偏低',
            String(this.result.efficiency) + '%',
            '建议使用更粗线规或缩短线缆长度',
            COLOR_WARNING
          )
        }

        // 供电充足时的提示
        if (this.result.remainingBudget > 5) {
          this.SuggestionItem(
            '功率余量充足',
            String(this.result.remainingBudget) + 'W',
            '配置稳定，可靠性高',
            COLOR_SUCCESS
          )
        }

        // 线缆超长警告
        if (this.cableLength > this.result.maxCableLength) {
          this.SuggestionItem(
            '⚠️ 警告',
            '线缆过长',
            '设备可能无法正常工作，请缩短线缆或升级PoE标准',
            COLOR_DANGER
          )
        }
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

  @Builder SuggestionItem(title: string, subtitle: string, detail: string, accentColor: string) {
    Row({ space: SPACE_MD }) {
      Column()
        .width(3).height(36)
        .backgroundColor(accentColor)
        .borderRadius(2)

      Column({ space: 2 }) {
        Text(title).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_MEDIUM)
        Text(subtitle).fontSize(FONT_SIZE_XS).fontColor(accentColor)
        Text(detail).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
  }

  // 功能说明
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text('功能说明')
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('⚡', '功率计算', '基于IEEE 802.3af/at/bt标准精确计算')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', '损耗分析', '实时计算线缆压降和功率损耗')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('💡', '智能建议', '自动推荐最大线缆长度和优化方案')
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
