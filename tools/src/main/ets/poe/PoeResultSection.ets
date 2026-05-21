// PoE 计算结果区域 — Aurora WiFi V2

import {
  COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_CYAN, COLOR_PURPLE, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_SHADOW_SM, GLASS_SHADOW_LG,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { PoeCalcResult } from '../poe/PoeCalculator'

// ==================== 结果区域（聚合容器） ====================
@Component
export struct PoeResultSection {
  @Prop isDarkMode: boolean = false
  @Prop result: PoeCalcResult = {
    standard: { name: '', type: '', powerAtPse: 0, powerAtPd: 0, voltage: 0, current: 0, pairs: '', pins: '', description: '' },
    cableLoss: 0, cableLossPercent: 0, powerDelivered: 0,
    remainingBudget: 0, isSufficient: false, maxCableLength: 0,
    efficiency: 0, voltageDrop: 0, currentFlow: 0, powerAtPse: 0
  }
  @Prop devicePower: number = 0
  @Prop cableLength: number = 0
  getEfficiencyColor: (eff: number) => string = (): string => COLOR_SUCCESS
  getStatusText: (isSufficient: boolean) => string = (): string => ''
  getStatusDesc: (isSufficient: boolean) => string = (): string => ''

  build() {
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

  // ==================== 供电状态 ====================
  @Builder StatusCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(48).height(48)
            .fill(this.result.isSufficient
              ? (this.isDarkMode ? COLOR_SUCCESS : COLOR_SUCCESS)
              : (this.isDarkMode ? COLOR_DANGER : COLOR_DANGER))
          Text(this.result.isSufficient ? '✓' : '!')
            .fontSize(FONT_SIZE_LG)
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
      ? COLOR_SUCCESS
      : COLOR_DANGER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({
      radius: GLASS_SHADOW_LG,
      color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
  }

  // ==================== 关键指标卡 ====================
  @Builder MetricsCard() {
    Row() {
      this.MetricCell($r('app.string.poe_delivered_power_label'), String(this.result.powerDelivered) + 'W', COLOR_WARNING)
      this.MetricCell($r('app.string.cable_loss'), String(this.result.cableLoss) + 'W', COLOR_DANGER)
      this.MetricCell($r('app.string.efficiency'), String(this.result.efficiency) + '%', this.getEfficiencyColor(this.result.efficiency))
    }
    .width('100%')
  }

  @Builder MetricCell(label: string | Resource, value: string | Resource, color: string) {
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
      color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 详细数据 ====================
  @Builder DetailCard() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.detail_data'))
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      this.DetailRow($r('app.string.poe_standard'), this.result.standard.name, COLOR_WARNING)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.pse_output'), String(this.result.standard.powerAtPse) + 'W @ ' + String(this.result.standard.voltage) + 'V', adaptiveTextPrimary(this.isDarkMode))
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.pd_available'), String(this.result.standard.powerAtPd) + 'W', adaptiveTextPrimary(this.isDarkMode))
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.cable_loss'), String(this.result.cableLoss) + 'W (' + String(this.result.cableLossPercent) + '%)', COLOR_DANGER)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.poe_voltage_drop_label'), String(this.result.voltageDrop) + 'V', COLOR_INFO)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.poe_working_current_label'), String(this.result.currentFlow) + 'A', COLOR_CYAN)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.device_required'), String(this.devicePower) + 'W', adaptiveTextPrimary(this.isDarkMode))
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.remaining_budget'), String(this.result.remainingBudget) + 'W',
        this.result.remainingBudget > 0 ? COLOR_SUCCESS : COLOR_DANGER)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.poe_power_pair_label'), this.result.standard.pairs, COLOR_PURPLE)
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
      color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .clip(true)
  }

  @Builder DetailRow(label: string | Resource, value: string | Resource, valueColor: string) {
    Row() {
      Text(label).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
      Blank()
      Text(value).fontSize(FONT_SIZE_SM).fontColor(valueColor).fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .width('100%').padding({ left: 16, right: 14, top: 12, bottom: 12 })
  }

  // ==================== 建议卡 ====================
  @Builder SuggestionCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.suggestion'))
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%')

      Column({ space: SPACE_SM }) {
        // 线缆长度建议
        this.SuggestionItem(
          $r('app.string.max_recommended_length'),
          String(this.result.maxCableLength) + ' ' + $r('app.string.cable_meter'),
          this.cableLength <= this.result.maxCableLength ? $r('app.string.within_length_hint') : '⚠️ ' + $r('app.string.poe_cable_too_long_detail'),
          COLOR_CYAN
        )

        // 供电效率
        if (this.result.efficiency < 85) {
          this.SuggestionItem(
            $r('app.string.low_efficiency_hint'),
            String(this.result.efficiency) + '%',
            $r('app.string.use_thicker_cable_hint'),
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

        // 线缆超长警告
        if (this.cableLength > this.result.maxCableLength) {
          this.SuggestionItem(
            '⚠️ ' + $r('app.string.poe_warning_title'),
            $r('app.string.poe_cable_too_long_warning'),
            $r('app.string.poe_cable_too_long_detail'),
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
      color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .clip(true)
  }

  @Builder SuggestionItem(title: string | Resource, subtitle: string | Resource, detail: string | Resource, accentColor: string) {
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
}
