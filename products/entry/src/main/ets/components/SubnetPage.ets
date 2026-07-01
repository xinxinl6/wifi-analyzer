// SubnetPage — 从 ToolPages.ets 拆分
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveTextCyan, adaptiveTextAmber, adaptiveTextGreen,
  adaptiveCardBg, adaptiveCardDarkGlass, adaptiveBorderCyan,
  adaptiveBackgroundList, adaptiveBtnBg,
  adaptiveSuccess, adaptiveDanger, adaptiveInfo,
  RADIUS_MD
} from '@wifi-analyzer/design-system';
import { RouterManager } from '@wifi-analyzer/core';
import { SubnetCalculator, SubnetResult, IpAddressInfo, SubnetPreset } from '@wifi-analyzer/network-tools';

@Builder
export function SubnetPageBuilder() { NavDestination() { SubnetPage() }.title($r('app.string.tool_subnet')).hideTitleBar(true) }

@Component
export struct SubnetPage {
  @StorageLink('isDarkMode') isDark: boolean = false
  @State inputText: string = '192.168.1.1/24'
  @State hasResult: boolean = false
  @State networkAddress: string = ''
  @State broadcastAddress: string = ''
  @State subnetMask: string = ''
  @State wildcardMask: string = ''
  @State firstHost: string = ''
  @State lastHost: string = ''
  @State totalHosts: number = 0
  @State prefixLength: number = 24
  @State ipClass: string = ''
  @State ipType: string = ''
  @State isPrivate: boolean = false
  @State inputValid: boolean = true
  @State inputError: string = ''

  private resolveIpType(): Resource {
    switch (this.ipType) {
      case 'ip_type_private_a': return $r('app.string.ip_type_private_a')
      case 'ip_type_private_b': return $r('app.string.ip_type_private_b')
      case 'ip_type_private_c': return $r('app.string.ip_type_private_c')
      case 'ip_type_loopback': return $r('app.string.ip_type_loopback')
      case 'ip_type_link_local': return $r('app.string.ip_type_link_local')
      case 'ip_type_multicast': return $r('app.string.ip_type_multicast')
      case 'ip_type_reserved': return $r('app.string.ip_type_reserved')
      case 'ip_type_public': return $r('app.string.ip_type_public')
      default: return $r('app.string.ip_type_public')
    }
  }

  private resolveYesNo(): Resource { return this.isPrivate ? $r('app.string.yes') : $r('app.string.no') }

  aboutToAppear(): void { this.doCalculate() }

  private doCalculate(): void {
    const inp: string = this.inputText.trim()
    if (inp.length === 0) { this.resetResult(); return }
    const info: IpAddressInfo = SubnetCalculator.parseInput(inp)
    if (!info.isValid) { this.inputValid = false; this.inputError = info.errorMessage; this.resetResult(); return }
    this.inputValid = true; this.inputError = ''
    const r: SubnetResult = SubnetCalculator.calculate(info.address, info.prefixLength)
    this.hasResult = true; this.networkAddress = r.networkAddress; this.broadcastAddress = r.broadcastAddress
    this.subnetMask = r.subnetMask; this.wildcardMask = r.wildcardMask; this.firstHost = r.firstHost; this.lastHost = r.lastHost
    this.totalHosts = r.totalHosts; this.prefixLength = r.prefixLength; this.ipClass = r.ipClass; this.ipType = r.ipType; this.isPrivate = r.isPrivate
  }

  private resetResult(): void {
    this.hasResult = false; this.networkAddress = ''; this.broadcastAddress = ''; this.subnetMask = ''; this.wildcardMask = ''
    this.firstHost = ''; this.lastHost = ''; this.totalHosts = 0; this.prefixLength = 0; this.ipClass = ''; this.ipType = ''; this.isPrivate = false
  }

  private onPresetTap(p: SubnetPreset): void {
    const info: IpAddressInfo = SubnetCalculator.parseInput(this.inputText)
    this.inputText = info.isValid ? info.address + '/' + String(p.prefix) : '192.168.1.1/' + String(p.prefix)
    this.doCalculate()
  }

