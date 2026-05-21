// Ping 测试 - 历史记录弹窗组件 v3
// 风格：仿「WiFi详情」居中圆角卡片 — 左键右值列表 + 线性动画

import { adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider, adaptiveCardBg,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SURFACE, COLOR_DANGER,
  COLOR_BORDER, COLOR_SUCCESS, COLOR_WARNING, COLOR_DIVIDER_WEAK,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL, RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_2XL, RADIUS_3XL,
          // 玻璃拟态
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  COLOR_SKY_BLUE_DIVIDER, COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_AURORA, COLOR_OVERLAY,
  GLASS_BLUR_MD, GLASS_BLUR_LG, GLASS_SHADOW_MD, GLASS_SHADOW_LG } from '@wifi-analyzer/design-system'
import { PingResult, PingSessionSummary } from './PingTestPage'

// ==================== Props ====================
export interface HistoryModalProps {
  isDarkMode: boolean
  pingHistory: PingResult[]
  onClose: () => void
  getGlobalHistForModal: () => Array<PingResult>
  onClearHistory: () => void
  sessionSummaries?: PingSessionSummary[]
}

interface PingStats {
  total: number
  successCount: number
  lossCount: number
  lossRate: number
  avgLatency: number
  maxLatency: number
  minLatency: number
}

// ==================== 组件 ====================
@Component
export struct HistoryModal {
  @Prop isDarkMode: boolean = false
  @State pingHistory: PingResult[] = []
  @State activeTab: 'records' | 'sessions' = 'records'
  // 动画状态（仿 WiFi 详情 translateY 滑入）
  @State overlayOpacity: number = 0
  @State modalOpacity: number = 0
  @State modalTranslateY: number = 60
  onClose: () => void = () => {}
  getGlobalHistForModal: () => Array<PingResult> = () => new Array<PingResult>()
  onClearHistory: () => void = () => {}
  sessionSummaries: PingSessionSummary[] = []

  aboutToAppear(): void {
    this.playEnterAnimation()
  }

  /** 滑入动画（仿 WiFi 详情） */
  private playEnterAnimation(): void {
    this.overlayOpacity = 0
    this.modalOpacity = 0
    this.modalTranslateY = 60
    setTimeout((): void => {
      this.getUIContext().animateTo({ duration: 280, curve: Curve.Linear }, (): void => {
        this.overlayOpacity = 1
        this.modalOpacity = 1
        this.modalTranslateY = 0
      })
    }, 16)
  }

  /** 滑出动画 */
  playExitAnimation(callback: () => void): void {
    this.getUIContext().animateTo({ duration: 200, curve: Curve.Linear }, (): void => {
      this.overlayOpacity = 0
      this.modalOpacity = 0
      this.modalTranslateY = 40
    })
    setTimeout(callback, 200)
  }

  handleCloseWithAnim(): void {
    this.playExitAnimation((): void => { this.onClose() })
  }

  getStats(): PingStats {
    const history: PingResult[] = this.getGlobalHistForModal()
    const total: number = history.length
    const successCount: number = history.filter((r: PingResult): boolean => r.status === 'success').length
    const lossCount: number = total - successCount
    const lossRate: number = total > 0 ? Math.round((lossCount / total) * 100) : 0
    const successTimes: number[] = history
      .filter((r: PingResult): boolean => r.status === 'success' && r.timeMs !== undefined)
      .map((r: PingResult): number => r.timeMs as number)
    const avgLatency: number = successTimes.length > 0
      ? Math.round(successTimes.reduce((a: number, b: number): number => a + b, 0) / successTimes.length)
      : 0
    const maxLatency: number = successTimes.length > 0 ? Math.max(...successTimes) : 0
    const minLatency: number = successTimes.length > 0 ? Math.min(...successTimes) : 0
    return { total, successCount, lossCount, lossRate, avgLatency, maxLatency, minLatency }
  }

  build() {
    Stack() {
      // 遮罩层（仿 WiFi 详情）
      Column().width('100%').height('100%')
        .backgroundColor(this.isDarkMode ? COLOR_OVERLAY : 'rgba(15,30,60,0.35)')
        .backdropBlur(4)
        .opacity(this.overlayOpacity)
        .onClick(() => { this.handleCloseWithAnim() })

      // 悬浮卡片（绝对定位，仿 WiFi 详情）
      Column({ space: 0 }) {
        // 标题栏
        Row() {
          Text($r('app.string.history'))
            .fontSize(FONT_SIZE_XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))

          Blank()

          Text('\u00D7')
            .fontSize(FONT_SIZE_2XL)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .width(30)
            .height(30)
            .borderRadius(RADIUS_MD)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.handleCloseWithAnim() })
        }
        .width('100%')
        .padding({ left: 20, right: 16, top: 18, bottom: 14 })

        // Tab 切换栏（胶囊式）
        this.TabBar()

        Divider()
          .color(adaptiveDivider(this.isDarkMode))
          .margin({ left: 20, right: 20 })

