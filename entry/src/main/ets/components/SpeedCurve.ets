// SpeedCurve.ets - 实时速度曲线组件
// Canvas 绘制折线图 + 渐变填充区域

import {
  COLOR_SKY_BLUE,
  COLOR_SUCCESS,
  COLOR_GLASS_WHITE,
  COLOR_GLASS_DARK_CARD,
  COLOR_SKY_BLUE_LIGHT,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  FONT_SIZE_XS,
  GLASS_BLUR_LG,
  GLASS_SHADOW_MD,
  COLOR_OVERLAY
} from '@wifi-analyzer/design-system'

export interface SpeedSample {
  timeMs: number
  speedMbps: number
  phase: string  // 'download' | 'upload'
}

interface CurvePoint {
  x: number
  y: number
}

@Component
export struct SpeedCurve {
  @Prop @Watch('onSamplesChanged') speedSamples: SpeedSample[] = []
  @Prop isTesting: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  build() {
    Column() {
      Row() {
        Text('实时速度曲线')
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
          .margin({ bottom: 6 })
      }
      .width('100%')

      Canvas(this.context)
        .width('100%')
        .height(120)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(12)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_MD, color: this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_SKY_BLUE_LIGHT })
  }

  private drawCurve(): void {
    const ctx: CanvasRenderingContext2D = this.context
    const width: number = ctx.width
    const height: number = ctx.height
    const padding: number = 8
    const innerW: number = width - padding * 2
    const innerH: number = height - padding * 2
    const samples: SpeedSample[] = this.speedSamples

    if (samples.length < 2) {
      // 不够点，画提示文字
      ctx.clearRect(0, 0, width, height)
      ctx.font = '10vp sans-serif'
      ctx.fillStyle = '#999999'
      ctx.textAlign = 'center'
      ctx.fillText('测速开始后将显示实时曲线', width / 2, height / 2)
      return
    }

    // 计算 Y 轴范围
    let maxSpeed: number = 0
    for (let i: number = 0; i < samples.length; i++) {
      maxSpeed = Math.max(maxSpeed, samples[i].speedMbps)
    }
    maxSpeed = Math.max(maxSpeed, 10) * 1.2 // +20% 余量

    // 清空画布
    ctx.clearRect(0, 0, width, height)

    // 网格线
    ctx.strokeStyle = this.isDarkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)'
    ctx.lineWidth = 0.5
    for (let g: number = 0; g <= 4; g++) {
      const y: number = padding + (innerH * g) / 4
      ctx.beginPath()
      ctx.moveTo(padding, y)
      ctx.lineTo(width - padding, y)
      ctx.stroke()
    }

    // 绘制下载折线
    this.drawPhaseLine(ctx, samples, 'download', COLOR_SKY_BLUE, innerW, innerH,
      padding, maxSpeed, height)
    // 绘制上传折线
    this.drawPhaseLine(ctx, samples, 'upload', COLOR_SUCCESS, innerW, innerH,
      padding, maxSpeed, height)
  }

  private drawPhaseLine(
    ctx: CanvasRenderingContext2D,
    samples: SpeedSample[],
    phase: string,
    color: string,
    innerW: number,
    innerH: number,
    padding: number,
    maxSpeed: number,
    height: number
  ): void {
    const points: CurvePoint[] = []
    let phaseCount: number = 0

    for (let i: number = 0; i < samples.length; i++) {
      if (samples[i].phase === phase) {
        phaseCount++
      }
    }
    if (phaseCount < 2) return

    // 收集该阶段的点
    let idx: number = 0
    for (let i: number = 0; i < samples.length; i++) {
      if (samples[i].phase === phase) {
        const px: number = padding + (innerW * idx) / (phaseCount - 1)
        const py: number = padding + innerH - (samples[i].speedMbps / maxSpeed) * innerH
        const pt: CurvePoint = { x: px, y: py }
        points.push(pt)
        idx++
      }
    }

    // 渐变填充
    const gradient: CanvasGradient = ctx.createLinearGradient(0, padding, 0, height - padding)
    gradient.addColorStop(0, color)
    gradient.addColorStop(1, 'rgba(255,255,255,0)')

    ctx.beginPath()
    ctx.moveTo(points[0].x, height - padding)
    for (let i: number = 0; i < points.length; i++) {
      ctx.lineTo(points[i].x, points[i].y)
    }
    ctx.lineTo(points[points.length - 1].x, height - padding)
    ctx.closePath()
    ctx.fillStyle = this.hexToRgba(color, 0.12)
    ctx.fill()

    // 折线
    ctx.beginPath()
    ctx.moveTo(points[0].x, points[0].y)
    for (let i: number = 1; i < points.length; i++) {
      ctx.lineTo(points[i].x, points[i].y)
    }
    ctx.strokeStyle = color
    ctx.lineWidth = 2
    ctx.stroke()

    // 数据点圆点
    for (let i: number = 0; i < points.length; i++) {
      ctx.beginPath()
      ctx.arc(points[i].x, points[i].y, 2.5, 0, Math.PI * 2)
      ctx.fillStyle = color
      ctx.fill()
    }
  }

  private hexToRgba(hex: string, alpha: number): string {
    if (hex.startsWith('#')) {
      const r: string = hex.slice(1, 3)
      const g: string = hex.slice(3, 5)
      const b: string = hex.slice(5, 7)
      return 'rgba(' + parseInt(r, 16) + ',' + parseInt(g, 16) + ',' + parseInt(b, 16) + ',' + alpha + ')'
    }
    return hex
  }

  private onSamplesChanged(): void {
    this.drawCurve()
  }
}
