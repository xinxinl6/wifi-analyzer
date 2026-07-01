// =============================================
// SpeedTestSection — HM7 沉浸光感网速测试 v5.1
// 接入 SpeedTestEngine 真实多线程持续测速
// v5.1: 完整结果存储、真实抖动、bufferbloat、持久化历史
// =============================================

import {
  RADIUS_2XL, RADIUS_XL, RADIUS_FULL,
  adaptiveTextPrimary, adaptiveTextSecondary,
  adaptivePrimaryLight, adaptivePrimary, adaptivePrimaryBg,
  adaptiveCardDarkGlass, adaptiveDivider, adaptiveBackgroundList,
  adaptiveSuccess, adaptiveInfo, adaptiveWarning, adaptiveDanger,
  adaptiveBtnBg
} from '@wifi-analyzer/design-system'
import { SpeedTestEngine, SpeedTestCallbacks, SERVER_NODES } from '@wifi-analyzer/speed-test'
import { SpeedTestResult, RouterManager } from '@wifi-analyzer/core'
import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'

const STORE_NAME: string = 'WifiAnalyzerSpeedTest'
const HISTORY_KEY: string = 'speed_test_history'
const MAX_HISTORY: number = 50

interface SpeedGrade {
  label: string
  color: string
}

@ComponentV2
export struct SpeedTestSection {
  @Param isDark: boolean = true
  @Param showBackButton: boolean = false
  @Local testing: boolean = false
  @Local dl: number = 0
  @Local ul: number = 0
  @Local ping: number = 0
  @Local progress: number = 0
  @Local done: boolean = false
  @Local phase: ResourceStr = $r('app.string.speed_ready')
  @Local isPressed: boolean = false
  @Local result: SpeedTestResult | null = null
  @Local history: SpeedTestResult[] = []
  @Local rawPhase: string = 'idle'  // 原始阶段名：selecting/ping/download/upload/done

  // 仪表盘大数字：下载阶段显示dl，上传阶段显示ul
  private get gaugeSpeed(): number {
    if (this.rawPhase === 'upload') return this.ul
    return this.dl
  }

  // 运行时加载资源字符串
  private resStr(key: string, fallback: string = ''): string {
    try {
      return getContext().resourceManager.getStringByNameSync(key)
    } catch (_e) {
      return fallback
    }
  }

