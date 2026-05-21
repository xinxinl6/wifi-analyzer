// 漫游测试页面组件 - Aurora WiFi V2 设计系统
// 界面：实时信号监测 + BSSID切换事件 + 漫游统计摘要 + 稳定性评分

import {
  COLOR_WARNING, COLOR_SUCCESS, COLOR_DANGER, COLOR_INFO,
  COLOR_ORANGE,
  COLOR_TEXT_GLASS_PRIMARY, COLOR_TEXT_GLASS_SECONDARY, COLOR_TEXT_GLASS_TERTIARY,
  COLOR_TEXT_LIGHT_PRIMARY, COLOR_TEXT_LIGHT_SECONDARY, COLOR_TEXT_LIGHT_TERTIARY,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_WHITE, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_SKY_LIGHT,
  FONT_SIZE_XXS, FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL, SPACE_2XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
  BUTTON_HEIGHT_MD, SAFE_AREA_BOTTOM,
  GLASS_BLUR_LG,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveCardBg, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import {
  RoamTestEngine, RoamEvent, RoamTestConfig, RoamTestCallbacks,
  RoamTestInfo, RoamTestSummary, BssidRecord, WifiInfo,
} from '../roamtest/RoamTestEngine'
import { RouterManager } from '@wifi-analyzer/core'
import { RssiLevel } from './RoamTestingView'
import { RoamIdleState, RoamDurationSelector, RoamFeatureCard } from './RoamIdleView'
import { RoamTestingCard } from './RoamTestingView'
import { RoamSummaryCard } from './RoamSummaryCard'
import { RoamTimelineCard } from './RoamTimelineCard'
import { RoamEventsList } from './RoamEventsList'

@Component
export struct RoamTestPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State viewMode: string = 'idle'
  @State currentBssid: string = ''
  @State currentRssi: number = 0
  @State elapsedSec: number = 0
  @State totalSec: number = 60
  @State roamCount: number = 0
  @State avgRssi: number = 0
  @State bssidHistory: BssidRecord[] = []
  @State testDuration: number = 60
  @State currentSsid: string = ''
  @State summary: RoamTestSummary | null = null
  @State showEvents: boolean = false

  private engine: RoamTestEngine = new RoamTestEngine()

  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
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

  getStabilityColor(score: number): ResourceColor {
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
    Stack({ alignContent: Alignment.Top }) {
      Column() {}
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

      Circle()
        .width(260).height(260)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })
        .blur(50)

      Circle()
        .width(200).height(200)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })
        .blur(40)

      Column() {
        this.MainContent()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 主内容 ====================
  @Builder MainContent() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')

        // 当前连接信息
        this.ConnectionCard()

        // 测试进行中
        if (this.viewMode === 'testing') {
          RoamTestingCard({
            isDarkMode: this.isDarkMode,
            currentRssi: this.currentRssi,
            elapsedSec: this.elapsedSec,
            totalSec: this.totalSec,
            roamCount: this.roamCount,
            avgRssi: this.avgRssi,
            formatDuration: (sec: number) => this.formatDuration(sec),
            getRssiLevel: (rssi: number) => this.getRssiLevel(rssi)
          })
          RoamTimelineCard({
            isDarkMode: this.isDarkMode,
            bssidHistory: this.bssidHistory,
            getRssiLevel: (rssi: number) => this.getRssiLevel(rssi)
          })
        }

        // 测试摘要
        if (this.viewMode === 'summary' && this.summary) {
          RoamSummaryCard({
            isDarkMode: this.isDarkMode,
            summary: this.summary,
            formatDuration: (sec: number) => this.formatDuration(sec),
            getStabilityColor: (score: number) => this.getStabilityColor(score),
            getStabilityLabel: (score: number) => this.getStabilityLabel(score)
          })
          RoamEventsList({
            isDarkMode: this.isDarkMode,
            showEvents: this.showEvents,
            summary: this.summary,
            onToggleEvents: () => { this.showEvents = !this.showEvents },
            getRssiLevel: (rssi: number) => this.getRssiLevel(rssi)
          })
        }

        // 空状态
        if (this.viewMode === 'idle') {
          RoamIdleState({ isDarkMode: this.isDarkMode })
          RoamDurationSelector({
            isDarkMode: this.isDarkMode,
            testDuration: this.testDuration,
            onDurationChange: (sec: number) => { this.testDuration = sec }
          })
        }

        // 操作按钮
        this.ActionButtons()

        // 功能说明
        RoamFeatureCard({ isDarkMode: this.isDarkMode })
      }
      .padding(SPACE_LG)
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  // ==================== 当前连接信息（内联） ====================
  @Builder ConnectionCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(40).height(40)
            .fill(this.isDarkMode ? 'rgba(251,146,60,0.18)' : 'rgba(251,146,60,0.13)')
          Image($r('app.media.ic_route')).width(22).height(22).fillColor(COLOR_ORANGE)
        }
        Column({ space: 2 }) {
          Text(this.currentSsid !== '' ? this.currentSsid : $r('app.string.wifi_connection'))
            .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          Row({ space: SPACE_SM }) {
            Text(this.currentBssid !== '' ? RoamTestEngine.formatBssid(this.currentBssid) : $r('app.string.not_connected'))
              .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
            Text(' | ').fontSize(FONT_SIZE_XS).fontColor(adaptiveDivider(this.isDarkMode))
            Text(String(this.currentRssi) + ' dBm')
              .fontSize(FONT_SIZE_XS).fontColor(this.getRssiLevel(this.currentRssi).color)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%').padding(SPACE_LG)
    .backgroundColor(adaptiveCardBg(this.isDarkMode))
    .borderRadius(RADIUS_2XL)
    .border({ width: 1, color: adaptiveDivider(this.isDarkMode) })
    .backdropBlur(GLASS_BLUR_LG)
  }

  // ==================== 操作按钮（内联） ====================
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
        BackButtonGlass({ onBack: () => RouterManager.goBack() })
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
}
