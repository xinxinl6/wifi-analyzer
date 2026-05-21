import { COLOR_PRIMARY, COLOR_SUCCESS, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY,
  COLOR_TEXT_TERTIARY, COLOR_TEXT_DISABLED, COLOR_SURFACE, COLOR_CARD_SHADOW,
  COLOR_CHART_GRID,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XL, CARD_RADIUS, CARD_SHADOW_RADIUS,
  getSmallGaugeSize, getSmallGaugeStrokeWidth, getSignalGaugeCircumference } from '@wifi-analyzer/design-system'

@Component
export struct DashboardConnectionCard {
  @Prop isDarkMode: boolean = false
  @Prop connected: boolean = false
  @Prop ssid: string = ''
  @Prop signalLevel: number = 0
  @Prop signalLevelBg: string = ''
  @Prop isScanning: boolean = false
  @Prop bssid: string = ''
  @Prop freq: number = 0
  @Prop channel: number = 0
  @Prop dashArray: [number, number] = [0, 1]
  @Prop signalColor: string = ''

  build() {
    Row({ space: SPACE_XL }) {
      // 左侧：WiFi 图标 + 状态信息
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(52).height(52).fill(COLOR_CHART_GRID)
        Image($r('app.media.ic_wifi'))
          .width(26).height(26)
          .fillColor(this.connected ? COLOR_PRIMARY : COLOR_TEXT_DISABLED)
      }.width(52).height(52)

      Column({ space: 6 }) {
        // 状态标签行
        Row({ space: 6 }) {
          Text(this.isScanning ? $r('app.string.scanning') : (this.connected ? $r('app.string.connected') : $r('app.string.not_connected')))
            .fontSize(FONT_SIZE_SM)
            .fontColor(this.connected ? COLOR_SUCCESS : COLOR_TEXT_TERTIARY)
            .fontWeight(FONT_WEIGHT_MEDIUM)

          // 已连接时显示绿色圆点
          if (this.connected) {
            Circle().width(6).height(6).fill(COLOR_SUCCESS)
          }
        }

        // SSID 名称（主标题）
        Text(this.connected ? this.ssid : $r('app.string.no_network'))
          .fontSize(FONT_SIZE_3XL)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(this.connected ? COLOR_TEXT_PRIMARY : COLOR_TEXT_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 副信息行：BSSID · 频率 · 信道（仅已连接时显示）
        // 对比度要求 > 4.5:1，使用 #64748B
        if (this.connected) {
          Text(`${this.bssid || '--'} · ${this.freq > 0 ? this.freq + 'GHz' : '--'} · CH ${this.channel > 0 ? String(this.channel) : '--'}`)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_TEXT_SECONDARY)
            .margin({ top: 1 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .constraintSize({ minWidth: 0 })

      // 右侧：信号强度环形图（仅已连接时显示）
      if (this.connected) {
        Stack({ alignContent: Alignment.Center }) {
          // 背景轨道
          Circle().width(getSmallGaugeSize()).height(getSmallGaugeSize())
            .stroke(COLOR_CHART_GRID).strokeWidth(getSmallGaugeStrokeWidth()).fillOpacity(0)

          // 进度弧
          Circle().width(getSmallGaugeSize()).height(getSmallGaugeSize())
            .stroke(this.signalColor)
            .strokeWidth(getSmallGaugeStrokeWidth())
            .fillOpacity(0)
            .strokeDashArray(this.dashArray)
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ angle: -90 })
        }.width(getSmallGaugeSize()).height(getSmallGaugeSize())
      }
    }
    .width('100%')
    .padding(SPACE_XL)
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(CARD_RADIUS + 4)
    .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
  }
}
