// Ping 测试 - 历史记录弹窗组件
// 职责：Ping 历史记录展示、清空
// 优化版本：天蓝色玻璃拟态风格

import { adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveCardBg, adaptiveDivider,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_TERTIARY, COLOR_TEXT_SECONDARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_PRIMARY, COLOR_DANGER,
  COLOR_BORDER, COLOR_SUCCESS, COLOR_WARNING,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL, RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL,
  BUTTON_HEIGHT_MD,
  // 玻璃拟态
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  GLASS_BLUR_MD, GLASS_BLUR_LG, GLASS_SHADOW_MD, GLASS_SHADOW_LG } from '@wifi-analyzer/design-system'
import { PingResult } from './PingTestPage'

// ==================== Props 接口 ====================
export interface HistoryModalProps {
  isDarkMode: boolean
  pingHistory: PingResult[]
  onClose: () => void
  getGlobalHistForModal: () => Array<PingResult>
  onClearHistory: () => void
}

// ==================== 统计数据结构 ====================
interface PingStats {
  total: number
  successCount: number
  lossCount: number
  lossRate: number
  avgLatency: number
  maxLatency: number
  minLatency: number
}

// ==================== 历史记录弹窗 ====================
@Component
export struct HistoryModal {
  @Prop isDarkMode: boolean = false
  @State pingHistory: PingResult[] = []
  onClose: () => void = () => {}
  getGlobalHistForModal: () => Array<PingResult> = () => new Array<PingResult>()
  onClearHistory: () => void = () => {}

  // 计算统计信息
  getStats(): PingStats {
    const history = this.getGlobalHistForModal()
    const total: number = history.length
    const successCount: number = history.filter((r: PingResult) => r.status === 'success').length
    const lossCount: number = total - successCount
    const lossRate: number = total > 0 ? Math.round((lossCount / total) * 100) : 0
    const successTimes: number[] = history
      .filter((r: PingResult) => r.status === 'success' && r.timeMs !== undefined)
      .map((r: PingResult) => r.timeMs as number)
    const avgLatency: number = successTimes.length > 0
      ? Math.round(successTimes.reduce((a: number, b: number) => a + b, 0) / successTimes.length)
      : 0
    const maxLatency: number = successTimes.length > 0 ? Math.max(...successTimes) : 0
    const minLatency: number = successTimes.length > 0 ? Math.min(...successTimes) : 0

    return { total, successCount, lossCount, lossRate, avgLatency, maxLatency, minLatency }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 遮罩
      Column().width('100%').height('100%').backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => { this.onClose() })

      Column({ space: 0 }) {
        // 渐变装饰条
        Column()
          .width(48)
          .height(4)
          .backgroundColor(adaptiveTextTertiary(this.isDarkMode))
          .borderRadius(2)
          .margin({ top: SPACE_SM, bottom: SPACE_MD })

        // 标题栏
        Row() {
          Text($r('app.string.history'))
            .fontSize(FONT_SIZE_XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))

          Blank()

          Button($r('app.string.clear_history'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_DANGER)
            .backgroundColor('rgba(239,68,68,0.1)')
            .borderRadius(RADIUS_SM)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .onClick(() => {
              this.onClearHistory()
              this.onClose()
            })

          Text('\u00D7')
            .fontSize(FONT_SIZE_4XL)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
            .margin({ left: SPACE_SM })
            .onClick(() => { this.onClose() })
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_SM, bottom: SPACE_MD })

        // 统计摘要卡片
        this.StatsSummaryCard()

        // 内容区
        Scroll() {
          Column({ space: SPACE_SM }) {
            if (this.getGlobalHistForModal().length === 0) {
              this.HistoryEmptyState()
            } else {
              ForEach(this.getGlobalHistForModal(), (result: PingResult, index: number) => {
                this.HistoryItemRow(result, index)
              }, (result: PingResult, index: number): string => String(index + '_' + result.timestamp))
            }
          }
          .width('100%')
          .padding({ left: SPACE_LG, right: SPACE_LG, bottom: SPACE_LG })
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Auto)
        .constraintSize({ maxHeight: 420 })

