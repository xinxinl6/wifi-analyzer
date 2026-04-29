// WiFi列表页组件 — Aurora 极光主题版
// 风格与首页 Aurora V2 保持一致

import {
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_AURORA_GLOW,
  COLOR_AURORA_DEEP,
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_GLASS_AURORA_BORDER,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_TEXT_LIGHT_PRIMARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_TEXT_LIGHT_TERTIARY,
  COLOR_SHADOW_AURORA,
  COLOR_SHADOW_GLASS,
  SIGNAL_COLORS_AURORA,
  SIGNAL_THRESHOLD_EXCELLENT,
  SIGNAL_THRESHOLD_GOOD,
  SIGNAL_THRESHOLD_FAIR,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_2XL, FONT_WEIGHT_MEDIUM,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_CARD, RADIUS_BUTTON,
  DURATION_FAST, DURATION_NORMAL, AnimationTapScale,
  TAB_BAR_SAFE_BOTTOM
} from '@wifi-analyzer/design-system'
import { WifiItem, SharedWifiState, WifiDataManager } from '@wifi-analyzer/core'

// 空 WiFi 项
function createEmptyWifiItem(): WifiItem {
  return { ssid: '', bssid: '', signal: -100, freq: 0, channel: 0, security: '', isConnected: false, bandwidth: '' }
}

// 筛选按钮配置接口
interface FilterChipConfig {
  label: Resource | string
  isSelected: boolean
  onClick: () => void
}

@Component
export struct WifiListSection {
  @Consume('wifiState') wifiState: SharedWifiState

  @State localFilter: string = 'all'
  @State private cachedFilteredList: WifiItem[] = []
  // 下拉刷新状态：独立于按钮扫描状态，避免 Refresh 指示器与按钮 LoadingProgress 同时触发造成闪动
  @State private isPullRefreshing: boolean = false
  @State selectedItem: WifiItem = createEmptyWifiItem()
  @State showDetail: boolean = false
  @State private itemScales: number[] = []
  // 详情弹窗动画状态
  @State private modalOpacity: number = 0
  @State private modalTranslateY: number = 60
  // 背景遮罩动画状态
  @State private overlayOpacity: number = 0

  private dataManager: WifiDataManager = WifiDataManager.getInstance()

  aboutToAppear(): void {
    this.localFilter = this.wifiState.currentFilter
    this.updateCachedList()
  }

  // 打开详情弹窗（带线性动画）
  openDetail(item: WifiItem): void {
    this.selectedItem = item
    this.showDetail = true
    // 先立即显示（opacity=1），再动画滑入
    // 解决 opacity=0 时不透传点击的问题
    this.overlayOpacity = 1
    this.modalOpacity = 1
    this.modalTranslateY = 60
    // 下一帧开始位移动画
    animateTo({
      duration: 280,
      curve: Curve.Linear
    }, () => {
      this.modalTranslateY = 0
    })
  }

  // 关闭详情弹窗（带线性动画）
  closeDetail(): void {
    // 线性动画：遮罩淡出 + 弹窗下滑
    animateTo({
      duration: 220,
      curve: Curve.Linear,
      onFinish: () => {
        // 动画结束后再隐藏组件
        this.showDetail = false
      }
    }, () => {
      this.overlayOpacity = 0
      this.modalTranslateY = 60
      this.modalOpacity = 0
    })
  }

  private updateCachedList(): void {
    const list: WifiItem[] = this.wifiState.wifiList || []
    let filtered: WifiItem[] = list
    // 5GHz: 频率 >= 4.0 GHz（常见值 5.18/5.745 GHz）
    if (this.localFilter === '5g') {
      filtered = list.filter((item: WifiItem) => item.freq >= 4.0)
    }
    // 2.4GHz: 频率 < 4.0 GHz（常见值 2.412 GHz）
    if (this.localFilter === '2.4g') {
      filtered = list.filter((item: WifiItem) => item.freq < 4.0)
    }
    this.cachedFilteredList = filtered.sort((a: WifiItem, b: WifiItem) => {
      if (a.isConnected !== b.isConnected) return a.isConnected ? -1 : 1
      return b.signal - a.signal
    })
  }