  private formatHosts(n: number): string {
    if (n >= 1000000) return String(Math.round(n / 1000000 * 10) / 10) + 'M'
    if (n >= 1000) return String(Math.round(n / 1000 * 10) / 10) + 'K'
    return String(n)
  }

  build() {
    Stack() {
      Circle().width(300).height(300).fill(this.isDark ? 'rgba(59,130,246,0.06)' : 'rgba(59,130,246,0.04)').position({ x: -80, y: -80 })
      Circle().width(200).height(200).fill(this.isDark ? 'rgba(59,130,246,0.04)' : 'rgba(59,130,246,0.03)').position({ x: '70%', y: '50%' })
      Column() {
        Row({ space: 16 }) {
          Row() { Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark)) }.width(36).height(36).justifyContent(FlexAlign.Center).borderRadius(8).backgroundColor(adaptiveBtnBg(this.isDark)).onClick(() => { RouterManager.goBack() })
          Text($r('app.string.tool_subnet')).fontSize(20).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
        }.width('100%').padding({ left: 20, right: 20, top: 44, bottom: 8 })
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                TextInput({ text: this.inputText, placeholder: $r('app.string.subnet_input_hint') }).fontColor(adaptiveTextPrimary(this.isDark)).placeholderColor(adaptiveTextTertiary(this.isDark)).fontSize(14).layoutWeight(1).height(42).backgroundColor(adaptiveBtnBg(this.isDark)).borderRadius(8).border({ width: 1, color: this.inputValid ? adaptiveBorderCyan(this.isDark) : adaptiveDanger(this.isDark), style: BorderStyle.Solid }).padding({ left: 14 }).onChange((v: string) => { this.inputText = v })
                Row() { Text($r('app.string.calculate_action')).fontSize(12).fontWeight(700).fontColor(Color.White) }.height(42).justifyContent(FlexAlign.Center).padding({ left: 16, right: 16 }).linearGradient({ angle: 135, colors: [['rgba(245,158,11,0.5)', 0], ['rgba(245,158,11,0.8)', 1]] }).borderRadius(8).onClick(() => { this.doCalculate() })
              }
              if (!this.inputValid) {
                Row({ space: 6 }) { Text('!').fontSize(10).fontColor(Color.White).fontWeight(700).width(16).height(16).textAlign(TextAlign.Center).backgroundColor(adaptiveDanger(this.isDark)).borderRadius(8); Text(this.inputError).fontSize(11).fontColor(adaptiveDanger(this.isDark)) }.width('100%')
              }
            }.width('100%').padding(16).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(SubnetCalculator.SUBNET_PRESETS, (p: SubnetPreset) => {
                Row() { Text(p.label).fontSize(11).fontWeight(700).fontColor(adaptiveTextAmber(this.isDark)) }.padding({ left: 12, right: 12, top: 5, bottom: 5 }).backgroundColor(this.isDark ? 'rgba(245,158,11,0.12)' : 'rgba(245,158,11,0.08)').borderRadius(999).margin({ bottom: 6, right: 6 }).onClick(() => { this.onPresetTap(p) })
              }, (p: SubnetPreset): string => p.label)
            }.width('100%')

            if (this.hasResult) {
              Row({ space: 10 }) { this.infoCard($r('app.string.network_addr'), this.networkAddress, adaptiveTextCyan(this.isDark)); this.infoCard($r('app.string.broadcast_addr'), this.broadcastAddress, adaptiveInfo(this.isDark)) }
              Column({ space: 10 }) {
                Text($r('app.string.host_range_title')).fontSize(13).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
                Row({ space: 8 }) {
                  Column({ space: 4 }) { Text($r('app.string.start_label')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)).textCase(TextCase.UpperCase); Text(this.firstHost).fontSize(14).fontWeight(700).fontColor(adaptiveSuccess(this.isDark)).fontFamily('monospace') }.layoutWeight(1).alignItems(HorizontalAlign.Center).padding(14).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
                  Text('~').fontSize(18).fontColor(adaptiveTextTertiary(this.isDark))
                  Column({ space: 4 }) { Text($r('app.string.end_label')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)).textCase(TextCase.UpperCase); Text(this.lastHost).fontSize(14).fontWeight(700).fontColor(adaptiveSuccess(this.isDark)).fontFamily('monospace') }.layoutWeight(1).alignItems(HorizontalAlign.Center).padding(14).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
                }
                Row({ space: 8 }) {
                  Row() { Text('#').fontSize(13).fontWeight(800).fontColor(adaptiveTextAmber(this.isDark)) }.width(36).height(36).justifyContent(FlexAlign.Center).backgroundColor(this.isDark ? 'rgba(245,158,11,0.12)' : 'rgba(245,158,11,0.08)').borderRadius(18)
                  Column({ space: 2 }) { Text($r('app.string.usable_hosts_label')).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)); Text(this.formatHosts(this.totalHosts)).fontSize(16).fontWeight(800).fontColor(adaptiveTextAmber(this.isDark)) }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                }.padding(14).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
              }
              Column({ space: 0 }) {
                Text($r('app.string.detail_info_label')).fontSize(13).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark)).width('100%').padding({ left: 16, right: 16, top: 14, bottom: 12 })
                Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
                this.detailRow($r('app.string.subnet_mask_label'), this.subnetMask, adaptiveTextCyan(this.isDark))
                Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
                this.detailRow($r('app.string.wildcard_mask_label'), this.wildcardMask, adaptiveInfo(this.isDark))
                Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
                this.detailRow($r('app.string.cidr_label'), '/' + String(this.prefixLength), adaptiveTextAmber(this.isDark))
                Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
                this.detailRow($r('app.string.ip_class_label'), this.ipClass, adaptiveTextGreen(this.isDark))
                Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
                this.detailRow($r('app.string.ip_type_label'), this.resolveIpType(), this.isPrivate ? adaptiveInfo(this.isDark) : adaptiveTextCyan(this.isDark))
                Column().width('100%').height(0.5).backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.3)
                this.detailRow($r('app.string.is_private_label'), this.resolveYesNo(), this.isPrivate ? adaptiveSuccess(this.isDark) : adaptiveTextTertiary(this.isDark))
              }.width('100%').linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD).clip(true)
            } else if (!this.inputValid) {
              Row({ space: 8 }) {
                Text('!').fontSize(16).fontColor(adaptiveDanger(this.isDark)).fontWeight(700).width(32).height(32).textAlign(TextAlign.Center).backgroundColor(this.isDark ? 'rgba(217,72,56,0.12)' : 'rgba(217,72,56,0.08)').borderRadius(16)
                Column({ space: 2 }) { Text($r('app.string.input_error_label')).fontSize(11).fontColor(adaptiveTextTertiary(this.isDark)); Text(this.inputError).fontSize(13).fontColor(adaptiveDanger(this.isDark)) }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }.padding(14).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveDanger(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
            }
          }.padding({ left: 20, right: 20, top: 8, bottom: 20 })
        }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off)
      }.width('100%').height('100%')
    }.width('100%').height('100%').linearGradient({ angle: 180, colors: adaptiveBackgroundList(this.isDark) })
  }

  @Builder infoCard(label: Resource, value: string, color: string) {
    Column({ space: 4 }) { Text(label).fontSize(9).fontColor(adaptiveTextTertiary(this.isDark)).textCase(TextCase.UpperCase); Text(value).fontSize(14).fontWeight(700).fontColor(color).fontFamily('monospace').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }) }.layoutWeight(1).alignItems(HorizontalAlign.Center).padding(14).height(64).linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] }).border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(RADIUS_MD)
  }

  @Builder detailRow(label: Resource, value: ResourceStr, color: string) {
    Row() { Text(label).fontSize(12).fontColor(adaptiveTextSecondary(this.isDark)).layoutWeight(1); Text(value).fontSize(12).fontWeight(600).fontColor(color).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }) }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }
}
