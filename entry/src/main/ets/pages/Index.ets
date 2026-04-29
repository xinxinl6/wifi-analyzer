import { common } from '@kit.AbilityKit'
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
  @State isDarkMode: boolean = false

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
        // 读取暗色模式
        const colorMode = context.config.colorMode
        this.isDarkMode = (colorMode === 0)

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

  // Aurora Tab 点击处理
  private onTabClick(index: number): void {
    animateTo({
      duration: 100,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.tabScales[index] = 0.90
    })

    setTimeout(() => {
      animateTo({
        duration: 200,
        curve: Curve.EaseOut
      }, () => {
        this.tabScales[index] = 1.0
      })
    }, 100)

    this.currentIndex = index
    this.tabsController.changeIndex(index)
  }

  // ==================== 权限请求 + 扫描流程 ====================
  async requestPermissionsAndScan(context: common.UIAbilityContext): Promise<void> {
    console.log('[Index] === requestPermissionsAndScan START ===')
    try {
      const granted: boolean = await PermissionManager.requestPermissions(context)
      this.permissionGranted = granted

      if (granted) {
        console.log('[Index] Permissions OK, starting WiFi scan...')
        this.startWifiScan()
      } else {
        console.warn('[Index] Permissions denied')
        this.wifiState.error = $r('app.string.err_perm_denied')
      }
    } catch (e) {
      console.error('[Index] Permission error:', e)
      this.permissionGranted = false
      this.wifiState.error = $r('app.string.err_perm_exception')
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
      // 背景层 — Aurora 极光渐变
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.isDarkMode ? '#0A1628' : '#F0F8FF')

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
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildMainContent() {
    Stack({ alignContent: Alignment.Bottom }) {
      // Tabs 内容区域 — 占满全屏
      Tabs({
        index: this.currentIndex,
        controller: this.tabsController
      }) {
        TabContent() {
          AuroraDashboard({ isDarkMode: this.isDarkMode })
        }

        TabContent() {
          WifiListSection()
        }

        TabContent() {
          ChannelSection()
        }

        TabContent() {
          SpeedTestSection()
        }

        TabContent() {
          ToolsSection()
        }
      }
      .barHeight(0)  // 隐藏原生 TabBar
      .scrollable(false)
      .animationDuration(300)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .width('100%')
      .height('100%')

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
    // 使用双 Stack 实现点击穿透
    // 内层 Stack：hitTestBehavior(None) 让透明区域穿透到外层
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景透明区域（无背景色=透明，点击穿透）
      Stack() {}
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)  // 透明区域完全不响应点击，点击穿透到下层

      // 顶层 Column：水平居中，承载毛玻璃 TabBar
      Column() {
        Row() {
          ForEach(TAB_ITEMS, (item: TabItem, index: number) => {
            Column() {
              Image(item.icon)
                .width(28)
                .height(28)
                .fillColor(this.currentIndex === index ? '#007AFF' : '#8E8E93')

              Text(item.title)
                .fontSize(12)
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentIndex === index ? '#007AFF' : '#8E8E93')
                .margin({ top: 4 })
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
        .width('85%')   // TabBar 宽度 85%
        .height(80)     // TabBar 高度 80vp
        .padding({ top: 10, bottom: 12 })
        // === 毛玻璃效果 ===
        .backgroundColor('rgba(255, 255, 255, 0.68)')
        .backdropBlur(18)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            ['rgba(255, 255, 255, 0.45)', 0],
            ['rgba(255, 255, 255, 0.14)', 0.5],
            ['rgba(255, 255, 255, 0.08)', 1]
          ]
        })
        .borderRadius(28)
        .border({
          width: { top: 0.5, bottom: 0 },
          color: {
            top: 'rgba(255, 255, 255, 0.78)',
            bottom: 'rgba(0, 0, 0, 0.04)'
          }
        })
        .shadow({
          radius: 24,
          color: 'rgba(0, 0, 0, 0.12)',
          offsetX: 0,
          offsetY: 6
        })
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .height(80)
      .position({ y: 40 })  // 底部安全区 20vp + 上方间距
    }
    .width('100%')
    .height(120)  // 内层 Stack 总高度（含底部安全区）
  }
}
