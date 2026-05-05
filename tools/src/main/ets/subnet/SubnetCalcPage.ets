// 子网换算页面组件 — Aurora WiFi V2 天蓝极光设计
// 界面：输入框 + 快捷子网标签 + 详细结果卡片 + 二进制可视化

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
  @Consume isDarkMode: boolean = false

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

  // 拆分二进制字符串为 bit 数组
  getBits(binary: string): BitItem[] {
    const result: BitItem[] = []
    for (let i = 0; i < binary.length; i++) {
      const item: BitItem = { char: binary[i], isOne: binary[i] === '1' }
      result.push(item)
    }
    return result
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
            this.InputSection()
            this.PresetSection()

            if (this.hasResult) {
              this.ResultSection()
            } else if (!this.inputValid) {
              this.ErrorTip()
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

  // ==================== 输入区域 ====================
  @Builder InputSection() {
    Column({ space: SPACE_SM }) {
      Row({ space: SPACE_SM }) {
        Image($r('app.media.ic_subnet')).width(FONT_SIZE_LG).height(FONT_SIZE_LG).fillColor(COLOR_WARNING)

        TextInput({ placeholder: $r('app.string.input_ip_subnet_hint'), text: this.inputText })
          .layoutWeight(1)
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode))
          .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => this.onInputChanged(value))

        Button($r('app.string.calculate_action'))
          .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
          .backgroundColor(COLOR_WARNING)
          .borderRadius(999)
          .height(36)
          .padding({ left: 18, right: 18 })
          .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.doCalculate())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.inputValid
      ? (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      : COLOR_DANGER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })

    // 输入提示/错误
    if (!this.inputValid) {
      Row({ space: SPACE_SM }) {
        Text('!')
          .fontSize(FONT_SIZE_XS).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
          .width(18).height(18).textAlign(TextAlign.Center)
          .backgroundColor(COLOR_DANGER).borderRadius(9)
        Text(this.inputError)
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_DANGER)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 18, right: 14, top: 8, bottom: 8 })
    } else {
      Text($r('app.string.cidr_format_hint'))
        .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)
        .padding({ left: 18 })
    }
  }

  // ==================== 子网预设 ====================
  @Builder PresetSection() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_subnets'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.presets, (preset: SubnetPreset) => {
          Text(preset.label)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_WARNING)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.isDarkMode ? 'rgba(245,158,11,0.15)' : '#FEF3C7')
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onPresetTap(preset))
        }, (preset: SubnetPreset): string => preset.label)
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
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
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
      Text(label).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
      Text(value).fontSize(FONT_SIZE_MD).fontColor(accentColor).fontWeight(FONT_WEIGHT_BOLD)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .alignItems(HorizontalAlign.Center)
  }

  // 地址范围
  @Builder AddressRangeCard() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.host_range'))
        .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        // 起始地址
        Column({ space: SPACE_XS }) {
          Text($r('app.string.start_ip')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text(this.result.firstHost)
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_BOLD)
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 14, top: 14, bottom: 14 })
        .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
        .borderRadius(18)
        .borderWidth(1.5)
        .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
        .backdropBlur(GLASS_BLUR_LG)
        .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
        .alignItems(HorizontalAlign.Center)

        // 连接符
        Text('~')
          .fontSize(FONT_SIZE_XL).fontColor(adaptiveTextTertiary(this.isDarkMode))

        // 结束地址
        Column({ space: SPACE_XS }) {
          Text($r('app.string.end_ip')).fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text(this.result.lastHost)
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_SUCCESS).fontWeight(FONT_WEIGHT_BOLD)
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 14, top: 14, bottom: 14 })
        .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
        .borderRadius(18)
        .borderWidth(1.5)
        .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
        .backdropBlur(GLASS_BLUR_LG)
        .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
        .alignItems(HorizontalAlign.Center)
      }

      // 可用主机数
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(38).height(38)
            .fill(this.isDarkMode ? 'rgba(245,158,11,0.15)' : '#FEF3C7')
          Text('#').fontSize(FONT_SIZE_MD).fontColor(COLOR_WARNING).fontWeight(FONT_WEIGHT_BOLD)
        }
        Column({ space: 2 }) {
          Text($r('app.string.usable_hosts'))
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text(this.formatHostCount(this.result.totalHosts))
            .fontSize(FONT_SIZE_LG).fontColor(COLOR_WARNING).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 14 })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    }
    .width('100%')
  }

  // 详细信息表
  @Builder DetailTable() {
    Column({ space: 0 }) {
      Row() {
        Text($r('app.string.detail_info'))
          .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
      }
      .width('100%').padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      this.DetailRow($r('app.string.subnet_mask'), this.result.subnetMask, COLOR_PRIMARY)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.wildcard_mask'), this.result.wildcardMask, COLOR_INFO)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow('CIDR', '/' + String(this.result.prefixLength), COLOR_WARNING)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.ip_class'), this.result.ipClass, COLOR_PURPLE)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.ip_type'), this.result.ipType, this.result.isPrivate ? COLOR_CYAN : COLOR_PRIMARY)
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
      this.DetailRow($r('app.string.is_private'), this.result.isPrivate ? $r('app.string.yes') : $r('app.string.no'),
        this.result.isPrivate ? COLOR_SUCCESS : adaptiveTextSecondary(this.isDarkMode))
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 0, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  @Builder DetailRow(label: Resource | string, value: Resource | string, valueColor: string) {
    Row() {
      Text(label).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
      Blank()
      Text(value).fontSize(FONT_SIZE_SM).fontColor(valueColor).fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .width('100%').padding({ left: 16, right: 14, top: 12, bottom: 12 })
  }

  // 二进制可视化
  @Builder BinaryVis() {
    Column({ space: SPACE_MD }) {
      Text($r('app.string.binary_subnet'))
        .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
        .alignSelf(ItemAlign.Start)
        .padding({ left: 16, right: 14 })

      Row({ space: SPACE_XS }) {
        ForEach(this.getBinaryOctets(), (octet: BinaryOctet, index: number) => {
          this.BinaryOctetBlock(octet, index)
        }, (octet: BinaryOctet, index: number): string => String(index))
      }
      .padding({ left: 16, right: 14, bottom: 14 })
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 0, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  @Builder BinaryOctetBlock(octet: BinaryOctet, index: number) {
    Column({ space: SPACE_XS }) {
      // 8 个 bit 方块
      Row({ space: 1 }) {
        ForEach(this.getBits(octet.binary), (bit: BitItem, bitIndex: number) => {
          Text(bit.char)
            .fontSize(FONT_SIZE_XS).fontColor(Color.White).fontWeight(FONT_WEIGHT_BOLD)
            .width(20).height(20).textAlign(TextAlign.Center)
            .backgroundColor(bit.isOne ? COLOR_WARNING : adaptiveDivider(this.isDarkMode))
            .borderRadius(4)
        }, (bit: BitItem, bitIndex: number): string => String(index) + '_' + String(bitIndex))
      }

      // 十进制值
      Text(octet.decimal)
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  // 错误提示
  @Builder ErrorTip() {
    Row({ space: SPACE_SM }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(36).height(36).fill(this.isDarkMode ? 'rgba(239,68,68,0.15)' : '#FEF2F2')
        Text('!').fontSize(FONT_SIZE_MD).fontColor(COLOR_DANGER).fontWeight(FONT_WEIGHT_BOLD)
      }
      Column({ space: 2 }) {
        Text($r('app.string.input_error'))
          .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        Text(this.inputError)
          .fontSize(FONT_SIZE_SM).fontColor(COLOR_DANGER)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : 'rgba(239,68,68,0.3)')
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(239,68,68,0.2)', offsetX: 0, offsetY: 4 })
  }

  // 功能说明
  @Builder FeatureCard() {
    Column({ space: 0 }) {
      Text($r('app.string.subnet_calc_intro'))
        .fontSize(FONT_SIZE_SM).fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('🔢', '子网计算', '计算网络地址、广播地址、可用主机范围')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', '二进制掩码', '可视化显示子网掩码的二进制形式')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('🏷️', '快速预设', '支持 /8 /16 /24 等常用 CIDR 掩码')
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

// ==================== 辅助接口 ====================

interface BinaryOctet {
  binary: string
  decimal: string
}

interface BitItem {
  char: string
  isOne: boolean
}
