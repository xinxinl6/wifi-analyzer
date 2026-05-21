import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { preferences } from '@kit.ArkData'
import {
  // Aurora V2 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_GLOW,
  // 毛玻璃色彩
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_CARD,
  COLOR_SHADOW_GLASS_STRONG,
  // 深色模式
  COLOR_TAB_BAR_BG_DARK,
  COLOR_TAB_BAR_BORDER_DARK,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_GLASS_DARK_BORDER,
  COLOR_SHADOW_GLASS,
  COLOR_OVERLAY,
  COLOR_TEXT_DARK_SECONDARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_TAB_BAR_TEXT_DARK,
  COLOR_GLASS_BORDER,
  // 极光背景工具函数
  adaptiveBackgroundList,
  adaptiveGlowLarge,
  adaptiveGlowMedium,
  adaptiveGlowSmall
} from '@wifi-analyzer/design-system'

// Aurora V2 页面组件
import { AuroraDashboard } from '../components/AuroraDashboard'
import { AuroraBackground } from '../components/AuroraBackground'

// 原有页面组件（可逐步迁移）
import { WifiListSection } from '../components/WifiListSection'
import { ChannelSection } from '../components/ChannelSection'
import { SpeedTestSection } from '../components/SpeedTestSection'
import { ToolsSection } from '../components/ToolsSection'

// 弹窗组件
import { PrivacyDialog } from '../components/PrivacyDialog'
import { PermissionDialog } from '../components/PermissionDialog'

// 动画辅助工具
import { TabAnimationHelper } from '../utils/TabAnimationHelper'

// 子页面（条件渲染）
import { PingTestPage } from '../components/PingTestPage'
import {
  TraceroutePage, DnsLookupPage, PortScanPage, SubnetCalcPage,
  IpGeoPage, PoeCalcPage, MacLookupPage, WolPage, LanScanPage,
  RoamTestPage
} from '@wifi-analyzer/tools'
import { AboutPage } from '../components/AboutPage'
// ChannelPage 已移除冗余条件渲染，ChannelSection 直接在 Tab 3 中显示

// 数据管理
import { WifiDataManager, SharedWifiState, PermissionManager, RouterManager } from '@wifi-analyzer/core'

// Tab 配置 — Aurora 风格
interface TabItem {
  title: ResourceStr
  icon: Resource
}

const TAB_ITEMS: Array<TabItem> = [
  { title: $r('app.string.tab_home'), icon: $r('app.media.ic_home') },
  { title: $r('app.string.tab_wifi'), icon: $r('app.media.ic_wifi') },
  { title: $r('app.string.tab_channel'), icon: $r('app.media.ic_chart') },
  { title: $r('app.string.tab_speed'), icon: $r('app.media.ic_speed') },
  { title: $r('app.string.tab_tools'), icon: $r('app.media.ic_tool') },
]

// 日志 domain
const DOMAIN = 0x0000

@Entry
@Component
struct Index {
  // WiFi 数据共享中枢
  @Provide('wifiState') wifiState: SharedWifiState = {
    wifiList: [],
    connectedSsid: '',
    connectedBssid: '',
    connectedSignal: -100,
    connectedFreq: 0,
    connectedChannel: 0,
    isScanning: false,
    currentFilter: 'all',
    isLoaded: false,
    scanRequestCount: 0,
    usingFallbackData: false,
    error: ''
  }

  @State permissionGranted: boolean = false
  @State currentIndex: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  // 权限拒绝弹窗控制
  @State showPermissionDeniedDialog: boolean = false
  // 隐私政策同意弹窗（首次启动）
  @State showPrivacyDialog: boolean = false
  // 隐私政策是否已同意（DataPreferences 持久化后更新）
  private privacyAgreed: boolean = false
  // UIAbilityContext 引用（隐私弹窗回调需要用）
  private abilityContextForPrivacy: common.UIAbilityContext | null = null

  // 子页面显示状态
  @StorageLink('showPingPage') showPingPage: boolean = false
  @StorageLink('showTraceroutePage') showTraceroutePage: boolean = false
  @StorageLink('showDnsPage') showDnsPage: boolean = false
  @StorageLink('showPortScanPage') showPortScanPage: boolean = false
  @StorageLink('showSubnetPage') showSubnetPage: boolean = false
  @StorageLink('showIpGeoPage') showIpGeoPage: boolean = false
  @StorageLink('showPoePage') showPoePage: boolean = false
  @StorageLink('showMacLookupPage') showMacLookupPage: boolean = false
  @StorageLink('showWolPage') showWolPage: boolean = false
  @StorageLink('showLanScanPage') showLanScanPage: boolean = false
  @StorageLink('showRoamTestPage') showRoamTestPage: boolean = false
  @StorageLink('showAboutPage') showAboutPage: boolean = false

