import {
  COLOR_FADE_LIGHT,
  COLOR_FADE_DARK_TOP,
  COLOR_GLASS_DARK_SURFACE,
  COLOR_GLASS_SURFACE,
  SPACE_MD,
  SPACE_LG,
  SPACE_SM,
  SPACE_XL,
  COLOR_CHANNEL_IDLE,
  COLOR_CHANNEL_LIGHT,
  COLOR_CHANNEL_MODERATE,
  COLOR_CHANNEL_CROWDED,
  COLOR_CHANNEL_IDLE_TOP,
  COLOR_CHANNEL_LIGHT_TOP,
  COLOR_CHANNEL_MODERATE_TOP,
  COLOR_CHANNEL_CROWDED_TOP,
  adaptiveBackgroundList,
  adaptiveGlowLarge,
  adaptiveGlowMedium
} from '@wifi-analyzer/design-system'
import { SharedWifiState } from '@wifi-analyzer/core'
import { ChannelBandTabs } from './ChannelBandTabs'
import { ChannelInfoCard } from './ChannelInfoCard'
import { ChannelBarChart } from './ChannelBarChart'
import { ChannelRecommend } from './ChannelRecommend'
import { ChannelDetailList } from './ChannelDetailList'
import {
  computeChannelCache,
  BANDS,
  ChannelCacheData,
  ChannelCountPair
} from './ChannelCalculator'

@Component
export struct ChannelSection {
  // 从父组件 Index 消费共享WiFi数据（@Consume 与 Index 的 @Provide 配对）
  @Consume('wifiState') wifiState: SharedWifiState

  // 暗色模式状态
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  // TabBar 显示/隐藏控制（通过 AppStorage 与父组件通信）
  @StorageLink('tabBarVisible') tabBarVisible: boolean = true

  // 滚动状态追踪
  private lastScrollOffset: number = 0
  private scrollThreshold: number = 20  // 滚动阈值，超过此值才触发显示/隐藏

  // 当前选中的频段
  @State currentBand: string = '2.4'

  // 预计算缓存（必须是 @State 才能触发 UI 更新）
  @State private cachedChannels: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  @State private cachedChannelData: ChannelCacheData[] = []
  @State private cachedRecommended: Array<ChannelCountPair> = []
  @State private cachedTotalCount: number = 0

  aboutToAppear(): void {
    this.currentBand = '2.4'
    this.recomputeChannelCache()
  }

  aboutToDisappear(): void {
    // 离开页面时恢复 TabBar 显示
    this.tabBarVisible = true
  }

  // 重新计算信道缓存
  recomputeChannelCache(): void {
    const result = computeChannelCache(
      this.wifiState,
      this.currentBand,
      COLOR_CHANNEL_IDLE,
      COLOR_CHANNEL_LIGHT,
      COLOR_CHANNEL_MODERATE,
      COLOR_CHANNEL_CROWDED,
      COLOR_CHANNEL_IDLE_TOP,
      COLOR_CHANNEL_LIGHT_TOP,
      COLOR_CHANNEL_MODERATE_TOP,
      COLOR_CHANNEL_CROWDED_TOP,
    )
    this.cachedChannels = result.channels
    this.cachedChannelData = result.channelData
    this.cachedRecommended = result.recommended
    this.cachedTotalCount = result.totalCount
  }

  // 频段切换
  private onBandChange(band: string): void {
    if (this.currentBand === band) return
    this.currentBand = band
    this.recomputeChannelCache()
  }

  // 左右滑动切换频段
  private onSwipe(isLeft: boolean): void {
    const idx: number = BANDS.indexOf(this.currentBand)
    if (isLeft) {
      // 左滑 → 下一个频段（循环）
      const next: number = (idx + 1) % BANDS.length
      this.onBandChange(BANDS[next])
    } else {
      // 右滑 → 上一个频段（循环）
      const prev: number = (idx - 1 + BANDS.length) % BANDS.length
      this.onBandChange(BANDS[prev])
    }
  }

  build() {
    Stack() {
      // ===== Aurora 天蓝渐变背景 =====
      Column() {}
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

      // ===== 主内容层 =====
      Column() {
        // ===== 频段切换标签栏 =====
        ChannelBandTabs({
          isDarkMode: this.isDarkMode,
          currentBand: this.currentBand,
          onBandChange: (band: string) => this.onBandChange(band)
        })

        // ===== 内容区（支持左右滑动手势切换频段） =====
        Stack() {
          Scroll() {
            Column({ space: SPACE_MD }) {
              // 频段信息卡片（随内容一起滚动）
              ChannelInfoCard({
                isDarkMode: this.isDarkMode,
                currentBand: this.currentBand,
                totalCount: this.cachedTotalCount
              })

              // 信道占用柱状图
              ChannelBarChart({
                isDarkMode: this.isDarkMode,
                cachedChannelData: this.cachedChannelData,
                currentBand: this.currentBand,
                cachedTotalCount: this.cachedTotalCount
              })

              // 推荐信道
              ChannelRecommend({
                isDarkMode: this.isDarkMode,
                recommendedChannels: this.cachedRecommended,
                cachedTotalCount: this.cachedTotalCount
              })

              // 信道详情列表
              ChannelDetailList({
                isDarkMode: this.isDarkMode,
                cachedChannels: this.cachedChannels,
                cachedChannelData: this.cachedChannelData
              })
            }
            .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 140 })
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .scrollable(ScrollDirection.Vertical)
          .layoutWeight(1)
          .width('100%')
          .height('100%')
          // 滚动监听：控制 TabBar 显示/隐藏
          .onScroll((scrollOffset: number, scrollState: ScrollState) => {
            // 向上滑（内容向上滚动，手指往下滑）→ 显示 TabBar
            // 向下滑（内容向下滚动，手指往上滑）→ 隐藏 TabBar
            const delta = scrollOffset - this.lastScrollOffset
            if (Math.abs(delta) > this.scrollThreshold) {
              if (delta > 0) {
                // 向上滑 → 显示 TabBar
                this.tabBarVisible = true
              } else {
                // 向下滑 → 隐藏 TabBar
                this.tabBarVisible = false
              }
              this.lastScrollOffset = scrollOffset
            }
          })

          // 底部边界渐变遮罩（缩短高度，避免遮挡过多内容）
          Column()
            .width('100%')
            .height(40)
            .position({ y: '100%' })
            .translate({ y: -40 })
            .linearGradient({
              direction: GradientDirection.Top,
              colors: this.isDarkMode
                ? [[COLOR_FADE_DARK_TOP, 1], [COLOR_GLASS_DARK_SURFACE, 0]]
                : [[COLOR_FADE_LIGHT, 0], [COLOR_GLASS_SURFACE, 0]]
            })
            .hitTestBehavior(HitTestMode.None)
        }
        .width('100%')
        .gesture(
          PanGesture({ direction: PanDirection.Horizontal, distance: 80 })
            .onActionEnd((event) => {
              // offsetX: 左滑为负，右滑为正
              if (event.offsetX < 0) {
                this.onSwipe(true)  // 左滑 → 下一频段
              } else if (event.offsetX > 0) {
                this.onSwipe(false) // 右滑 → 上一频段
              }
            })
        )
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: SPACE_SM })
    }
    .width('100%')
    .height('100%')
  }
}