  // 信号色
  getSignalColor(signal: number): string {
    if (signal > SIGNAL_THRESHOLD_EXCELLENT) return SIGNAL_COLORS_AURORA.excellent
    if (signal > SIGNAL_THRESHOLD_GOOD) return SIGNAL_COLORS_AURORA.good
    if (signal > SIGNAL_THRESHOLD_FAIR) return SIGNAL_COLORS_AURORA.fair
    return SIGNAL_COLORS_AURORA.poor
  }

  build() {
    Stack() {
      // ===== Aurora 背景层 =====
      Column() {
        // 渐变主背景
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [
          ['#F7FBFF', 0],
          ['#F0F8FF', 0.4],
          ['#F8FCFF', 0.75],
          ['#FDFDFF', 1]
        ]
      })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill('rgba(74,144,217,0.07)')
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill('rgba(135,206,235,0.06)')
        .position({ x: '68%', y: '45%' })

      Circle()
        .width(120)
        .height(120)
        .fill('rgba(74,144,217,0.04)')
        .position({ x: '80%', y: '10%' })

      // ===== 主内容 =====
      Column() {
        // ===== 顶部筛选栏 =====
        Column() {
          // 标题行
          Row() {
            // 标题
            Column() {
              Text($r('app.string.app_name'))
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLOR_TEXT_LIGHT_PRIMARY)

              Text($r('app.string.networks_found'))
                .fontSize(FONT_SIZE_SM)
                .fontColor(COLOR_TEXT_LIGHT_SECONDARY)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 扫描按钮
            this.ScanButton()
          }
          .width('100%')
          .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: SPACE_SM })

          // 筛选胶囊行
          Row({ space: SPACE_SM }) {
            this.FilterChip({
              label: $r('app.string.filter_all'),
              isSelected: this.localFilter === 'all',
              onClick: () => { this.localFilter = 'all'; this.wifiState.currentFilter = 'all'; this.updateCachedList() }
            })
            this.FilterChip({
              label: $r('app.string.filter_5g'),
              isSelected: this.localFilter === '5g',
              onClick: () => { this.localFilter = '5g'; this.wifiState.currentFilter = '5g'; this.updateCachedList() }
            })
            this.FilterChip({
              label: $r('app.string.filter_2g'),
              isSelected: this.localFilter === '2.4g',
              onClick: () => { this.localFilter = '2.4g'; this.wifiState.currentFilter = '2.4g'; this.updateCachedList() }
            })
          }
          .padding({ left: SPACE_LG, right: SPACE_LG, bottom: SPACE_MD })
          .width('100%')
        }

