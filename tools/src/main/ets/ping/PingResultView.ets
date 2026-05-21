// Ping 测试结果视图组件

import {
  COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT,
  COLOR_TEXT_TERTIARY, COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_SKY_SHADOW_MED,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_2XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { PingResult, PingStats } from './PingEngine'

@Component
export struct PingResultView {
  @Prop isDarkMode: boolean = false
  @Prop targetHost: string = ''
  @Prop resolvedIp: string = ''
  @Prop pingResults: PingResult[] = []
  @Prop pingStats: PingStats = {
    sent: 0, received: 0, lost: 0, lossRate: 0,
    minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0
  }
  @Prop isRunning: boolean = false
  @Prop viewMode: string = 'idle'
  @Prop progress: string = '0/0'
  @Prop pulseOpacity: number = 1.0

  onGoBack: () => void = () => {}
  onRestart: () => void = () => {}
  onStop: () => void = () => {}

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 目标信息卡片
        this.TargetInfoCard()

        // 统计概览
        if (this.pingResults.length > 0) {
          this.StatsOverviewCard()
        }

        // Ping 结果列表
        if (this.pingResults.length > 0) {
          this.PingResultsCard()
        }
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 目标信息卡片
  @Builder TargetInfoCard() {
    Row({ space: 14 }) {
      // 脉冲图标
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? COLOR_GLASS_SKY_LIGHT : COLOR_GLASS_SKY_LIGHT)
          .opacity(this.isRunning ? this.pulseOpacity : 1.0)
        Circle().width(36).height(36)
          .fill(this.isRunning ? COLOR_SKY_BLUE : (this.viewMode === 'completed' ? COLOR_SUCCESS : COLOR_SKY_BLUE))
        Image($r('app.media.ic_device')).width(18).height(18).fillColor(adaptiveTextPrimary(this.isDarkMode))
      }

      Column({ space: 4 }) {
        Text(this.targetHost)
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          if (this.resolvedIp !== this.targetHost && this.resolvedIp.length > 0) {
            Text(this.resolvedIp)
              .fontSize(FONT_SIZE_XS)
              .fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
          if (this.isRunning) {
            Row({ space: 4 }) {
              Circle().width(5).height(5)
                .fill(COLOR_SKY_BLUE)
                .opacity(this.pulseOpacity)
              Text($r('app.string.label_pinging') + this.progress)
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SKY_BLUE)
            }
          } else if (this.viewMode === 'completed') {
            Row({ space: 4 }) {
              Circle().width(5).height(5).fill(COLOR_SUCCESS)
              Text($r('app.string.ping_complete'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SUCCESS)
            }
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 重新输入按钮
      Row() {
        Text('🔍').fontSize(14)
      }
      .width(34).height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_SKY_LIGHT : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(10)
      .onClick(() => this.onGoBack())
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

  // 统计概览
  @Builder StatsOverviewCard() {
    Row() {
      this.StatCell($r('app.string.ping_sent_label'), String(this.pingStats.sent), COLOR_SKY_BLUE)
      this.StatDivider()
      this.StatCell($r('app.string.ping_success_label'), String(this.pingStats.received), COLOR_SUCCESS)
      this.StatDivider()
      this.StatCell($r('app.string.ping_loss_label'), String(this.pingStats.lossRate) + '%', this.pingStats.lossRate > 0 ? COLOR_DANGER : COLOR_SUCCESS)
      this.StatDivider()
      this.StatCell($r('app.string.ping_avg_label'), this.pingStats.avgTime > 0 ? String(this.pingStats.avgTime) + 'ms' : '--', COLOR_SKY_BLUE_LIGHT)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  @Builder StatCell(label: string | Resource, value: string, valueColor: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(FONT_SIZE_2XL)
        .fontColor(valueColor)
        .fontWeight(FONT_WEIGHT_BOLD)
      Text(label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder StatDivider() {
    Column()
      .width(1).height(36)
      .backgroundColor(adaptiveDivider(this.isDarkMode))
  }

  // Ping 结果列表
  @Builder PingResultsCard() {
    Column({ space: 0 }) {
      // 卡片标题
      Row() {
        Row({ space: 6 }) {
          Text('📊').fontSize(14)
          Text($r('app.string.ping_result_title'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        Text(this.pingStats.received + '/' + this.pingStats.sent)
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_SKY_BLUE)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_SKY_LIGHT : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      // 分割线
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      // 结果列表
      Column({ space: 0 }) {
        ForEach(this.pingResults, (result: PingResult, index: number) => {
          this.PingResultItem(result, index)
        }, (result: PingResult, index: number): string => String(result.index))
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 12 })
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

  // Ping 结果项
  @Builder PingResultItem(result: PingResult, index: number) {
    Row({ space: SPACE_SM }) {
      // 序号
      Text(String(result.index))
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .width(24)
        .textAlign(TextAlign.Center)

      // 状态图标
      Text(this.getStatusIcon(result.status))
        .fontSize(FONT_SIZE_MD)
        .fontColor(this.getStatusColor(result.status))
        .width(24)
        .textAlign(TextAlign.Center)

      // IP 地址
      Text(result.address)
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 延迟
      if (result.status === 'success') {
        Text(result.time + 'ms')
          .fontSize(FONT_SIZE_SM)
          .fontColor(this.getLatencyColor(result.time))
          .fontWeight(FONT_WEIGHT_BOLD)
      } else {
        Text(result.status === 'timeout' ? $r('app.string.ping_timeout') : $r('app.string.ping_failure'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })

    // 分隔线
    if (index < this.pingResults.length - 1) {
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
    }
  }

  getStatusIcon(status: string): string {
    if (status === 'success') return '✓'
    if (status === 'timeout') return '⏳'
    return '✗'
  }

  getStatusColor(status: string): string {
    if (status === 'success') return COLOR_SUCCESS
    if (status === 'timeout') return COLOR_WARNING
    return COLOR_DANGER
  }

  getLatencyColor(latency: number): string {
    if (latency <= 0) return COLOR_TEXT_TERTIARY
    if (latency <= 50) return COLOR_SUCCESS
    if (latency <= 100) return COLOR_SKY_BLUE
    if (latency <= 200) return COLOR_WARNING
    return COLOR_DANGER
  }
}
