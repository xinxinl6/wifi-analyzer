import { COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_TEXT_DISABLED, COLOR_SURFACE, COLOR_CARD_SHADOW, COLOR_CHART_GRID,
  COLOR_SIGNAL_EXCELLENT, COLOR_SIGNAL_GOOD, COLOR_SIGNAL_FAIR, COLOR_SIGNAL_POOR,
  COLOR_SIGNAL_EXCELLENT_BG, COLOR_SIGNAL_GOOD_BG, COLOR_SIGNAL_FAIR_BG, COLOR_SIGNAL_POOR_BG,
  SIGNAL_THRESHOLD_EXCELLENT, SIGNAL_THRESHOLD_GOOD, SIGNAL_THRESHOLD_FAIR,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD, FONT_WEIGHT_NORMAL,
  SPACE_XL, SPACE_XS, SPACE_SM, SPACE_LG, SPACE_MD, SPACE_XS,
  CARD_RADIUS, CARD_SHADOW_RADIUS, RADIUS_FULL,
  getSignalGaugeSize, getSignalGaugeStrokeWidth, getSignalGaugeCircumference } from '@wifi-analyzer/design-system'

@Component
export struct DashboardSignalCard {
  @Prop isDarkMode: boolean = false
  @Prop signalLevel: number = 0
  @Prop signalLabel: Resource = $r('app.string.signal_poor')
  @Prop signalColor: string = COLOR_SIGNAL_POOR
  @Prop signalLevelBg: string = COLOR_SIGNAL_POOR_BG
  @Prop cachedDashArray: [number, number] = [0, 1]
  @Prop connected: boolean = false

  // 信号等级指示器项（带背景色的圆点+文字）
  @Builder SignalIndicator(label: Resource, dotColor: string, bgColor: string, active: boolean) {
    Row({ space: 8 }) {
      Circle()
        .width(10).height(10)
        .fill(active ? dotColor : COLOR_TEXT_DISABLED)

      Text(label)
        .fontSize(FONT_SIZE_LG)
        .fontColor(active ? COLOR_TEXT_PRIMARY : COLOR_TEXT_SECONDARY)
        .fontWeight(active ? FONT_WEIGHT_MEDIUM : FONT_WEIGHT_NORMAL)
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(RADIUS_FULL)
    .backgroundColor(active ? bgColor : 'transparent')
    .justifyContent(FlexAlign.End)
  }

  build() {
    Column({ space: SPACE_LG }) {
      // 标题栏
      Row() {
        Text($r('app.string.signal_strength'))
          .fontSize(FONT_SIZE_XL)
          .fontColor(COLOR_TEXT_SECONDARY)
          .fontWeight(FONT_WEIGHT_MEDIUM)

        Blank()

        // 信号等级标签（带背景）— 未连接时显示"无信号"灰色标签
        Text(this.connected ? this.signalLabel : $r('app.string.no_signal'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(this.connected ? this.signalColor : COLOR_TEXT_TERTIARY)
          .fontWeight(FONT_WEIGHT_BOLD)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(RADIUS_FULL)
          .backgroundColor(this.connected ? this.signalLevelBg : COLOR_CHART_GRID)
      }
      .width('100%')

      // 仪表盘 + 信号等级列表
      Row({ space: SPACE_XL }) {
        // 左侧：大号环形仪表（响应式尺寸）
        Stack({ alignContent: Alignment.Center }) {
          // 外圈轨道
          Circle().width(getSignalGaugeSize()).height(getSignalGaugeSize())
            .stroke(COLOR_CHART_GRID).strokeWidth(getSignalGaugeStrokeWidth()).fillOpacity(0)

          // 进度弧（未连接时为空环）
          Circle().width(getSignalGaugeSize()).height(getSignalGaugeSize())
            .stroke(this.connected ? this.signalColor : COLOR_TEXT_TERTIARY)
            .strokeWidth(getSignalGaugeStrokeWidth())
            .fillOpacity(0)
            .strokeDashArray(this.connected ? this.cachedDashArray : [0, getSignalGaugeCircumference()])
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ angle: -90 })

          // 中心数值 — 未连接时显示"--"
          Column({ space: 2 }) {
            Text(this.connected ? String(this.signalLevel) : '--')
              .fontSize(FONT_SIZE_4XL)
              .fontWeight(FONT_WEIGHT_BOLD)
              .fontColor(this.connected ? COLOR_TEXT_PRIMARY : COLOR_TEXT_TERTIARY)
            Text('dBm')
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_TEXT_SECONDARY)
          }
        }
        .width(getSignalGaugeSize())
        .height(getSignalGaugeSize())

        // 右侧：信号等级指示器
        Column({ space: 14 }) {
          this.SignalIndicator($r('app.string.signal_excellent'), COLOR_SIGNAL_EXCELLENT, COLOR_SIGNAL_EXCELLENT_BG, this.connected && this.signalLevel > SIGNAL_THRESHOLD_EXCELLENT)
          this.SignalIndicator($r('app.string.signal_good'), COLOR_SIGNAL_GOOD, COLOR_SIGNAL_GOOD_BG, this.connected && this.signalLevel > SIGNAL_THRESHOLD_GOOD && this.signalLevel <= SIGNAL_THRESHOLD_EXCELLENT)
          this.SignalIndicator($r('app.string.signal_fair'), COLOR_SIGNAL_FAIR, COLOR_SIGNAL_FAIR_BG, this.connected && this.signalLevel > SIGNAL_THRESHOLD_FAIR && this.signalLevel <= SIGNAL_THRESHOLD_GOOD)
          this.SignalIndicator($r('app.string.signal_poor'), COLOR_SIGNAL_POOR, COLOR_SIGNAL_POOR_BG, this.connected && this.signalLevel <= SIGNAL_THRESHOLD_FAIR)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.End)
        .justifyContent(FlexAlign.Center)
        .constraintSize({ minWidth: 0 })
      }
      .width('100%')
    }
    .width('100%')
    .padding(SPACE_XL)
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(CARD_RADIUS + 4)
    .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
  }
}
