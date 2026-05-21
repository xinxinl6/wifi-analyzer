// Ping 测试页面 - 天蓝色透明毛玻璃悬浮风格
// 风格：天蓝色渐变背景 + 透明毛玻璃卡片 + 胶囊按钮

import { adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_BACKGROUND, COLOR_SUCCESS, COLOR_WARNING,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_SOLID, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_GLASS_SKY_SHADOW_MED, COLOR_GLASS_SKY_LINE,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  GLASS_BLUR_LG, GLASS_BLUR_MD, GLASS_BLUR_XL,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG, GLASS_SHADOW_XL, SAFE_AREA_BOTTOM, SAFE_AREA_TOP } from '@wifi-analyzer/design-system'
import { http, connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import promptAction from '@ohos.promptAction'
import { NativePing, PingMode, usToMs, getDuration } from '../utils/NativePing'
import { PingStorage, StoredPingResult, StoredSessionSummary } from '../utils/PingStorage'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { IdleView } from './PingIdleView'
import { TestingView } from './PingTestingView'
import { HistoryModal } from './PingHistoryModal'
import { GatewayDetector } from '../utils/GatewayDetector'
import { PingStatsHelper } from '../utils/PingStatsHelper'

const DOMAIN = 0x0000

// ==================== 类型定义 ====================
export interface PingResult {
  address: string
  timeMs: number
  timestamp: number
  status: 'success' | 'timeout' | 'error'
}

export interface QuickAddressItem {
  name: Resource | string
  url: string
}

export interface PingStats {
  sentCount: number
  receivedCount: number
  lossRate: number
  maxTime: number
  minTime: number
  avgTime: number
  jitter: number
  stabilityScore: number
}

export interface PingSessionSummary {
  timestamp: number
  targetHost: string
  avgTime: number
  lossRate: number
  jitter: number
  stabilityScore: number
  pingCount: number
}

// ==================== Props 接口 ====================
interface PingTestPageProps {
  onBack?: () => void
}

// ==================== 组件 ====================
@Component
export struct PingTestPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  // 输入验证错误消息
  @State inputError: string = ''
  // 输入 & 网关检测
  @State inputText: string = ''
  @State detectedGateway: string = ''
  @State gatewayStatus: string = 'loading'
  @State detectedDns: string = ''

  // UI 状态
  @State viewMode: string = 'idle'

  // Ping 模式：快速(1s) / 准确(3s)
  @State pingMode: PingMode = PingMode.FAST

  // Native Ping 支持性
  private nativeSupported: boolean = false

  // 推荐标签 — 使用有 HTTP 服务的外部站点
  private recommendItems: Resource[] = [
    $r('app.string.baidu'),
    $r('app.string.aliyun'),
    $r('app.string.tencent')
  ]

  // 常用地址列表
  @State quickAddressList: QuickAddressItem[] = []

  // 连续 Ping 数据
  @State pingHistory: PingResult[] = []
  @State sessionStats: PingStats = {
    sentCount: 0, receivedCount: 0, lossRate: 0,
    maxTime: 0, minTime: 0, avgTime: 0,
    jitter: 0, stabilityScore: 100
  }

  // 会话历史摘要
  @State sessionSummaries: PingSessionSummary[] = []

  // 图表显示模式
  @State chartMode: string = 'live'

  // 当前目标信息
  @State targetHost: string = ''
  @State resolvedIp: string = ''

  // 控制
  private pingTimerId: number = -1
  @State isPaused: boolean = false
  @State isTesting: boolean = false

  // DNS 缓存（本次会话解析一次即可）
  private cachedIpMap: Map<string, string> = new Map()

  // 历史记录弹窗
  @State showHistoryModal: boolean = false

  // 图表计算结果
  @State chartData: PingResult[] = []
  @State chartMaxY: number = 35
  @State chartAvgMs: number = 0
  @State chartMinMs: number = 0
  @State chartMaxMs: number = 0

  // 最新单条 ping 结果（实时显示用）
  @State lastPingResult: PingResult | null = null

  // 获取资源字符串的辅助方法
  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
      return ''
    }
  }

  aboutToAppear(): void {
    this.quickAddressList = [
      { name: 'www.baidu.com', url: 'https://www.baidu.com' },
      { name: 'www.aliyun.com', url: 'https://www.aliyun.com' },
      { name: 'cloud.tencent.com', url: 'https://cloud.tencent.com' }
    ]
    this.detectGateway()
    // 检测 Native ICMP Ping 是否可用
    this.nativeSupported = NativePing.isSupported()

    // 初始化持久化存储 & 加载历史数据
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
    if (ctx) {
      PingStorage.init(ctx).then((): void => {
        this.loadPersistedData()
      })
    }

    // 兼容 AppStorage（内存缓存）
    if (!AppStorage.has('pingHistory')) {
      AppStorage.set('pingHistory', new Array<PingResult>())
    }
  }

  aboutToDisappear(): void {
    this.endTest()
  }

  // ==================== 网关 & DNS 检测 ====================
  detectGateway(): void {
    this.gatewayStatus = 'loading'
    GatewayDetector.detect((result) => {
      this.detectedGateway = result.gateway
      this.detectedDns = result.dns
      this.gatewayStatus = result.status
    })
  }

  // 仅填充网关地址到输入框（不立即开始Ping）
  onFillGateway(): void {
    if (this.detectedGateway !== '') {
      this.inputText = this.detectedGateway
    } else {
      // 如果未检测到，显示默认网关
      this.inputText = GatewayDetector.getDefaultGateway()
    }
  }

  // ==================== 业务逻辑 ====================
  onRecommendTap(index: number): void {
    // Native ICMP Ping：支持 IP 和域名探测
    switch (index) {
      case 0: // 网关
        if (this.detectedGateway !== '') {
          this.inputText = this.detectedGateway
        } else {
          this.inputText = GatewayDetector.getDefaultGateway()
        }
        // 仅填充地址，不立即开始Ping
        break
      case 1: // DNS
        if (this.detectedDns !== '') {
          this.inputText = this.detectedDns
        } else {
          this.inputText = GatewayDetector.getDefaultDns()
        }
        this.startContinuousPing()
        break
      case 2: // 百度
        this.inputText = 'www.baidu.com'
        this.startContinuousPing()
        break
    }
  }

  startContinuousPing(): void {
    const addr: string = this.inputText.trim()
    // 输入验证
    const errorMsg = this.validateInput(addr)
    if (errorMsg !== '') {
      promptAction.showToast({ message: errorMsg, duration: 2000 })
      return
    }

    this.targetHost = addr
    this.resolvedIp = addr
    this.pingHistory = []
    this.sessionStats = {
      sentCount: 0, receivedCount: 0, lossRate: 0,
      maxTime: 0, minTime: 0, avgTime: 0,
      jitter: 0, stabilityScore: 100
    }
    this.isTesting = true
    this.isPaused = false
    this.viewMode = 'testing'
    this.lastPingResult = null

    this.chartData = []
    this.chartMaxY = 35
    this.chartAvgMs = 0
    this.chartMinMs = 0
    this.chartMaxMs = 0

    // 清空 DNS 缓存，开始新的解析
    this.cachedIpMap.clear()

    // 立即开始第一次 ping
    this.doSinglePing()
    // 根据模式设置刷新间隔：快速模式1s，准确模式3s（与 Native duration 对齐）
    const intervalMs = getDuration(this.pingMode) * 1000
    this.pingTimerId = setInterval((): void => {
      if (!this.isPaused) {
        this.doSinglePing()
      }
    }, intervalMs)
  }

  async doSinglePing(): Promise<void> {
    const addr: string = this.targetHost
    if (!addr || addr.length === 0) return

    this.sessionStats.sentCount++

    let elapsed: number = -1
    let status: 'success' | 'timeout' | 'error' = 'error'

    // 获取目标 IP 地址（优先使用缓存，Native API 需要传入地址）
    let targetIp: string = addr
    if (!/^\d+\.\d+\.\d+\.\d+$/.test(targetIp)) {
      if (this.cachedIpMap.has(addr)) {
        targetIp = this.cachedIpMap.get(addr) as string
      } else {
        targetIp = await this.resolveDomain(targetIp)
        if (targetIp !== '') {
          this.cachedIpMap.set(addr, targetIp)
        }
      }
      if (targetIp === '') {
        // DNS 解析失败
        status = 'error'
        const result: PingResult = {
          address: addr,
          timeMs: -1,
          timestamp: Date.now(),
          status: status
        }
        this.addPingResult(result)
        return
      }
    }

    // 更新显示的解析 IP
    this.resolvedIp = targetIp

    // ★ 核心：使用 Native ICMP 探测（替换原 TCP Socket Ping）
    try {
      const probeResult = await NativePing.probe(targetIp, this.pingMode)

      if (probeResult.error === 0 && probeResult.minRtt >= 0) {
        // 成功：微秒 → 毫秒
        elapsed = usToMs(probeResult.minRtt)
        if (elapsed === 0) elapsed = 1  // 避免 0ms 显示异常
        // 根据丢包率判断状态：100%丢包视为超时
        status = probeResult.lossRate >= 100 ? 'timeout' : 'success'
      } else {
        // Native 返回错误码
        status = 'error'
      }
    } catch (e) {
      // Native 调用异常
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingTest] Native probe exception: ' + JSON.stringify(e))
      status = 'error'
    }

    if (status === 'success') {
      this.sessionStats.receivedCount++
    }

    const result: PingResult = {
      address: addr,
      timeMs: status === 'success' ? elapsed : -1,
      timestamp: Date.now(),
      status: status
    }

    this.addPingResult(result)
  }

  // 解析域名为 IP 地址
  private async resolveDomain(domain: string): Promise<string> {
    return await new Promise<string>((resolve: (v: string) => void) => {
      let cleanDomain: string = domain
      if (cleanDomain.indexOf('http') >= 0) {
        cleanDomain = domain.replace(/^https?:\/\//, '').replace(/\/.*$/, '')
      }
      if (/^\d+\.\d+\.\d+\.\d+$/.test(cleanDomain)) {
        resolve(cleanDomain)
        return
      }

      try {
        const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
        if (!netHandle) {
          resolve('')
          return
        }
        connection.getAddressesByName(
          cleanDomain,
          (err: BusinessError, addresses: Array<connection.NetAddress>): void => {
            if (!err && addresses && addresses.length > 0) {
              resolve(addresses[0].address || '')
            } else {
              resolve('')
            }
          }
        )
      } catch (error) {
        resolve('')
      }
    })
  }

  // 添加 Ping 结果到历史
  private addPingResult(result: PingResult): void {
    this.pingHistory.push(result)
    if (this.pingHistory.length > 50) {
      this.pingHistory.shift()
    }

    // 更新最新单条 ping 结果
    this.lastPingResult = result

    // 使用 PingStatsHelper 计算统计数据
    this.sessionStats = PingStatsHelper.recalcStats(this.pingHistory)

    // 使用 PingStatsHelper 准备图表数据
    const chartResult = PingStatsHelper.prepareChartData(this.pingHistory)
    this.chartData = chartResult.chartData
    this.chartMaxY = chartResult.chartMaxY
    this.chartAvgMs = chartResult.chartAvgMs
    this.chartMinMs = chartResult.chartMinMs
    this.chartMaxMs = chartResult.chartMaxMs

    this.saveToGlobalHistory(result)
  }

  isChartBest(item: PingResult): boolean {
    return PingStatsHelper.isChartBest(item, this.chartMinMs)
  }

  isChartWorst(item: PingResult): boolean {
    return PingStatsHelper.isChartWorst(item, this.chartMaxMs)
  }

  private saveToGlobalHistory(result: PingResult): void {
    // 内存缓存（给 HistoryModal 实时用）
    const globalHistory = AppStorage.get<Array<PingResult>>('pingHistory')
    if (globalHistory) {
      globalHistory.unshift(result)
      if (globalHistory.length > 50) globalHistory.pop()
    }
    // 持久化存储
    const stored: StoredPingResult = {
      address: result.address,
      timeMs: result.timeMs,
      timestamp: result.timestamp,
      status: result.status
    }
    PingStorage.addPingResult(stored)
  }

  /** 从持久化存储加载数据 */
  private async loadPersistedData(): Promise<void> {
    try {
      // 加载会话摘要
      const summaries = await PingStorage.loadSessionSummaries()
      if (summaries.length > 0) {
        this.sessionSummaries = summaries
      }
      // 同步最新一批到 AppMemory（用于弹窗快速展示）
      const results = await PingStorage.loadPingResults()
      if (results.length > 0) {
        AppStorage.setOrCreate('pingHistory', results as PingResult[])
      }
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[PingTestPage] loadPersistedData error: ' + JSON.stringify(e))
    }
  }

  togglePause(): void {
    this.isPaused = !this.isPaused
  }

  stopPing(): void {
    if (this.pingTimerId >= 0) {
      clearInterval(this.pingTimerId)
      this.pingTimerId = -1
    }
    this.isTesting = false
    this.isPaused = false
  }

  private saveSessionSummary(): void {
    if (this.pingHistory.length === 0) return

    const summary: StoredSessionSummary = {
      timestamp: Date.now(),
      targetHost: this.targetHost,
      avgTime: this.sessionStats.avgTime,
      lossRate: this.sessionStats.lossRate,
      jitter: this.sessionStats.jitter,
      stabilityScore: this.sessionStats.stabilityScore,
      pingCount: this.pingHistory.length
    }

    // 内存 — 转为 PingSessionSummary 类型（ArkTS 不支持结构化类型赋值）
    const sessionEntry: PingSessionSummary = {
      timestamp: summary.timestamp,
      targetHost: summary.targetHost,
      avgTime: summary.avgTime,
      lossRate: summary.lossRate,
      jitter: summary.jitter,
      stabilityScore: summary.stabilityScore,
      pingCount: summary.pingCount
    }
    this.sessionSummaries.unshift(sessionEntry)
    if (this.sessionSummaries.length > 20) {
      this.sessionSummaries.pop()
    }
    const refreshed: PingSessionSummary[] = []
    for (let i = 0; i < this.sessionSummaries.length; i++) {
      refreshed.push(this.sessionSummaries[i])
    }
    this.sessionSummaries = refreshed

    // 持久化
    PingStorage.addSessionSummary(summary)
  }

  endTest(): void {
    this.stopPing()
    this.saveSessionSummary()
    this.viewMode = 'idle'
  }

  getGlobalHistForModal(): Array<PingResult> {
    const h = AppStorage.get<Array<PingResult>>('pingHistory')
    return h || new Array<PingResult>()
  }

  hasQuickAddresses(): boolean {
    if (this.quickAddressList.length === 0) return false
    if (this.gatewayStatus === 'loading') return false
    return true
  }

  // ==================== 输入验证 ====================
  private validateInput(addr: string): string {
    const trimmed = addr.trim()
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }
    if (trimmed.length > 255) {
      return this.getString($r('app.string.err_input_too_long'))
    }
    // 验证是否为有效的IP或域名
    if (!ValidationPatterns.isValidIpOrDomain(trimmed)) {
      return this.getString($r('app.string.err_invalid_ip_or_domain'))
    }
    // 特殊处理内网IP - Ping测试支持内网，所以这里只做提示不阻止
    return ''
  }

  getHostLabelResource(): Resource {
    if (this.targetHost.indexOf('.') > 0 && !this.targetHost.startsWith('http')) {
      if (/^\d+\.\d+\.\d+\.\d+$/.test(this.targetHost)) return $r('app.string.target_ip')
      return $r('app.string.domain_name')
    }
    return $r('app.string.target')
  }

  getHostLabel(): string {
    if (this.targetHost.indexOf('.') > 0 && !this.targetHost.startsWith('http')) {
      if (/^\d+\.\d+\.\d+\.\d+$/.test(this.targetHost)) return this.getString($r('app.string.target_ip'))
      return this.getString($r('app.string.domain'))
    }
    return this.getString($r('app.string.target'))
  }

  // ==================== Ping 模式切换 ====================

  /** 切换快速/准确模式 */
  togglePingMode(): void {
    this.pingMode = (this.pingMode === PingMode.FAST) ? PingMode.ACCURATE : PingMode.FAST
  }

  /** 获取当前模式显示文本 */
  getPingModeLabel(): Resource | string {
    return this.pingMode === PingMode.FAST ? $r('app.string.ping_fast_mode') : $r('app.string.ping_accurate_mode')
  }

  /** 获取当前模式描述文本 */
  getPingModeDesc(): Resource | string {
    return this.pingMode === PingMode.FAST ? $r('app.string.ping_mode_fast_desc') : $r('app.string.ping_mode_accurate_desc')
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
        // 顶部返回按钮栏（华为标准：只显示箭头，不显示文字）
        Row() {
          BackButtonGlass({ onBack: () => {
            if (this.viewMode === 'testing') {
              this.endTest()
            } else {
              RouterManager.goBack()
            }
          }})
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: 36, bottom: 4 })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'testing') {
          TestingView({
            isDarkMode: this.isDarkMode,
            pingHistory: this.pingHistory,
            sessionStats: this.sessionStats,
            sessionSummaries: this.sessionSummaries,
            targetHost: this.targetHost,
            resolvedIp: this.resolvedIp,
            isTesting: this.isTesting,
            isPaused: this.isPaused,
            chartMode: this.chartMode,
            chartData: this.chartData,
            chartMaxY: this.chartMaxY,
            chartAvgMs: this.chartAvgMs,
            chartMinMs: this.chartMinMs,
            chartMaxMs: this.chartMaxMs,
            lastPingResult: this.lastPingResult,
            pingMode: this.pingMode,
            isChartBest: (item: PingResult) => this.isChartBest(item),
            isChartWorst: (item: PingResult) => this.isChartWorst(item),
            onEndTest: () => this.endTest(),
            onTogglePause: () => this.togglePause(),
            onToggleMode: () => this.togglePingMode(),
            onChartModeChange: (mode: string) => { this.chartMode = mode }
          })
            .transition(TransitionEffect.asymmetric(
              TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
                .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
              TransitionEffect.OPACITY.animation({ duration: 200 })
            ))
        } else {
          IdleView({
            isDarkMode: this.isDarkMode,
            inputText: this.inputText,
            gatewayStatus: this.gatewayStatus,
            detectedGateway: this.detectedGateway,
            detectedDns: this.detectedDns,
            quickAddressList: this.quickAddressList,
            pingMode: this.pingMode,
            nativeSupported: this.nativeSupported,
            onInputChange: (value: string) => { this.inputText = value },
            onRecommendTap: (index: number) => this.onRecommendTap(index),
            onFillGateway: () => this.onFillGateway(),
            onStartPing: () => this.startContinuousPing(),
            onToggleMode: () => this.togglePingMode(),
            hasQuickAddresses: () => this.hasQuickAddresses(),
            onShowHistory: () => { this.showHistoryModal = true }
          })
            .transition(TransitionEffect.asymmetric(
              TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
                .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
              TransitionEffect.OPACITY.animation({ duration: 200 })
            ))
        }

      }
      .width('100%').height('100%')

      // 历史记录弹窗 — 放在 Stack 顶层作为覆盖层
      if (this.showHistoryModal) {
        HistoryModal({
          isDarkMode: this.isDarkMode,
          pingHistory: this.pingHistory,
          onClose: () => { this.showHistoryModal = false },
          getGlobalHistForModal: () => this.getGlobalHistForModal(),
          onClearHistory: () => {
            AppStorage.set('pingHistory', new Array<PingResult>())
            PingStorage.clearAll()
          },
          sessionSummaries: this.sessionSummaries
        })
      }
    }
    .width('100%').height('100%')
  }

}
