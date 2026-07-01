// POE 计算器 — 从 tools 模块迁移
// 引擎改用 @wifi-analyzer/network-tools

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD, SPACE_LG,
  SAFE_AREA_TOP,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveBtnBg
} from '@wifi-analyzer/design-system'
import { PoeCalculator, CableSpec, DevicePreset, PoeResult } from '@wifi-analyzer/network-tools'
import { RouterManager } from '@wifi-analyzer/core'

interface StandardDisplayItem {
  name: string; type: string; powerPse: string; powerPd: string; description: string
}

const PANEL_RADIUS = 14

@Builder
export function PoePageBuilder() {
  NavDestination() { PoeCalcPage() }.title('PoE 计算器').hideTitleBar(true)
}

@Component
export struct PoeCalcPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State selectedStandard: number = 1
  @State standardItems: StandardDisplayItem[] = []
  @State cableLength: number = 100
  @State selectedGauge: number = 24
  @State devicePower: number = 12.95
  @State devicePowerText: string = '12.95'
  @State cableSpecs: CableSpec[] = []
  @State devicePresets: DevicePreset[] = []
  @State result: PoeResult = PoeCalculator.calculate({ cableLength: 100, cableGauge: 24, standardIndex: 1, devicePower: 12.95 })
  @State showDetail: boolean = true

  aboutToAppear(): void {
    this.loadStandards()
    this.cableSpecs = PoeCalculator.CABLE_SPECS
    this.devicePresets = PoeCalculator.DEVICE_PRESETS
    this.devicePower = PoeCalculator.STANDARDS[this.selectedStandard].powerAtPd
    this.devicePowerText = String(this.devicePower)
    this.recalc()
  }

  private loadStandards(): void {
    const items: StandardDisplayItem[] = []
    for (let i = 0; i < PoeCalculator.STANDARDS.length; i++) {
      const s = PoeCalculator.STANDARDS[i]
      items.push({ name: s.name, type: s.type, powerPse: String(s.powerAtPse) + 'W', powerPd: String(s.powerAtPd) + 'W', description: s.description })
    }
    this.standardItems = items
  }

  recalc() { this.result = PoeCalculator.calculate({ cableLength: this.cableLength, cableGauge: this.selectedGauge, standardIndex: this.selectedStandard, devicePower: this.devicePower }) }
  onStandardTap(index: number): void { this.selectedStandard = index; this.devicePower = PoeCalculator.STANDARDS[index].powerAtPd; this.devicePowerText = String(this.devicePower); this.recalc() }
  onGaugeTap(g: number): void { this.selectedGauge = g; this.recalc() }
  onDeviceTap(p: DevicePreset): void { this.devicePower = p.power; this.devicePowerText = String(p.power); this.recalc() }

  private get cardBg(): string { return this.isDarkMode ? COLOR_GLASS_DARK_CARD : '#FFFFFF' }
  private get borderClr(): string { return this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER }
  private get heroColor(): string { return this.result.isSufficient ? COLOR_SUCCESS : COLOR_DANGER }
  private get efficiencyColor(): string { if (this.result.efficiency >= 90) return COLOR_SUCCESS; if (this.result.efficiency >= 80) return COLOR_WARNING; return COLOR_DANGER }

  build() {
    Stack() {
      Column().width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Bottom, colors: adaptiveBackgroundList(this.isDarkMode) })
      Circle().width(280).height(280).fill(adaptiveGlowLarge(this.isDarkMode)).position({ x: -60, y: -60 })
      Circle().width(180).height(180).fill(adaptiveGlowMedium(this.isDarkMode)).position({ x: '68%', y: '45%' })

      Column() {
        Row() {
          Row() { Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDarkMode)) }.width(36).height(36).justifyContent(FlexAlign.Center).borderRadius(8).backgroundColor(adaptiveBtnBg(this.isDarkMode)).onClick(() => { RouterManager.goBack() })
          Blank(); Text('PoE 计算器').fontSize(FONT_SIZE_LG).fontWeight(FONT_WEIGHT_BOLD).fontColor(adaptiveTextPrimary(this.isDarkMode)); Blank(); Row().width(44).height(44)
        }.width('100%').padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP, bottom: SPACE_SM })

        Scroll() {
          Column({ space: SPACE_MD }) {
            this.StandardChipBar()
            this.HeroPanel()
            this.InputPanel()

            Column({ space: 0 }) {
              this.detailRow('PoE 标准', PoeCalculator.STANDARDS[this.selectedStandard].name, COLOR_WARNING)
              Column().width('100%').height(0.5).backgroundColor(this.borderClr)
              this.detailRow('PSE 输出', String(this.result.standard.powerAtPse) + 'W @ ' + String(this.result.standard.voltage) + 'V', COLOR_PRIMARY)
              Column().width('100%').height(0.5).backgroundColor(this.borderClr)
              this.detailRow('PD 可用功率', String(this.result.standard.powerAtPd) + 'W', COLOR_SUCCESS)
              Column().width('100%').height(0.5).backgroundColor(this.borderClr)
              this.detailRow('电压降', String(this.result.voltageDrop) + 'V', COLOR_DANGER)
              Column().width('100%').height(0.5).backgroundColor(this.borderClr)
              this.detailRow('工作电流', String(this.result.currentFlow) + 'A', COLOR_WARNING)
              Column().width('100%').height(0.5).backgroundColor(this.borderClr)
              this.detailRow('剩余预算', String(this.result.remainingBudget) + 'W', this.result.remainingBudget > 0 ? COLOR_SUCCESS : COLOR_DANGER)
              Column().width('100%').height(0.5).backgroundColor(this.borderClr)
              this.detailRow('供电线对', this.result.standard.pairs, COLOR_WARNING)
              Column().width('100%').height(0.5).backgroundColor(this.borderClr)
              this.detailRow('最大推荐长度', String(this.result.maxCableLength) + ' m', this.cableLength <= this.result.maxCableLength ? COLOR_SUCCESS : COLOR_DANGER)
              if (this.cableLength > this.result.maxCableLength) {
                Column().width('100%').height(0.5).backgroundColor(this.borderClr)
                Row({ space: SPACE_SM }) {
                  Text('⚠').fontSize(FONT_SIZE_SM)
                  Text('设备可能无法正常工作，请缩短线缆或升级PoE标准').fontSize(FONT_SIZE_XS).fontColor(COLOR_DANGER).layoutWeight(1)
                }.width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
              }
            }.width('100%').backgroundColor(this.cardBg).borderRadius(PANEL_RADIUS).border({ width: 1, color: this.borderClr }).padding({ top: 4, bottom: 4 })
              .visibility(this.showDetail ? Visibility.Visible : Visibility.None)
            Row().width('100%').height(64)
          }.padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_SM }).width('100%')
        }.scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring).layoutWeight(1)
      }.width('100%').height('100%')
    }.width('100%').height('100%')
  }

  @Builder detailRow(label: string, value: string, color: string) {
    Row() {
      Text(label).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
      Blank()
      Text(value).fontSize(FONT_SIZE_XS).fontColor(color).fontWeight(FONT_WEIGHT_BOLD)
    }.width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
  }

  @Builder StandardChipBar() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.standardItems, (item: StandardDisplayItem, index: number) => {
        Column({ space: 2 }) {
          Text(item.name).fontSize(FONT_SIZE_XS).fontWeight(FONT_WEIGHT_MEDIUM).fontColor(index === this.selectedStandard ? '#FFFFFF' : adaptiveTextSecondary(this.isDarkMode))
          Text(item.powerPd).fontSize(FONT_SIZE_XS).fontColor(index === this.selectedStandard ? '#FFFFFF' : adaptiveTextSecondary(this.isDarkMode))
        }.padding({ left: 12, right: 12, top: 6, bottom: 6 }).borderRadius(12).margin({ right: SPACE_SM, bottom: SPACE_SM })
          .backgroundColor(index === this.selectedStandard ? COLOR_WARNING : this.cardBg)
          .border({ width: 1, color: index === this.selectedStandard ? COLOR_WARNING : this.borderClr })
          .onClick(() => this.onStandardTap(index))
      }, (_item: StandardDisplayItem, index: number): string => String(index))
    }.width('100%')
  }

  @Builder HeroPanel() {
    Column({ space: SPACE_SM }) {
      Row({ space: SPACE_SM }) {
        Text(this.result.isSufficient ? 'POWER OK' : 'POWER LOW').fontSize(FONT_SIZE_XS).fontWeight(FONT_WEIGHT_BOLD).fontColor('#ffee0606')
          .padding({ left: 10, right: 10, top: 3, bottom: 3 }).borderRadius(6).backgroundColor(this.heroColor)
        Text(this.result.standard.name).fontSize(FONT_SIZE_SM).fontColor('#FFFFFF').backgroundColor('#4A90D9')
          .padding({ left: 10, right: 10, top: 3, bottom: 3 }).borderRadius(6)
      }
      Row() {
        Column({ space: 0 }) {
          Text(String(Math.round(this.result.powerDelivered * 10) / 10)).fontSize(48).fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode)).fontFamily('sans-serif-medium')
          Row({ space: 4 }) {
            Text('送达功率').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode))
            Text('W').fontSize(FONT_SIZE_XS).fontColor(this.heroColor).fontWeight(FONT_WEIGHT_BOLD)
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        this.EfficiencyRing(this.result.efficiency)
      }.width('100%')
      Row().width('100%').height(1).backgroundColor(this.borderClr).margin({ top: SPACE_SM, bottom: SPACE_SM })
      Row() {
        this.MiniStat('线缆损耗', String(Math.round(this.result.cableLoss * 10) / 10) + 'W', COLOR_DANGER)
        this.MiniStat('供电效率', String(this.result.efficiency) + '%', this.efficiencyColor)
      }.width('100%')
    }.width('100%').padding(16).backgroundColor(this.cardBg).borderRadius(PANEL_RADIUS).border({ width: 1, color: this.borderClr })
  }

  @Builder EfficiencyRing(pct: number) {
    Stack({ alignContent: Alignment.Center }) {
      Circle().width(64).height(64).fill(Color.Transparent).stroke(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)').strokeWidth(5)
      Progress({ value: pct, total: 100, type: ProgressType.Ring }).width(64).height(64).color(this.efficiencyColor).backgroundColor(Color.Transparent).style({ strokeWidth: 5, enableSmoothEffect: false })
      Text(String(pct)).fontSize(FONT_SIZE_MD).fontWeight(FONT_WEIGHT_BOLD).fontColor(this.efficiencyColor)
    }.width(64).height(64)
  }

  @Builder MiniStat(label: string, value: string, color: string) {
    Column({ space: 2 }) { Text(label).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode)); Text(value).fontSize(FONT_SIZE_XL).fontWeight(FONT_WEIGHT_BOLD).fontColor(color) }.layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder InputPanel() {
    Column({ space: SPACE_SM }) {
      Text('参数设置').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextSecondary(this.isDarkMode)).fontWeight(FONT_WEIGHT_MEDIUM).letterSpacing(1).alignSelf(ItemAlign.Start)
      Column({ space: 0 }) {
        Row({ space: SPACE_MD }) {
          Text('线缆长度').fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode)).width(80)
          Slider({ value: this.cableLength, min: 1, max: 300, step: 1 }).blockColor(COLOR_WARNING).trackColor(this.borderClr).selectedColor(COLOR_WARNING).layoutWeight(1)
            .onChange((value: number) => { this.cableLength = Math.round(value); this.recalc() })
          Text(String(this.cableLength) + 'm').fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD).fontColor(adaptiveTextPrimary(this.isDarkMode)).width(48).textAlign(TextAlign.End)
        }.width('100%').padding({ top: 12, bottom: 8 })

        Row({ space: SPACE_MD }) {
          Text('设备功率').fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode)).width(80)
          TextInput({ text: this.devicePowerText }).type(InputType.Normal).width(72).textAlign(TextAlign.Center).fontSize(FONT_SIZE_SM)
            .fontColor(adaptiveTextPrimary(this.isDarkMode)).backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)').borderRadius(8).padding({ left: 8, right: 8, top: 6, bottom: 6 })
            .onChange((v: string) => { const n = parseFloat(v.replace(/[^0-9.]/g, '')); if (!isNaN(n) && n >= 0 && n <= 100) { this.devicePower = n; this.devicePowerText = v; this.recalc() } })
          Text('W').fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode)); Blank()
        }.width('100%').padding({ top: 8, bottom: 8 })

        Row({ space: SPACE_SM }) {
          Text('线缆规格').fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode)).width(64)
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.cableSpecs, (spec: CableSpec) => {
              Text(spec.label).fontSize(FONT_SIZE_XS).fontWeight(this.selectedGauge === spec.gauge ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
                .fontColor(this.selectedGauge === spec.gauge ? '#FFFFFF' : adaptiveTextSecondary(this.isDarkMode))
                .padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(8).margin({ right: SPACE_SM, bottom: SPACE_SM })
                .backgroundColor(this.selectedGauge === spec.gauge ? COLOR_WARNING : (this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)'))
                .onClick(() => this.onGaugeTap(spec.gauge))
            }, (spec: CableSpec): string => String(spec.gauge))
          }.layoutWeight(1)
        }.width('100%').padding({ top: 8, bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.devicePresets, (preset: DevicePreset) => {
            Text(preset.icon + ' ' + preset.name).fontSize(FONT_SIZE_XS).fontColor(COLOR_WARNING)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 }).borderRadius(8).margin({ right: SPACE_SM, bottom: SPACE_SM })
              .backgroundColor(this.isDarkMode ? 'rgba(245,158,11,0.1)' : '#FFF8E1')
              .border({ width: 1, color: this.isDarkMode ? 'rgba(245,158,11,0.2)' : '#FFE082' })
              .onClick(() => this.onDeviceTap(preset))
          }, (preset: DevicePreset): string => preset.name)
        }.width('100%').padding({ top: 8, bottom: 4 })

        Row() {
          Row({ space: 4 }) {
            Text(this.showDetail ? '收起详情' : '展开详情').fontSize(FONT_SIZE_XS).fontColor(COLOR_WARNING)
            Text(this.showDetail ? '▴' : '▾').fontSize(10).fontColor(COLOR_WARNING)
          }.padding({ top: 6, bottom: 2 }).onClick(() => { this.showDetail = !this.showDetail })
        }.width('100%').justifyContent(FlexAlign.Center)
      }
    }.width('100%').padding(14).backgroundColor(this.cardBg).borderRadius(PANEL_RADIUS).border({ width: 1, color: this.borderClr })
  }
}
