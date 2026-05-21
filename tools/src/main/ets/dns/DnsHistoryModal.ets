// DNS 查询 - 历史记录弹窗组件
// 风格：仿「Ping 历史记录」居中圆角卡片 — 左键右值列表 + 滑入滑出动画

import {
  COLOR_PRIMARY, COLOR_DANGER,
  COLOR_DIVIDER_WEAK, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_AURORA, COLOR_SHADOW_AURORA,
  COLOR_MODAL_OVERLAY, COLOR_GLASS_DARK_SURFACE, COLOR_GLASS_DARK_CARD,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  RADIUS_MD, RADIUS_2XL, RADIUS_3XL,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { DnsHistoryEntry, DnsLookupEngine } from '../dnslookup/DnsLookupEngine'

// ==================== Props ====================
export interface DnsHistoryModalProps {
  isDarkMode: boolean
  history: DnsHistoryEntry[]
  onClose: () => void
  onClearHistory: () => void
  onItemClick: (entry: DnsHistoryEntry) => void
}

// ==================== 组件 ====================
@Component
export struct DnsHistoryModal {
  @Prop isDarkMode: boolean = false
  @State history: DnsHistoryEntry[] = []
  // 动画状态（滑入/滑出）
  @State overlayOpacity: number = 0
  @State modalOpacity: number = 0
  @State modalTranslateY: number = 60
  onClose: () => void = () => {}
  onClearHistory: () => void = () => {}
  onItemClick: (entry: DnsHistoryEntry) => void = (_entry: DnsHistoryEntry) => {}

  aboutToAppear(): void {
    this.playEnterAnimation()
  }

  /** 滑入动画 */
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

  build() {
    Stack() {
      // 遮罩层
      Column().width('100%').height('100%')
        .backgroundColor(this.isDarkMode ? 'rgba(0,0,0,0.55)' : 'rgba(15,30,60,0.35)')
        .backdropBlur(4)
        .opacity(this.overlayOpacity)
        .onClick(() => { this.handleCloseWithAnim() })

      // 悬浮卡片
      Column({ space: 0 }) {
        // 标题栏
        Row() {
          Row({ space: 6 }) {
            Text('\ud83d\udcdd').fontSize(FONT_SIZE_LG)
            Text($r('app.string.dns_history_title'))
              .fontSize(FONT_SIZE_XL)
              .fontWeight(FONT_WEIGHT_BOLD)
              .fontColor(adaptiveTextPrimary(this.isDarkMode))
          }

          Blank()

          Text('\u00D7')
            .fontSize(FONT_SIZE_2XL)
            .fontColor(this.isDarkMode ? 'rgba(255,255,255,0.45)' : adaptiveTextTertiary(this.isDarkMode))
            .width(30)
            .height(30)
            .borderRadius(RADIUS_MD)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.handleCloseWithAnim() })
        }
        .width('100%')
        .padding({ left: 20, right: 16, top: 18, bottom: 14 })

        Divider()
          .color(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_DIVIDER_WEAK)
          .margin({ left: 20, right: 20 })

        // 内容区
        Scroll() {
          Column() {
            if (this.history.length === 0) {
              this.EmptyView()
            } else {
              // 统计概览行
              this.KVRow($r('app.string.dns_history_total'), String(this.history.length))
              Divider()
                .color(this.isDarkMode ? 'rgba(255,255,255,0.05)' : COLOR_DIVIDER_WEAK)
                .margin({ left: 20, right: 20 })

              // 记录列表标题
              Text($r('app.string.dns_history_recent'))
                .fontSize(FONT_SIZE_SM)
                .fontWeight(FONT_WEIGHT_BOLD)
                .fontColor(adaptiveTextSecondary(this.isDarkMode))
                .padding({ left: 20, top: 10, bottom: 10 })

              // 历史记录列表
              ForEach(this.history, (entry: DnsHistoryEntry, index: number) => {
                this.HistoryItem(entry, index)
              }, (entry: DnsHistoryEntry, index: number): string => String(index + '_' + entry.timestamp))
            }
          }
        }
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .constraintSize({ maxHeight: 380 })
        .width('100%')
        .layoutWeight(1)

        // 底部操作栏
        Row() {
          Blank()
          Text($r('app.string.clear_history'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(COLOR_DANGER)
            .padding({ left: 18, right: 18, top: 8, bottom: 8 })
            .borderRadius(RADIUS_MD)
            .backgroundColor(this.isDarkMode ? 'rgba(239,68,68,0.12)' : COLOR_GLASS_AURORA)
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
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : 'rgba(240,248,255,0.92)')
      .border({ width: 1, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_AURORA })
      .backdropBlur(20)
      .shadow({ radius: 32, color: COLOR_SHADOW_AURORA, offsetX: 0, offsetY: 8 })
      .position({ x: '5.5%', y: '8%' })
      .zIndex(999)
      .opacity(this.modalOpacity)
      .translate({ y: this.modalTranslateY })
    }
    .zIndex(999)
  }

  // ==================== KV 行 ====================
  @Builder KVRow(label: Resource | string, value: string, valueColor?: string) {
    Row() {
      Text(typeof label === 'string' ? label : label)
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

  // ==================== 单条历史记录 ====================
  @Builder HistoryItem(entry: DnsHistoryEntry, index: number) {
    Column() {
      // 主行：域名 + 时间
      Row() {
        // 左侧：DNS 图标 + 域名信息
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(32).height(32)
            .fill(this.isDarkMode ? COLOR_GLASS_AURORA : '#EEF6FE')
          Text('DNS').fontSize(9).fontColor(COLOR_PRIMARY).fontWeight(FONT_WEIGHT_BOLD)
        }

        Column({ space: 3 }) {
          Text(entry.domain)
            .fontSize(FONT_SIZE_SM)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_MEDIUM)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row({ space: SPACE_SM }) {
            Text(entry.server).fontSize(11).fontColor(adaptiveTextTertiary(this.isDarkMode))
            Text('\u00b7').fontSize(11).fontColor(adaptiveDivider(this.isDarkMode))
            Text(this.formatTime(entry.timestamp)).fontSize(11).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 右侧：统计指标
        Column({ space: 3 }) {
          Text(String(entry.recordCount))
            .fontSize(FONT_SIZE_SM)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(COLOR_PRIMARY)
          Text(entry.queryTime + 'ms')
            .fontSize(10)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 11, bottom: 11 })
      .alignItems(VerticalAlign.Center)

      // 点击整行 → 重新查询该域名（通过外层容器）
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.03)' : 'rgba(255,255,255,0.6)')
    .borderRadius(RADIUS_MD)
    .padding(3)
    .onClick(() => { this.onItemClick(entry); this.handleCloseWithAnim() })

    if (index < this.history.length - 1) {
      Column().width('100%').height(4)
    }
  }

  // ==================== 空状态 ====================
  @Builder EmptyView() {
    Column({ space: 14 }) {
      // 图标
      Row({ space: 5 }) {
        Column().width(6).height(22).borderRadius(3)
          .backgroundColor(COLOR_GLASS_AURORA)
        Column().width(6).height(34).borderRadius(3)
          .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,0.45)' : 'rgba(74,144,217,0.25)')
        Column().width(6).height(26).borderRadius(3)
          .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,0.35)' : 'rgba(74,144,217,0.18)')
        Column().width(6).height(30).borderRadius(3)
          .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,0.4)' : 'rgba(74,144,217,0.22)')
      }

      Text($r('app.string.dns_history_empty_title'))
        .fontSize(FONT_SIZE_MD)
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
      Text($r('app.string.dns_history_empty_desc'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%')
    .height(260)
    .justifyContent(FlexAlign.Center)
  }

  // ==================== 工具方法 ====================
  private formatTime(timestamp: number): string {
    const date: Date = new Date(timestamp)
    const month: string = String(date.getMonth() + 1).padStart(2, '0')
    const day: string = String(date.getDate()).padStart(2, '0')
    const hours: string = String(date.getHours()).padStart(2, '0')
    const minutes: string = String(date.getMinutes()).padStart(2, '0')
    const seconds: string = String(date.getSeconds()).padStart(2, '0')
    return `${month}-${day} ${hours}:${minutes}:${seconds}`
  }
}
