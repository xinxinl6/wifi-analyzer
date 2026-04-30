// 子网换算页面组件
// 界面：输入框 + 快捷子网标签 + 详细结果卡片 + 二进制可视化

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
import { BackButtonCapsule } from '@wifi-analyzer/design-system'
import {
  SubnetCalculator, SubnetResult, IpAddressInfo, SubnetPreset,
} from '../subnet/SubnetCalculator'
import { RouterManager } from '@wifi-analyzer/core'

// ==================== 接口定义 ====================

interface ResultRowItem {
  label: string
  value: string
  color: string
}

// ==================== 组件 ====================

@Component
export struct SubnetCalcPage {
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
    // 初始计算
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
    // 用当前IP加上选择的掩码
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
    // 实时计算
    if (value.trim().length > 0) {
      this.doCalculate()
    } else {
      this.hasResult = false
    }
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
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .borderRadius(20)
        .backgroundColor(COLOR_SURFACE)
        .borderWidth(1)
        .borderColor(COLOR_BORDER)
        .onClick(() => RouterManager.goBack())
        .onClick(() => RouterManager.goBack())

        Blank()
      }
      .width('100%')
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: SAFE_AREA_BOTTOM })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: SPACE_LG }) {
          this.InputSection()
          this.PresetSection()

          if (this.hasResult) {
            this.ResultSection()
          } else if (!this.inputValid) {
            this.ErrorTip()
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
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
  }

  // ==================== 输入区域 ====================
  @Builder InputSection() {
    Column({ space: SPACE_SM }) {
      Row({ space: SPACE_SM }) {
        Image($r('app.media.ic_subnet')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_WARNING)

        TextInput({ placeholder: $r('app.string.input_ip_subnet_hint'), text: this.inputText })
          .layoutWeight(1)
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).placeholderColor(COLOR_TEXT_TERTIARY)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => this.onInputChanged(value))

        Button($r('app.string.calculate_action'))
          .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
          .backgroundColor(COLOR_WARNING)
          .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_SM)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.doCalculate())
      }
      .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
      .border({ width: 1, color: this.inputValid ? COLOR_BORDER : COLOR_DANGER })

      // 输入提示/错误
      if (!this.inputValid) {
        Text(this.inputError)
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_DANGER)
          .alignSelf(ItemAlign.Start)
          .padding({ left: SPACE_MD })
      } else {
        Text($r('app.string.cidr_format_hint'))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          .alignSelf(ItemAlign.Start)
          .padding({ left: SPACE_MD })
      }
    }
    .width('100%')
  }

  // ==================== 子网预设 ====================
  @Builder PresetSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_subnets')).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.presets, (preset: SubnetPreset) => {
          Text(preset.label)
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_WARNING)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor('#FEF3C7').borderRadius(RADIUS_3XL)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onPresetTap(preset))
        }, (preset: SubnetPreset): string => preset.label)
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // ==================== 结果区域 ====================
  @Builder ResultSection() {
    Column({ space: SPACE_LG }) {
      // 基础信息卡
      this.BasicInfoCard()

      // 地址范围卡
      this.AddressRangeCard()

      // 详细信息表
      this.DetailTable()

      // 二进制可视化
      this.BinaryVis()
    }
    .width('100%')
  }

  // 基础信息
  @Builder BasicInfoCard() {
    Row() {
      this.InfoCell($r('app.string.network_addr'), this.result.networkAddress, COLOR_PRIMARY)
      this.InfoCell($r('app.string.broadcast_addr'), this.result.broadcastAddress, COLOR_INFO)
    }
    .width('100%')
  }

  @Builder InfoCell(label: Resource | string, value: string, accentColor: string) {
    Column({ space: SPACE_XS }) {
      Text(label).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      Text(value).fontSize(FONT_SIZE_MD).fontColor(accentColor).fontWeight(FONT_WEIGHT_BOLD)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding(SPACE_MD)
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_LG)
    .border({ width: 1, color: COLOR_BORDER })
    .alignItems(HorizontalAlign.Center)
  }

  // 地址范围
  @Builder AddressRangeCard() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.host_range'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        // 起始地址
        Column({ space: SPACE_XS }) {
          Text($r('app.string.start_ip')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(this.result.firstHost)
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_BOLD)
        }
        .layoutWeight(1)
        .padding(SPACE_MD)
        .backgroundColor(COLOR_SURFACE)
        .borderRadius(RADIUS_MD)
        .alignItems(HorizontalAlign.Center)

        // 连接符
        Text('~')
          .fontSize(FONT_SIZE_XL).fontColor(COLOR_TEXT_TERTIARY)

        // 结束地址
        Column({ space: SPACE_XS }) {
          Text($r('app.string.end_ip')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(this.result.lastHost)
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_BOLD)
        }
        .layoutWeight(1)
        .padding(SPACE_MD)
        .backgroundColor(COLOR_SURFACE)
        .borderRadius(RADIUS_MD)
        .alignItems(HorizontalAlign.Center)
      }

      // 可用主机数
      Row({ space: SPACE_SM }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#FEF3C7')
          Text('#').fontSize(FONT_SIZE_MD).fontColor(COLOR_WARNING).fontWeight(FONT_WEIGHT_BOLD)
        }
        Column({ space: 2 }) {
          Text($r('app.string.usable_hosts'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(this.formatHostCount(this.result.totalHosts))
            .fontSize(FONT_SIZE_LG).fontColor(COLOR_WARNING).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(SPACE_MD)
      .backgroundColor(COLOR_SURFACE)
      .borderRadius(RADIUS_LG)
      .border({ width: 1, color: COLOR_BORDER })
    }
    .width('100%')
  }

  // 格式化主机数
  formatHostCount(count: number): string {
    if (count >= 1000000) {
      return String(Math.round(count / 1000000 * 10) / 10) + 'M'
    }
    if (count >= 1000) {
      return String(Math.round(count / 1000 * 10) / 10) + 'K'
    }
    return String(count)
  }

  // 详细信息表
  @Builder DetailTable() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.detail_info')).fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%').padding({ bottom: SPACE_SM })

      this.DetailRow($r('app.string.subnet_mask'), this.result.subnetMask, COLOR_PRIMARY)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.wildcard_mask'), this.result.wildcardMask, COLOR_INFO)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow('CIDR', '/' + String(this.result.prefixLength), COLOR_WARNING)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.ip_class'), this.result.ipClass, COLOR_PURPLE)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.ip_type'), this.result.ipType, this.result.isPrivate ? COLOR_CYAN : COLOR_PRIMARY)
      Divider().color(COLOR_DIVIDER)
      this.DetailRow($r('app.string.is_private'), this.result.isPrivate ? $r('app.string.yes') : $r('app.string.no'),
        this.result.isPrivate ? COLOR_SUCCESS : COLOR_TEXT_SECONDARY)
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  @Builder DetailRow(label: Resource | string, value: Resource | string, valueColor: string) {
    Row() {
      Text(label).fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY)
      Blank()
      Text(value).fontSize(FONT_SIZE_SM).fontColor(valueColor).fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .width('100%').padding({ top: SPACE_SM, bottom: SPACE_SM })
  }

  // 二进制可视化
  @Builder BinaryVis() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.binary_subnet'))
        .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_XS }) {
        ForEach(this.getBinaryOctets(), (octet: BinaryOctet, index: number) => {
          this.BinaryOctetBlock(octet, index)
        }, (octet: BinaryOctet, index: number): string => String(index))
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // 获取二进制八位组
  getBinaryOctets(): BinaryOctet[] {
    const binary: string = this.result.binaryMask
    const parts: string[] = binary.split('.')
    const result: BinaryOctet[] = []
    for (let i = 0; i < parts.length; i++) {
      const item: BinaryOctet = { binary: parts[i], decimal: this.result.subnetMask.split('.')[i] }
      result.push(item)
    }
    return result
  }

  @Builder BinaryOctetBlock(octet: BinaryOctet, index: number) {
    Column({ space: SPACE_XS }) {
      // 8 个 bit 方块
      Row({ space: 1 }) {
        ForEach(this.getBits(octet.binary), (bit: BitItem, bitIndex: number) => {
          Text(bit.char)
            .fontSize(FONT_SIZE_XS).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
            .width(20).height(20).textAlign(TextAlign.Center)
            .backgroundColor(bit.isOne ? COLOR_WARNING : COLOR_DIVIDER)
            .borderRadius(2)
        }, (bit: BitItem, bitIndex: number): string => String(index) + '_' + String(bitIndex))
      }

      // 十进制值
      Text(octet.decimal)
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  // 拆分二进制字符串为 bit 数组
  getBits(binary: string): BitItem[] {
    const result: BitItem[] = []
    for (let i = 0; i < binary.length; i++) {
      const item: BitItem = { char: binary[i], isOne: binary[i] === '1' }
      result.push(item)
    }
    return result
  }

  // 错误提示
  @Builder ErrorTip() {
    Row({ space: SPACE_SM }) {
      Text('!')
        .fontSize(FONT_SIZE_SM).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
        .width(20).height(20).textAlign(TextAlign.Center)
        .backgroundColor(COLOR_DANGER).borderRadius(10)
      Text(this.inputError)
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_DANGER)
    }
    .width('100%')
    .padding(SPACE_MD)
    .backgroundColor('#FEF2F2')
    .borderRadius(RADIUS_MD)
  }

  // 功能说明
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#FEF3C7')
          Image($r('app.media.ic_subnet')).width(18).height(18).fillColor(COLOR_WARNING)
        }
        Column({ space: 2 }) {
          Text($r('app.string.subnet_calc_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.subnet_calc_intro_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_2XL).border({ width: 1, color: COLOR_BORDER })
  }
}

// 辅助接口
interface BinaryOctet {
  binary: string
  decimal: string
}

interface BitItem {
  char: string
  isOne: boolean
}
