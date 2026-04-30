// Ping 测试页面 - 天蓝色透明毛玻璃悬浮风格
// 风格：天蓝色渐变背景 + 透明毛玻璃卡片 + 胶囊按钮

import { COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_DIVIDER,
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
import { http, connection, socket } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import promptAction from '@ohos.promptAction'

// 子组件
import { IdleView } from './PingIdleView'
import { TestingView } from './PingTestingView'
import { HistoryModal } from './PingHistoryModal'

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

export interface TcpPingResult {
  elapsed: number
  status: 'success' | 'timeout' | 'error'
}

interface TcpPortResult {
  success: boolean
  elapsed: number
  port: number
}

// ==================== Props 接口 ====================
interface PingTestPageProps {
  onBack?: () => void
}

// ==================== 组件 ====================
@Component
export struct PingTestPage {
  // 输入验证错误消息
  @State inputError: string = ''
  // 输入 & 网关检测
  @State inputText: string = ''
  @State detectedGateway: string = ''
  @State gatewayStatus: string = 'loading'
  @State detectedDns: string = ''

  // UI 状态
  @State viewMode: string = 'idle'

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

  aboutToAppear(): void {
    this.quickAddressList = [
      { name: 'www.baidu.com', url: 'https://www.baidu.com' },
      { name: 'www.aliyun.com', url: 'https://www.aliyun.com' },
      { name: 'cloud.tencent.com', url: 'https://cloud.tencent.com' }
    ]
    this.detectGateway()
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
    try {
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (!netHandle) {
        this.gatewayStatus = 'failed'
        return
      }

      connection.getConnectionProperties(
        netHandle,
        (err: BusinessError, data: connection.ConnectionProperties): void => {
          if (err) {
            this.gatewayStatus = 'failed'
            return
          }

          let gwIp: string = ''
          if (data.routes && data.routes.length > 0) {
            for (let r = 0; r < data.routes.length; r++) {
              const route = data.routes[r]
              if (route.isDefaultRoute === true && route.hasGateway === true && route.gateway !== undefined) {
                gwIp = route.gateway.address || ''
                if (gwIp !== '') break
              }
            }
          }

          let dnsIp: string = '223.5.5.5'
          if (data.dnses && data.dnses.length > 0) {
            const firstDns = data.dnses[0]
            if (firstDns && firstDns.address && firstDns.address.length > 0) {
              dnsIp = firstDns.address
            }
          }
          this.detectedDns = dnsIp

          if (gwIp !== '') {
            this.detectedGateway = gwIp
            this.gatewayStatus = 'ready'
          } else {
            this.gatewayStatus = 'failed'
          }
        }
      )
    } catch (error) {
      this.gatewayStatus = 'failed'
    }
  }

  // ==================== 业务逻辑 ====================
  onRecommendTap(index: number): void {
    // TCP Socket 方案：可以 ping 任意 IP + 常用端口
    // 自动尝试 80/443/22/23/53/8080 端口，找到第一个可用的
    switch (index) {
      case 0: // 网关
        if (this.detectedGateway !== '') {
          this.inputText = this.detectedGateway
        } else {
          this.inputText = '192.168.1.1'
        }
        this.startContinuousPing()
        break
      case 1: // DNS
        if (this.detectedDns !== '') {
          this.inputText = this.detectedDns
        } else {
          this.inputText = '223.5.5.5'
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
    this.pingTimerId = setInterval((): void => {
      if (!this.isPaused) {
        this.doSinglePing()
      }
    }, 1000)
  }

  async doSinglePing(): Promise<void> {
    const addr: string = this.targetHost
    if (!addr || addr.length === 0) return

    this.sessionStats.sentCount++

    const startTime: number = Date.now()
    let elapsed: number = -1
    let status: 'success' | 'timeout' | 'error' = 'error'

    // 获取目标 IP 地址（优先使用缓存）
    let targetIp: string = addr
    if (!/^\d+\.\d+\.\d+\.\d+$/.test(targetIp)) {
      // 先检查缓存
      if (this.cachedIpMap.has(addr)) {
        targetIp = this.cachedIpMap.get(addr) as string
      } else {
        // 缓存没有，解析并缓存
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

    // 并行尝试多个端口的 TCP Socket 连接
    const pingResult = await this.tcpPing(targetIp, addr)
    elapsed = pingResult.elapsed
    status = pingResult.status

    if (status === 'success') {
      this.sessionStats.receivedCount++
    }

    const result: PingResult = {
      address: addr,
      timeMs: status === 'success' ? Math.max(elapsed, 1) : -1,
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

  // TCP Socket Ping 实现 — 并行尝试多个端口
  // 缩短超时至 1.5s，最快响应的端口决定结果
  private async tcpPing(ipAddress: string, originalAddr: string): Promise<TcpPingResult> {
    // 常用端口列表
    // 80: HTTP, 443: HTTPS, 22: SSH, 23: Telnet, 53: DNS, 8080: HTTP-Alt
    const commonPorts: number[] = [80, 443, 22, 23, 53, 8080]
    const timeout: number = 1500

    // 并行发起所有端口连接
    const promises: Promise<TcpPortResult>[] = []
    for (let i = 0; i < commonPorts.length; i++) {
      const port: number = commonPorts[i]
      promises.push(this.tcpConnect(ipAddress, port, timeout))
    }

    const results: TcpPortResult[] = await Promise.all(promises)

    // 找到第一个成功的
    for (let i = 0; i < results.length; i++) {
      if (results[i].success) {
        return { elapsed: results[i].elapsed, status: 'success' }
      }
    }

    // 所有端口都失败，返回最快失败的用时（用于调试）
    let fastestFail: number = timeout
    for (let i = 0; i < results.length; i++) {
      if (results[i].elapsed < fastestFail) {
        fastestFail = results[i].elapsed
      }
    }
    return { elapsed: fastestFail, status: 'timeout' }
  }

  // 建立 TCP 连接 — 只用 connectOptions.timeout 控制超时
  private tcpConnect(host: string, port: number, timeout: number): Promise<TcpPortResult> {
    return new Promise<TcpPortResult>((resolve: (v: TcpPortResult) => void) => {
      try {
        const tcp: socket.TCPSocket = socket.constructTCPSocketInstance()
        const startTime: number = Date.now()

        // 创建连接选项（只用此处的 timeout，避免双重超时冲突）
        const tcpAddress: socket.NetAddress = { address: host, port: port }
        const connectOptions: socket.TCPConnectOptions = {
          address: tcpAddress,
          timeout: timeout
        }

        // 尝试连接
        tcp.connect(connectOptions, (err: BusinessError) => {
          const elapsed: number = Date.now() - startTime
          try {
            tcp.close()
          } catch (e) {
            // 忽略关闭错误
          }
          if (!err) {
            resolve({ success: true, elapsed: elapsed, port: port })
          } else {
            resolve({ success: false, elapsed: elapsed, port: port })
          }
        })
      } catch (e) {
        resolve({ success: false, elapsed: timeout, port: port })
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

    this.recalcStats()
    this.prepareChartData()
    this.saveToGlobalHistory(result)
  }

  private recalcStats(): void {
    const arr: PingResult[] = this.pingHistory
    if (arr.length === 0) return

    let successArr: number[] = []
    let received: number = 0
    for (let i = 0; i < arr.length; i++) {
      if (arr[i].status === 'success') {
        successArr.push(arr[i].timeMs)
        received++
      }
    }

    const lossRateVal: number = arr.length > 0 ? Math.round((1 - received / arr.length) * 10000) / 100 : 0
    let maxVal: number = 0
    let minVal: number = 0
    let sum: number = 0
    let jitterVal: number = 0
    let stabilityScoreVal: number = 100

    if (successArr.length > 0) {
      maxVal = successArr[0]
      minVal = successArr[0]
      sum = 0
      for (let j = 0; j < successArr.length; j++) {
        const v = successArr[j]
        if (v > maxVal) maxVal = v
        if (v < minVal) minVal = v
        sum += v
      }

      const avg: number = sum / successArr.length
      let varianceSum: number = 0
      for (let k = 0; k < successArr.length; k++) {
        const diff: number = successArr[k] - avg
        varianceSum += diff * diff
      }
      jitterVal = Math.round(Math.sqrt(varianceSum / successArr.length) * 100) / 100

      const lossPenalty: number = Math.min(lossRateVal * 2, 100)
      const jitterPenalty: number = Math.min(jitterVal / 10, 20)
      stabilityScoreVal = Math.max(0, 100 - lossPenalty - jitterPenalty)
      stabilityScoreVal = Math.round(stabilityScoreVal)
    }

    this.sessionStats = {
      sentCount: arr.length,
      receivedCount: received,
      lossRate: lossRateVal,
      maxTime: Math.round(maxVal * 100) / 100,
      minTime: Math.round(minVal * 100) / 100,
      avgTime: successArr.length > 0 ? Math.round((sum / successArr.length) * 100) / 100 : 0,
      jitter: jitterVal,
      stabilityScore: stabilityScoreVal
    }
  }

  prepareChartData(): void {
    const arr: PingResult[] = this.pingHistory
    if (arr.length === 0) {
      this.chartData = []
      this.chartMaxY = 35
      this.chartAvgMs = 0
      this.chartMinMs = 0
      this.chartMaxMs = 0
      return
    }

    const displayCount: number = Math.min(arr.length, 24)
    const startIndex: number = arr.length - displayCount
    const sliced: PingResult[] = arr.slice(startIndex)

    let maxY: number = 35
    let minValid: number = 999999
    let maxValid: number = 0
    let validSum: number = 0
    let validCount: number = 0

    for (let i = 0; i < sliced.length; i++) {
      if (sliced[i].status === 'success' && sliced[i].timeMs > 0) {
        if (sliced[i].timeMs > maxValid) maxValid = sliced[i].timeMs
        if (sliced[i].timeMs < minValid) minValid = sliced[i].timeMs
        validSum += sliced[i].timeMs
        validCount++
      }
    }

    if (maxValid > maxY) maxY = Math.ceil(maxValid / 10) * 10
    const avgV: number = validCount > 0 ? validSum / validCount : 0

    this.chartData = sliced
    this.chartMaxY = maxY
    this.chartAvgMs = avgV
    this.chartMinMs = minValid === 999999 ? 0 : minValid
    this.chartMaxMs = maxValid
  }

  isChartBest(item: PingResult): boolean {
    return item.status === 'success' && item.timeMs > 0 && item.timeMs === this.chartMinMs && this.chartMinMs > 0
  }

  isChartWorst(item: PingResult): boolean {
    return item.status === 'success' && item.timeMs > 0 && item.timeMs === this.chartMaxMs && this.chartMaxMs > 0
  }

  private saveToGlobalHistory(result: PingResult): void {
    const globalHistory = AppStorage.get<Array<PingResult>>('pingHistory')
    if (globalHistory) {
      globalHistory.unshift(result)
      if (globalHistory.length > 50) globalHistory.pop()
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

    const summary: PingSessionSummary = {
      timestamp: Date.now(),
      targetHost: this.targetHost,
      avgTime: this.sessionStats.avgTime,
      lossRate: this.sessionStats.lossRate,
      jitter: this.sessionStats.jitter,
      stabilityScore: this.sessionStats.stabilityScore,
      pingCount: this.pingHistory.length
    }

    this.sessionSummaries.unshift(summary)
    if (this.sessionSummaries.length > 20) {
      this.sessionSummaries.pop()
    }
    const refreshed: PingSessionSummary[] = []
    for (let i = 0; i < this.sessionSummaries.length; i++) {
      refreshed.push(this.sessionSummaries[i])
    }
    this.sessionSummaries = refreshed
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${hours}:${minutes}`
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
      return $r('app.string.err_empty_input').toString()
    }
    if (trimmed.length > 255) {
      return $r('app.string.err_input_too_long').toString()
    }
    // 验证是否为有效的IP或域名
    if (!ValidationPatterns.isValidIpOrDomain(trimmed)) {
      return $r('app.string.err_invalid_ip_or_domain').toString()
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
      if (/^\d+\.\d+\.\d+\.\d+$/.test(this.targetHost)) return $r('app.string.target_ip').toString()
      return $r('app.string.domain').toString()
    }
    return $r('app.string.target').toString()
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

      // 主内容
      Column() {
        // 顶部返回按钮栏（华为标准：只显示箭头，不显示文字）
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP, bottom: SAFE_AREA_BOTTOM })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'testing') {
          TestingView({
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
            isChartBest: (item: PingResult) => this.isChartBest(item),
            isChartWorst: (item: PingResult) => this.isChartWorst(item),
            onEndTest: () => this.endTest(),
            onTogglePause: () => this.togglePause(),
            onChartModeChange: (mode: string) => { this.chartMode = mode }
          })
        } else {
          IdleView({
            inputText: this.inputText,
            gatewayStatus: this.gatewayStatus,
            detectedGateway: this.detectedGateway,
            detectedDns: this.detectedDns,
            quickAddressList: this.quickAddressList,
            onInputChange: (value: string) => { this.inputText = value },
            onRecommendTap: (index: number) => this.onRecommendTap(index),
            onStartPing: () => this.startContinuousPing(),
            hasQuickAddresses: () => this.hasQuickAddresses()
          })
        }

        if (this.showHistoryModal) {
          HistoryModal({
            pingHistory: this.pingHistory,
            onClose: () => { this.showHistoryModal = false },
            getGlobalHistForModal: () => this.getGlobalHistForModal(),
            onClearHistory: () => {
              AppStorage.set('pingHistory', new Array<PingResult>())
            }
          })
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }

}
