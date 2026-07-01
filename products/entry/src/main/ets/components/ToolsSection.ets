// ToolsSection — HM7 沉浸光感工具箱 v3.1 i18n
import {
  adaptiveTextPrimary, adaptiveTextSecondary,
  adaptivePrimaryLight,
  adaptiveBackgroundList,
} from '@wifi-analyzer/design-system'
import { CommonConstants } from 'wifi-base'

interface ToolItem {
  name: Resource
  desc: Resource
  color: string
  route: string
  iconChar: string
}

@Component
export struct ToolsSection {
  @Prop isDark: boolean = true
  @Prop deviceWidth: number = 360
  @Consume('pageStack') pageStack: NavPathStack = new NavPathStack()

  private diagTools: ToolItem[] = [
    { name: $r('app.string.tool_ping'), desc: $r('app.string.desc_monitor'), color: 'rgba(49,122,247,0.12)', route: CommonConstants.PING_PAGE, iconChar: 'P' },
    { name: $r('app.string.tool_traceroute'), desc: $r('app.string.desc_path'), color: 'rgba(49,122,247,0.12)', route: CommonConstants.TRACEROUTE_PAGE, iconChar: 'T' },
    { name: $r('app.string.tool_dns'), desc: $r('app.string.desc_dns_resolve'), color: 'rgba(139,92,246,0.12)', route: CommonConstants.DNS_PAGE, iconChar: 'D' },
  ]

  private secTools: ToolItem[] = [
    { name: $r('app.string.tool_portscan'), desc: $r('app.string.desc_port'), color: 'rgba(139,92,246,0.12)', route: CommonConstants.PORT_SCAN_PAGE, iconChar: 'P' },
    { name: $r('app.string.tool_lan'), desc: $r('app.string.desc_lan'), color: 'rgba(139,92,246,0.12)', route: CommonConstants.LAN_SCAN_PAGE, iconChar: 'L' },
  ]

  private netTools: ToolItem[] = [
    { name: $r('app.string.tool_subnet'), desc: $r('app.string.desc_cidr'), color: 'rgba(91,168,84,0.12)', route: CommonConstants.SUBNET_PAGE, iconChar: 'S' },
    { name: $r('app.string.tool_ipgeo'), desc: $r('app.string.desc_geo'), color: 'rgba(219,107,66,0.12)', route: CommonConstants.IP_GEO_PAGE, iconChar: 'G' },
  ]

  private otherTools: ToolItem[] = [
    { name: $r('app.string.tool_poe'), desc: $r('app.string.desc_poe'), color: 'rgba(245,158,11,0.12)', route: CommonConstants.POE_PAGE, iconChar: 'P' },
    { name: $r('app.string.tool_settings'), desc: $r('app.string.desc_settings'), color: 'rgba(255,255,255,0.06)', route: 'SettingsPage', iconChar: '⚙' },
  ]

  build() {
    Column() {
      Scroll() {
        Column({ space: 0 }) {
          Text($r('app.string.tools_title'))
            .fontSize(32).fontWeight(800)
            .fontColor(adaptiveTextPrimary(this.isDark))
            .letterSpacing(-0.5)
            .width('100%').padding({ top: 56, bottom: 4 })

          Text($r('app.string.tools_subtitle'))
            .fontSize(13).fontWeight(400)
            .fontColor(adaptiveTextSecondary(this.isDark))
            .width('100%').padding({ bottom: 8 })

          this.category($r('app.string.section_diag'), this.diagTools)
          this.category($r('app.string.section_security'), this.secTools)
          this.category($r('app.string.section_network'), this.netTools)
          this.category($r('app.string.section_other'), this.otherTools)

          Row().height(80)
        }.width('100%').padding({ left: 16, right: 16 })
      }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off).width('100%')
        .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: adaptiveBackgroundList(this.isDark)
    })
  }

  @Builder category(title: Resource, items: ToolItem[]) {
    Column() {
      Text(title)
        .fontSize(12).fontWeight(700)
        .fontColor(adaptiveTextSecondary(this.isDark))
        .letterSpacing(0.15).textCase(TextCase.UpperCase)
        .width('100%').padding({ top: 22, bottom: 14 })

      Row({ space: 8 }) {
        ForEach(items, (t: ToolItem, idx: number) => {
          Column({ space: 6 }) {
            Column() {
              Text(t.iconChar)
                .fontSize(14).fontWeight(700)
                .fontColor(adaptivePrimaryLight(this.isDark))
            }
            .width(46).height(46)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(t.color)
            .borderRadius(14)

            Text(t.name)
              .fontSize(12).fontWeight(600)
              .fontColor(adaptiveTextPrimary(this.isDark))
              .textAlign(TextAlign.Center)
              .maxLines(1)

            Text(t.desc)
              .fontSize(10).fontWeight(400)
              .fontColor(adaptiveTextSecondary(this.isDark))
              .textAlign(TextAlign.Center)
              .maxLines(1)
          }
          .width('25%').padding({ top: 6, bottom: 6 })
          .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.pageStack.pushPathByName(t.route, undefined)
          })
        })
      }.width('100%')
    }.width('100%')
  }
}
