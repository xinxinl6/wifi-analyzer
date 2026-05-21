// 子网计算结果区域组件

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_INFO, COLOR_WARNING,
  COLOR_PURPLE, COLOR_CYAN, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider,
} from '@wifi-analyzer/design-system'
import { SubnetResult } from '../subnet/SubnetCalculator'

// ==================== 辅助接口 ====================

interface BinaryOctet {
  binary: string
  decimal: string
}

interface BitItem {
  char: string
  isOne: boolean
}

@Component
export struct SubnetResultSection {
  @Prop isDarkMode: boolean = false
  @Prop result: SubnetResult = {
    networkAddress: '', broadcastAddress: '', subnetMask: '', wildcardMask: '',
    firstHost: '', lastHost: '', totalHosts: 0, prefixLength: 24,
    ipClass: '', isPrivate: false, binaryMask: '', ipType: '',
  }

  // ==================== 工具方法 ====================

  formatHostCount(count: number): string {
    if (count >= 1000000) {
      return String(Math.round(count / 1000000 * 10) / 10) + 'M'
    }
    if (count >= 1000) {
      return String(Math.round(count / 1000 * 10) / 10) + 'K'
    }
    return String(count)
  }

  getBinaryOctets(): BinaryOctet[] {
    const binary: string = this.result.binaryMask
    const parts: string[] = binary.split('.')
    const res: BinaryOctet[] = []
    for (let i = 0; i < parts.length; i++) {
      const item: BinaryOctet = { binary: parts[i], decimal: this.result.subnetMask.split('.')[i] }
      res.push(item)
    }
    return res
  }

  getBits(binary: string): BitItem[] {
    const res: BitItem[] = []
    for (let i = 0; i < binary.length; i++) {
      const item: BitItem = { char: binary[i], isOne: binary[i] === '1' }
      res.push(item)
    }
    return res
  }

  // ==================== 构建 ====================

  build() {
    Column({ space: SPACE_LG }) {
      this.BasicInfoCard()
      this.AddressRangeCard()
      this.DetailTable()
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
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
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
        .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
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
        .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
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
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
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
      this.DetailRow($r('app.string.label_cidr'), '/' + String(this.result.prefixLength), COLOR_WARNING)
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
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
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
    Column({ space: 14 }) {
      Row() {
        Text($r('app.string.binary_subnet'))
          .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode)).fontWeight(FONT_WEIGHT_MEDIUM)
        Blank()
        Text($r('app.string.label_bits_32'))
          .fontSize(14).fontColor(this.isDarkMode ? 'rgba(255,255,255,0.3)' : 'rgba(99,102,241,0.4)')
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14 })

      Row({ space: 4 }) {
        ForEach(this.getBinaryOctets(), (octet: BinaryOctet, index: number) => {
          this.BinaryOctetBlock(octet, index)
        }, (octet: BinaryOctet, index: number): string => String(index))
      }
      .padding({ left: 12, right: 12, bottom: 14 })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  @Builder BinaryOctetBlock(octet: BinaryOctet, index: number) {
    Column({ space: 6 }) {
      // 8 个 bit 方块
      Row({ space: 2 }) {
        ForEach(this.getBits(octet.binary), (bit: BitItem, bitIndex: number) => {
          Text(bit.char)
            .fontSize(14)
            .fontColor(bit.isOne ? Color.White : (this.isDarkMode ? 'rgba(255,255,255,0.25)' : 'rgba(0,0,0,0.2)'))
            .fontWeight(FONT_WEIGHT_BOLD)
            .width(18).height(22).textAlign(TextAlign.Center)
            .backgroundColor(bit.isOne
              ? (this.isDarkMode ? COLOR_PRIMARY : COLOR_PRIMARY)
              : (this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(99,102,241,0.06)'))
            .borderRadius(5)
            .borderWidth(1)
            .borderColor(bit.isOne
              ? 'transparent'
              : (this.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(99,102,241,0.15)'))
        }, (bit: BitItem, bitIndex: number): string => String(index) + '_' + String(bitIndex))
      }

      // 十进制值
      Text(octet.decimal)
        .fontSize(15)
        .fontColor(this.isDarkMode ? 'rgba(255,255,255,0.5)' : 'rgba(99,102,241,0.7)')
        .fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }
}
