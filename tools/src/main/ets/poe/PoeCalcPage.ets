// POE 计算器页面组件
// 界面：PoE标准选择 + 线缆参数 + 设备功率 + 计算结果（损耗/预算/效率）

import {
  COLOR_PRIMARY, COLOR_PRIMARY_LIGHT, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_PURPLE, COLOR_PINK, COLOR_CYAN, COLOR_INDIGO,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_SM, BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM,
} from '@wifi-analyzer/design-system'
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
    cableLoss: 0, cableLossPercent: 0,
    powerDelivered: 0, remainingBudget: 0,
    isSufficient: false, maxCableLength: 0, efficiency: 0,
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

  // ==================== 页面入口 ====================
  build() {
    Column() {
      // 顶部返回按钮栏
      Row() {
        Row() {
          Text('←')
            .fontSize(20)
            .fontColor(COLOR_PRIMARY)
          Text($r('app.string.back'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(COLOR_PRIMARY)
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .padding({ left: 4, right: 12, top: 6, bottom: 6 })
        .borderRadius(20)
        .backgroundColor(COLOR_SURFACE)
        .onClick(() => RouterManager.goBack())

        Blank()
      }
      .width('100%')
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: SAFE_AREA_BOTTOM })
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
        }
        .padding(SPACE_LG)
        .width('100%')
      }
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Auto)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
    .onBackPress(() => {
      RouterManager.goBack()
      return true
    })
  }

  // ==================== PoE 标准选择 ====================
  @Builder StandardSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.poe_standard')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

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
          .fill(this.selectedStandard === index ? COLOR_DANGER : Color.Transparent)
          .border({ width: 2, color: this.selectedStandard === index ? COLOR_DANGER : COLOR_BORDER })

        Column({ space: 2 }) {
          Row({ space: SPACE_SM }) {
            Text(item.name)
              .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
            Text(item.type)
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_DANGER)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor('#FEE2E2').borderRadius(RADIUS_SM)
          }
          Text(item.description)
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 功率
        Column({ space: 2 }) {
          Text(item.powerPd).fontSize(FONT_SIZE_MD).fontColor(COLOR_DANGER).fontWeight(FONT_WEIGHT_BOLD)
          Text($r('app.string.poe_available')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.End)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_MD)
    .border({ width: 1, color: this.selectedStandard === index ? COLOR_DANGER : COLOR_BORDER })
    .stateStyles({ pressed: { opacity: 0.8 } })
    .onClick(() => this.onStandardTap(index))
  }

  // ==================== 参数输入 ====================
  @Builder ParamSection() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.param_settings')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Column({ space: SPACE_MD }) {
        // 线缆长度
        Row() {
          Text($r('app.string.cable_length')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).layoutWeight(1)
          TextInput({ text: String(this.cableLength) })
            .type(InputType.Number)
            .width(80).textAlign(TextAlign.End)
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY)
            .onChange((value: string) => this.onCableLengthChanged(value))
          Text($r('app.string.cable_meter')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_SECONDARY)
        }
        .width('100%')

        Divider().color(COLOR_DIVIDER)

        // 线缆规格
        Column({ space: SPACE_SM }) {
          Text($r('app.string.cable_spec')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_TERTIARY)
          Row({ space: SPACE_SM }) {
            ForEach(this.cableSpecs, (spec: CableSpec) => {
              Text(spec.label)
                .fontSize(FONT_SIZE_XS)
                .fontColor(this.selectedGauge === spec.gauge ? Color.White : COLOR_TEXT_SECONDARY)
                .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
                .backgroundColor(this.selectedGauge === spec.gauge ? COLOR_DANGER : COLOR_DIVIDER)
                .borderRadius(RADIUS_3XL)
                .stateStyles({ pressed: { opacity: 0.8 } })
                .onClick(() => this.onGaugeTap(spec.gauge))
            }, (spec: CableSpec): string => String(spec.gauge))
          }
        }
        .width('100%')

        Divider().color(COLOR_DIVIDER)

        // 设备功率需求
        Row() {
          Text($r('app.string.device_power')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).layoutWeight(1)
          TextInput({ text: String(this.devicePower) })
            .type(InputType.Number)
            .width(80).textAlign(TextAlign.End)
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY)
            .onChange((value: string) => this.onDevicePowerChanged(value))
          Text($r('app.string.power_unit_w')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_SECONDARY)
        }
        .width('100%')
      }
      .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
      .border({ width: 1, color: COLOR_BORDER })
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // ==================== 设备快速选择 ====================
  @Builder DevicePresetsSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_devices')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.devicePresets, (preset: DevicePreset) => {
          Text(preset.icon + ' ' + preset.name)
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_DANGER)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor('#FEE2E2').borderRadius(RADIUS_3XL)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onDeviceTap(preset))
        }, (preset: DevicePreset): string => preset.name)
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // ==================== 结果区域 ====================
  @Builder ResultSection() {
    Column({ space: SPACE_LG }) {
      // 供电状态卡
      this.StatusCard()

      // 详细数据
      this.DetailCard()

      // 建议
      this.SuggestionCard()
    }
    .width('100%')
  }

  // 获取供电状态文案
  getStatusText(isSufficient: boolean): Resource {
    return isSufficient ? $r('app.string.power_sufficient') : $r('app.string.power_insufficient')
  }

  // 获取供电状态描述
  getStatusDesc(isSufficient: boolean): Resource {
    return isSufficient ? $r('app.string.config_can_meet') : $r('app.string.upgrade_poe_hint')
  }

  // 供电状态
  @Builder StatusCard() {
    Column({ space: SPACE_MD }) {
      // 状态指示
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(48).height(48)
            .fill(this.result.isSufficient ? '#ECFDF5' : '#FEF2F2')
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
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 关键指标
      Row() {
        this.MetricCell($r('app.string.delivered_power'), String(this.result.powerDelivered) + 'W', COLOR_DANGER)
        this.MetricCell($r('app.string.cable_loss'), String(this.result.cableLoss) + 'W', COLOR_WARNING)
        this.MetricCell($r('app.string.efficiency'), String(this.result.efficiency) + '%', this.getEfficiencyColor(this.result.efficiency))
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  @Builder MetricCell(label: Resource | string, value: string, color: string) {
    Column({ space: SPACE_XS }) {
      Text(value).fontSize(FONT_SIZE_XL).fontColor(color).fontWeight(FONT_WEIGHT_BOLD)
      Text(label).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
    }
    .layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  // 详细数据
  @Builder DetailCard() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.detail_data')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%').padding({ bottom: SPACE_SM })

      this.DetailRow($r('app.string.poe_standard'), this.result.standard.name, COLOR_DANGER)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.pse_output'), String(this.result.standard.powerAtPse) + 'W @ ' + String(this.result.standard.voltage) + 'V', COLOR_TEXT_PRIMARY)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.pd_available'), String(this.result.standard.powerAtPd) + 'W', COLOR_TEXT_PRIMARY)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.cable_loss'), String(this.result.cableLoss) + 'W (' + String(this.result.cableLossPercent) + '%)', COLOR_WARNING)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.actual_delivered'), String(this.result.powerDelivered) + 'W', COLOR_SUCCESS)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.device_required'), String(this.devicePower) + 'W', COLOR_TEXT_PRIMARY)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.remaining_budget'), String(this.result.remainingBudget) + 'W',
        this.result.remainingBudget > 0 ? COLOR_SUCCESS : COLOR_DANGER)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.power_pins'), this.result.standard.pins, COLOR_INFO)
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  @Builder DetailRow(label: Resource | string, value: string, valueColor: string) {
    Row() {
      Text(label).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY)
      Blank()
      Text(value).fontSize(FONT_SIZE_SM).fontColor(valueColor).fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .width('100%').padding({ top: SPACE_SM, bottom: SPACE_SM })
  }

  // 建议卡
  @Builder SuggestionCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.suggestion'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%')

      Column({ space: SPACE_SM }) {
        // 线缆长度建议
        this.SuggestionItem(
          $r('app.string.max_recommended_length'),
          String(this.result.maxCableLength) + ' ' + 'm',
          $r('app.string.within_length_hint'),
          COLOR_CYAN
        )

        // 供电效率
        if (this.result.efficiency < 85) {
          this.SuggestionItem(
            $r('app.string.low_efficiency_hint'),
            $r('app.string.use_thicker_cable_hint'),
            String(this.result.efficiency) + '%',
            COLOR_WARNING
          )
        }

        // 供电充足时的提示
        if (this.result.remainingBudget > 5) {
          this.SuggestionItem(
            $r('app.string.sufficient_margin'),
            String(this.result.remainingBudget) + 'W',
            $r('app.string.config_stable'),
            COLOR_SUCCESS
          )
        }
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  @Builder SuggestionItem(title: ResourceStr, subtitle: ResourceStr, detail: ResourceStr, accentColor: string) {
    Row({ space: SPACE_MD }) {
      Column()
        .width(3).height(36)
        .backgroundColor(accentColor)
        .borderRadius(2)

      Column({ space: 2 }) {
        Text(title).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
        Text(subtitle).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_SECONDARY)
        Text(detail).fontSize(FONT_SIZE_XS).fontColor(accentColor)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
  }

  // Helper: 创建带数值的 detail 文本
  @Builder detailWithValue(prefixRes: Resource, value: string, suffixRes?: Resource) {
    Text() {
      Span(prefixRes)
      Span(' ' + value)
      if (suffixRes) {
        Span(' ')
        Span(suffixRes)
      }
    }.fontSize(FONT_SIZE_XS).fontColor(COLOR_WARNING)
  }
}
