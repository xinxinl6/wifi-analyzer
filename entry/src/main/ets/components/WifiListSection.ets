// WiFi列表页组件 — Aurora 极光主题版（容器组件）
// 风格与首页 Aurora V2 保持一致
// 注意：当前使用 ForEach + Scroll 而非 LazyForEach + List，
// 因为 WiFi 列表通常不超过 50 项，且 Scroll+Column 提供了更好的毛玻璃卡片圆角兼容。
// 若列表项超过 100 可考虑切换到 List + LazyForEach。

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
  COLOR_GLASS_SKY_LIGHT,
  SIGNAL_COLORS_AURORA,
  SIGNAL_THRESHOLD_EXCELLENT,
  SIGNAL_THRESHOLD_GOOD,
  SIGNAL_THRESHOLD_FAIR,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_2XL, FONT_WEIGHT_MEDIUM,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_CARD, RADIUS_BUTTON,
  DURATION_FAST, DURATION_NORMAL, AnimationTapScale,
  TAB_BAR_SAFE_BOTTOM,
  // 暗色模式自适应工具
  adaptiveBackgroundList,
  adaptiveGlowLarge,
  adaptiveGlowMedium,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  adaptiveCardBg,
  adaptiveFadeColor,
  adaptiveDivider,
  COLOR_TEXT_GLASS_PRIMARY as COLOR_TEXT_GLASS_PRIMARY_ALT,
  COLOR_GLASS_DARK_SURFACE,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_FADE_DARK_TOP,
  COLOR_FADE_LIGHT
} from '@wifi-analyzer/design-system'
import { WifiItem, SharedWifiState, WifiDataManager } from '@wifi-analyzer/core'
import { WifiListItemComponent, WifiSignalBars } from './WifiListItem'
import { WifiDetailModal } from './WifiDetailModal'
import { WifiFilterChip, WifiScanButton, WifiFilterChipConfig } from './WifiFilterChips'

// 空 WiFi 项
function createEmptyWifiItem(): WifiItem {
  return { ssid: '', bssid: '', signal: -100, freq: 0, channel: 0, security: '', isConnected: false, bandwidth: '' }
}

@Component
export struct WifiListSection {
  @Consume('wifiState') wifiState: SharedWifiState
  @StorageLink('isDarkMode') isDarkMode: boolean = false

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
    this.getUIContext().animateTo({
      duration: 280,
      curve: Curve.Linear
    }, () => {
      this.modalTranslateY = 0
    })
  }

  // 关闭详情弹窗（带线性动画）
  closeDetail(): void {
    // 线性动画：遮罩淡出 + 弹窗下滑
    this.getUIContext().animateTo({
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
        colors: adaptiveBackgroundList(this.isDarkMode)
      })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })

      Circle()
        .width(120)
        .height(120)
        .fill(this.isDarkMode ? COLOR_GLASS_AURORA_LIGHT : COLOR_GLASS_SKY_LIGHT)
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
                .fontColor(adaptiveTextPrimary(this.isDarkMode))

              Text() {
                Span($r('app.string.networks_found'))
                Span(String(this.wifiState.wifiList ? this.wifiState.wifiList.length : 0))
                Span($r('app.string.networks_unit'))
              }
                .fontSize(FONT_SIZE_SM)
                .fontColor(adaptiveTextSecondary(this.isDarkMode))
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 扫描按钮
            WifiScanButton({
              isScanning: this.wifiState.isScanning,
              onTap: () => { this.onRefreshScan() }
            })
          }
          .width('100%')
          .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: SPACE_SM })

          // 筛选胶囊行
          Row({ space: SPACE_SM }) {
            WifiFilterChip({
              config: {
                label: $r('app.string.filter_all'),
                isSelected: this.localFilter === 'all',
                onClick: () => { this.localFilter = 'all'; this.wifiState.currentFilter = 'all'; this.updateCachedList() }
              }
            })
            WifiFilterChip({
              config: {
                label: $r('app.string.filter_5g'),
                isSelected: this.localFilter === '5g',
                onClick: () => { this.localFilter = '5g'; this.wifiState.currentFilter = '5g'; this.updateCachedList() }
              }
            })
            WifiFilterChip({
              config: {
                label: $r('app.string.filter_2g'),
                isSelected: this.localFilter === '2.4g',
                onClick: () => { this.localFilter = '2.4g'; this.wifiState.currentFilter = '2.4g'; this.updateCachedList() }
              }
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
                  WifiListItemComponent({
                    item: item,
                    index: index,
                    onItemClick: (clickedItem: WifiItem) => { this.openDetail(clickedItem) }
                  })
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
              colors: this.isDarkMode
                ? [[COLOR_FADE_DARK_TOP, 1], [COLOR_GLASS_DARK_SURFACE, 0]]
                : [[COLOR_FADE_LIGHT, 1], [COLOR_GLASS_SURFACE, 0]]
            })
            .hitTestBehavior(HitTestMode.None)
        }
        .layoutWeight(1)
        .width('100%')
        .alignContent(Alignment.Top)
      }
      .width('100%')
      .height('100%')

      // ===== 详情弹窗 =====
      if (this.showDetail) {
        WifiDetailModal({
          selectedItem: this.selectedItem,
          modalOpacity: this.modalOpacity,
          modalTranslateY: this.modalTranslateY,
          overlayOpacity: this.overlayOpacity,
          onClose: () => { this.closeDetail() }
        })
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

  // ==================== Builder: 空状态（Aurora 风格）====================
  @Builder EmptyView() {
    Column({ space: SPACE_LG }) {
      // Aurora 发光图标容器
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(90)
          .height(90)
          .fill(COLOR_GLASS_AURORA)

        Circle()
          .width(68)
          .height(68)
          .fill(COLOR_GLASS_AURORA_LIGHT)

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
          .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY)
          .textAlign(TextAlign.Center)

        Text($r('app.string.grant_permission_hint'))
          .fontSize(FONT_SIZE_SM)
          .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY)
          .textAlign(TextAlign.Center)
          .width('80%')
      }
    }
    .width('100%')
    .height(320)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