  // 页面转场动画状态（淡入淡出 + 缩放）
  @State overlayOpacity: number = 0
  @State overlayScale: number = 0.95
  // 标记是否正在执行关闭动画（防止 enter/exit 动画冲突）
  @State private isClosingOverlay: boolean = false

  // Tabs 控制器
  private tabsController: TabsController = new TabsController()

  private dataManager: WifiDataManager = WifiDataManager.getInstance()

  // WiFi 扫描定时器句柄
  private scanTimerId: number = -1

  // Tab 点击动画状态
  @State private tabScales: number[] = TabAnimationHelper.getInitialTabScales()
  @State private tabGlows: number[] = TabAnimationHelper.getInitialTabGlows()
  // Tab 图标弹跳偏移量（选中时向上跳）
  @State private tabOffsetY: number[] = TabAnimationHelper.getInitialTabOffsetY()
  // Tab 选中指示点透明度
  @State private tabDotOpacity: number[] = TabAnimationHelper.getInitialTabDotOpacity()
  // 页面内容透明度（切换时淡入淡出）
  @State private contentOpacity: number = TabAnimationHelper.getInitialContentOpacity()
  // 页面内容偏移量（切换时上滑入场）
  @State private contentOffsetY: number = TabAnimationHelper.getInitialContentOffsetY()

  // Tab 切换订阅句柄
  private tabUnsubscribe: (() => void) | null = null
  // 路由变更订阅句柄
  private routerUnsubscribe: (() => void) | null = null

  aboutToAppear(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] === aboutToAppear START ===')

    // 初始化 AppStorage 路由模式
    RouterManager.initAppStorageMode()

    // 订阅 Tab 切换事件
    this.tabUnsubscribe = RouterManager.subscribeTab((tabIndex: number) => {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Tab navigation requested:' + JSON.stringify(tabIndex))
      this.onTabClick(tabIndex)
    })

    // 订阅路由变更，触发子页面转场动画
    this.routerUnsubscribe = RouterManager.subscribe((route: string | null) => {
      this.onRouterChange(route)
    })

    // 直接通过 UIContext 获取 UIAbilityContext（不依赖 AppStorage 中转）
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      if (context) {
        // 读取暗色模式
        const colorMode = context.config.colorMode
        this.isDarkMode = (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
        AppStorage.setOrCreate('isDarkMode', this.isDarkMode)

        // ★ 隐私政策前置：必须先同意隐私政策才能请求权限（华为审核要求）
        this.abilityContextForPrivacy = context
        this.checkPrivacyAgreement(context)
      } else {
        hilog.error(DOMAIN, 'testTag', '%{public}s', '[Index] FATAL: getUIContext().getHostContext() returned null')
        this.wifiState.error = $r('app.string.err_init_failed')
      }
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[Index] FATAL: Failed to get context:' + JSON.stringify(e))
      this.wifiState.error = $r('app.string.err_init_failed')
    }

