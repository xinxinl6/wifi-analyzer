import { COLOR_PRIMARY, COLOR_PRIMARY_LIGHT, COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY, COLOR_BACKGROUND, COLOR_SURFACE, COLOR_BORDER,
  COLOR_CHANNEL_IDLE, COLOR_CHANNEL_LIGHT, COLOR_CHANNEL_MODERATE, COLOR_CHANNEL_CROWDED,
  COLOR_CHANNEL_IDLE_TOP, COLOR_CHANNEL_LIGHT_TOP, COLOR_CHANNEL_MODERATE_TOP, COLOR_CHANNEL_CROWDED_TOP,
  COLOR_CHANNEL_RECOMMEND_BG, COLOR_CHANNEL_RECOMMEND_BORDER,
  COLOR_CHART_GRID, COLOR_DIVIDER_WEAK, COLOR_FADE_LIGHT, COLOR_CARD_SHADOW,
  COLOR_SIGNAL_EXCELLENT,
  COLOR_GLASS_BORDER_LIGHT, COLOR_SHADOW_GLASS,
  FONT_SIZE_XXS, FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL, FONT_SIZE_6XL, FONT_WEIGHT_BOLD, FONT_WEIGHT_MEDIUM,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL, SPACE_2XL, RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_XL, RADIUS_FULL, STROKE_WIDTH_SM, STROKE_WIDTH_MD, CARD_RADIUS, CARD_SHADOW_RADIUS, TAB_BAR_SAFE_BOTTOM } from '@wifi-analyzer/design-system'
import { WifiItem, SharedWifiState } from '@wifi-analyzer/core'

// 信道-AP数量对（用于排序）
interface ChannelCountPair {
  channel: number
  count: number
}

// 信道缓存数据（避免 build 中重复计算）
interface ChannelCacheData {
  channel: number
  count: number
  height: number
  barWidth: string
  color: string
  gradientTop: string
  gradientBottom: string
}

@Component
export struct ChannelSection {
  // 消费共享WiFi数据
  @Consume('wifiState') wifiState: SharedWifiState

  // 当前选中的频段
  @State currentBand: string = '2.4'

  // 预计算缓存（必须是 @State 才能触发 UI 更新）
  @State private cachedChannels: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  @State private cachedChannelData: ChannelCacheData[] = []
  @State private cachedRecommended: Array<ChannelCountPair> = []
  @State private cachedTotalCount: number = 0

  // 预定义的信道列表
  private readonly CHANNELS_2_4G: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
  private readonly CHANNELS_5G1: number[] = [36, 40, 44, 48]
  private readonly CHANNELS_5G2: number[] = [149, 153, 157, 161, 165]

  // 颜色配置
  private readonly COLOR_2_4G: string = '#3B82F6'  // 蓝色
  private readonly COLOR_5G1: string = '#8B5CF6'   // 紫色
  private readonly COLOR_5G2: string = '#EC4899'   // 粉色

  aboutToAppear(): void {
    this.currentBand = '2.4'
    this.recomputeChannelCache()
  }

  // 获取当前频段简称（Resource）
  private getBandShortName(): string {
    if (this.currentBand === '5g1') return '5.1'
    if (this.currentBand === '5g2') return '5.8'
    return '2.4'
  }

  // 获取当前频段名称（资源）
  private getBandNameResource(): Resource {
    if (this.currentBand === '5g1') return $r('app.string.5_2ghz')
    if (this.currentBand === '5g2') return $r('app.string.5_8ghz')
    return $r('app.string.2_4ghz')
  }

  // 获取当前频段描述（资源）
  private getBandDescriptionResource(): Resource {
    if (this.currentBand === '5g1') return $r('app.string.5_1ghz_desc')
    if (this.currentBand === '5g2') return $r('app.string.5_8ghz_desc')
    return $r('app.string.2_4ghz_desc')
  }

  // 获取网络数量标签
  private getNetworkCountLabel(): Resource {
    return $r('app.string.unit_network')
  }

