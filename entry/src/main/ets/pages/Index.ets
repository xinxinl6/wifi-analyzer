import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { EventBus } from '../utils/EventBus'
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
  COLOR_TEXT_GLASS_TERTIARY
} from '@wifi-analyzer/design-system'

// Aurora V2 页面组件
import { AuroraDashboard } from '../components/AuroraDashboard'
import { AuroraAIPanel, AuroraAIFabButton, FAB_CLICK_EVENT_ID } from '../components/AuroraAIModule'

// 原有页面组件（可逐步迁移）
import { WifiListSection } from '../components/WifiListSection'
import { ChannelSection } from '../components/ChannelSection'
import { SpeedTestSection } from '../components/SpeedTestSection'
import { ToolsSection } from '../components/ToolsSection'

// 子页面（条件渲染）
import { PingTestPage } from '../components/PingTestPage'
import {
  TraceroutePage, DnsLookupPage, PortScanPage, SubnetCalcPage,
  IpGeoPage, PoeCalcPage, MacLookupPage, WolPage, LanScanPage,
  RoamTestPage, FindDevicePage
} from '@wifi-analyzer/tools'
import { AboutPage } from '../components/AboutPage'

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
    error: ''
  }

  @State permissionGranted: boolean = false
  @State currentIndex: number = 0
  @Provide('isDarkMode') isDarkMode: boolean = false
  // 权限拒绝弹窗控制
  @State showPermissionDeniedDialog: boolean = false

  // Aurora V2 — AI 助手状态
  @State showAIPanel: boolean = false

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
  @StorageLink('showFindDevicePage') showFindDevicePage: boolean = false
  @StorageLink('showAboutPage') showAboutPage: boolean = false

  // Tabs 控制器
  private tabsController: TabsController = new TabsController()

  private dataManager: WifiDataManager = WifiDataManager.getInstance()

  // WiFi 扫描定时器句柄
  private scanTimerId: number = -1

  // Tab 点击动画状态
  @State private tabScales: number[] = [1, 1, 1, 1, 1]
  @State private tabGlows: number[] = [0, 0, 0, 0, 0]
  // Tab 图标弹跳偏移量（选中时向上跳）
  @State private tabOffsetY: number[] = [0, 0, 0, 0, 0]
  // Tab 选中指示点透明度
  @State private tabDotOpacity: number[] = [1, 0, 0, 0, 0]
  // 页面内容透明度（切换时淡入淡出）
  @State private contentOpacity: number = 1
  // 页面内容偏移量（切换时上滑入场）
  @State private contentOffsetY: number = 0

  aboutToAppear(): void {
    console.log('[Index] === aboutToAppear START ===')

    // 订阅 AI FAB 点击事件
    EventBus.on(FAB_CLICK_EVENT_ID, () => {
      this.showAIPanel = !this.showAIPanel
    })

    // 初始化 AppStorage 路由模式
    RouterManager.initAppStorageMode()

    // 直接通过 UIContext 获取 UIAbilityContext（不依赖 AppStorage 中转）
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      if (context) {
        // 读取暗色模式（COLOR_MODE_DARK = 1 表示暗色模式）
        const colorMode = context.config.colorMode
        this.isDarkMode = (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK)

        // 直接请求权限并开始扫描
        this.requestPermissionsAndScan(context)
      } else {
        console.error('[Index] FATAL: getUIContext().getHostContext() returned null')
        this.wifiState.error = $r('app.string.err_init_failed')
      }
    } catch (e) {
      console.error('[Index] FATAL: Failed to get context:', e)
      this.wifiState.error = $r('app.string.err_init_failed')
    }

    // 每 5 秒自动刷新 WiFi 状态
    this.scanTimerId = setInterval(() => {
      if (this.permissionGranted) {
        this.startWifiScan()
      }
    }, 5000) as number

    console.log('[Index] === aboutToAppear END ===')
  }

  aboutToDisappear(): void {
    // 清理定时器
    if (this.scanTimerId !== -1) {
      clearInterval(this.scanTimerId)
      this.scanTimerId = -1
    }
  }

  // 检查是否有子页面显示
  private hasOverlayPage(): boolean {
    return this.showPingPage || this.showTraceroutePage || this.showDnsPage ||
           this.showPortScanPage || this.showSubnetPage || this.showIpGeoPage ||
           this.showPoePage || this.showMacLookupPage || this.showWolPage ||
           this.showLanScanPage || this.showRoamTestPage || this.showFindDevicePage ||
           this.showAboutPage
  }

  // Aurora Tab 点击处理 — 弹跳 + 光晕 + 页面淡入
  private onTabClick(index: number): void {
    if (this.currentIndex === index) return  // 已选中，不重复触发

    const prevIndex = this.currentIndex

    // === 阶段 1：页面内容淡出 ===
    this.getUIContext().animateTo({
      duration: 100,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.contentOpacity = 0.6
      this.contentOffsetY = 8
    })

    // === 阶段 1：旧 Tab 图标缩小 + 新 Tab 预压缩 ===
    const scales1 = [
      this.tabScales[0], this.tabScales[1], this.tabScales[2],
      this.tabScales[3], this.tabScales[4]
    ]
    const offsets1 = [
      this.tabOffsetY[0], this.tabOffsetY[1], this.tabOffsetY[2],
      this.tabOffsetY[3], this.tabOffsetY[4]
    ]
    const dots1 = [
      this.tabDotOpacity[0], this.tabDotOpacity[1], this.tabDotOpacity[2],
      this.tabDotOpacity[3], this.tabDotOpacity[4]
    ]
    scales1[prevIndex] = 0.85
    scales1[index] = 0.75
    offsets1[index] = 4
    dots1[prevIndex] = 0

    this.getUIContext().animateTo({ duration: 100, curve: Curve.FastOutSlowIn }, () => {
      this.tabScales = scales1
      this.tabOffsetY = offsets1
      this.tabDotOpacity = dots1
    })

    // === 阶段 2：切换页面 + 图标弹出 ===
    setTimeout(() => {
      this.currentIndex = index
      this.tabsController.changeIndex(index)

      const scales2 = [
        this.tabScales[0], this.tabScales[1], this.tabScales[2],
        this.tabScales[3], this.tabScales[4]
      ]
      const offsets2 = [
        this.tabOffsetY[0], this.tabOffsetY[1], this.tabOffsetY[2],
        this.tabOffsetY[3], this.tabOffsetY[4]
      ]
      const glows2 = [
        this.tabGlows[0], this.tabGlows[1], this.tabGlows[2],
        this.tabGlows[3], this.tabGlows[4]
      ]
      const dots2 = [
        this.tabDotOpacity[0], this.tabDotOpacity[1], this.tabDotOpacity[2],
        this.tabDotOpacity[3], this.tabDotOpacity[4]
      ]
      scales2[index] = 1.12
      offsets2[index] = -6
      glows2[index] = 1
      dots2[index] = 1

      // 图标弹跳弹出 + 光晕出现
      this.getUIContext().animateTo({ duration: 280, curve: Curve.FastOutSlowIn }, () => {
        this.tabScales = scales2
        this.tabOffsetY = offsets2
        this.tabGlows = glows2
        this.tabDotOpacity = dots2
      })

      // 页面内容淡入
      this.getUIContext().animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
        this.contentOpacity = 1
        this.contentOffsetY = 0
      })
    }, 100)

    // === 阶段 3：图标回弹到正常大小 ===
    setTimeout(() => {
      const scales3 = [1.0, 1.0, 1.0, 1.0, 1.0]
      const offsets3 = [0, 0, 0, 0, 0]
      const glows3 = [0, 0, 0, 0, 0]

      this.getUIContext().animateTo({ duration: 220, curve: Curve.EaseOut }, () => {
        this.tabScales = scales3
        this.tabOffsetY = offsets3
        this.tabGlows = glows3
      })
    }, 380)
  }

  // ==================== 权限请求 + 扫描流程 ====================
  // 保存 context 引用，供弹窗回调使用
  private abilityContext: common.UIAbilityContext | null = null

  async requestPermissionsAndScan(context: common.UIAbilityContext): Promise<void> {
    console.log('[Index] === requestPermissionsAndScan START ===')
    this.abilityContext = context  // 保存 context 供后续使用
    try {
      const granted: boolean = await PermissionManager.requestPermissions(context)
      this.permissionGranted = granted

      if (granted) {
        console.log('[Index] Permissions OK, starting WiFi scan...')
        this.startWifiScan()
      } else {
        console.warn('[Index] Permissions denied, showing dialog...')
        // 显示权限拒绝弹窗
        this.showPermissionDeniedDialog = true
      }
    } catch (e) {
      console.error('[Index] Permission error:', e)
      this.permissionGranted = false
      this.showPermissionDeniedDialog = true  // 出错时也显示弹窗
    }
  }

  // 跳转到应用权限设置页面
  private openAppSettings(): void {
    console.log('[Index] Opening app settings...')
    if (this.abilityContext) {
      PermissionManager.openAppSettings(this.abilityContext)
    }
    this.showPermissionDeniedDialog = false
  }

  // 退出应用
  private exitApp(): void {
    console.log('[Index] Exiting app...')
    if (this.abilityContext) {
      PermissionManager.terminateApp(this.abilityContext)
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
      // 背景层 — Aurora 极光渐变（延伸到状态栏区域）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.isDarkMode ? '#0A1628' : '#F0F8FF')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // 内容层
      if (this.hasOverlayPage()) {
        this.buildOverlayPages()
      } else {
        this.buildMainContent()
      }

      // AI 助手悬浮按钮
      if (!this.hasOverlayPage()) {
        AuroraAIFabButton({
          fabVisible: true,
          wifiSsid: this.wifiState.connectedSsid,
          wifiSignal: this.wifiState.connectedSignal,
          wifiChannel: this.wifiState.connectedChannel
        })
        .position({ x: '85%', y: '70%' })
      }

      // 权限拒绝弹窗
      if (this.showPermissionDeniedDialog) {
        this.buildPermissionDeniedDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 权限拒绝弹窗
  @Builder
  buildPermissionDeniedDialog() {
    Column() {
      Column() {
        // 标题
        Text('权限申请')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#1E293B')
          .margin({ bottom: 12 })

        // 提示文字
        Text('WiFi分析仪需要位置权限才能扫描周围的WiFi网络。\n请在设置中开启位置权限。')
          .fontSize(14)
          .fontColor(this.isDarkMode ? 'rgba(255,255,255,0.7)' : 'rgba(30,41,59,0.7)')
          .textAlign(TextAlign.Center)
          .lineHeight(22)
          .margin({ bottom: 24 })

        // 按钮区域
        Row() {
          // 退出按钮
          Button('退出')
            .fontSize(15)
            .fontColor('#FF3B30')
            .backgroundColor(this.isDarkMode ? 'rgba(255,59,48,0.15)' : 'rgba(255,59,48,0.1)')
            .borderRadius(12)
            .height(44)
            .layoutWeight(1)
            .onClick(() => {
              this.exitApp()
            })

          // 去设置按钮
          Button('去设置')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(12)
            .height(44)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.openAppSettings()
            })
        }
      }
      .padding(24)
      .backgroundColor(this.isDarkMode ? 'rgba(30,41,59,0.95)' : 'rgba(255,255,255,0.95)')
      .borderRadius(20)
      .border({
        width: 1,
        color: this.isDarkMode ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.08)'
      })
      .shadow({
        radius: 24,
        color: this.isDarkMode ? 'rgba(0,0,0,0.4)' : 'rgba(0,0,0,0.15)',
        offsetX: 0,
        offsetY: 8
      })
      .width('85%')
      .constraintSize({ maxWidth: 340 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
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
            AuroraDashboard({ isDarkMode: this.isDarkMode })
          }
          .padding({ top: 32 }) // 避让状态栏高度
        }

        TabContent() {
          Column() {
            WifiListSection()
          }
          .padding({ top: 32 })
        }

        TabContent() {
          Column() {
            ChannelSection()
          }
          .padding({ top: 32 })
        }

        TabContent() {
          Column() {
            SpeedTestSection()
          }
          .padding({ top: 32 })
        }

        TabContent() {
          Column() {
            ToolsSection()
          }
          .padding({ top: 32 })
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
      if (this.showFindDevicePage) {
        FindDevicePage()
      }
      if (this.showAboutPage) {
        AboutPage()
      }
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
                  .fillColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : (this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : '#8E8E93'))
                  .scale({ x: this.tabScales[index], y: this.tabScales[index] })
                  .translate({ x: 0, y: this.tabOffsetY[index] })
              }
              .width(44)
              .height(44)

              // Tab 标签文字
              Text(item.title)
                .fontSize(11)
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentIndex === index ? COLOR_AURORA_PRIMARY : (this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : '#8E8E93'))
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
        .backgroundColor(this.isDarkMode ? 'rgba(30,41,59,0.75)' : 'rgba(255,255,255,0.68)')
        .backdropBlur(18)
        .linearGradient(this.isDarkMode
          ? { direction: GradientDirection.Top, colors: [['rgba(30,41,59,0.45)', 0], ['rgba(30,41,59,0.14)', 0.5], ['rgba(30,41,59,0.08)', 1]] }
          : { direction: GradientDirection.Top, colors: [['rgba(255,255,255,0.45)', 0], ['rgba(255,255,255,0.14)', 0.5], ['rgba(255,255,255,0.08)', 1]] })
        .borderRadius(28)
        .border({
          width: { top: 0.5, bottom: 0 },
          color: {
            top: this.isDarkMode ? 'rgba(255,255,255,0.15)' : 'rgba(255,255,255,0.78)',
            bottom: this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)'
          }
        })
        .shadow({
          radius: 24,
          color: this.isDarkMode ? 'rgba(0,0,0,0.25)' : 'rgba(0,0,0,0.12)',
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
