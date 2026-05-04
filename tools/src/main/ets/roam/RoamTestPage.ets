// 漫游测试页面组件
// 界面：实时信号监测 + BSSID切换事件 + 漫游统计摘要 + 稳定性评分

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO,
  COLOR_ORANGE,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XXS, FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL, SPACE_2XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_SM, BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM,
} from '@wifi-analyzer/design-system'
import { BackButtonCapsule } from '@wifi-analyzer/design-system'
import {
  RoamTestEngine, RoamEvent, RoamTestConfig, RoamTestCallbacks,
  RoamTestInfo, RoamTestSummary, BssidRecord, WifiInfo,
} from '../roamtest/RoamTestEngine'
import { RouterManager } from '@wifi-analyzer/core'

// 信号等级信息
interface RssiLevel {
  label: string
  color: string
}

@Component
export struct RoamTestPage {
  // UI 状态：'idle' | 'testing' | 'summary'
  @State viewMode: string = 'idle'

  // 实时测试信息
  @State currentBssid: string = ''
  @State currentRssi: number = 0
  @State elapsedSec: number = 0
  @State totalSec: number = 60
  @State roamCount: number = 0
  @State avgRssi: number = 0
  @State bssidHistory: BssidRecord[] = []

  // 测试配置
  @State testDuration: number = 60
  @State currentSsid: string = ''

  // 测试结果摘要
  @State summary: RoamTestSummary | null = null

  // 漫游事件列表（展开/收起）
  @State showEvents: boolean = false

  // 引擎
  private engine: RoamTestEngine = new RoamTestEngine()