  // 获取当前频段范围
  private getBandRange(): string {
    if (this.currentBand === '5g1') return '5150-5250 MHz'
    if (this.currentBand === '5g2') return '5725-5850 MHz'
    return '2400-2500 MHz'
  }

  // 获取当前频段颜色
  private getBandColor(): string {
    if (this.currentBand === '5g1') return this.COLOR_5G1
    if (this.currentBand === '5g2') return this.COLOR_5G2
    return this.COLOR_2_4G
  }

  // 获取当前信道列表
  private getCurrentChannels(): number[] {
    if (this.currentBand === '5g1') return this.CHANNELS_5G1
    if (this.currentBand === '5g2') return this.CHANNELS_5G2
    return this.CHANNELS_2_4G
  }

  // 统一预计算所有信道数据
  private recomputeChannelCache(): void {
    const channels: number[] = this.getCurrentChannels()
    this.cachedChannels = channels
    const list: WifiItem[] = this.wifiState.wifiList || []

    // 频段过滤
    const is2_4G: boolean = this.currentBand === '2.4'
    const is5G: boolean = !is2_4G

    // 单次遍历计算
    const counts: number[] = []
    let maxCount: number = 1
    let totalCount: number = 0

    for (let c = 0; c < channels.length; c++) {
      let count: number = 0
      for (let i = 0; i < list.length; i++) {
        const wifi: WifiItem = list[i]
        const freqMatch: boolean = (is2_4G && wifi.freq === 2.4) || (is5G && wifi.freq === 5.0)
        if (freqMatch && wifi.channel === channels[c]) {
          count++
        }
      }
      counts.push(count)
      totalCount += count
      if (count > maxCount) maxCount = count
    }
    maxCount = Math.max(maxCount, 1)
    this.cachedTotalCount = totalCount

    // 生成缓存数据
    const cacheData: ChannelCacheData[] = []
    for (let c = 0; c < channels.length; c++) {
      const count: number = counts[c]
      const height: number = Math.max(Math.round(20 + (count / maxCount) * 100), 10)
      const barPercent: number = Math.min(count / maxCount * 100, 100)

      cacheData.push({
        channel: channels[c],
        count: count,
        height: height,
        barWidth: barPercent + '%',
        color: count === 0 ? COLOR_CHANNEL_IDLE : count === 1 ? COLOR_CHANNEL_LIGHT : count <= 3 ? COLOR_CHANNEL_MODERATE : COLOR_CHANNEL_CROWDED,
        gradientTop: count === 0 ? COLOR_CHANNEL_IDLE_TOP : count === 1 ? COLOR_CHANNEL_LIGHT_TOP : count <= 3 ? COLOR_CHANNEL_MODERATE_TOP : COLOR_CHANNEL_CROWDED_TOP,
        gradientBottom: count === 0 ? COLOR_CHANNEL_IDLE : count === 1 ? COLOR_CHANNEL_LIGHT : count <= 3 ? COLOR_CHANNEL_MODERATE : COLOR_CHANNEL_CROWDED
      })
    }
    this.cachedChannelData = cacheData

    // 推荐信道
    const pairs: Array<ChannelCountPair> = []
    for (let c = 0; c < channels.length; c++) {
      pairs.push({ channel: channels[c], count: counts[c] })
    }
    pairs.sort((a: ChannelCountPair, b: ChannelCountPair): number => a.count - b.count)
    const limit: number = Math.min(3, pairs.length)
    this.cachedRecommended = pairs.slice(0, limit)
  }

  // 频段切换
  private onBandChange(band: string): void {
    if (this.currentBand === band) return
    this.currentBand = band
    this.recomputeChannelCache()
  }

  // 左右滑动切换频段
  private readonly BANDS: string[] = ['2.4', '5g1', '5g2']
  private onSwipe(isLeft: boolean): void {
    const idx: number = this.BANDS.indexOf(this.currentBand)
    if (isLeft) {
      // 左滑 → 下一个频段（循环）
      const next: number = (idx + 1) % this.BANDS.length
      this.onBandChange(this.BANDS[next])
    } else {
      // 右滑 → 上一个频段（循环）
      const prev: number = (idx - 1 + this.BANDS.length) % this.BANDS.length
      this.onBandChange(this.BANDS[prev])
    }
  }

