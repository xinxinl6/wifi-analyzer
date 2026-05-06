// Ping 测试页面 — 天蓝色透明毛玻璃悬浮风格
// 使用 TCP 连接检测网络连通性

import promptAction from '@ohos.promptAction'
import { COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_SOLID, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_LINE,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL, GLASS_SHADOW_3XL, SAFE_AREA_BOTTOM, SAFE_AREA_TOP,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider,
  PulseIndicator } from '@wifi-analyzer/design-system'
import {
  PingEngine, PingResult, PingStats, PingConfig
} from '../ping/PingEngine'
import { RouterManager, ValidationPatterns, DnsConfig, DiagnosticsConfig } from '@wifi-analyzer/core'
import { BackButtonGlass, BackButtonCapsule } from '@wifi-analyzer/design-system'

// ==================== 接口定义 ====================

interface QuickTargetItem {
  name: string
  address: string
}

// ==================== 组件 ====================

@Component
export struct PingPage {
  @Consume isDarkMode: boolean = false
  @State detectedGateway: string = ''
  @State inputText: string = ''
  @State viewMode: string = 'idle'

  // 推荐目标
  private recommendItems: QuickTargetItem[] = [
    { name: '网关', address: '' },
    { name: 'DNS', address: DnsConfig.ALI_DNS },
    { name: '百度', address: 'baidu.com' }
  ]

  @State pingResults: PingResult[] = []
  @State pingStats: PingStats = {
    sent: 0, received: 0, lost: 0, lossRate: 0,
    minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0
  }
  @State targetHost: string = ''
  @State resolvedIp: string = ''
  @State isRunning: boolean = false
  @State progress: string = '0/0'

  private engine: PingEngine = new PingEngine()
  private pulser: PulseIndicator = new PulseIndicator()

  aboutToAppear(): void {
    this.detectGateway()
  }

  aboutToDisappear(): void {
    this.engine.stopPing()
    this.pulser.stop()
  }

  // ==================== 网关检测 ====================
  private detectGateway(): void {
    this.engine.resolveHost(DiagnosticsConfig.DEFAULT_GATEWAY)
      .then((gw: string) => {
        this.detectedGateway = gw
        if (this.recommendItems.length > 0) {
          this.recommendItems[0].address = gw || DiagnosticsConfig.DEFAULT_GATEWAY
        }
      })
  }

  // ==================== 业务逻辑 ====================

  // 验证目标地址输入
  private validateTarget(addr: string): string {
    const trimmed: string = addr.trim()

    if (trimmed.length === 0) {
      return '请输入目标地址'
    }

    if (trimmed.length > 255) {
      return '输入地址过长'
    }

    if (!ValidationPatterns.isValidIpOrDomain(trimmed)) {
      return '无效的IP地址或域名格式'
    }

    return ''
  }

  onRecommendTap(index: number): void {
    const item = this.recommendItems[index]
    if (item.address) {
      this.inputText = item.address
    }
  }

  startPing(): void {
    const addr: string = this.inputText.trim()

    // 输入验证
    const errorMsg: string = this.validateTarget(addr)
    if (errorMsg !== '') {
      promptAction.showToast({
        message: errorMsg,
        duration: 2000
      })
      return
    }

    this.targetHost = addr
    this.resolvedIp = addr
    this.pingResults = []
    this.pingStats = {
      sent: 0, received: 0, lost: 0, lossRate: 0,
      minTime: 0, maxTime: 0, avgTime: 0, totalTime: 0
    }
    this.isRunning = true
    this.viewMode = 'pinging'
    this.pulser.start()
    this.progress = '0/4'

    const config: PingConfig = PingEngine.getDefaultConfig(addr)
    this.engine.startPing(config, {
      onResult: (result: PingResult): void => {
        this.pingResults = [...this.pingResults, result]
        this.pingStats = PingEngine.calcStats(this.pingResults)
        if (this.resolvedIp !== result.address && result.address !== addr) {
          this.resolvedIp = result.address
        }
      },
      onProgress: (sent: number, received: number): void => {
        this.progress = `${sent}/4`
      },
      onComplete: (results: PingResult[], stats: PingStats): void => {
        this.pingResults = results
        this.pingStats = stats
        this.isRunning = false
        this.pulser.stop()
        this.viewMode = 'completed'
      },
      onError: (message: string): void => {
        console.error('[PingPage] Error:', message)
        this.isRunning = false
        this.pulser.stop()
        this.viewMode = 'completed'
        promptAction.showToast({
          message: 'Ping 失败: ' + message,
          duration: 3000
        })
      }
    })
  }

  stopPing(): void {
    this.engine.stopPing()
    this.isRunning = false
    this.pulser.stop()
    if (this.pingResults.length > 0) {
      this.viewMode = 'completed'
    } else {
      this.viewMode = 'idle'
    }
  }