  // 速度等级
  private speedGrade(): SpeedGrade {
    const s = this.dl
    if (s > 500) return { label: this.resStr('speed_grade_extreme', 'Extreme'), color: adaptiveSuccess(this.isDark) }
    if (s > 100) return { label: this.resStr('speed_grade_fast', 'Fast'), color: adaptiveInfo(this.isDark) }
    if (s > 20) return { label: this.resStr('speed_grade_normal', 'Normal'), color: adaptiveWarning(this.isDark) }
    if (s > 0) return { label: this.resStr('speed_grade_slow', 'Slow'), color: adaptiveDanger(this.isDark) }
    return { label: '', color: adaptiveTextSecondary(this.isDark) }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 0 }) {
          // 标题
          Row() {
            if (this.showBackButton) {
              Row() {
                Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark))
              }
              .width(36).height(36).justifyContent(FlexAlign.Center).borderRadius(8)
              .backgroundColor(adaptiveBtnBg(this.isDark))
              .margin({ right: 12 })
              .onClick(() => { RouterManager.goBack() })
            }
            Column({ space: 2 }) {
              Text($r('app.string.speed_network'))
                .fontSize(28).fontWeight(800)
                .fontColor(adaptiveTextPrimary(this.isDark)).letterSpacing(-0.5)
            }
            Blank()
            if (this.done) {
              Text(this.speedGrade().label)
                .fontSize(12).fontWeight(600)
                .fontColor(this.speedGrade().color)
                .padding({ left: 12, right: 14, top: 6, bottom: 6 })
                .borderRadius(RADIUS_FULL)
                .backgroundColor(this.speedGrade().color + '20')
            }
          }.width('100%').padding({ top: this.showBackButton ? 44 : 56, bottom: 20 })

          // 仪表盘区域
          this.gauge()

          // 三指标
          Row({ space: 10 }) {
            Column({ space: 2 }) {
              Text(this.testing || this.done ? this.f(this.dl) : '--')
                .fontSize(20).fontWeight(700)
                .fontColor(adaptiveInfo(this.isDark))
                .fontFamily('HarmonyOS Sans Mono')
              Text($r('app.string.unit_mbps')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
              Text($r('app.string.speed_download')).fontSize(10).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(500).margin({ top: 2 })
            }.layoutWeight(1).height(72).padding(12)
            .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
            .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
            .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
            .clip(true)

            Column({ space: 2 }) {
              Text(this.testing || this.done ? this.f(this.ul) : '--')
                .fontSize(20).fontWeight(700)
                .fontColor(adaptiveSuccess(this.isDark))
                .fontFamily('HarmonyOS Sans Mono')
              Text($r('app.string.unit_mbps')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
              Text($r('app.string.speed_upload')).fontSize(10).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(500).margin({ top: 2 })
            }.layoutWeight(1).height(72).padding(12)
            .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
            .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
            .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
            .clip(true)

            Column({ space: 2 }) {
              Text(this.testing || this.done ? `${this.ping}` : '--')
                .fontSize(20).fontWeight(700)
                .fontColor(adaptiveWarning(this.isDark))
                .fontFamily('HarmonyOS Sans Mono')
              Text($r('app.string.unit_ms')).fontSize(9).fontColor(adaptiveTextSecondary(this.isDark))
              Text($r('app.string.speed_latency')).fontSize(10).fontColor(adaptiveTextSecondary(this.isDark)).fontWeight(500).margin({ top: 2 })
            }.layoutWeight(1).height(72).padding(12)
            .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
            .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
            .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
            .clip(true)
          }.width('100%').margin({ top: 12 })

          // 测试按钮
          this.testButton()

          // 测试结果
          if (this.done) {
            this.resultCard()
          }

          // 历史记录
          if (this.history.length > 0 && !this.testing) {
            this.historySection()
          }

          // 使用说明
          if (!this.testing && !this.done) {
            this.infoCard()
          }

          Row().height(80)
        }.width('100%').padding({ left: 16, right: 16 })
      }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off).width('100%')
        .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: adaptiveBackgroundList(this.isDark)
    })
  }

  // ── 仪表盘：大数字 + 圆环进度 ──
  @Builder gauge() {
    Column({ space: 4 }) {
      // 速度展示
      Row() {
        Text(this.testing || this.done ? this.f(this.gaugeSpeed) : '--')
          .fontSize(64).fontWeight(800)
          .fontColor(adaptivePrimaryLight(this.isDark))
          .fontFamily('HarmonyOS Sans Mono')
          .lineHeight(64)
        Text($r('app.string.unit_mbps'))
          .fontSize(20).fontWeight(500)
          .fontColor(adaptiveTextSecondary(this.isDark))
          .margin({ left: 6 })
      }

      // 测试状态
      Text(this.testing ? this.phase : this.done ? $r('app.string.speed_complete') : $r('app.string.speed_start_hint'))
        .fontSize(13)
        .fontColor(this.testing ? adaptivePrimaryLight(this.isDark)
          : this.done ? adaptiveSuccess(this.isDark)
          : adaptiveTextSecondary(this.isDark))
        .margin({ top: 4 })

      // 进度条
      if (this.testing) {
        Column() {
          Column()
            .width(`${this.progress * 100}%`).height(4)
            .backgroundColor(adaptivePrimaryLight(this.isDark))
            .borderRadius(2)
            .animation({ duration: 200, curve: Curve.Friction })
        }
        .width('60%').height(4)
        .backgroundColor(adaptiveDivider(this.isDark))
        .borderRadius(2)
        .margin({ top: 24 })
      }
    }
    .width('100%').padding({ top: 20, bottom: 32 }).alignItems(HorizontalAlign.Center)
    .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_2XL)
    .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
    .clip(true)
  }

  // ── 测试按钮（HM7 光感 + 物理按动） ──
  @Builder testButton() {
    Button({ type: ButtonType.Capsule }) {
      Row({ space: 8 }) {
        if (this.testing) {
          LoadingProgress()
            .width(18).height(18)
            .color(Color.White)
        }
        Text(this.testing ? $r('app.string.speed_testing') : $r('app.string.speed_start'))
          .fontSize(16).fontWeight(600)
      }
    }
    .width('100%').height(52)
    .fontColor(Color.White)
    .backgroundColor(this.testing
      ? adaptiveTextSecondary(this.isDark)
      : adaptivePrimaryLight(this.isDark))
    .borderRadius(RADIUS_FULL)
    .margin({ top: 24 })
    .scale({ x: this.isPressed ? 0.96 : 1, y: this.isPressed ? 0.96 : 1 })
    .shadow({
      radius: this.testing ? 0 : 12,
      color: this.testing ? 'transparent' : 'rgba(49,122,247,0.25)',
      offsetY: this.testing ? 0 : 4
    })
    .onClick(() => {
      if (!this.testing) {
        this.start()
      }
    })
    .animation({ duration: 150, curve: Curve.Friction })
  }

  // ── 结果卡片 ──
  @Builder resultCard() {
    Column({ space: 12 }) {
      // 状态行
      Row({ space: 6 }) {
        Circle().width(8).height(8).fill(adaptiveSuccess(this.isDark))
        Text($r('app.string.speed_complete'))
          .fontSize(15).fontWeight(600)
          .fontColor(adaptiveSuccess(this.isDark))
        Blank()
        Text() {
          Span($r('app.string.speed_grade'))
          Span(' ' + this.speedGrade().label)
        }
          .fontSize(12).fontColor(this.speedGrade().color)
      }.width('100%')

      // 结果列表
      Column({ space: 2 }) {
        this.rRow($r('app.string.speed_download_speed'), this.dl, $r('app.string.unit_mbps'), adaptiveInfo(this.isDark), '⬇')
        Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))
        this.rRow($r('app.string.speed_upload_speed'), this.ul, $r('app.string.unit_mbps'), adaptiveSuccess(this.isDark), '⬆')
        Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))
        this.rRow($r('app.string.speed_network_latency'), this.ping, $r('app.string.unit_ms'), this.ping < 20
          ? adaptiveSuccess(this.isDark)
          : this.ping < 50 ? adaptiveWarning(this.isDark)
          : adaptiveDanger(this.isDark), '⏱')
        Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))
        this.rRow($r('app.string.speed_jitter'), this.result?.jitterMs ?? 0, $r('app.string.unit_ms'), adaptiveTextSecondary(this.isDark), '~')
        Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))
        this.rRow($r('app.string.speed_download_full_latency'), this.result?.bufferbloatDownloadMs ?? 0, $r('app.string.unit_ms'),
          (this.result?.bufferbloatDownloadMs ?? 0) < 10 ? adaptiveSuccess(this.isDark) :
          (this.result?.bufferbloatDownloadMs ?? 0) < 30 ? adaptiveWarning(this.isDark) :
            adaptiveDanger(this.isDark), '⇩')
        Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))
        this.rRow($r('app.string.speed_upload_full_latency'), this.result?.bufferbloatUploadMs ?? 0, $r('app.string.unit_ms'),
          (this.result?.bufferbloatUploadMs ?? 0) < 10 ? adaptiveSuccess(this.isDark) :
          (this.result?.bufferbloatUploadMs ?? 0) < 30 ? adaptiveWarning(this.isDark) :
            adaptiveDanger(this.isDark), '⇧')
        if (this.result?.serverName) {
          Column().width('100%').height(1).backgroundColor(adaptiveDivider(this.isDark))
          this.rRow($r('app.string.speed_server'), 0, '--', adaptiveTextSecondary(this.isDark), '🖥')
        }
      }.width('100%')
    }
    .width('100%').padding(18)
    .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
    .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
    .clip(true)
    .margin({ top: 16 })
    .animation({ duration: 300, curve: Curve.Friction })
  }

  @Builder rRow(label: Resource, value: number, unit: ResourceStr, accent: string, icon: string) {
    Row() {
      Text(icon)
        .fontSize(13)
      Text(label)
        .fontSize(12).fontColor(adaptiveTextSecondary(this.isDark)).margin({ left: 4 })
      Blank()
      if (unit === '--') {
        // 纯文本展示（如服务器名称）
        Text(this.result?.serverName ?? '--')
          .fontSize(12).fontWeight(500)
          .fontColor(accent)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      } else {
        Text(this.f(value))
          .fontSize(16).fontWeight(700)
          .fontColor(accent)
          .fontFamily('HarmonyOS Sans Mono')
        Row({ space: 2 }) {
          Text(unit)
            .fontSize(11).fontColor(adaptiveTextSecondary(this.isDark))
        }
      }
    }.width('100%').padding({ top: 10, bottom: 10 })
  }

  // ── 使用说明 ──
  @Builder infoCard() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Text('i')
          .fontSize(16).fontWeight(700)
          .fontColor(adaptiveTextSecondary(this.isDark))
        Text($r('app.string.speed_guide'))
          .fontSize(13).fontWeight(600)
          .fontColor(adaptiveTextSecondary(this.isDark))
      }
      Text($r('app.string.speed_guide_desc'))
        .fontSize(11).fontColor(adaptiveTextSecondary(this.isDark)).lineHeight(16)
    }
    .width('100%').padding(14)
    .backgroundColor(adaptiveCardDarkGlass(this.isDark)).borderRadius(RADIUS_XL)
    .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
    .clip(true)
    .margin({ top: 16 })
  }

  // ── 历史记录列表 ──
  @Builder historySection() {
    Column({ space: 8 }) {
      // 标题行（含清空按钮）
      Row() {
        Text($r('app.string.history'))
          .fontSize(15).fontWeight(700)
          .fontColor(adaptiveTextPrimary(this.isDark))
        Blank()
        Text($r('app.string.clear'))
          .fontSize(11).fontColor(adaptiveTextSecondary(this.isDark))
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .borderRadius(RADIUS_FULL)
          .borderWidth(1).borderColor(adaptiveDivider(this.isDark))
          .onClick(() => {
            this.history = []
            this.saveHistory()
          })
      }.width('100%')

      // 历史条目
      ForEach(this.history, (item: SpeedTestResult, index: number) => {
        Column() {
          Row() {
            // 时间
            Text(item.timeLabel)
              .fontSize(12).fontColor(adaptiveTextSecondary(this.isDark))
              .layoutWeight(1)
            // 下载
            Text(`⬇ ${this.f(item.downloadSpeed)}`)
              .fontSize(13).fontWeight(600)
              .fontColor(adaptiveInfo(this.isDark))
              .fontFamily('HarmonyOS Sans Mono')
            // 上传
            Text(`⬆ ${this.f(item.uploadSpeed)}`)
              .fontSize(13).fontWeight(600)
              .fontColor(adaptiveSuccess(this.isDark))
              .fontFamily('HarmonyOS Sans Mono')
              .margin({ left: 8 })
            // 延迟
            Text(`⏱ ${item.pingMs}ms`)
              .fontSize(11).fontColor(adaptiveTextSecondary(this.isDark))
              .fontFamily('HarmonyOS Sans Mono')
              .margin({ left: 6 })
          }.width('100%')
        }
        .width('100%').padding({ top: 10, bottom: 10, left: 12, right: 12 })
        .backgroundColor(adaptiveCardDarkGlass(this.isDark))
        .borderRadius(RADIUS_XL)
        .borderWidth(1).borderColor(adaptiveDivider(this.isDark)).borderStyle(BorderStyle.Solid)
        .margin({ top: index === 0 ? 0 : 6 })
      }, (item: SpeedTestResult, index: number): string => item.timestamp + '_' + index)
    }
    .width('100%')
    .margin({ top: 16 })
  }

  // ── 真实测速：接入 SpeedTestEngine ──
  private engine: SpeedTestEngine = new SpeedTestEngine()

  // ── 生命周期：加载历史 ──
  aboutToAppear(): void {
    this.loadHistory()
  }

  aboutToDisappear(): void {
    // 离开页面时取消测速，防止回调访问已销毁组件
    if (this.testing) {
      this.engine.cancel()
      this.testing = false
    }
  }

  // ── 持久化：加载历史记录 ──
  private async loadHistory(): Promise<void> {
    try {
      const ctx: common.Context = getContext(this) as common.Context
      const prefs: preferences.Preferences = await preferences.getPreferences(ctx, STORE_NAME)
      const jsonStr: string = prefs.getSync(HISTORY_KEY, '[]') as string
      this.history = JSON.parse(jsonStr) as SpeedTestResult[]
    } catch (_e) {
      this.history = []
    }
  }

  // ── 持久化：保存历史记录 ──
  private async saveHistory(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
      const prefs: preferences.Preferences = await preferences.getPreferences(ctx, STORE_NAME)
      const jsonStr: string = JSON.stringify(this.history)
      prefs.putSync(HISTORY_KEY, jsonStr)
      prefs.flush()
    } catch (_e) {
      // 静默失败
    }
  }

  private start(): void {
    if (this.testing) return
    this.testing = true; this.done = false; this.dl = 0; this.ul = 0; this.ping = 0; this.progress = 0; this.rawPhase = 'idle'

    const callbacks: SpeedTestCallbacks = {
      onPhaseChanged: (phase: string) => {
        this.rawPhase = phase
        this.phase = this.phaseLabel(phase)
      },
      onDownloadProgress: (speed: number) => { this.dl = speed; this.progress = 0.3 + speed * 0.001 },
      onUploadProgress: (speed: number) => { this.ul = speed; this.progress = 0.7 + speed * 0.001 },
      onPingResult: (ping: number, jitter: number) => {
        this.ping = ping; this.progress = 0.2
      },
      onComplete: (result: SpeedTestResult) => {
        this.result = result
        this.dl = result.downloadSpeed
        this.ul = result.uploadSpeed
        this.ping = result.pingMs
        this.progress = 1
        this.phase = $r('app.string.speed_complete')
        this.testing = false
        this.done = true
        // 添加到历史记录并持久化
        this.history = [result, ...this.history].slice(0, MAX_HISTORY)
        this.saveHistory()
      },
      onError: (error: string) => {
        this.phase = $r('app.string.speed_failed')
        this.testing = false
        this.done = true
      },
      onCancelled: () => {
        this.phase = $r('app.string.speed_cancelled')
        this.testing = false
      }
    }

    // 使用自动选路 + http 模式
    this.engine.startTest('auto', 'auto', 'http', callbacks)
  }

  private phaseLabel(p: string): Resource {
    switch (p) {
      case 'selecting': return $r('app.string.speed_select_node')
      case 'ping': return $r('app.string.speed_test_latency')
      case 'download': return $r('app.string.speed_test_download')
      case 'upload': return $r('app.string.speed_test_upload')
      case 'done': return $r('app.string.speed_complete')
      default: return $r('app.string.speed_ready')
    }
  }

  private f(v: number): string {
    return v >= 100 ? v.toFixed(0) : v >= 1 ? v.toFixed(1) : '0.0'
  }
}