  // 判断WiFi数据是否可用
  private isWifiDataAvailable(): boolean {
    return this.wifiState.connectedSsid !== '' && this.wifiState.wifiList.length > 0
  }

  // 获取空状态标题（资源）
  private getEmptyTitleResource(): Resource {
    if (!this.isWifiDataAvailable()) return $r('app.string.wifi_not_connected')
    if (this.cachedTotalCount === 0) {
      if (this.currentBand === '2.4') return $r('app.string.no_2_4g_network')
      if (this.currentBand === '5g1') return $r('app.string.no_5g1_network')
      return $r('app.string.no_5g2_network')
    }
    return $r('app.string.no_data')
  }

  // 获取空状态副标题（资源）
  private getEmptySubtitleResource(): Resource {
    if (!this.isWifiDataAvailable()) return $r('app.string.connect_wifi_hint_short')
    if (this.cachedTotalCount === 0) {
      if (this.currentBand === '2.4') return $r('app.string.no_2_4g_network_hint')
      if (this.currentBand === '5g1') return $r('app.string.no_5g1_network_hint')
      return $r('app.string.no_5g2_network_hint')
    }
    return $r('app.string.no_data')
  }

  // 获取指示器偏移量
  private getIndicatorMargin(): string {
    if (this.currentBand === '5g1') return '33.33%'
    if (this.currentBand === '5g2') return '66.66%'
    return '0%'
  }

  // 判断是否是5G频段
  private is5GBand(): boolean {
    return this.currentBand !== '2.4'
  }

