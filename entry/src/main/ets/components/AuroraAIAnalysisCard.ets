// ============================================
// Aurora WiFi V2 — AI 分析卡片组件
// API Level: 23+
// ============================================

import {
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  // 毛玻璃色彩
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_GLASS_DARK_BORDER,
  // 功能色
  COLOR_SUCCESS,
  COLOR_WARNING,
  COLOR_DANGER,
  // 文字色
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY
} from '@wifi-analyzer/design-system'

// ============================================
// AI 网络分析卡片
// ============================================

@Component
export struct AuroraAIAnalysisCard {
  @Prop cardTitle: string = ''
  @Prop analysisResult: string = ''
  @Prop cardSuggestion: string = ''
  @Prop healthScore: number = 85 // 0-100
  @Prop cardType: string = 'analysis'

  private getScoreColor(): string {
    if (this.healthScore >= 80) return COLOR_SUCCESS
    if (this.healthScore >= 60) return COLOR_WARNING
    return COLOR_DANGER
  }

  private getTypeIcon(): Resource {
    switch (this.cardType) {
      case 'warning': return $r('app.media.ic_warning')
      case 'suggestion': return $r('app.media.ic_tip')
      default: return $r('app.media.ic_ai_assistant')
    }
  }

  private getTypeBgColor(): string {
    switch (this.cardType) {
      case 'warning': return COLOR_DANGER
      case 'suggestion': return COLOR_GLASS_AURORA_LIGHT
      default: return COLOR_SUCCESS
    }
  }

  build() {
    Column({ space: 16 }) {
      // 标题行
      Row({ space: 12 }) {
        // 图标
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(40)
            .height(40)
            .fill(this.getTypeBgColor())
          Image(this.getTypeIcon())
            .width(20)
            .height(20)
            .fillColor(this.cardType === 'warning' ? COLOR_DANGER : COLOR_AURORA_PRIMARY)
        }

        Column({ space: 2 }) {
          Text(this.cardTitle)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLOR_TEXT_GLASS_PRIMARY)
          Text(this.analysisResult)
            .fontSize(13)
            .fontColor(COLOR_TEXT_GLASS_SECONDARY)
        }

        Blank()

        // 健康分数
        if (this.healthScore > 0) {
          Column() {
            Text(String(this.healthScore))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getScoreColor())
            Text($r('app.string.health_score_unit'))
              .fontSize(10)
              .fontColor(COLOR_TEXT_GLASS_TERTIARY)
          }
        }
      }

      // 建议内容
      if (this.cardSuggestion !== '') {
        Row() {
          Image($r('app.media.ic_tip'))
            .width(16)
            .height(16)
            .fillColor(COLOR_AURORA_LIGHT)
          Text(this.cardSuggestion)
            .fontSize(13)
            .fontColor(COLOR_TEXT_GLASS_SECONDARY)
            .layoutWeight(1)
            .margin({ left: 8 })
        }
        .padding(12)
        .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
        .borderRadius(12)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLOR_GLASS_CARD)
    .borderRadius(16)
    .border({
      width: 1,
      color: this.cardType === 'warning' ? COLOR_DANGER : COLOR_GLASS_BORDER_LIGHT,
      radius: 16
    })
  }
}
