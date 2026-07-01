// IpCard — Ping 子组件（从 PingPage.ets 拆分）
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveTextCyan, adaptiveTextAmber,
  adaptiveCardBg, adaptiveCardDarkGlass, adaptiveBorderCyan,
  adaptiveDivider,
} from '@wifi-analyzer/design-system'

export class PingItem {
  index: number
  time: number
  status: 'success' | 'timeout'
  constructor(index: number, time: number, status: 'success' | 'timeout') {
    this.index = index; this.time = time; this.status = status
  }
}

@Component
export struct IpCard {
  @Prop idx: number = 1
  @Prop isDark: boolean = false
  @Prop ip: string = '—'
  @Prop sent: number = 0
  @Prop received: number = 0
  @Prop lost: number = 0
  @Prop lossRate: number = 0
  @Prop minTime: number = 0
  @Prop maxTime: number = 0
  @Prop avgTime: number = 0
  @Prop resultsJson: string = '[]'

  private getResults(): PingItem[] { try { return JSON.parse(this.resultsJson) } catch { return [] } }
  private lossColor(): string { return this.lost > 0 ? '#D94838' : '#5BA854' }
  private rttColor(t: number): string {
    if (t <= 0) return adaptiveTextTertiary(this.isDark)
    if (t < 30) return '#5EA1FF'
    if (t < 80) return adaptiveTextAmber(this.isDark)
    return '#DB6B42'
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 4 }) {
        Text('IP ' + String(this.idx)).fontSize(13).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
        Text(this.ip).fontSize(10).fontColor(adaptiveTextTertiary(this.isDark)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
      }.width('100%')

      Row() {
        Column({ space: 2 }) { Text(String(this.sent)).fontSize(16).fontWeight(800).fontColor(adaptiveTextCyan(this.isDark)).fontFamily('HarmonyOS Sans Mono'); Text($r('app.string.sent')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark)) }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column({ space: 2 }) { Text(String(this.lost)).fontSize(16).fontWeight(800).fontColor(this.lossColor()).fontFamily('HarmonyOS Sans Mono'); Text($r('app.string.lost_count')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark)) }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column({ space: 2 }) { Text(this.lossRate + '%').fontSize(16).fontWeight(800).fontColor(this.lossColor()).fontFamily('HarmonyOS Sans Mono'); Text($r('app.string.loss_rate')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark)) }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      }.width('100%')

      Divider().height(1).color(adaptiveDivider(this.isDark)).margin({ top: 2, bottom: 2 })

      Row() {
        Column({ space: 2 }) { Text(this.received > 0 ? this.minTime + ' ms' : '— ms').fontSize(16).fontWeight(800).fontColor('#5EA1FF').fontFamily('HarmonyOS Sans Mono'); Text($r('app.string.fastest')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark)) }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column({ space: 2 }) { Text(this.received > 0 ? this.maxTime + ' ms' : '— ms').fontSize(16).fontWeight(800).fontColor(adaptiveTextAmber(this.isDark)).fontFamily('HarmonyOS Sans Mono'); Text($r('app.string.slowest')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark)) }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        Column({ space: 2 }) { Text(this.received > 0 ? this.avgTime + ' ms' : '— ms').fontSize(16).fontWeight(800).fontColor(adaptiveTextPrimary(this.isDark)).fontFamily('HarmonyOS Sans Mono'); Text($r('app.string.average')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark)) }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      }.width('100%')

      if (this.getResults().length > 0) {
        Scroll() {
          Row({ space: 3 }) {
            ForEach(this.getResults().slice(-20), (r: PingItem) => {
              Rect().width(10).height(Math.max(3, r.status === 'success' ? Math.min(20, r.time * 0.5) : 3)).radius(1.5)
                .fill(r.status === 'success' ? this.rttColor(r.time) : 'rgba(128,128,128,0.3)')
            })
          }.padding({ left: 4, right: 4 }).alignItems(VerticalAlign.Bottom)
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).height(22)
      }
    }
    .layoutWeight(1).padding(12)
    .linearGradient({ angle: 135, colors: [[adaptiveCardDarkGlass(this.isDark), 0], [adaptiveCardBg(this.isDark), 1]] })
    .border({ width: 1, color: adaptiveBorderCyan(this.isDark), style: BorderStyle.Solid }).borderRadius(14)
  }
}