  // 获取资源字符串的辅助方法
  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch {
      return ''
    }
  }

  aboutToAppear(): void {
    this.loadCurrentInfo()
  }

  aboutToDisappear(): void {
    this.engine.stopTest()
  }

  // ==================== 业务逻辑 ====================

  async loadCurrentInfo(): Promise<void> {
    const info: WifiInfo = await this.engine.getCurrentInfo()
    this.currentBssid = info.bssid
    this.currentRssi = info.rssi
    this.currentSsid = info.ssid
  }

  startTest(): void {
    this.viewMode = 'testing'
    this.roamCount = 0
    this.elapsedSec = 0
    this.summary = null
    this.showEvents = false
    this.bssidHistory = []

    const config: RoamTestConfig = {
      intervalMs: 1000,
      durationSec: this.testDuration,
      targetBssid: ''
    }
    this.totalSec = this.testDuration

    const callbacks: RoamTestCallbacks = {
      onUpdate: (info: RoamTestInfo): void => {
        this.currentBssid = info.currentBssid
        this.currentRssi = info.currentRssi
        this.elapsedSec = info.elapsedSec
        this.totalSec = info.totalSec
        this.roamCount = info.roamCount
        this.avgRssi = info.avgRssi
        this.bssidHistory = info.bssidHistory
      },
      onRoamDetected: (event: RoamEvent): void => {
        // 漫游事件已通过 onUpdate 中的 roamCount 反映
      },
      onComplete: (testSummary: RoamTestSummary): void => {
        this.summary = testSummary
        this.viewMode = 'summary'
      },
      onError: (message: string): void => {
        this.viewMode = 'idle'
      }
    }

    this.engine.startTest(config, callbacks)
  }

  stopTest(): void {
    this.engine.stopTest()
    this.viewMode = 'summary'
  }

  formatDuration(sec: number): string {
    const m: number = Math.floor(sec / 60)
    const s: number = sec % 60
    if (m > 0) {
      return String(m) + ':' + String(s).padStart(2, '0')
    }
    return String(s) + 's'
  }

  getRssiLevel(rssi: number): RssiLevel {
    if (rssi >= -50) return { label: this.getString($r('app.string.rssi_excellent')), color: COLOR_SUCCESS }
    if (rssi >= -60) return { label: this.getString($r('app.string.rssi_good')), color: COLOR_INFO }
    if (rssi >= -70) return { label: this.getString($r('app.string.rssi_average')), color: COLOR_WARNING }
    return { label: this.getString($r('app.string.rssi_poor')), color: COLOR_DANGER }
  }

  getStabilityColor(score: number): string {
    if (score >= 80) return COLOR_SUCCESS
    if (score >= 60) return COLOR_WARNING
    return COLOR_DANGER
  }

  getStabilityLabel(score: number): string {
    if (score >= 90) return this.getString($r('app.string.stability_very_stable'))
    if (score >= 80) return this.getString($r('app.string.stability_stable'))
    if (score >= 60) return this.getString($r('app.string.rssi_average'))
    if (score >= 40) return this.getString($r('app.string.stability_unstable'))
    return this.getString($r('app.string.stability_very_unstable'))
  }

  // ==================== 页面入口 ====================
  build() {
    Column() {
      this.MainContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
    .padding({ top: SPACE_LG, bottom: SAFE_AREA_BOTTOM })
  }

  // ==================== 主内容 ====================
  @Builder MainContent() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 当前连接信息
        this.ConnectionCard()

        // 测试进行中：实时数据
        if (this.viewMode === 'testing') {
          this.TestingCard()
          this.BssidTimelineCard()
        }

        // 测试摘要
        if (this.viewMode === 'summary' && this.summary) {
          this.SummaryCard()
          this.RoamEventsSection()
        }

        // 空状态
        if (this.viewMode === 'idle') {
          this.IdleState()
          this.DurationSelector()
        }

        // 操作按钮
        this.ActionButtons()

        // 功能说明
        this.FeatureCard()
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // ==================== 当前连接信息 ====================
  @Builder ConnectionCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(40).height(40).fill('#FFF7ED')
          Image($r('app.media.ic_route')).width(22).height(22).fillColor(COLOR_ORANGE)
        }
        Column({ space: 2 }) {
          Text(this.currentSsid !== '' ? this.currentSsid : $r('app.string.wifi_connection'))
            .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          Row({ space: SPACE_SM }) {
            Text(this.currentBssid !== '' ? RoamTestEngine.formatBssid(this.currentBssid) : $r('app.string.not_connected'))
              .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
            Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
            Text(String(this.currentRssi) + ' dBm')
              .fontSize(FONT_SIZE_XS).fontColor(this.getRssiLevel(this.currentRssi).color)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
  }

  // ==================== 测试进行中卡片 ====================
  @Builder TestingCard() {
    Column({ space: SPACE_MD }) {
      // 环形进度 + 信号强度
      Row({ space: SPACE_XL }) {
        // 倒计时
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(80).height(80).fill(COLOR_DIVIDER)
          Text(this.formatDuration(this.totalSec - this.elapsedSec))
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_ORANGE).fontWeight(FONT_WEIGHT_BOLD)
        }
        .width(80).height(80)

        // 实时数据
        Column({ space: SPACE_SM }) {
          Row({ space: SPACE_XL }) {
            Column({ space: SPACE_XS }) {
              Text($r('app.string.signal_label')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
              Text(String(this.currentRssi) + ' dBm')
                .fontSize(FONT_SIZE_MD).fontColor(this.getRssiLevel(this.currentRssi).color)
                .fontWeight(FONT_WEIGHT_BOLD)
            }
            .alignItems(HorizontalAlign.Start)

            Column({ space: SPACE_XS }) {
              Text($r('app.string.avg_signal')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
              Text(String(this.avgRssi) + ' dBm')
                .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
            }
            .alignItems(HorizontalAlign.Start)

            Column({ space: SPACE_XS }) {
              Text($r('app.string.roam_label')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
              Text() {
                Span(String(this.roamCount))
                Span(' ')
                Span($r('app.string.times_suffix'))
              }
                .fontSize(FONT_SIZE_MD)
                .fontColor(this.roamCount === 0 ? COLOR_SUCCESS : COLOR_WARNING)
                .fontWeight(FONT_WEIGHT_BOLD)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 进度条
      Row() {
        Row()
          .width(this.elapsedSec > 0 && this.totalSec > 0
            ? Math.min(100, Math.round(this.elapsedSec / this.totalSec * 100)) + '%' : '0%')
          .height(4).backgroundColor(COLOR_ORANGE).borderRadius(2)
      }
      .width('100%').height(4).backgroundColor(COLOR_DIVIDER).borderRadius(2)

      Row({ space: SPACE_SM }) {
        Text() {
          Span($r('app.string.tested'))
          Span(' ' + this.formatDuration(this.elapsedSec))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        Blank()
        Text() {
          Span($r('app.string.total_duration'))
          Span(' ' + this.formatDuration(this.totalSec))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG).backgroundColor('#FFF7ED').borderRadius(RADIUS_2XL)
  }

  // ==================== BSSID 时间线 ====================
  @Builder BssidTimelineCard() {
    if (this.bssidHistory.length > 0) {
      Column({ space: SPACE_SM }) {
        Row() {
          Text($r('app.string.bssid_history'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          Blank()
          Text() {
            Span($r('app.string.recent_records'))
            Span(' ' + String(this.bssidHistory.length) + ' ')
            Span($r('app.string.records_suffix'))
          }
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .width('100%')

        // 信号强度可视化（用水平色条表示）
        Scroll() {
          Row({ space: 2 }) {
            ForEach(this.bssidHistory, (record: BssidRecord) => {
              Column() {
                Stack() {
                  Row()
                    .width(4)
                    .height(record.rssi > -40 ? 40 : record.rssi > -60 ? 32 : record.rssi > -70 ? 24 : 16)
                    .backgroundColor(this.getRssiLevel(record.rssi).color)
                    .borderRadius(2)
                }
              }
            }, (record: BssidRecord, index: number): string => String(index))
          }
          .width('100%')
          .padding({ top: SPACE_SM, bottom: SPACE_SM })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        // 图例
        Row({ space: SPACE_LG }) {
          Row({ space: SPACE_XS }) {
            Circle().width(8).height(8).fill(COLOR_SUCCESS)
            Text('>=-50').fontSize(FONT_SIZE_XXS).fontColor(COLOR_TEXT_TERTIARY)
          }
          Row({ space: SPACE_XS }) {
            Circle().width(8).height(8).fill(COLOR_INFO)
            Text('>=-60').fontSize(FONT_SIZE_XXS).fontColor(COLOR_TEXT_TERTIARY)
          }
          Row({ space: SPACE_XS }) {
            Circle().width(8).height(8).fill(COLOR_WARNING)
            Text('>=-70').fontSize(FONT_SIZE_XXS).fontColor(COLOR_TEXT_TERTIARY)
          }
          Row({ space: SPACE_XS }) {
            Circle().width(8).height(8).fill(COLOR_DANGER)
            Text('<-70').fontSize(FONT_SIZE_XXS).fontColor(COLOR_TEXT_TERTIARY)
          }
        }
        .width('100%')
      }
      .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
      .border({ width: 1, color: COLOR_BORDER })
    }
  }

  // ==================== 测试摘要卡片 ====================
  @Builder SummaryCard() {
    if (this.summary) {
      Column({ space: SPACE_LG }) {
      // 稳定性评分
      Row({ space: SPACE_XL }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(80).height(80).fill(this.getStabilityColor(this.summary.stabilityScore) + '20')
          Text(String(this.summary.stabilityScore))
            .fontSize(FONT_SIZE_3XL).fontColor(this.getStabilityColor(this.summary.stabilityScore))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        .width(80).height(80)

        Column({ space: SPACE_SM }) {
          Text($r('app.string.stability_score'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
          Text(this.getStabilityLabel(this.summary.stabilityScore))
            .fontSize(FONT_SIZE_SM).fontColor(this.getStabilityColor(this.summary.stabilityScore))
          Text() {
            Span($r('app.string.test_duration'))
            Span(': ' + this.formatDuration(Math.round(this.summary.totalDuration / 1000)))
          }
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')

      Divider().color(COLOR_DIVIDER)

      // 详细数据
      Row({ space: SPACE_XL }) {
        Column({ space: SPACE_XS }) {
          Text($r('app.string.roam_count')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text() {
            Span(String(this.summary.roamCount))
            Span(' ')
            Span($r('app.string.times_suffix'))
          }
            .fontSize(FONT_SIZE_2XL)
            .fontColor(this.summary.roamCount === 0 ? COLOR_SUCCESS : COLOR_WARNING)
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: SPACE_XS }) {
          Text($r('app.string.roaming_ap')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text() {
            Span(String(this.summary.bssidCount))
            Span(' ')
            Span($r('app.string.count_suffix'))
          }
            .fontSize(FONT_SIZE_2XL).fontColor(COLOR_INFO).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: SPACE_XS }) {
          Text($r('app.string.signal_range')).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(String(this.summary.minRssi) + '~' + String(this.summary.maxRssi))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
    }
  }

  // ==================== 漫游事件列表 ====================
  @Builder RoamEventsSection() {
    if (this.summary && this.summary.roamEvents.length > 0) {
      Column({ space: SPACE_SM }) {
      Row() {
        Text($r('app.string.roam_events_detail'))
          .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text(this.showEvents ? $r('app.string.collapse') : $r('app.string.expand'))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_ORANGE)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.showEvents = !this.showEvents })
      }
      .width('100%')

      if (this.showEvents) {
        ForEach(this.summary.roamEvents, (event: RoamEvent, index: number) => {
          this.RoamEventRow(event, index)
        }, (event: RoamEvent, index: number): string => String(index))
      } else {
        Text() {
          Span($r('app.string.total_roam_events'))
          Span(' ' + String(this.summary.roamEvents.length) + ' ')
          Span($r('app.string.roam_event_hint'))
        }
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
      }
    }
    .width('100%').padding(SPACE_LG).backgroundColor(COLOR_SURFACE).borderRadius(RADIUS_2XL)
    .border({ width: 1, color: COLOR_BORDER })
    }
  }

  @Builder RoamEventRow(event: RoamEvent, index: number) {
    Row({ space: SPACE_MD }) {
      // 序号
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(24).height(24).fill('#FFF7ED')
        Text('#' + String(index + 1))
          .fontSize(FONT_SIZE_XS).fontColor(COLOR_ORANGE).fontWeight(FONT_WEIGHT_BOLD)
      }

      // 事件详情
      Column({ space: SPACE_XS }) {
        Row({ space: SPACE_SM }) {
          Text(RoamTestEngine.formatBssid(event.fromBssid))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_SECONDARY)
          Text(' → ')
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_ORANGE).fontWeight(FONT_WEIGHT_BOLD)
          Text(RoamTestEngine.formatBssid(event.toBssid))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_SECONDARY)
        }
        Row({ space: SPACE_SM }) {
          Text(String(event.rssiBefore) + 'dBm')
            .fontSize(FONT_SIZE_XS).fontColor(this.getRssiLevel(event.rssiBefore).color)
          Text('→')
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
          Text(String(event.rssiAfter) + 'dBm')
            .fontSize(FONT_SIZE_XS).fontColor(this.getRssiLevel(event.rssiAfter).color)
          Text(' | ').fontSize(FONT_SIZE_XS).fontColor(COLOR_DIVIDER)
          Text(String(event.duration) + 'ms')
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding({ top: SPACE_SM, bottom: SPACE_SM })
  }

  // ==================== 空状态 ====================
  @Builder IdleState() {
    Column({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(80).height(80).fill('#FFF7ED')
        Image($r('app.media.ic_roaming')).width(40).height(40)
      }
      Text($r('app.string.wifi_roam_test'))
        .fontSize(FONT_SIZE_LG).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
      Text($r('app.string.roam_test_desc'))
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_TERTIARY)
    }
    .width('100%').padding({ top: SPACE_2XL, bottom: SPACE_2XL }).justifyContent(FlexAlign.Center)
  }

  // ==================== 测试时长选择 ====================
  @Builder DurationSelector() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.test_duration'))
        .fontSize(FONT_SIZE_SM).fontColor(COLOR_TEXT_SECONDARY).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        Text('30s')
          .fontSize(FONT_SIZE_XS).fontColor(this.testDuration === 30 ? Color.White : COLOR_ORANGE)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.testDuration === 30 ? COLOR_ORANGE : '#FFF7ED').borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.testDuration = 30 })
        Text('60s')
          .fontSize(FONT_SIZE_XS).fontColor(this.testDuration === 60 ? Color.White : COLOR_ORANGE)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.testDuration === 60 ? COLOR_ORANGE : '#FFF7ED').borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.testDuration = 60 })
        Text('120s')
          .fontSize(FONT_SIZE_XS).fontColor(this.testDuration === 120 ? Color.White : COLOR_ORANGE)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.testDuration === 120 ? COLOR_ORANGE : '#FFF7ED').borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.testDuration = 120 })
        Text('300s')
          .fontSize(FONT_SIZE_XS).fontColor(this.testDuration === 300 ? Color.White : COLOR_ORANGE)
          .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
          .backgroundColor(this.testDuration === 300 ? COLOR_ORANGE : '#FFF7ED').borderRadius(RADIUS_3XL)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => { this.testDuration = 300 })
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  // ==================== 操作按钮 ====================
  @Builder ActionButtons() {
    if (this.viewMode === 'testing') {
      Button($r('app.string.stop_roam_test'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_DANGER)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).width('100%')
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.stopTest())
    } else if (this.viewMode === 'idle') {
      Button($r('app.string.start_roam_test'))
        .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
        .backgroundColor(COLOR_ORANGE)
        .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).width('100%')
        .stateStyles({ pressed: { opacity: 0.8 } })
        .onClick(() => this.startTest())
    } else if (this.viewMode === 'summary') {
      Row({ space: SPACE_MD }) {
        BackButtonCapsule({ onBack: () => RouterManager.goBack() })
        Button($r('app.string.retry_roam_test'))
          .fontSize(FONT_SIZE_MD).fontColor(Color.White).fontWeight(FONT_WEIGHT_MEDIUM)
          .backgroundColor(COLOR_ORANGE)
          .borderRadius(RADIUS_3XL).height(BUTTON_HEIGHT_MD).layoutWeight(1)
          .stateStyles({ pressed: { opacity: 0.8 } })
          .onClick(() => this.startTest())
      }
      .width('100%')
    }
  }

  // ==================== 功能说明卡片 ====================
  @Builder FeatureCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(36).height(36).fill('#FFF7ED')
          Image($r('app.media.ic_route')).width(18).height(18).fillColor(COLOR_ORANGE)
        }
        Column({ space: 2 }) {
          Text($r('app.string.roam_test_intro'))
            .fontSize(FONT_SIZE_MD).fontColor(COLOR_TEXT_PRIMARY).fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.roam_test_intro_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('100%').padding(SPACE_MD).backgroundColor(COLOR_SURFACE)
    .borderRadius(RADIUS_2XL).border({ width: 1, color: COLOR_BORDER })
  }
}