        // 内容区
        Scroll() {
          if (this.activeTab === 'records') {
            this.RecordsContent()
          } else {
            this.SessionsContent()
          }
        }
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .constraintSize({ maxHeight: 340 })
        .width('100%')
        .layoutWeight(1)

        // 清空按钮（底部）
        Row() {
          Blank()
          Text($r('app.string.clear_history'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(COLOR_DANGER)
            .padding({ left: 18, right: 18, top: 8, bottom: 8 })
            .borderRadius(RADIUS_MD)
            .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_AURORA)
            .onClick(() => {
              this.onClearHistory()
              this.handleCloseWithAnim()
            })
          Blank()
        }
        .width('100%')
        .padding({ top: 12, bottom: 16 })
      }
      .width('96%')
      .constraintSize({ maxWidth: 560, maxHeight: '80%' })
      .borderRadius(RADIUS_3XL)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .border({ width: 1, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_AURORA })
      .backdropBlur(20)
      .shadow({ radius: 32, color: COLOR_GLASS_AURORA, offsetX: 0, offsetY: 8 })
      .position({ x: '5.5%', y: '10%' })
      .zIndex(999)
      .opacity(this.modalOpacity)
      .translate({ y: this.modalTranslateY })
    }
    .width('100%')
    .height('100%')
    .zIndex(999)
  }

  // ==================== Tab 胶囊栏 ====================
  @Builder TabBar() {
    Row({ space: 10 }) {
      this.TabPill($r('app.string.ping_records'), String(this.getStats().total), 'records')
      this.TabPill($r('app.string.history_sessions'), String(this.sessionSummaries?.length || 0), 'sessions')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 6, bottom: 10 })
  }

  @Builder TabPill(label: string | Resource, count: string | Resource, tab: 'records' | 'sessions') {
    Row({ space: 5 }) {
      Text(label).fontSize(FONT_SIZE_SM)
        .fontWeight(this.activeTab === tab ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
        .fontColor(this.activeTab === tab ? adaptiveTextPrimary(this.isDarkMode) : adaptiveTextSecondary(this.isDarkMode))
      Text(count).fontSize(FONT_SIZE_XS)
        .fontColor(this.activeTab === tab ? COLOR_GLASS_SURFACE_MEDIUM : adaptiveTextTertiary(this.isDarkMode))
    }
    .padding({ left: 14, right: 14, top: 7, bottom: 7 })
    .backgroundColor(this.activeTab === tab ? COLOR_SKY_BLUE : (this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_DIVIDER_WEAK))
    .borderRadius(RADIUS_2XL)
    .onClick(() => { this.activeTab = tab })
  }

  // ==================== Ping 记录内容（WiFi详情式 左键右值）====================
  @Builder RecordsContent() {
    Column({ space: 0 }) {
      if (this.getGlobalHistForModal().length === 0) {
        this.EmptyView($r('app.string.no_ping_records'), $r('app.string.ping_records_hint'))
      } else {
        // 统计概览行（仿 WiFi 详情的 key-value 风格）
        this.KVRow($r('app.string.total_records'), String(this.getStats().total))
        this.KVRow($r('app.string.avg_latency'), this.getStats().avgLatency > 0 ? String(this.getStats().avgLatency) + ' ms' : '--')
        this.KVRow($r('app.string.packet_loss_rate'), String(this.getStats().lossRate) + '%',
          this.getStats().lossRate > 5 ? COLOR_DANGER :
          this.getStats().lossRate > 0 ? COLOR_WARNING : COLOR_SUCCESS)
        this.KVRow($r('app.string.min_latency'), this.getStats().minLatency > 0 ? String(this.getStats().minLatency) + ' ms' : '--')
        this.KVRow($r('app.string.max_latency'), this.getStats().maxLatency > 0 ? String(this.getStats().maxLatency) + ' ms' : '--')

        Divider()
          .color(adaptiveDivider(this.isDarkMode))
          .margin({ left: 20, right: 20, top: 8, bottom: 8 })

        // 最近记录标题
        Text($r('app.string.recent_records'))
          .fontSize(FONT_SIZE_SM)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
          .padding({ left: 20, bottom: 10 })

        // 记录列表（取最近 15 条）
        ForEach(
          this.getGlobalHistForModal().slice(-15),
          (result: PingResult, index: number) => {
            this.RecordKVRow(result, index)
          },
          (result: PingResult, index: number): string => String(index + '_' + result.timestamp)
        )
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  /** 单条 KV 行（仿 WiFi 详情） */
  @Builder KVRow(label: string | Resource, value: string | Resource, valueColor?: string) {
    Row() {
      Text(label)
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
      Blank()
      Text(value)
        .fontSize(FONT_SIZE_MD)
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .fontColor(valueColor || adaptiveTextPrimary(this.isDarkMode))
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 13, bottom: 13 })
  }

  /** 单条 Ping 记录行 */
  @Builder RecordKVRow(result: PingResult, index: number) {
    Row() {
      // 左侧：地址 + 时间
      Column({ space: 2 }) {
        Text(result.address)
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(new Date(result.timestamp).toLocaleTimeString())
          .fontSize(11)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：结果值（带颜色标签感）
      if (result.status === 'success') {
        Text(String(result.timeMs) + ' ms')
          .fontSize(FONT_SIZE_SM)
          .fontWeight(FONT_WEIGHT_MEDIUM)
          .fontColor(this.getLatencyColor(result.timeMs as number))
      } else if (result.status === 'timeout') {
        Text($r('app.string.timeout'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(COLOR_DANGER)
      } else {
        Text($r('app.string.failed'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(COLOR_DANGER)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 11, bottom: 11 })
    .alignItems(VerticalAlign.Center)
  }

  // ==================== 历史会话内容 ====================
  @Builder SessionsContent() {
    Column({ space: 0 }) {
      if (!this.sessionSummaries || this.sessionSummaries.length === 0) {
        this.EmptyView($r('app.string.no_history_sessions'), $r('app.string.sessions_save_hint'))
      } else {
        ForEach(this.sessionSummaries, (summary: PingSessionSummary, index: number) => {
          this.SessionBlock(summary)
        }, (summary: PingSessionSummary, index: number): string => String(index + '_' + summary.timestamp))

        if ((this.sessionSummaries?.length || 0) < (this.sessionSummaries?.length || 0)) {
          Divider()
            .color(adaptiveDivider(this.isDarkMode))
            .margin({ left: 20, right: 20 })
        }
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  /** 会话块 */
  @Builder SessionBlock(summary: PingSessionSummary) {
    Column({ space: 0 }) {
      // 头部行
      Row() {
        Circle()
          .width(8).height(8)
          .fill(this.getStabilityColor(summary.stabilityScore))

        Text(summary.targetHost || '--')
          .fontSize(FONT_SIZE_MD)
          .fontWeight(FONT_WEIGHT_MEDIUM)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(String(summary.stabilityScore))
          .fontSize(FONT_SIZE_SM)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(this.getStabilityColor(summary.stabilityScore))
      }
      .width('100%').alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 13, bottom: 4 })

      // 指标行（左键右值风格）
      Row() {
        Text($r('app.string.avg_latency'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
        Blank()
        Text(summary.avgTime > 0 ? String(summary.avgTime) + ' ms' : '--')
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .width('100%').padding({ left: 36, right: 20, top: 7, bottom: 7 })

      Row() {
        Text($r('app.string.packet_loss_rate'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
        Blank()
        Text(String(summary.lossRate) + '%')
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .width('100%').padding({ left: 36, right: 20, top: 7, bottom: 7 })

      Row() {
        Text($r('app.string.jitter'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
        Blank()
        Text(String(summary.jitter) + ' ms')
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .width('100%').padding({ left: 36, right: 20, top: 7, bottom: 7 })

      Row() {
        Text($r('app.string.ping_count_label'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
        Blank()
        Text(String(summary.pingCount))
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .width('100%').padding({ left: 36, right: 20, top: 7, bottom: 13 })

      // 分割线（非最后一项显示）
      Divider()
        .color(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_DIVIDER_WEAK)
        .margin({ left: 20, right: 20 })
    }
    .width('100%')
  }

  // ==================== 空状态 ====================
  @Builder EmptyView(title: string | Resource, desc: string | Resource) {
    Column({ space: 14 }) {
      // 柱状图图标
      Row({ space: 5 }) {
        Column().width(6).height(22).borderRadius(3)
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_LIGHT)
        Column().width(6).height(34).borderRadius(3)
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_LIGHT)
        Column().width(6).height(26).borderRadius(3)
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_AURORA)
        Column().width(6).height(30).borderRadius(3)
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_AURORA)
      }

      Text(title)
        .fontSize(FONT_SIZE_MD)
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
      Text(desc)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%')
    .height(260)
    .justifyContent(FlexAlign.Center)
  }

  // ==================== 工具方法 ====================
  getStabilityColor(score: number): string {
    if (score >= 80) return COLOR_SUCCESS
    if (score >= 60) return COLOR_SKY_BLUE
    if (score >= 40) return COLOR_WARNING
    return COLOR_DANGER
  }

  getLatencyColor(latency: number): string {
    if (latency < 50) return COLOR_SUCCESS
    if (latency < 100) return COLOR_SKY_BLUE
    if (latency < 200) return COLOR_WARNING
    return COLOR_DANGER
  }

  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp)
    const month: string = String(date.getMonth() + 1).padStart(2, '0')
    const day: string = String(date.getDate()).padStart(2, '0')
    const hours: string = date.getHours().toString().padStart(2, '0')
    const minutes: string = date.getMinutes().toString().padStart(2, '0')
    return `${month}-${day} ${hours}:${minutes}`
  }
}