  getStatusIcon(status: string): string {
    if (status === 'success') return '✓'
    if (status === 'timeout') return '⏳'
    return '✗'
  }

  getStatusColor(status: string): string {
    if (status === 'success') return COLOR_SUCCESS
    if (status === 'timeout') return COLOR_WARNING
    return COLOR_DANGER
  }

  // ==================== 页面入口 ====================
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

      // 主内容
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          this.IdleView()
        } else {
          this.PingView()
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

  // ==================== 初始视图 ====================
  @Builder IdleView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 大标题区
        Column({ space: 6 }) {
          Text('Ping 测试')
            .fontSize(FONT_SIZE_2XL)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
          Text('检测网络连通性与延迟')
            .fontSize(FONT_SIZE_SM)
            .fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        // 搜索栏
        this.SearchBarSection()

        // 推荐标签
        this.RecommendTagsSection()

        // 功能说明卡片
        this.FeatureCardsSection()
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 搜索栏
  @Builder SearchBarSection() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_device'))
        .width(20).height(20)
        .fillColor(COLOR_SKY_BLUE)

      TextInput({ placeholder: '输入 IP 或域名', text: this.inputText })
        .layoutWeight(1)
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .onChange((value: string) => { this.inputText = value })
        .onSubmit(() => this.startPing())

      // Ping 按钮
      Row() {
        Text('Ping')
          .fontSize(FONT_SIZE_SM)
          .fontColor('#FFFFFF')
          .fontWeight(FONT_WEIGHT_BOLD)
      }
      .padding({ left: 18, right: 18, top: 9, bottom: 9 })
      .backgroundColor(COLOR_SKY_BLUE)
      .borderRadius(999)
      .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 4 })
      .onClick(() => this.startPing())
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 推荐标签
  @Builder RecommendTagsSection() {
    Column({ space: 8 }) {
      Text('快速测试')
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Row({ space: SPACE_SM }) {
        ForEach(this.recommendItems, (item: QuickTargetItem, index: number) => {
          Row({ space: 5 }) {
            Text(index === 0 ? '🛡' : index === 1 ? '🔍' : '🌐')
              .fontSize(14)
            Text(item.name)
              .fontSize(FONT_SIZE_MD)
              .fontColor(COLOR_SKY_BLUE)
              .fontWeight(FONT_WEIGHT_MEDIUM)
          }
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
          .borderWidth(1)
          .borderColor(this.isDarkMode ? 'rgba(14,165,233,0.25)' : COLOR_GLASS_SKY_TAG_BORDER)
          .onClick(() => this.onRecommendTap(index))
        }, (item: QuickTargetItem, index: number): string => String(index))
      }
      .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  // 功能说明卡片
  @Builder FeatureCardsSection() {
    Column({ space: 0 }) {
      Text('功能介绍')
        .fontSize(FONT_SIZE_SM)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .width('100%')
        .padding({ bottom: 12 })

      Column({ space: 0 }) {
        this.FeatureItem('⏱', '延迟检测', '测量到目标的网络往返延迟')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📊', '连通性分析', '检测网络是否可达')
        Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
        this.FeatureItem('📈', '统计报告', '丢包率、平均延迟等数据')
      }
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(18)
      .borderWidth(1.5)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .backdropBlur(GLASS_BLUR_LG)
      .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
      .clip(true)
    }
    .width('100%')
  }

  @Builder FeatureItem(emoji: string, title: string, desc: string) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(38).height(38)
          .fill(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_ACTIVE)
        Text(emoji).fontSize(16)
      }

      Column({ space: 3 }) {
        Text(title)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Text(desc)
          .fontSize(FONT_SIZE_XS)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
  }

  // ==================== Ping 结果视图 ====================
  @Builder PingView() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        // 目标信息卡片
        this.TargetInfoCard()

        // 统计概览
        if (this.pingResults.length > 0) {
          this.StatsOverviewCard()
        }

        // Ping 结果列表
        if (this.pingResults.length > 0) {
          this.PingResultsCard()
        }

        // 操作按钮
        if (this.viewMode !== 'idle') {
          this.ActionButtons()
        }
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 目标信息卡片
  @Builder TargetInfoCard() {
    Row({ space: 14 }) {
      // 脉冲图标
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_LIGHT)
          .opacity(this.isRunning ? this.pulser.opacity : 1.0)
        Circle().width(36).height(36)
          .fill(this.isRunning ? COLOR_SKY_BLUE : (this.viewMode === 'completed' ? COLOR_SUCCESS : COLOR_SKY_BLUE))
        Image($r('app.media.ic_device')).width(18).height(18).fillColor('#FFFFFF')
      }

      Column({ space: 4 }) {
        Text(this.targetHost)
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          if (this.resolvedIp !== this.targetHost && this.resolvedIp.length > 0) {
            Text(this.resolvedIp)
              .fontSize(FONT_SIZE_XS)
              .fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
          if (this.isRunning) {
            Row({ space: 4 }) {
              Circle().width(5).height(5)
                .fill(COLOR_SKY_BLUE)
                .opacity(this.pulser.opacity)
              Text('Pinging ' + this.progress)
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SKY_BLUE)
            }
          } else if (this.viewMode === 'completed') {
            Row({ space: 4 }) {
              Circle().width(5).height(5).fill(COLOR_SUCCESS)
              Text('完成')
                .fontSize(FONT_SIZE_XS)
                .fontColor(COLOR_SUCCESS)
            }
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 重新输入按钮
      Row() {
        Text('🔍').fontSize(14)
      }
      .width(34).height(34)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(10)
      .onClick(() => {
        this.viewMode = 'idle'
        this.inputText = this.targetHost
      })
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 统计概览
  @Builder StatsOverviewCard() {
    Row() {
      this.StatCell('发送', String(this.pingStats.sent), COLOR_SKY_BLUE)
      this.StatDivider()
      this.StatCell('成功', String(this.pingStats.received), COLOR_SUCCESS)
      this.StatDivider()
      this.StatCell('丢包', String(this.pingStats.lossRate) + '%', this.pingStats.lossRate > 0 ? COLOR_DANGER : COLOR_SUCCESS)
      this.StatDivider()
      this.StatCell('平均', this.pingStats.avgTime > 0 ? String(this.pingStats.avgTime) + 'ms' : '--', COLOR_SKY_BLUE_LIGHT)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  @Builder StatCell(label: string, value: string, valueColor: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(FONT_SIZE_2XL)
        .fontColor(valueColor)
        .fontWeight(FONT_WEIGHT_BOLD)
      Text(label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder StatDivider() {
    Column()
      .width(1).height(36)
      .backgroundColor(adaptiveDivider(this.isDarkMode))
  }

  // Ping 结果列表
  @Builder PingResultsCard() {
    Column({ space: 0 }) {
      // 卡片标题
      Row() {
        Row({ space: 6 }) {
          Text('📊').fontSize(14)
          Text('Ping 结果')
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        Text(this.pingStats.received + '/' + this.pingStats.sent)
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_SKY_BLUE)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.isDarkMode ? 'rgba(14,165,233,0.15)' : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(999)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      // 分割线
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      // 结果列表
      Column({ space: 0 }) {
        ForEach(this.pingResults, (result: PingResult, index: number) => {
          this.PingResultItem(result, index)
        }, (result: PingResult, index: number): string => String(result.index))
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  // Ping 结果项
  @Builder PingResultItem(result: PingResult, index: number) {
    Row({ space: SPACE_SM }) {
      // 序号
      Text(String(result.index))
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .width(24)
        .textAlign(TextAlign.Center)

      // 状态图标
      Text(this.getStatusIcon(result.status))
        .fontSize(FONT_SIZE_MD)
        .fontColor(this.getStatusColor(result.status))
        .width(24)
        .textAlign(TextAlign.Center)

      // IP 地址
      Text(result.address)
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 延迟
      if (result.status === 'success') {
        Text(result.time + 'ms')
          .fontSize(FONT_SIZE_SM)
          .fontColor(this.getLatencyColor(result.time))
          .fontWeight(FONT_WEIGHT_BOLD)
      } else {
        Text(result.status === 'timeout' ? '超时' : '失败')
          .fontSize(FONT_SIZE_SM)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })

    // 分隔线
    if (index < this.pingResults.length - 1) {
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
    }
  }

  getLatencyColor(latency: number): string {
    if (latency <= 0) return COLOR_TEXT_TERTIARY
    if (latency <= 50) return COLOR_SUCCESS
    if (latency <= 100) return COLOR_SKY_BLUE
    if (latency <= 200) return COLOR_WARNING
    return COLOR_DANGER
  }

  // 操作按钮
  @Builder ActionButtons() {
    Row({ space: SPACE_MD }) {
      // 返回按钮
      BackButtonCapsule({ onBack: () => RouterManager.goBack() })

      // 停止/重新 Ping 按钮
      if (this.isRunning) {
        Row() {
          Text('停止').fontSize(FONT_SIZE_MD).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor('rgba(239,68,68,0.85)')
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? 'rgba(239,68,68,0.5)' : 'rgba(239,68,68,0.35)', offsetX: 0, offsetY: 5 })
        .onClick(() => this.stopPing())
      } else {
        Row() {
          Text('重新 Ping').fontSize(FONT_SIZE_MD).fontColor('#FFFFFF').fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor(COLOR_SKY_BLUE)
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
        .onClick(() => this.startPing())
      }
    }
    .width('100%')
  }
}