        // 底部安全区
        Column().height(SPACE_XL).width('100%')
      }
      .width('100%')
      .backgroundColor(this.isDarkMode ? 'rgba(30,41,59,0.95)' : COLOR_SURFACE)
      .borderRadius({ topLeft: RADIUS_2XL, topRight: RADIUS_2XL })
    }
    .zIndex(999)
  }

  @Builder StatsSummaryCard() {
    Column({ space: SPACE_MD }) {
      // 统计数字行
      Row() {
        this.StatItem('总数', String(this.getStats().total), adaptiveTextPrimary(this.isDarkMode))
        Column().width(1).height(32).backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_BORDER)
        this.StatItem('平均延迟', this.getStats().avgLatency > 0 ? String(this.getStats().avgLatency) + ' ms' : '--', COLOR_SKY_BLUE)
        Column().width(1).height(32).backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_BORDER)
        this.StatItem('丢包率', this.getStats().lossRate > 0 ? String(this.getStats().lossRate) + '%' : '0%', this.getStats().lossRate > 0 ? COLOR_DANGER : COLOR_SUCCESS)
      }
      .width('100%')
      .padding({ top: SPACE_SM, bottom: SPACE_SM })

      Divider().color(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_BORDER)

      // 延迟范围行
      Row() {
        this.StatSmallItem('最低', this.getStats().minLatency > 0 ? String(this.getStats().minLatency) : '--', 'ms')
        Blank()
        this.StatSmallItem('最高', this.getStats().maxLatency > 0 ? String(this.getStats().maxLatency) : '--', 'ms')
        Blank()
        this.StatSmallItem('成功', String(this.getStats().successCount), '次')
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_SM, bottom: SPACE_MD })
    .backgroundColor(this.isDarkMode ? 'rgba(15,30,60,0.6)' : COLOR_BACKGROUND)
    .margin({ left: SPACE_LG, right: SPACE_LG, bottom: SPACE_MD })
    .borderRadius(RADIUS_LG)
  }

  @Builder StatItem(label: string, value: string, valueColor: string) {
    Column({ space: SPACE_XS }) {
      Text(value)
        .fontSize(FONT_SIZE_LG)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(valueColor)
      Text(label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder StatSmallItem(label: string, value: string, unit: string) {
    Row({ space: SPACE_XS }) {
      Text(label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
      Text(value)
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
      Text(unit)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
  }

  @Builder HistoryEmptyState() {
    Column({ space: SPACE_MD }) {
      Column()
        .width(64)
        .height(64)
        .backgroundColor(this.isDarkMode ? 'rgba(15,30,60,0.6)' : COLOR_BACKGROUND)
        .borderRadius(32)
        .align(Alignment.Center)

      Text($r('app.string.no_records'))
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder HistoryItemRow(result: PingResult, index: number) {
    Row({ space: SPACE_MD }) {
      // 序号
      Text(String(index + 1))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .width(24)
        .textAlign(TextAlign.Center)

      Column({ space: 4 }) {
        Text(result.address)
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(new Date(result.timestamp).toLocaleTimeString())
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 状态和延迟
      if (result.status === 'success') {
        Row({ space: SPACE_SM }) {
          // 延迟等级指示
          Column()
            .width(3)
            .height(24)
            .backgroundColor(this.getLatencyColor(result.timeMs as number))
            .borderRadius(1.5)

          Text(String(result.timeMs) + ' ms')
            .fontSize(FONT_SIZE_SM)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
      } else if (result.status === 'timeout') {
        Row({ space: SPACE_SM }) {
          Column()
            .width(3)
            .height(24)
            .backgroundColor(COLOR_DANGER)
            .borderRadius(1.5)

          Text($r('app.string.timeout'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(COLOR_DANGER)
        }
      } else {
        Row({ space: SPACE_SM }) {
          Column()
            .width(3)
            .height(24)
            .backgroundColor(COLOR_DANGER)
            .borderRadius(1.5)

          Text($r('app.string.failed'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(COLOR_DANGER)
        }
      }
    }
    .width('100%')
    .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_SM, bottom: SPACE_SM })
    .backgroundColor(this.isDarkMode ? 'rgba(15,30,60,0.4)' : COLOR_BACKGROUND)
    .borderRadius(RADIUS_MD)
    .stateStyles({ pressed: { opacity: 0.8 } })
  }

  // 根据延迟值返回颜色
  getLatencyColor(latency: number): string {
    if (latency < 50) return COLOR_SUCCESS // 绿色 - 优秀
    if (latency < 100) return COLOR_SKY_BLUE // 蓝色 - 良好
    if (latency < 200) return COLOR_WARNING // 橙色 - 一般
    return COLOR_DANGER // 红色 - 较差
  }
}