  build() {
    Stack() {
      // ===== Aurora 天蓝渐变背景 =====
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['#C9E2F5', 0],
            ['#D6E9F8', 0.4],
            ['#E0F0FA', 0.75],
            ['#EAF4FB', 1]
          ]
        })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill('rgba(74,144,217,0.12)')
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill('rgba(135,206,235,0.10)')
        .position({ x: '68%', y: '45%' })

      // ===== 主内容层 =====
      Column() {
        // ===== 频段切换标签栏 =====
        this.buildBandTabs()

        // ===== 频段信息卡片 =====
        this.buildBandInfoCard()

        // ===== 内容区（支持左右滑动手势切换频段） =====
        Stack() {
          Scroll() {
            Column({ space: SPACE_MD }) {
              // 信道占用柱状图
              this.buildChartCard()

              // 推荐信道
              this.buildRecommendCard()

              // 信道详情列表
              this.buildDetailList()
            }
            .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: TAB_BAR_SAFE_BOTTOM })
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .scrollable(ScrollDirection.Vertical)
          .layoutWeight(1)
          .width('100%')
          .height('100%')

          // 底部边界渐变遮罩
          Column()
            .width('100%')
            .height(80)
            .position({ y: '100%' })
            .translate({ y: -80 })
            .linearGradient({
              direction: GradientDirection.Top,
              colors: [[COLOR_FADE_LIGHT, 0], ['rgba(245,247,250,0)', 1]]
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

  // ==================== Builder: 频段切换标签栏 ====================
  @Builder buildBandTabs() {
    Column() {
      Row() {
        this.buildBandTab('2.4GHz', '2.4')
        this.buildBandTab('5.2GHz', '5g1')
        this.buildBandTab('5.8GHz', '5g2')
      }
      .width('100%')
      .height(48)
      .padding({ left: SPACE_SM, right: SPACE_LG })

      // 底部滑动指示器
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('33.33%')
          .height(3)
          .backgroundColor(this.getBandColor())
          .borderRadius({ topLeft: 2, topRight: 2 })
          .margin({ left: this.getIndicatorMargin() })
          .animation({ duration: 250, curve: Curve.EaseInOut })
      }
      .width('100%')
      .height(3)
      .padding({ left: SPACE_SM, right: SPACE_SM })
    }
    .width('100%')
    .backgroundColor('rgba(74,144,217,0.10)')
    .shadow({ radius: 6, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
  }

  // ==================== Builder: 单个频段标签 ====================
  @Builder buildBandTab(label: string, band: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(FONT_SIZE_MD)
        .fontWeight(this.currentBand === band ? FONT_WEIGHT_BOLD : FONT_WEIGHT_MEDIUM)
        .fontColor(this.currentBand === band ? this.getBandColor() : COLOR_TEXT_SECONDARY)
        .animation({ duration: 200 })

      Circle()
        .width(this.currentBand === band ? 4 : 0)
        .height(4)
        .fill(this.currentBand === band ? this.getBandColor() : 'transparent')
        .animation({ duration: 200 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onBandChange(band))
  }

  // ==================== Builder: 频段信息卡片 ====================
  @Builder buildBandInfoCard() {
    Column() {
      Row() {
        // 频段图标
        Column() {
          Text(this.getBandShortName())
            .fontSize(FONT_SIZE_XS)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor(this.getBandColor())
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 2 }) {
          Text(this.getBandNameResource())
            .fontSize(FONT_SIZE_SM)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(COLOR_TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.getBandDescriptionResource())
            .fontSize(FONT_SIZE_XXS)
            .fontColor(COLOR_TEXT_TERTIARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .margin({ left: SPACE_SM })
        .alignItems(HorizontalAlign.Start)

        // 网络数量
        Column({ space: 0 }) {
          Text(this.cachedTotalCount + '')
            .fontSize(FONT_SIZE_XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(this.getBandColor())

          Text(this.getNetworkCountLabel())
            .fontSize(FONT_SIZE_XXS)
            .fontColor(COLOR_TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)

      // 频段范围
      Row() {
        Text(this.getBandRange())
          .fontSize(FONT_SIZE_XXS)
          .fontColor(COLOR_TEXT_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        Text('CH' + this.cachedChannels[0] + '-' + this.cachedChannels[this.cachedChannels.length - 1])
          .fontSize(FONT_SIZE_XXS)
          .fontColor(COLOR_TEXT_TERTIARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height(20)
      .margin({ top: SPACE_SM })
    }
    .width('95%')
    .height(88)
    .padding(SPACE_MD)
    .backgroundColor('rgba(255,255,255,0.60)')
    .borderRadius(CARD_RADIUS)
    .border({ width: 1, color: COLOR_GLASS_BORDER_LIGHT })
    .shadow({ radius: 8, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 2 })
    .backdropBlur(10)
    .margin({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: SPACE_MD })
  }

  // ==================== Builder: 柱状图卡片 ====================
  @Builder buildChartCard() {
    Column() {
      // 标题行
      Row() {
        Text($r('app.string.channel_distribution'))
          .fontSize(FONT_SIZE_LG)
          .fontColor(COLOR_TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT_BOLD)

        Blank()

        // 图例
        Row({ space: SPACE_SM }) {
          this.buildLegendDot(COLOR_CHANNEL_IDLE, $r('app.string.idle'))
          this.buildLegendDot(COLOR_CHANNEL_LIGHT, $r('app.string.light'))
          this.buildLegendDot(COLOR_CHANNEL_MODERATE, $r('app.string.moderate'))
          this.buildLegendDot(COLOR_CHANNEL_CROWDED, $r('app.string.crowded'))
        }
      }
      .width('100%')
      .margin({ bottom: SPACE_MD })

      // 柱状图区域
      if (this.cachedChannelData.length === 0 || this.cachedTotalCount === 0) {
        this.buildEmptyChart()
      } else {
        this.buildBarChart()
      }
    }
    .width('100%')
    .padding(SPACE_LG)
    .backgroundColor('rgba(255,255,255,0.60)')
    .borderRadius(CARD_RADIUS)
    .border({ width: 1, color: COLOR_GLASS_BORDER_LIGHT })
    .shadow({ radius: 8, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 2 })
    .backdropBlur(10)
  }

  // ==================== Builder: 空状态图表 ====================
  @Builder buildEmptyChart() {
    Column() {
      Column() {
        Text('📶')
          .fontSize(32)
      }
      .width(60)
      .height(60)
      .backgroundColor('#F0F9FF')
      .borderRadius(30)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(this.getEmptyTitleResource())
        .fontSize(FONT_SIZE_MD)
        .fontColor(COLOR_TEXT_TERTIARY)
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .margin({ top: SPACE_SM })

      Text(this.getEmptySubtitleResource())
        .fontSize(FONT_SIZE_XS)
        .fontColor(COLOR_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(110)
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== Builder: 柱状图 ====================
  @Builder buildBarChart() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景参考网格
      Column() {
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(COLOR_CHART_GRID)
          .opacity(0.5)
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(COLOR_CHART_GRID)
          .opacity(0.5)
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(COLOR_CHART_GRID)
          .opacity(0.5)
        Blank()
      }
      .width('100%')
      .height(100)

      // 柱状图主体 - 使用 Scroll 防止溢出
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.cachedChannelData, (item: ChannelCacheData) => {
            Column() {
              // 数量标签
              if (item.count > 0) {
                Text(item.count.toString())
                  .fontSize(13)
                  .fontWeight(FONT_WEIGHT_MEDIUM)
                  .fontColor(item.color)
                  .margin({ bottom: 2 })
              }

              // 柱体（固定宽度）
              Column()
                .width(24)
                .height(item.height)
                .linearGradient({
                  angle: 180,
                  colors: [[item.gradientTop, 0], [item.gradientBottom, 1]]
                })
                .borderRadius(RADIUS_SM)
                .shadow({
                  radius: 3,
                  color: item.color + '30',
                  offsetX: 0,
                  offsetY: 1
                })

              // 信道号
              Text(item.channel.toString())
                .fontSize(13)
                .fontColor(COLOR_TEXT_TERTIARY)
                .margin({ top: 4 })
            }
            .justifyContent(FlexAlign.End)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .height(100)
        .alignItems(VerticalAlign.Bottom)
        .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .height(100)
      .scrollBar(BarState.Off)
      .scrollable(ScrollDirection.Horizontal)
    }
    .width('100%')
    .height(110)
  }

  // ==================== Builder: 图例点 ====================
  @Builder buildLegendDot(color: string, label: Resource) {
    Row({ space: SPACE_XS }) {
      Circle()
        .width(6)
        .height(6)
        .fill(color)
      Text(label)
        .fontSize(FONT_SIZE_XXS)
        .fontColor(COLOR_TEXT_TERTIARY)
    }
  }

  // ==================== Builder: 推荐信道卡片 ====================
  @Builder buildRecommendCard() {
    Column() {
      Row() {
        Text($r('app.string.recommend_channels'))
          .fontSize(FONT_SIZE_LG)
          .fontColor(COLOR_TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT_BOLD)

        Blank()

        if (this.cachedTotalCount > 0) {
          Text($r('app.string.least_interference'))
            .fontSize(FONT_SIZE_XXS)
            .fontColor(COLOR_TEXT_TERTIARY)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: 2, bottom: 2 })
            .backgroundColor(COLOR_CHANNEL_RECOMMEND_BG)
            .borderRadius(RADIUS_SM)
        }
      }
      .width('100%')
      .margin({ bottom: SPACE_MD })

      if (this.cachedRecommended.length > 0) {
        Row({ space: SPACE_MD }) {
          ForEach(this.cachedRecommended, (item: ChannelCountPair) => {
            this.buildRecommendChip(item)
          })
        }
        .width('100%')
      } else {
        Row() {
          Text($r('app.string.no_recommend'))
            .fontSize(FONT_SIZE_SM)
            .fontColor(COLOR_TEXT_TERTIARY)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: SPACE_MD, bottom: SPACE_MD })
      }
    }
    .width('100%')
    .padding(SPACE_LG)
    .backgroundColor('rgba(255,255,255,0.60)')
    .borderRadius(CARD_RADIUS)
    .border({ width: 1, color: COLOR_GLASS_BORDER_LIGHT })
    .shadow({ radius: 8, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 2 })
    .backdropBlur(10)
  }

  // ==================== Builder: 推荐信道芯片 ====================
  @Builder buildRecommendChip(item: ChannelCountPair) {
    Column() {
      // 信道号
      Text('CH' + item.channel)
        .fontSize(FONT_SIZE_LG)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(COLOR_SUCCESS)

      if (item.count === 0) {
        Text($r('app.string.best'))
          .fontSize(FONT_SIZE_XXS)
          .fontColor(COLOR_CHANNEL_IDLE)
          .margin({ top: 2 })
      } else {
        Text() {
          Span($r('app.string.networks_found'))
          Span(' ' + item.count + ' ')
          Span($r('app.string.networks_unit'))
        }
          .fontSize(FONT_SIZE_XXS)
          .fontColor(COLOR_TEXT_TERTIARY)
          .margin({ top: 2 })
      }
    }
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: SPACE_MD, bottom: SPACE_MD })
    .backgroundColor(COLOR_CHANNEL_RECOMMEND_BG)
    .borderRadius(RADIUS_LG)
    .border({
      width: 1,
      color: COLOR_CHANNEL_RECOMMEND_BORDER,
      radius: RADIUS_LG
    })
  }

  // ==================== Builder: 信道详情列表 ====================
  @Builder buildDetailList() {
    Column() {
      Row() {
        Text($r('app.string.channel_detail'))
          .fontSize(FONT_SIZE_LG)
          .fontColor(COLOR_TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT_BOLD)

        Blank()

        Text(this.cachedChannels.length + ' 个信道')
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_TEXT_TERTIARY)
      }
      .width('100%')
      .margin({ bottom: SPACE_MD })

      // 列表内容
      ForEach(this.cachedChannelData, (item: ChannelCacheData) => {
        this.buildChannelRow(item)
      })
    }
    .width('100%')
    .padding(SPACE_LG)
    .backgroundColor('rgba(255,255,255,0.60)')
    .borderRadius(CARD_RADIUS)
    .border({ width: 1, color: COLOR_GLASS_BORDER_LIGHT })
    .shadow({ radius: 8, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 2 })
    .backdropBlur(10)
  }

  // ==================== Builder: 信道行 ====================
  @Builder buildChannelRow(item: ChannelCacheData) {
    Column() {
      Row({ space: SPACE_SM }) {
        // 信道号 + 状态指示
        Row({ space: 4 }) {
          Circle()
            .width(6)
            .height(6)
            .fill(item.color)

          Text('CH' + item.channel)
            .fontSize(FONT_SIZE_XS)
            .fontWeight(FONT_WEIGHT_MEDIUM)
            .fontColor(COLOR_TEXT_PRIMARY)
        }
        .width(50)

        // 占用条
        Row() {
          Row()
            .width(item.barWidth)
            .height(6)
            .linearGradient({
              angle: 90,
              colors: [[item.gradientTop, 0], [item.gradientBottom, 1]]
            })
            .borderRadius(3)
        }
        .backgroundColor(COLOR_CHART_GRID)
        .borderRadius(3)
        .layoutWeight(1)

        // AP 数量
        Row({ space: 2 }) {
          Text(item.count + '')
            .fontSize(FONT_SIZE_XS)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(item.color)

          Text($r('app.string.unit_count'))
            .fontSize(9)
            .fontColor(COLOR_TEXT_TERTIARY)
        }
        .width(36)
        .justifyContent(FlexAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分隔线
      if (item.channel !== this.cachedChannels[this.cachedChannels.length - 1]) {
        Divider()
          .color(COLOR_DIVIDER_WEAK)
          .strokeWidth(1)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}