        // ===== 列表区 =====
        Stack() {
          Refresh({ refreshing: this.isPullRefreshing }) {
            Scroll() {
              Column({ space: SPACE_SM }) {
                // 空状态
                if (this.cachedFilteredList.length === 0 && !this.wifiState.isScanning) {
                  this.EmptyView()
                }

                // WiFi 列表项
                ForEach(this.cachedFilteredList, (item: WifiItem, index: number) => {
                  this.WifiListItem(item, index)
                }, (item: WifiItem): string => (item.bssid || '') + '_' + item.channel.toString())

                // 底部安全间距
                Column().height(TAB_BAR_SAFE_BOTTOM)
              }
              .width('100%')
              .padding({ left: SPACE_LG, right: SPACE_LG })
            }
            .scrollBar(BarState.Auto)
            .edgeEffect(EdgeEffect.Spring)
            .layoutWeight(1)
            .width('100%')
          }
          .onStateChange((refreshState: RefreshStatus) => {
            if (refreshState === RefreshStatus.Refresh) {
              // 下拉刷新时：先标记刷新状态，再执行扫描
              this.isPullRefreshing = true
              this.onRefreshScan()
            } else if (refreshState === RefreshStatus.Done) {
              // 刷新完成后：清除下拉刷新指示器
              this.isPullRefreshing = false
            }
          })
          .align(Alignment.Top)

          // 底部渐变遮罩
          Column()
            .width('100%')
            .height(60)
            .position({ y: '100%' })
            .translate({ y: -60 })
            .linearGradient({
              direction: GradientDirection.Top,
              colors: [['rgba(253,253,255,0)', 1], ['rgba(253,253,255,0.95)', 0]]
            })
            .hitTestBehavior(HitTestMode.None)
        }
        .layoutWeight(1)
        .width('100%')
        .alignContent(Alignment.Top)
      }
      .width('100%')
      .height('100%')

      // ===== 详情弹窗背景遮罩（带动画）=====
      if (this.showDetail) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(15,30,60,0.35)')
          .backdropBlur(4)
          .opacity(this.overlayOpacity)
          .onClick(() => { this.closeDetail() })
          .zIndex(998)
      }

      // ===== 详情弹窗（带线性动画）=====
      if (this.showDetail) {
        Column() {
          // 顶部拖拽指示条
          Column()
            .width(36)
            .height(4)
            .borderRadius(2)
            .backgroundColor('rgba(74,144,217,0.30)')
            .margin({ top: SPACE_SM, bottom: SPACE_SM })

          // 标题栏
          Row() {
            Column() {
              Text($r('app.string.wifi_detail'))
                .fontSize(FONT_SIZE_LG)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLOR_TEXT_LIGHT_PRIMARY)

              if (this.selectedItem.isConnected) {
                Text($r('app.string.connected'))
                  .fontSize(FONT_SIZE_XS)
                  .fontColor(COLOR_AURORA_PRIMARY)
                  .margin({ top: 2 })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 关闭按钮
            Column() {
              Text('×')
                .fontSize(20)
                .fontColor(COLOR_TEXT_LIGHT_SECONDARY)
            }
            .width(32)
            .height(32)
            .borderRadius(16)
            .backgroundColor('rgba(74,144,217,0.10)')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => { this.closeDetail() })
          }
          .padding({ left: SPACE_LG, right: SPACE_LG, bottom: SPACE_MD })
          .width('100%')

          // 分割线（Aurora 发光）
          Column()
            .width('100%')
            .height(1)
            .backgroundColor('rgba(74,144,217,0.18)')
            .margin({ bottom: SPACE_MD })

          // 详情内容
          Column({ space: SPACE_SM }) {
            this.DetailRow($r('app.string.network_name'), this.selectedItem.ssid)
            this.DetailRow($r('app.string.bssid'), this.selectedItem.bssid)
            this.DetailRow($r('app.string.signal_strength'), this.selectedItem.signal + ' dBm')
            this.DetailRow($r('app.string.band'), this.selectedItem.freq >= 4.0 ? $r('app.string.filter_5g') : $r('app.string.filter_2g'))
            this.DetailRow($r('app.string.channel_ch'), 'CH ' + this.selectedItem.channel)
            this.DetailRow($r('app.string.bandwidth_mhz'), this.selectedItem.bandwidth || '--MHz')
            this.DetailRow($r('app.string.encryption'), this.selectedItem.security)
            this.DetailRow($r('app.string.status'), this.selectedItem.isConnected ? $r('app.string.connected') : $r('app.string.not_connected'))
          }
          .padding({ left: SPACE_LG, right: SPACE_LG, bottom: SPACE_LG })
          .width('100%')
        }
        .width('88%')
        // Aurora 毛玻璃底板
        .backgroundColor('rgba(240,248,255,0.92)')
        .borderRadius(RADIUS_CARD)
        .border({ width: 1, color: COLOR_GLASS_AURORA_BORDER })
        .backdropBlur(20)
        .shadow({ radius: 32, color: 'rgba(74,144,217,0.20)', offsetX: 0, offsetY: 8 })
        .position({ x: '6%', y: '15%' })
        .zIndex(999)
        // 线性动画属性
        .opacity(this.modalOpacity)
        .translate({ y: this.modalTranslateY })
      }
    }
    .width('100%')
    .height('100%')
  }

  async onRefreshScan(): Promise<void> {
    // 重新读取系统 WiFi 列表
    this.wifiState.isScanning = true
    this.wifiState.isLoaded = false
    try {
      await this.dataManager.scanAndUpdate(
        this.wifiState,
        (newState: SharedWifiState) => {
          this.wifiState = newState
          this.updateCachedList()
        }
      )
    } catch (e) {
      this.wifiState.isScanning = false
    } finally {
      // 扫描完成后清除下拉刷新指示器（无论成功或失败）
      this.isPullRefreshing = false
    }
  }

  // ==================== Builder: 单个WiFi卡片 ====================
  @Builder WifiListItem(item: WifiItem, index?: number) {
    Row({ space: SPACE_MD }) {
      // 信号图标区（Aurora 发光效果）
      Stack({ alignContent: Alignment.Center }) {
        // 发光底圆（已连接时）
        if (item.isConnected) {
          Circle()
            .width(44)
            .height(44)
            .fill('rgba(74,144,217,0.15)')
        }

        // 信号条
        Column({ space: 2 }) {
          this.SignalBars(item.signal)
        }
        .width(40)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width(44)
      .height(44)

      // 中间信息区
      Column() {
        Row({ space: SPACE_SM }) {
          Text(item.ssid || '(隐藏网络)')
            .fontSize(FONT_SIZE_LG)
            .fontWeight(FONT_WEIGHT_MEDIUM)
            .fontColor(COLOR_TEXT_LIGHT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (item.isConnected) {
            Text($r('app.string.connected'))
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_AURORA_PRIMARY)
              .fontWeight(FONT_WEIGHT_MEDIUM)
              .padding({ left: SPACE_SM, right: SPACE_SM, top: 2, bottom: 2 })
              .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
              .borderRadius(RADIUS_SM)
              .border({ width: 1, color: COLOR_GLASS_AURORA_BORDER })
          }
        }
        .width('100%')

        Text((item.bssid || '') + ' · ' + (item.freq >= 4.0 ? '5GHz' : '2.4GHz') + ' · CH ' + item.channel + ' · ' + (item.bandwidth || '--MHz'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(COLOR_TEXT_LIGHT_TERTIARY)
          .margin({ top: 3 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧信号数值
      Column({ space: 4 }) {
        Text(item.signal + ' dBm')
          .fontSize(FONT_SIZE_MD)
          .fontWeight(FONT_WEIGHT_MEDIUM)
          .fontColor(this.getSignalColor(item.signal))

        Text(item.security || 'Open')
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_TEXT_LIGHT_TERTIARY)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('rgba(74,144,217,0.08)')
          .borderRadius(RADIUS_SM)
          .border({ width: 1, color: 'rgba(74,144,217,0.15)' })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: SPACE_LG, right: SPACE_MD, top: SPACE_MD, bottom: SPACE_MD })
    // Aurora 毛玻璃卡片
    .backgroundColor(item.isConnected ? 'rgba(74,144,217,0.10)' : 'rgba(255,255,255,0.60)')
    .borderRadius(RADIUS_CARD)
    .border({
      width: 1,
      color: item.isConnected ? COLOR_GLASS_AURORA_BORDER : COLOR_GLASS_BORDER_LIGHT
    })
    .shadow({
      radius: item.isConnected ? 16 : 8,
      color: item.isConnected ? COLOR_SHADOW_AURORA : COLOR_SHADOW_GLASS,
      offsetX: 0,
      offsetY: item.isConnected ? 4 : 2
    })
    .backdropBlur(10)
    // 点击时半透明反馈
    .stateStyles({
      pressed: { .opacity(0.65) },
      normal: { .opacity(1) }
    })
    .animation({ duration: DURATION_FAST, curve: Curve.EaseOut })
    .onClick(() => {
      this.selectedItem = item
      this.showDetail = true
      this.overlayOpacity = 1
      this.modalOpacity = 1
      this.modalTranslateY = 60
      animateTo({ duration: 280, curve: Curve.Linear }, () => {
        this.modalTranslateY = 0
      })
    })
  }

  // ==================== Builder: 筛选胶囊（Aurora 风格）====================
  @Builder FilterChip(config: FilterChipConfig) {
    Column() {
      Text(config.label)
        .fontSize(FONT_SIZE_SM)
        .fontWeight(config.isSelected ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(config.isSelected ? '#FFFFFF' : COLOR_TEXT_LIGHT_PRIMARY)
    }
    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
    .backgroundColor(config.isSelected ? COLOR_AURORA_PRIMARY : 'rgba(255,255,255,0.75)')
    .borderRadius(20)
    .border({
      width: 1,
      color: config.isSelected ? 'rgba(255,255,255,0.35)' : 'rgba(74,144,217,0.18)'
    })
    .shadow({
      radius: config.isSelected ? 12 : 6,
      color: config.isSelected ? 'rgba(74,144,217,0.35)' : 'rgba(74,144,217,0.08)',
      offsetX: 0,
      offsetY: config.isSelected ? 4 : 2
    })
    .backdropBlur(config.isSelected ? 8 : 4)
    .animation({ duration: DURATION_NORMAL, curve: Curve.EaseOut })
    .onClick(config.onClick)
  }

  // ==================== Builder: 扫描按钮（Aurora 风格）====================
  @Builder ScanButton() {
    Row({ space: SPACE_SM }) {
      if (this.wifiState.isScanning) {
        LoadingProgress()
          .width(14)
          .height(14)
          .color('#FFFFFF')
      } else {
        Text('↺')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      Text(this.wifiState.isScanning ? $r('app.string.scanning') : $r('app.string.refresh'))
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
    }
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .backgroundColor(this.wifiState.isScanning ? 'rgba(74,144,217,0.50)' : COLOR_AURORA_PRIMARY)
    .borderRadius(RADIUS_BUTTON)
    .border({
      width: 1,
      color: this.wifiState.isScanning ? 'rgba(255,255,255,0.15)' : 'rgba(255,255,255,0.40)'
    })
    .shadow({
      radius: 12,
      color: this.wifiState.isScanning ? 'rgba(74,144,217,0.15)' : 'rgba(74,144,217,0.45)',
      offsetX: 0,
      offsetY: 4
    })
    .backdropBlur(8)
    .animation({ duration: DURATION_NORMAL, curve: Curve.EaseOut })
    .onClick(() => this.onRefreshScan())
  }

  // ==================== Builder: 信号强度 Aurora 指示器 ====================
  @Builder SignalBars(signal: number) {
    Row({ space: 2 }) {
      // 4 格信号条，渐进高度
      Column()
        .width(3).height(5).borderRadius(2)
        .backgroundColor(signal > SIGNAL_THRESHOLD_FAIR ? this.getSignalColor(signal) : 'rgba(74,144,217,0.20)')

      Column()
        .width(3).height(8).borderRadius(2)
        .backgroundColor(signal > SIGNAL_THRESHOLD_GOOD ? this.getSignalColor(signal) : 'rgba(74,144,217,0.20)')

      Column()
        .width(3).height(12).borderRadius(2)
        .backgroundColor(signal > -62 ? this.getSignalColor(signal) : 'rgba(74,144,217,0.20)')

      Column()
        .width(3).height(16).borderRadius(2)
        .backgroundColor(signal > SIGNAL_THRESHOLD_EXCELLENT ? this.getSignalColor(signal) : 'rgba(74,144,217,0.20)')
    }
    .alignItems(VerticalAlign.Bottom)
  }

  // ==================== Builder: 空状态（Aurora 风格）====================
  @Builder EmptyView() {
    Column({ space: SPACE_LG }) {
      // Aurora 发光图标容器
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(90)
          .height(90)
          .fill('rgba(74,144,217,0.10)')

        Circle()
          .width(68)
          .height(68)
          .fill('rgba(74,144,217,0.08)')

        Image($r('app.media.ic_wifi'))
          .width(36)
          .height(36)
          .fillColor(COLOR_AURORA_PRIMARY)
      }
      .width(90)
      .height(90)

      Column({ space: SPACE_SM }) {
        Text($r('app.string.no_scan_result'))
          .fontSize(FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLOR_TEXT_LIGHT_PRIMARY)
          .textAlign(TextAlign.Center)

        Text($r('app.string.grant_permission_hint'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(COLOR_TEXT_LIGHT_SECONDARY)
          .textAlign(TextAlign.Center)
          .width('80%')
      }
    }
    .width('100%')
    .height(320)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 详情行
  @Builder DetailRow(label: Resource, value: Resource | string) {
    Row({ space: SPACE_MD }) {
      Text(label)
        .fontSize(FONT_SIZE_SM)
        .fontColor(COLOR_TEXT_LIGHT_TERTIARY)
        .width('35%')

      Text(value)
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLOR_TEXT_LIGHT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ top: SPACE_XS, bottom: SPACE_XS })
    .border({ width: { bottom: 1 }, color: 'rgba(74,144,217,0.08)' })
  }
}