    // 每 12 秒自动刷新 WiFi 状态（避免频繁扫描耗电）
    this.scanTimerId = setInterval(() => {
      if (this.permissionGranted) {
        this.startWifiScan()
      }
    }, 12000) as number

    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] === aboutToAppear END ===')
  }

  aboutToDisappear(): void {
    // 清理定时器
    if (this.scanTimerId !== -1) {
      clearInterval(this.scanTimerId)
      this.scanTimerId = -1
    }
    // 清理 Tab 切换订阅
    if (this.tabUnsubscribe) {
      this.tabUnsubscribe()
      this.tabUnsubscribe = null
    }
    // 清理路由变更订阅
    if (this.routerUnsubscribe) {
      this.routerUnsubscribe()
      this.routerUnsubscribe = null
    }
  }

  // 页面每次变为可见时触发（包括从设置页返回、从后台恢复）
  // 华为审核要求：返回后需重新检查权限状态，未授权则重新请求
  onPageShow(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] onPageShow triggered')
    // 仅在隐私已同意但权限尚未授予时才重检（避免隐私弹窗期间重复触发）
    if (this.privacyAgreed && !this.permissionGranted) {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Privacy agreed but permission not granted, re-checking...')
      this.recheckPermissionsOnReturn()
    }
  }

  /**
   * 从设置页面返回后重新检查权限
   * 如果用户已在设置中授权 → 开始扫描
   * 如果仍未授权 → 重新弹出权限申请弹窗
   */
  private async recheckPermissionsOnReturn(): Promise<void> {
    try {
      if (!this.abilityContext) {
        // abilityContext 可能为空（首次还未赋值），尝试重新获取
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext
        if (context) {
          this.abilityContext = context
        } else {
          hilog.warn(DOMAIN, 'testTag', '%{public}s', '[Index] No context available for recheck')
          return
        }
      }

      const context = this.abilityContext
      // 直接用 PermissionManager 重新检查并请求权限
      const granted: boolean = await PermissionManager.requestPermissions(context)
      this.permissionGranted = granted

      if (granted) {
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Permissions granted after returning from settings!')
        this.showPermissionDeniedDialog = false
        this.startWifiScan()
      } else {
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Permissions still denied after returning from settings')
        // 重新显示权限引导弹窗（让用户再次选择"去设置"或"继续使用"）
        this.showPermissionDeniedDialog = true
      }
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[Index] Recheck permissions error:' + JSON.stringify(e))
    }
  }

  // 路由变更回调 - 触发子页面转场动画（淡入淡出 + 缩放）
  private onRouterChange(route: string | null): void {
    if (route === null) {
      // 返回主页：播放退出动画
      this.playOverlayExitAnimation()
    } else {
      // 进入子页面：播放入场动画
      this.playOverlayEnterAnimation()
    }
  }

  // 子页面入场动画（淡入 + 缩放弹簧效果）
  private playOverlayEnterAnimation(): void {
    if (this.isClosingOverlay) {
      this.isClosingOverlay = false
    }
    this.overlayOpacity = TabAnimationHelper.getOverlayEnterInitial().opacity
    this.overlayScale = TabAnimationHelper.getOverlayEnterInitial().scale

    // 延迟触发动画，让内容先渲染
    const animConfig = TabAnimationHelper.getEnterAnimationConfig()
    setTimeout(() => {
      this.getUIContext().animateTo({
        duration: animConfig.duration,
        curve: animConfig.curve
      }, () => {
        this.overlayOpacity = TabAnimationHelper.getOverlayEnterFinal().opacity
        this.overlayScale = TabAnimationHelper.getOverlayEnterFinal().scale
      })
    }, TabAnimationHelper.getEnterAnimationDelay())
  }

  // 子页面退出动画（淡出 + 缩小）
  private playOverlayExitAnimation(): void {
    this.isClosingOverlay = true
    const animConfig = TabAnimationHelper.getExitAnimationConfig()
    this.getUIContext().animateTo({
      duration: animConfig.duration,
      curve: animConfig.curve
    }, () => {
      this.overlayOpacity = TabAnimationHelper.getOverlayExitFinal().opacity
      this.overlayScale = TabAnimationHelper.getOverlayExitFinal().scale
    })
  }

  // 检查是否有子页面显示
  private hasOverlayPage(): boolean {
    return this.showPingPage || this.showTraceroutePage || this.showDnsPage ||
           this.showPortScanPage || this.showSubnetPage || this.showIpGeoPage ||
           this.showPoePage || this.showMacLookupPage || this.showWolPage ||
           this.showLanScanPage || this.showRoamTestPage ||
           this.showAboutPage
  }

  // Aurora Tab 点击处理 — 弹跳 + 光晕 + 页面淡入
  private onTabClick(index: number): void {
    if (this.currentIndex === index) return // 已选中，不重复触发

    const prevIndex = this.currentIndex

    // === 阶段 1：页面内容淡出 ===
    this.getUIContext().animateTo({
      duration: TabAnimationHelper.ANIMATION_DURATION_FAST,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.contentOpacity = 0.6
      this.contentOffsetY = 8
    })

    // === 阶段 1：旧 Tab 图标缩小 + 新 Tab 预压缩 ===
    const phase1 = TabAnimationHelper.calcPhase1States(
      prevIndex, index,
      this.tabScales, this.tabOffsetY, this.tabDotOpacity
    )

    this.getUIContext().animateTo({
      duration: TabAnimationHelper.ANIMATION_DURATION_FAST,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.tabScales = phase1.scales
      this.tabOffsetY = phase1.offsets
      this.tabDotOpacity = phase1.dots
    })

    // === 阶段 2：切换页面 + 图标弹出 ===
    setTimeout(() => {
      this.currentIndex = index
      this.tabsController.changeIndex(index)

      const phase2 = TabAnimationHelper.calcPhase2States(
        index,
        this.tabScales, this.tabOffsetY, this.tabGlows, this.tabDotOpacity
      )

      // 图标弹跳弹出 + 光晕出现
      this.getUIContext().animateTo({
        duration: TabAnimationHelper.ANIMATION_DURATION_SLOW,
        curve: Curve.FastOutSlowIn
      }, () => {
        this.tabScales = phase2.scales
        this.tabOffsetY = phase2.offsets
        this.tabGlows = phase2.glows
        this.tabDotOpacity = phase2.dots
      })

      // 页面内容淡入
      this.getUIContext().animateTo({
        duration: TabAnimationHelper.ANIMATION_DURATION_NORMAL,
        curve: Curve.EaseOut
      }, () => {
        this.contentOpacity = 1
        this.contentOffsetY = 0
      })
    }, TabAnimationHelper.getPhase2Delay())

    // === 阶段 3：图标回弹到正常大小 ===
    setTimeout(() => {
      const phase3 = TabAnimationHelper.calcPhase3States()

      this.getUIContext().animateTo({
        duration: TabAnimationHelper.ANIMATION_DURATION_REBOUND,
        curve: Curve.EaseOut
      }, () => {
        this.tabScales = phase3.scales
        this.tabOffsetY = phase3.offsets
        this.tabGlows = phase3.glows
      })
    }, TabAnimationHelper.getPhase3Delay())
  }

  // ==================== 权限请求 + 扫描流程 ====================
  // 保存 context 引用，供弹窗回调使用
  private abilityContext: common.UIAbilityContext | null = null

  async requestPermissionsAndScan(context: common.UIAbilityContext): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] === requestPermissionsAndScan START ===')
    this.abilityContext = context // 保存 context 供后续使用
    try {
      const granted: boolean = await PermissionManager.requestPermissions(context)
      this.permissionGranted = granted

      if (granted) {
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Permissions OK, starting WiFi scan...')
        this.startWifiScan()
      } else {
        hilog.warn(DOMAIN, 'testTag', '%{public}s', '[Index] Permissions denied, showing dialog...')
        // 显示权限拒绝弹窗
        this.showPermissionDeniedDialog = true
      }
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[Index] Permission error:' + JSON.stringify(e))
      this.permissionGranted = false
      this.showPermissionDeniedDialog = true // 出错时也显示弹窗
    }
  }

  // 跳转到应用权限设置页面
  private openAppSettings(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Opening app settings...')
    if (this.abilityContext) {
      PermissionManager.openAppSettings(this.abilityContext)
    }
    this.showPermissionDeniedDialog = false
  }

  // 退出应用（仅保留入口，不再主动调用）
  private exitApp(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] exitApp called - no longer terminates app')
    this.showPermissionDeniedDialog = false
  }

  // ==================== 隐私政策前置流程（华为审核要求）====================

  // DataPreferences 存储键名
  private static readonly PRIVACY_STORE_NAME: string = 'privacy_agreement'
  private static readonly PRIVACY_KEY_AGREED: string = 'user_agreed'

  /**
   * 检查用户是否已同意隐私政策
   * - 已同意 → 直接请求权限 + 开始扫描
   * - 未同意 → 弹出隐私政策弹窗（不请求任何权限）
   */
  private async checkPrivacyAgreement(context: common.UIAbilityContext): Promise<void> {
    try {
      const prefs: preferences.Preferences = await preferences.getPreferences(context, Index.PRIVACY_STORE_NAME)
      const agreed: boolean = await prefs.get(Index.PRIVACY_KEY_AGREED, false) === true
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Privacy agreed=' + agreed)

      if (agreed) {
        // 已同意：直接走权限请求+扫描
        this.privacyAgreed = true
        this.requestPermissionsAndScan(context)
      } else {
        // 未同意：弹出隐私政策弹窗，不请求权限
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Show privacy agreement dialog')
        this.showPrivacyDialog = true
      }
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[Index] Check privacy error:' + JSON.stringify(e))
      // 出错时默认弹出隐私政策（安全侧）
      this.showPrivacyDialog = true
    }
  }

  /** 用户点击"同意并继续" */
  private async onPrivacyAgree(): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] User agreed to privacy policy')

    try {
      if (this.abilityContextForPrivacy) {
        const prefs: preferences.Preferences = await preferences.getPreferences(this.abilityContextForPrivacy, Index.PRIVACY_STORE_NAME)
        await prefs.put(Index.PRIVACY_KEY_AGREED, true)
        await prefs.flush()
        hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] Privacy agreed state saved')
      }

      this.privacyAgreed = true
      this.showPrivacyDialog = false

      // 同意后才开始请求权限
      if (this.abilityContextForPrivacy) {
        this.requestPermissionsAndScan(this.abilityContextForPrivacy)
      }
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', '%{public}s', '[Index] Save privacy agree error:' + JSON.stringify(e))
      // 即使保存失败也继续（用户体验优先）
      this.showPrivacyDialog = false
      if (this.abilityContextForPrivacy) {
        this.requestPermissionsAndScan(this.abilityContextForPrivacy)
      }
    }
  }

  /** 用户点击"不同意" — 退出应用 */
  private onPrivacyDisagree(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] User disagreed to privacy policy - exiting app')
    this.showPrivacyDialog = false

    if (this.abilityContextForPrivacy) {
      // 不同意隐私政策 → 终止应用
      this.abilityContextForPrivacy.terminateSelf()
    }
  }

  startWifiScan(): void {
    this.dataManager.scanAndUpdate(
      this.wifiState,
      (newState: SharedWifiState) => {
        this.wifiState = newState
      }
    )
  }

  // 拦截系统返回键和边缘滑动返回，统一由 RouterManager 处理
  onBackPress(): boolean {
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] onBackPress triggered');
    if (RouterManager.isInSubPage()) {
      hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] In sub page, calling goBack()');
      RouterManager.goBack();
      return true; // 已处理，返回上一页
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', '[Index] On home page, let system handle');
    return false; // 交由系统默认处理
  }

  build() {
    Stack() {
      // 背景层 — Aurora 极光渐变（与 WiFi 页面统一）
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 极光装饰光晕 1（左上角）
      Circle()
        .width(280)
        .height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })
        .hitTestBehavior(HitTestMode.None)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 极光装饰光晕 2（右中）
      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })
        .hitTestBehavior(HitTestMode.None)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 极光装饰光晕 3（右上）
      Circle()
        .width(120)
        .height(120)
        .fill(adaptiveGlowSmall(this.isDarkMode))
        .position({ x: '80%', y: '10%' })
        .hitTestBehavior(HitTestMode.None)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 内容层
      if (this.hasOverlayPage()) {
        this.buildOverlayPages()
      } else {
        this.buildMainContent()
      }

      // 隐私政策同意弹窗（权限请求之前，华为审核要求）
      if (this.showPrivacyDialog) {
        PrivacyDialog({
          privacyAgreed: this.privacyAgreed,
          onAgree: () => this.onPrivacyAgree(),
          onDisagree: () => this.onPrivacyDisagree()
        })
      }

      // 权限拒绝弹窗
      if (this.showPermissionDeniedDialog) {
        PermissionDialog({
          onOpenSettings: () => this.openAppSettings(),
          onExit: () => this.exitApp()
        })
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  buildMainContent() {
    Stack({ alignContent: Alignment.Bottom }) {
      // Tabs 内容区域 — 占满全屏，顶部避让状态栏
      Tabs({
        index: this.currentIndex,
        controller: this.tabsController
      }) {
        TabContent() {
          Column() {
            AuroraDashboard()
          }
          .padding({ top: 32 }) // 避让状态栏高度
        }

        TabContent() {
          Stack() {
            AuroraBackground()
            Column() {
              WifiListSection()
            }
            .padding({ top: 32 })
          }
        }

        TabContent() {
          Stack() {
            AuroraBackground()
            Column() {
              ChannelSection()
            }
            .padding({ top: 32 })
          }
        }

        TabContent() {
          Stack() {
            AuroraBackground()
            Column() {
              SpeedTestSection()
            }
            .padding({ top: 32 })
          }
        }

        TabContent() {
          Stack() {
            AuroraBackground()
            Column() {
              ToolsSection()
            }
            .padding({ top: 32 })
          }
        }
      }
      .barHeight(0)  // 隐藏原生 TabBar
      .scrollable(false)
      .animationDuration(0)  // 关闭原生动画，由自定义动画接管
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .width('100%')
      .height('100%')
      .opacity(this.contentOpacity)
      .translate({ x: 0, y: this.contentOffsetY })

      // 悬浮 TabBar — 浮在内容上方，底部居中
      this.AuroraTabBarRow()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildOverlayPages() {
    Stack() {
      // 半透明黑色背景遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(COLOR_OVERLAY)
        .opacity(this.overlayOpacity * 0.5)
        .onClick(() => {
          // 点击遮罩返回
          RouterManager.goBack()
        })

      // 子页面内容容器（带缩放 + 淡入动画）
      Column() {
        if (this.showPingPage) {
          PingTestPage()
        }
        if (this.showTraceroutePage) {
          TraceroutePage()
        }
        if (this.showDnsPage) {
          DnsLookupPage()
        }
        if (this.showPortScanPage) {
          PortScanPage()
        }
        if (this.showSubnetPage) {
          SubnetCalcPage()
        }
        if (this.showIpGeoPage) {
          IpGeoPage()
        }
        if (this.showPoePage) {
          PoeCalcPage()
        }
        if (this.showMacLookupPage) {
          MacLookupPage()
        }
        if (this.showWolPage) {
          WolPage()
        }
        if (this.showLanScanPage) {
          LanScanPage()
        }
        if (this.showRoamTestPage) {
          RoamTestPage()
        }
        if (this.showAboutPage) {
          AboutPage()
        }
      }
      .width('100%')
      .height('100%')
      .scale({ x: this.overlayScale, y: this.overlayScale })
      .opacity(this.overlayOpacity)
    }
    .width('100%')
    .height('100%')
  }

    // ==================== Aurora TabBar（悬浮毛玻璃效果）====================
  @Builder
  AuroraTabBarRow() {
    // 全屏模式：底部安全区需要手动处理
    // 外层 Column 占满屏幕，底部预留安全区 + 悬浮间距
    Column() {
      // 透明区域（点击穿透到 Tabs）
      Column() {}
        .layoutWeight(1)
        .hitTestBehavior(HitTestMode.None)

      // TabBar 毛玻璃卡片
      Column() {
        Row() {
          ForEach(TAB_ITEMS, (item: TabItem, index: number) => {
            Column() {
              // 图标 + 光晕容器
              Stack() {
                // 选中光晕背景（蓝色圆形）
                Column()
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,0.35)' : '#007AFF')
                  .opacity(this.tabGlows[index] * (this.isDarkMode ? 0.20 : 0.12) + (this.currentIndex === index ? (this.isDarkMode ? 0.15 : 0.10) : 0))
                  .blur(8)

                // Tab 图标（带弹跳位移 + 缩放）
                Image(item.icon)
                  .width(26)
                  .height(26)
                  .fillColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : (this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_SECONDARY))
                  .scale({ x: this.tabScales[index], y: this.tabScales[index] })
                  .translate({ x: 0, y: this.tabOffsetY[index] })
              }
              .width(44)
              .height(44)

              // Tab 标签文字
              Text(item.title)
                .fontSize(11)
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : (this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_SECONDARY))
                .margin({ top: 2 })
                .scale({ x: this.tabScales[index], y: this.tabScales[index] })

              // 选中指示点
              Column()
                .width(4)
                .height(4)
                .borderRadius(2)
                .backgroundColor(COLOR_AURORA_PRIMARY)
                .margin({ top: 3 })
                .opacity(this.tabDotOpacity[index])
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.onTabClick(index)
            })
          }, (item: TabItem, index: number) => index.toString())
        }
        .width('85%')
        .height(80)
        .padding({ top: 10, bottom: 12 })
        // === 毛玻璃效果 ===
        .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_SURFACE_LIGHT)
        .backdropBlur(18)
        .linearGradient(this.isDarkMode
          ? { direction: GradientDirection.Top, colors: [['rgba(30,41,59,0.45)', 0], ['rgba(30,41,59,0.14)', 0.5], ['rgba(30,41,59,0.08)', 1]] }
          : { direction: GradientDirection.Top, colors: [['rgba(255,255,255,0.45)', 0], ['rgba(255,255,255,0.14)', 0.5], ['rgba(255,255,255,0.08)', 1]] })
        .borderRadius(28)
        .border({
          width: { top: 0.5, bottom: 0 },
          color: {
            top: this.isDarkMode ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_CARD,
            bottom: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER
          }
        })
        .shadow({
          radius: 24,
          color: this.isDarkMode ? COLOR_SHADOW_GLASS : COLOR_SHADOW_GLASS,
          offsetX: 0,
          offsetY: 6
        })
      }
    }
    .width('100%')
    .height(104)  // TabBar 80 + 底部安全区 24
    .padding({ bottom: 24 })  // 底部安全区 24vp（贴近底部，留出导航条空间）
    .backgroundColor(Color.Transparent)  // 背景透明，让下层 Tabs 可点击
  }
}
