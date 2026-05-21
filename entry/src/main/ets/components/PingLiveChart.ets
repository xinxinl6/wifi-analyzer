// Ping 实时折线图表组件

import { adaptiveTextTertiary, COLOR_SKY_BLUE, COLOR_SUCCESS, COLOR_DANGER, COLOR_CHART_GRID, COLOR_CHART_GRID_DARK, COLOR_TEXT_DISABLED, COLOR_AURORA_PRIMARY } from '@wifi-analyzer/design-system'
import { PingResult } from './PingTestPage'
import { FONT_WEIGHT_MEDIUM } from '@wifi-analyzer/design-system'

/**
 * PingLiveChart - 实时折线图表组件
 * 显示 Ping 结果的实时折线图
 */
@Component
export struct PingLiveChart {
  @Prop isDarkMode: boolean = false
  @Prop chartData: PingResult[] = []
  @Prop chartMaxY: number = 100
  @Prop chartAvgMs: number = 0
  @Prop chartMinMs: number = 0
  @Prop chartMaxMs: number = 0
  @Prop lastPingResult: PingResult | null = null

  // 函数属性：判断是否为最佳/最差点
  isChartBest: (item: PingResult) => boolean = () => false
  isChartWorst: (item: PingResult) => boolean = () => false

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      // ===== 背景层：渐变填充区域 =====
      if (this.chartData.length >= 2) {
        this.ChartAreaPath(110)
      }

      // ===== 网格层：2条水平参考线 + Y轴标签 =====
      Column({ space: 0 }) {
        // 上半区 + 上刻度
        Row({ space: 6 }) {
          Text(String(Math.round(this.chartMaxY))).fontSize(9).fontColor(adaptiveTextTertiary(this.isDarkMode)).opacity(0.5).width(24).textAlign(TextAlign.End)
          Row().width('100%').height(1).backgroundColor(this.isDarkMode ? COLOR_CHART_GRID_DARK : COLOR_CHART_GRID).margin({ left: 2 })
        }.layoutWeight(1).alignItems(VerticalAlign.Center)

        // 下半区 + 下刻度（0）
        Row({ space: 6 }) {
          Text('0').fontSize(9).fontColor(adaptiveTextTertiary(this.isDarkMode)).opacity(0.5).width(24).textAlign(TextAlign.End)
          Row().width('100%').height(1).backgroundColor(this.isDarkMode ? COLOR_CHART_GRID_DARK : COLOR_CHART_GRID).margin({ left: 2 })
        }.layoutWeight(1).alignItems(VerticalAlign.Center)
      }
      .width('100%').height(110)

      // ===== 平均值虚线参考 =====
      if (this.chartAvgMs > 0 && this.chartMaxY > 0) {
        Column() {
          Row({ space: 4 }) {
            Text($r('app.string.avg_label')).fontSize(9).fontColor(COLOR_SKY_BLUE).opacity(0.7)
            Text(String(Math.round(this.chartAvgMs * 10) / 10) + 'ms')
              .fontSize(9).fontColor(COLOR_SKY_BLUE).fontWeight(FONT_WEIGHT_MEDIUM).opacity(0.8)
          }
          // 虚线
          Row()
            .width('100%')
            .height(1)
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: 1 }, style: BorderStyle.Dashed, color: COLOR_SKY_BLUE })
            .opacity(0.25)
        }
        .width('100%')
        .position({ x: 28, y: Math.max(0, (1 - this.chartAvgMs / this.chartMaxY) * 110 - 5) })
      }

      // ===== 数据点 + 折线层 =====
      Row() {
        ForEach(this.chartData, (item: PingResult, index: number) => {
          Column() {
            // 成功数据点
            if (item.status === 'success') {
              // 垂直连线到 X 轴（增强可见度）
              Column()
                .width(2)
                .height(Math.max(1, (item.timeMs / this.chartMaxY) * 110))
                .backgroundColor(
                  this.isChartBest(item) ? COLOR_SUCCESS + '55' :
                    (this.isChartWorst(item) ? COLOR_DANGER + '55' : COLOR_AURORA_PRIMARY + '35')
                )
                .margin({ bottom: 0 })

              // 数据圆点
              Stack({ alignContent: Alignment.Center }) {
                // 外发光
                Circle().width(10).height(10).fill(
                  this.isChartBest(item) ? COLOR_SUCCESS + '35' :
                    (this.isChartWorst(item) ? COLOR_DANGER + '35' : COLOR_AURORA_PRIMARY + '30')
                )
                // 内实心点
                Circle().width(5).height(5).fill(
                  this.isChartBest(item) ? COLOR_SUCCESS :
                    (this.isChartWorst(item) ? COLOR_DANGER : COLOR_SKY_BLUE)
                )
              }

              // 最新点放大高亮
              if (index === this.chartData.length - 1) {
                Circle()
                  .width(9).height(9)
                  .fill(Color.Transparent)
                  .strokeWidth(2)
                  .stroke(COLOR_SKY_BLUE)
                  .position({ x: -2, y: -2 })
              }
            } else {
              // 失败/超时 — X 标记
              Column().height(4).layoutWeight(1)
              Text(item.status === 'timeout' ? '—' : '×')
                .fontSize(10).fontColor(COLOR_TEXT_DISABLED)
                .fontWeight(FONT_WEIGHT_MEDIUM)
            }
          }
          .alignItems(HorizontalAlign.Center)
          .width(0)
          .layoutWeight(1)
        }, (item: PingResult, index: number): string => String(index + '_' + item.timestamp))
      }
      .width('100%')
      .height(110)
      .padding({ left: 28, right: 4 })
      .alignItems(VerticalAlign.Bottom)

      // ===== 底部 X 轴序号 =====
      Row() {
        ForEach(this.chartData, (item: PingResult, index: number) => {
          Text(String(index + 1))
            .fontSize(8)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
            .opacity(index % 5 === 0 || index === this.chartData.length - 1 ? 0.6 : 0.25)
            .width(0).layoutWeight(1)
            .textAlign(TextAlign.Center)
        }, (item: PingResult, index: number): string => String(index + '_' + item.timestamp))
      }
      .width('100%')
      .padding({ left: 28, right: 4 })
      .position({ x: 0, y: 112 })
    }
    .width('100%')
    .height(126)
  }

  // 面积图（用多列模拟渐变填充）
  @Builder
  ChartAreaPath(h: number) {
    Row() {
      ForEach(this.chartData, (item: PingResult, index: number) => {
        if (item.status === 'success') {
          Column()
            .width('100%')
            .height(Math.max(1, (item.timeMs / this.chartMaxY) * h))
            .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,' + String(0.12 + (index / this.chartData.length) * 0.10) + ')' : 'rgba(14,165,233,' + String(0.14 + (index / this.chartData.length) * 0.12) + ')')
            .borderRadius({ topLeft: 2, topRight: 2 })
            .margin({ top: h - Math.max(1, (item.timeMs / this.chartMaxY) * h) })
            .layoutWeight(1)
            .alignItems(HorizontalAlign.End)
        } else {
          Column()
            .layoutWeight(1)
            .alignItems(HorizontalAlign.End)
        }
      }, (item: PingResult, index: number): string => String('area_' + index + '_' + item.timestamp))
    }
    .width('100%').height(h).padding({ left: 28, right: 4 }).clip(true)
  }
}
