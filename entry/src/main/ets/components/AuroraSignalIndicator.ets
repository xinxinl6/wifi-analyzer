// ============================================
// Aurora WiFi V2 — Aurora 信号强度指示器
// ============================================

import {
  SIGNAL_COLORS_AURORA,
  COLOR_TEXT_DISABLED
} from '@wifi-analyzer/design-system'

@Component
export struct AuroraSignalIndicator {
  @Prop signalLevel: string = 'none'
  @Prop signalLabel: string = ''
  @Prop showLabel: boolean = true
  @Prop indicatorSize: string = 'medium'

  private getBarColor(): string {
    const level = this.signalLevel
    if (level === 'excellent') return SIGNAL_COLORS_AURORA.excellent
    if (level === 'good') return SIGNAL_COLORS_AURORA.good
    if (level === 'fair') return SIGNAL_COLORS_AURORA.fair
    if (level === 'poor') return SIGNAL_COLORS_AURORA.poor
    return SIGNAL_COLORS_AURORA.none
  }

  private getBarCount(): number {
    switch (this.signalLevel) {
      case 'excellent': return 4
      case 'good': return 3
      case 'fair': return 2
      case 'poor': return 1
      default: return 0
    }
  }

  private getBarWidth(): number {
    switch (this.indicatorSize) {
      case 'small': return 4
      case 'medium': return 6
      case 'large': return 8
      default: return 6
    }
  }

  build() {
    Row({ space: 4 }) {
      // 信号条
      Row({ space: 2 }) {
        ForEach([1, 2, 3, 4], (barIndex: number) => {
          Column()
            .width(this.getBarWidth())
            .height(6 + barIndex * 3)
            .borderRadius(2)
            .backgroundColor(barIndex <= this.getBarCount()
              ? this.getBarColor()
              : COLOR_TEXT_DISABLED)
        })
      }

      // 标签
      if (this.showLabel && this.signalLabel !== '') {
        Text(this.signalLabel)
          .fontSize(11)
          .fontColor(this.getBarColor())
          .margin({ left: 6 })
      }
    }
  }
}
