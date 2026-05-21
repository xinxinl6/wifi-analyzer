// 路由追踪页面 — 状态管理 + 容器编排
// 子组件：TracerouteIdleView / TracerouteTraceView / TraceroutePathCard
//         TracerouteLoadingState / TracerouteActionButtons

import promptAction from '@ohos.promptAction'
import { SPACE_LG, SPACE_MD,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium } from '@wifi-analyzer/design-system'
import {
  TracerouteEngine, TracerouteHop, TracerouteConfig, TracerouteStats, DnsResolveResult
} from '../traceroute/TracerouteEngine'
import { RouterManager, ValidationPatterns, DnsConfig, DiagnosticsConfig } from '@wifi-analyzer/core'
import { BackButtonGlass, PulseIndicator } from '@wifi-analyzer/design-system'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { TracerouteIdleView } from './TracerouteIdleView'
import { TracerouteTraceView } from './TracerouteTraceView'
import { TraceroutePathCard } from './TraceroutePathCard'
import { TracerouteLoadingState } from './TracerouteLoadingState'
import { TracerouteActionButtons } from './TracerouteActionButtons'

const DOMAIN = 0x0000

@Component
export struct TraceroutePage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State detectedGateway: string = ''
  @State detectedDns: string = ''
  @State inputText: string = ''
  @State viewMode: string = 'idle'

  @State hopList: TracerouteHop[] = []
  @State traceStats: TracerouteStats = {
    totalHops: 0, successHops: 0, failedHops: 0,
    avgLatency: 0, maxLatency: 0, minLatency: 0, totalLatency: -1
  }
  @State targetHost: string = ''
  @State resolvedIp: string = ''
  @State isRunning: boolean = false
  private pulser: PulseIndicator = new PulseIndicator()
  private engine: TracerouteEngine = new TracerouteEngine()

  // 获取资源字符串
  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
      return ''
    }
  }

  aboutToAppear(): void {
    this.detectGateway()
    this.detectDns()
  }

  aboutToDisappear(): void {
    this.engine.stopTrace()
    this.pulser.stop()
  }

  // ==================== 系统信息检测 ====================
  private detectGateway(): void {
    this.engine.detectGateway().then((gw: string) => { this.detectedGateway = gw })
  }

  private detectDns(): void {
    this.engine.detectDns().then((dns: string) => { this.detectedDns = dns })
  }

  // ==================== 业务逻辑 ====================
  private validateTarget(addr: string): string {
    const trimmed: string = addr.trim()
    if (trimmed.length === 0) return this.getString($r('app.string.err_empty_input'))
    if (trimmed.length > 255) return this.getString($r('app.string.err_input_too_long'))
    if (!ValidationPatterns.isValidIpOrDomain(trimmed)) return this.getString($r('app.string.err_invalid_ip_or_domain'))
    return ''
  }

  private onRecommendTap(index: number): void {
    switch (index) {
      case 0: this.inputText = this.detectedGateway || DiagnosticsConfig.DEFAULT_GATEWAY; break
      case 1: this.inputText = this.detectedDns || DnsConfig.ALI_DNS; break
      case 2: this.inputText = 'baidu.com'; break
      default: break
    }
  }

  startTrace(): void {
    const addr: string = this.inputText.trim()
    const errorMsg: string = this.validateTarget(addr)
    if (errorMsg !== '') {
      promptAction.showToast({ message: errorMsg, duration: 2000 })
      return
    }
    this.targetHost = addr
    this.resolvedIp = addr
    this.hopList = []
    this.traceStats = { totalHops: 0, successHops: 0, failedHops: 0, avgLatency: 0, maxLatency: 0, minLatency: 0, totalLatency: -1 }
    this.isRunning = true
    this.viewMode = 'tracing'
    this.pulser.start(600)

    this.engine.resolveHost(addr).then((result: DnsResolveResult) => { this.resolvedIp = result.address })

    const config: TracerouteConfig = TracerouteEngine.getDefaultConfig(addr)
    this.engine.startTrace(config, {
      onHopUpdate: (hops: TracerouteHop[]): void => {
        this.hopList = hops
        this.traceStats = TracerouteEngine.calcStats(hops)
      },
      onComplete: (hops: TracerouteHop[]): void => {
        this.hopList = hops
        this.traceStats = TracerouteEngine.calcStats(hops)
        this.isRunning = false
        this.pulser.stop()
        this.viewMode = 'completed'
      },
      onError: (message: string): void => {
        hilog.error(DOMAIN, 'testTag', '%{public}s', '[TraceroutePage] Error: ' + message)
        this.isRunning = false
        this.pulser.stop()
        this.viewMode = 'completed'
      }
    })
  }

  stopTrace(): void {
    this.engine.stopTrace()
    this.isRunning = false
    this.pulser.stop()
    this.viewMode = this.hopList.length > 0 ? 'completed' : 'idle'
  }

  goBackToIdle(): void {
    this.engine.stopTrace()
    this.isRunning = false
    this.pulser.stop()
    this.viewMode = 'idle'
  }

  // ==================== 页面入口 ====================
  build() {
    Stack() {
      // Aurora 天蓝渐变背景
      Column() {}
        .width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Bottom, colors: adaptiveBackgroundList(this.isDarkMode) })

      // 极光装饰光晕
      Circle().width(280).height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })
      Circle().width(180).height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })

      // 主内容
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({
            onBack: () => {
              if (this.viewMode !== 'idle') {
                this.goBackToIdle()
              } else {
                RouterManager.goBack()
              }
            }
          })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: 80 })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          Column({ space: 0 }) {
            TracerouteIdleView({
              isDarkMode: this.isDarkMode,
              inputText: this.inputText,
              onInputChange: (value: string) => { this.inputText = value },
              onSubmit: () => this.startTrace(),
              onRecommendTap: (index: number) => this.onRecommendTap(index)
            })
          }
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
              .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
            TransitionEffect.OPACITY.animation({ duration: 200 })
          ))
        } else {
          Scroll() {
            Column({ space: SPACE_LG }) {
              TracerouteTraceView({
                isDarkMode: this.isDarkMode,
                targetHost: this.targetHost,
                resolvedIp: this.resolvedIp,
                isRunning: this.isRunning,
                viewMode: this.viewMode,
                pulserOpacity: this.pulser.opacity,
                traceStats: this.traceStats,
                onSearchTap: () => {
                  this.viewMode = 'idle'
                  this.inputText = this.targetHost
                }
              })

              if (this.hopList.length > 0) {
                TraceroutePathCard({
                  isDarkMode: this.isDarkMode,
                  hopList: this.hopList,
                  isRunning: this.isRunning,
                  onHopDetail: () => {}
                })
              }

              if (this.isRunning && this.hopList.length === 0) {
                TracerouteLoadingState({
                  isDarkMode: this.isDarkMode,
                  pulserOpacity: this.pulser.opacity
                })
              }

              if (this.viewMode !== 'idle') {
                TracerouteActionButtons({
                  isDarkMode: this.isDarkMode,
                  isRunning: this.isRunning,
                  onStart: () => this.startTrace(),
                  onStop: () => this.stopTrace(),
                  onBack: () => this.goBackToIdle()
                })
              }
            }
            .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
            .width('100%')
          }
          .edgeEffect(EdgeEffect.Spring)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .transition(TransitionEffect.asymmetric(
            TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 24 }))
              .animation({ duration: 300, curve: Curve.FastOutSlowIn }),
            TransitionEffect.OPACITY.animation({ duration: 200 })
          ))
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }
}
