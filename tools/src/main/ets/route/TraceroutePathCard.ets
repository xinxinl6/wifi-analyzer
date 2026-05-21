// 路由追踪 — 路径可视化卡片组件
// 包含：路径时间线卡片 + 路径节点

import { COLOR_TEXT_PRIMARY, COLOR_TEXT_TERTIARY,
  COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER, COLOR_SHADOW_DARK,
  COLOR_SKY_BLUE,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_LINE, COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_SKY_TAG_BG,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD,
  FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  adaptiveTextPrimary, adaptiveTextTertiary } from '@wifi-analyzer/design-system'
import { TracerouteHop } from '../traceroute/TracerouteEngine'

@Component
export struct TraceroutePathCard {
  @Prop isDarkMode: boolean = false
  @Prop hopList: TracerouteHop[] = []
  @Prop isRunning: boolean = false
  onHopDetail: (hop: TracerouteHop) => void = () => {}

  build() {
    Column({ space: 0 }) {
      // 卡片标题
      Row() {
        Row({ space: 6 }) {
          Text('\u{1F6F0}').fontSize(14)
          Text($r('app.string.route_path'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        Text() {
          Span(String(this.hopList.length))
          Span(' ')
          Span($r('app.string.hops_count'))
        }
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_SKY_BLUE)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_SKY_LIGHT : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      // 分割线
      Column().width('100%').height(0.5).backgroundColor(
        this.isDarkMode ? 'rgba(148,163,184,0.15)' : 'rgba(148,163,184,0.25)')

      // 时间线列表
      Column({ space: 0 }) {
        ForEach(this.hopList, (hop: TracerouteHop, index: number) => {
          this.PathNode(hop, index)
        }, (hop: TracerouteHop, index: number): string => String(index + '_' + hop.hopIndex))
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  private isLastHop(index: number): boolean {
    return index === this.hopList.length - 1 && !this.isRunning
  }

  private getLatencyColor(latency: number): string {
    if (latency < 0) return COLOR_TEXT_TERTIARY
    if (latency <= 10) return COLOR_SUCCESS
    if (latency <= 50) return COLOR_SKY_BLUE
    if (latency <= 100) return COLOR_WARNING
    return COLOR_DANGER
  }

  private getLatencyLabelResource(latency: number): Resource | string {
    if (latency < 0) return ''
    if (latency <= 10) return $r('app.string.very_fast')
    if (latency <= 50) return $r('app.string.good_speed')
    if (latency <= 100) return $r('app.string.normal_speed')
    return $r('app.string.slow_speed')
  }

  // 路径节点
  @Builder PathNode(hop: TracerouteHop, index: number) {
    Row() {
      // 左侧时间线
      Column() {
        // 节点圆点
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(26).height(26)
            .fill(hop.status === 'success'
              ? (this.isLastHop(index) ? COLOR_SKY_BLUE : COLOR_GLASS_SKY_LIGHT)
              : 'rgba(148,163,184,0.2)')
            .borderWidth(1.5)
            .borderColor(hop.status === 'success' ? COLOR_SKY_BLUE : 'rgba(148,163,184,0.4)')

          Text(String(hop.hopIndex))
            .fontSize(FONT_SIZE_XS)
            .fontColor(hop.status === 'success'
              ? (this.isLastHop(index) ? adaptiveTextPrimary(this.isDarkMode) : COLOR_SKY_BLUE)
              : adaptiveTextTertiary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }

        // 连接竖线
        if (!this.isLastHop(index) || this.isRunning) {
          Column()
            .width(1.5)
            .layoutWeight(1)
            .backgroundColor(hop.status === 'success' ? COLOR_GLASS_SKY_LINE : (this.isDarkMode ? 'rgba(148,163,184,0.15)' : 'rgba(148,163,184,0.25)'))
            .margin({ top: 3, bottom: 3 })
        } else {
          Column().height(SPACE_SM)
        }
      }
      .width(32)
      .alignItems(HorizontalAlign.Center)

      // 右侧节点信息
      Stack({ alignContent: Alignment.Start }) {
        Column({ space: SPACE_XS }) {
          // IP地址行
          Row({ space: SPACE_SM }) {
            Text(hop.address === '*' ? $r('app.string.no_response') : hop.address)
              .fontSize(FONT_SIZE_SM)
              .fontColor(hop.address === '*' ? adaptiveTextTertiary(this.isDarkMode) : adaptiveTextPrimary(this.isDarkMode))
              .fontWeight(hop.address === '*' ? FontWeight.Normal : FONT_WEIGHT_BOLD)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            if (hop.latency > 0) {
              Text(hop.latency + 'ms')
                .fontSize(FONT_SIZE_XS)
                .fontColor(this.getLatencyColor(hop.latency))
                .fontWeight(FONT_WEIGHT_BOLD)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(this.getLatencyColor(hop.latency) + '18')
                .borderRadius(999)
                .flexShrink(0)
            } else {
              Text($r('app.string.timeout'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(adaptiveTextTertiary(this.isDarkMode))
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(this.isDarkMode ? 'rgba(148,163,184,0.15)' : 'rgba(148,163,184,0.2)')
                .borderRadius(999)
                .flexShrink(0)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 多次探测 RTT 详情行
          if (hop.allRtt !== undefined && hop.allRtt.length > 1) {
            Row({ space: 4 }) {
              ForEach(hop.allRtt, (rtt: number, rttIdx: number) => {
                Text(rtt + 'ms')
                  .fontSize(10)
                  .fontColor(this.getLatencyColor(rtt))
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)')
                  .borderRadius(4)
              }, (rtt: number, rttIdx: number): string => String(rttIdx))
            }
            .width('100%')
          }

          // 主机名
          if (hop.hostname !== '' && hop.hostname !== '*') {
            Text(hop.hostname)
              .fontSize(FONT_SIZE_XS)
              .fontColor(adaptiveTextTertiary(this.isDarkMode))
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          // 标签行
          Row({ space: 6 }) {
            if (hop.hopIndex === 1) {
              Text($r('app.string.gateway_tag'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SKY_BLUE)
                .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                .backgroundColor(this.isDarkMode ? COLOR_GLASS_SKY_LIGHT : COLOR_GLASS_SKY_TAG_BG)
                .borderRadius(999)
            }
            if (this.isLastHop(index) && hop.address !== '*') {
              Text($r('app.string.target_tag'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SUCCESS)
                .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                .backgroundColor(this.isDarkMode ? 'rgba(16,185,129,0.15)' : (COLOR_SUCCESS + '18'))
                .borderRadius(999)
            }
            if (hop.latency > 0) {
              Text(this.getLatencyLabelResource(hop.latency))
                .fontSize(FONT_SIZE_XS)
                .fontColor(this.getLatencyColor(hop.latency))
                .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                .backgroundColor(this.isDarkMode ? this.getLatencyColor(hop.latency) + '20' : this.getLatencyColor(hop.latency) + '15')
                .borderRadius(999)
            }
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .constraintSize({ minWidth: 0 })
        .layoutWeight(1)
        .padding({ left: 12, top: 4, bottom: 8 })
      }
      .alignContent(Alignment.Start)
      .constraintSize({ minWidth: 0 })
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}
