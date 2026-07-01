// MainView — HM7 断点驱动的多端布局 v3.0
// xs (<320vp): 超小屏 → 底部浮动TabBar（紧凑模式）
// sm (320-600vp): 手机/折叠折叠态 → 底部浮动TabBar
// md (600-840vp): 平板/折叠展开态 → 底部浮动TabBar + 内容双列
// lg (>=840vp): 大屏/PC → SideBarContainer 左侧固定侧边栏
// 升级：systemMaterial 材质 · 边缘光感 · Curve.Friction 动效
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GlobalInfoModel } from 'wifi-base';
import { RouterManager, RouteName, ApiCompat } from '@wifi-analyzer/core';
import {
  adaptivePrimary,
  adaptivePrimaryLight,
  adaptivePrimaryBg,
  adaptiveAuroraPrimary,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  adaptiveDivider,
  adaptiveBackgroundList,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_LIGHT_PRIMARY,
  COLOR_BG,
  PRESET_TAB_PHASE1,
  PRESET_TAB_PHASE2,
  PRESET_TAB_PHASE3,
  PRESET_TAB_CONTENT,
} from '@wifi-analyzer/design-system';
import { AuroraTabBar } from '../components/AuroraTabBar';
import { TabAnimationHelper } from '../utils/TabAnimationHelper';
import { wifiManager } from '@kit.ConnectivityKit'
import { connection } from '@kit.NetworkKit'
import { AuroraDashboard } from '../components/AuroraDashboard';
import { WifiListSection } from '../components/WifiListSection';
import { ChannelSection } from '../components/ChannelSection';
import { SpeedTestSection } from '../components/SpeedTestSection';
import { ToolsSection } from '../components/ToolsSection';
import { NetworkOverviewGateway } from '../components/NetworkOverviewGateway';

const TAG = '[MainView]'

@ComponentV2
export struct MainView {
  @Local globalInfoModel: GlobalInfoModel = GlobalInfoModel.getInstance();
  @Local currentIndex: number = 0;
  @Local deviceWidth: number = 360;
  @Local deviceHeight: number = 0;
  @Local isApi23: boolean = false;
  @Local widthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @Local localIp: string = '获取中...';
  @Local dns: string = '获取中...';
  private winRef: window.Window | null = null;


  // ── Classic TabBar（API <23 降级）：动画状态 ──
  @Local tabScales: number[] = TabAnimationHelper.getInitialTabScales();
  @Local tabGlows: number[] = TabAnimationHelper.getInitialTabGlows();
  @Local tabOffsetY: number[] = TabAnimationHelper.getInitialTabOffsetY();
  @Local tabDotOpacity: number[] = TabAnimationHelper.getInitialTabDotOpacity();
  @Local contentOpacity: number = TabAnimationHelper.getInitialContentOpacity();
  @Local contentOffsetY: number = TabAnimationHelper.getInitialContentOffsetY();
  private tabsController: TabsController = new TabsController();

  aboutToAppear(): void {
    // 在 UI 构建前判断设备是否支持 API 23+ 的 HdsTabs 浮动样式
    this.isApi23 = ApiCompat.isApi23OrHigher();
    this.refreshSize();
    // 独立获取网络信息
    this.fetchLocalIp()
    this.fetchDns()
    window.getLastWindow(getContext()).then((win: window.Window) => {
      this.winRef = win;
      win.on('windowSizeChange', () => this.refreshSize());
    });
  }

  aboutToDisappear(): void {
    if (this.winRef) {
      try { this.winRef.off('windowSizeChange'); } catch (_e) {}
      this.winRef = null;
    }
  }

  private fetchLocalIp(): void {
    try {
      const ipInfo = wifiManager.getIpInfo()
      if (ipInfo && ipInfo.ipAddress && ipInfo.ipAddress !== 0) {
        const ip: string = ((ipInfo.ipAddress >>> 24) & 0xFF) + '.' +
          ((ipInfo.ipAddress >> 16) & 0xFF) + '.' +
          ((ipInfo.ipAddress >> 8) & 0xFF) + '.' +
          (ipInfo.ipAddress & 0xFF)
        if (ip !== '0.0.0.0') { this.localIp = ip; return }
      }
    } catch (e) { hilog.warn(0x0000, TAG, 'fetchLocalIp error: %{public}s', JSON.stringify(e)) }
    this.localIp = '--'
  }

  private fetchDns(): void {
    try {
      const netHandle = connection.getDefaultNetSync()
      if (netHandle && netHandle.netId !== 0) {
        const props: connection.ConnectionProperties = connection.getConnectionPropertiesSync(netHandle)
        if (props && props.dnses) {
          for (let i = 0; i < props.dnses.length; i++) {
            const d = props.dnses[i]
            if (d && d.address && !d.address.startsWith('::') && d.address !== '0.0.0.0') {
              this.dns = d.address; return
            }
          }
        }
      }
    } catch (e) { hilog.warn(0x0000, TAG, 'fetchDns error: %{public}s', JSON.stringify(e)) }
    this.dns = '--'
  }

  private refreshSize(): void {
    window.getLastWindow(getContext()).then((win: window.Window) => {
      const uiCtx = win.getUIContext();
      const rect = win.getWindowProperties().windowRect;
      this.deviceWidth = uiCtx.px2vp(rect.width);
      this.deviceHeight = uiCtx.px2vp(rect.height);
      this.widthBreakpoint = uiCtx.getWindowWidthBreakpoint();
      this.globalInfoModel.deviceWidth = this.deviceWidth;
      this.globalInfoModel.deviceHeight = this.deviceHeight;
      this.globalInfoModel.widthBreakpoint = this.widthBreakpoint;
    });
  }

  // ── 工具方法 ──
  private get isDark(): boolean { return this.globalInfoModel.isDarkMode }
  private selectedColor(): string { return adaptivePrimaryLight(this.isDark) }
  private unselectedColor(): string { return adaptiveTextSecondary(this.isDark) }
  private onTabChange(index: number): void {
    this.currentIndex = index;
    this.globalInfoModel.currentTabIndex = index;
  }

  // ── 平板模式下内容列数 ──
  private get contentColumns(): number {
    if (this.widthBreakpoint >= WidthBreakpoint.WIDTH_LG) return 1;
    if (this.widthBreakpoint >= WidthBreakpoint.WIDTH_MD) return 2;
    return 1;
  }

  // ── 侧边栏宽度 ──
  private get sideBarWidth(): number {
    if (this.deviceWidth >= 1200) return 240;
    return 200;
  }

  // ========== 底部浮动 TabBar（xs/sm/md 竖屏）==========
  @Builder
  bottomTabBuilder(icon: Resource, name: ResourceStr, index: number) {
    Column() {
      Image(icon).width(22).height(22)
        .fillColor(index === this.currentIndex ? this.selectedColor() : this.unselectedColor())
      Text(name).fontSize(10).fontWeight(index === this.currentIndex ? 600 : 400)
        .fontColor(index === this.currentIndex ? this.selectedColor() : this.unselectedColor())
        .margin({ top: 3 })
    }
    .height('100%').width('100%')
    .justifyContent(FlexAlign.Center)
    .animation({ duration: 250, curve: Curve.Friction })
  }

  private getBarWidth(): number {
    const w = this.deviceWidth > 0 ? this.deviceWidth : 360;
    if (w <= 520) return Math.min(w - 32, 360);
    if (w <= 700) return Math.min(w - 80, 520);
    return 560;
  }

  // ── Classic Tab 切换动画（API <23 降级）──
  private onTabClick(index: number): void {
    if (this.currentIndex === index) return;
    const prevIndex = this.currentIndex;

    this.getUIContext().animateTo(PRESET_TAB_PHASE1, () => {
      this.contentOpacity = 0.6;
      this.contentOffsetY = 8;
    });

    const phase1 = TabAnimationHelper.calcPhase1States(prevIndex, index,
      this.tabScales, this.tabOffsetY, this.tabDotOpacity);
    this.getUIContext().animateTo(PRESET_TAB_PHASE1, () => {
      this.tabScales = phase1.scales;
      this.tabOffsetY = phase1.offsets;
      this.tabDotOpacity = phase1.dots;
    });

    setTimeout(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(index);
      this.globalInfoModel.currentTabIndex = index;

      const phase2 = TabAnimationHelper.calcPhase2States(index,
        this.tabScales, this.tabOffsetY, this.tabGlows, this.tabDotOpacity);
      this.getUIContext().animateTo(PRESET_TAB_PHASE2, () => {
        this.tabScales = phase2.scales;
        this.tabOffsetY = phase2.offsets;
        this.tabGlows = phase2.glows;
        this.tabDotOpacity = phase2.dots;
      });

      this.getUIContext().animateTo(PRESET_TAB_CONTENT, () => {
        this.contentOpacity = 1;
        this.contentOffsetY = 0;
      });
    }, TabAnimationHelper.getPhase2Delay());

    setTimeout(() => {
      const phase3 = TabAnimationHelper.calcPhase3States();
      this.getUIContext().animateTo(PRESET_TAB_PHASE3, () => {
        this.tabScales = phase3.scales;
        this.tabOffsetY = phase3.offsets;
        this.tabGlows = phase3.glows;
      });
    }, TabAnimationHelper.getPhase3Delay());
  }

  // API 23+：HdsTabs 浮动 TabBar（沉浸光感自适应材质）
  @Builder
  BottomTabFloating() {
    HdsTabs() {
      TabContent() { this.ContentView() }
        .tabBar(this.bottomTabBuilder($r('app.media.ic_home'), $r('app.string.tab_home'), 0))
      TabContent() { WifiListSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        .tabBar(this.bottomTabBuilder($r('app.media.ic_wifi'), $r('app.string.tab_wifi'), 1))
      TabContent() { ChannelSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        .tabBar(this.bottomTabBuilder($r('app.media.ic_chart'), $r('app.string.tab_channel'), 2))
      TabContent() { SpeedTestSection({ isDark: this.isDark }) }
        .tabBar(this.bottomTabBuilder($r('app.media.ic_speed'), $r('app.string.tab_speed'), 3))
      TabContent() { ToolsSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        .tabBar(this.bottomTabBuilder($r('app.media.ic_tool'), $r('app.string.tab_tools'), 4))
    }
    .onChange((index: number) => this.onTabChange(index))
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .vertical(false)
    .scrollable(false)
    .animationDuration(250)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.ALL])
    .height(LayoutPolicy.matchParent)
    .backgroundColor(Color.Transparent)
    .barWidth(this.getBarWidth())
    .barHeight(56)
    .barFloatingStyle({
      barBottomMargin: Math.max(this.globalInfoModel.naviIndicatorHeight, 36),
      adaptToHandedness: true,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.ADAPTIVE,
        materialLevel: hdsMaterial.MaterialLevel.GENTLE,
      }
    })
  }

  // 兼容 API 17-22：旧项目经典 Tabs + AuroraTabBar（毛玻璃圆角 + 图标动画）
  @Builder
  BottomTabClassic() {
    Stack({ alignContent: Alignment.Bottom }) {
      Tabs({
        index: this.currentIndex,
        controller: this.tabsController
      }) {
        TabContent() { this.ContentView() }
        TabContent() { WifiListSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        TabContent() { ChannelSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        TabContent() { SpeedTestSection({ isDark: this.isDark }) }
        TabContent() { ToolsSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
      }
      .barHeight(0)
      .scrollable(false)
      .animationDuration(0)
      .padding({ top: 36 })
      .onChange((index: number) => {
        this.currentIndex = index;
        this.globalInfoModel.currentTabIndex = index;
      })
      .width('100%')
      .height('100%')
      .opacity(this.contentOpacity)
      .translate({ x: 0, y: this.contentOffsetY })

      AuroraTabBar({
        currentIndex: this.currentIndex,
        isDarkMode: this.isDark,
        tabScales: this.tabScales,
        tabGlows: this.tabGlows,
        tabOffsetY: this.tabOffsetY,
        tabDotOpacity: this.tabDotOpacity,
        onTabSelected: (idx: number) => { this.onTabClick(idx) }
      })
    }
    .width('100%').height('100%')
  }

  @Builder
  BottomTabLayout() {
    Stack() {
      if (this.isApi23) {
        this.BottomTabFloating()
      } else {
        this.BottomTabClassic()
      }

      // ── 顶部毛玻璃状态栏浮条 ──
      Column()
        .width('100%')
        .height(this.globalInfoModel.statusBarHeight + 56)
        .backdropBlur(12)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [this.isDark ? 'rgba(10,13,20,0.82)' : 'rgba(255,255,255,0.78)', 0.0],
            [this.isDark ? 'rgba(10,13,20,0.55)' : 'rgba(255,255,255,0.50)', 0.6],
            [this.isDark ? 'rgba(10,13,20,0.0)' : 'rgba(255,255,255,0.0)', 1.0]
          ]
        })
        .position({ x: 0, y: 0 })
        .padding({ top: this.globalInfoModel.statusBarHeight })
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%').height('100%')
    .backgroundColor(this.isDark ? '#0A0D14' : COLOR_BG)
  }

  // ── 内容视图（首页在平板模式下双列）──
  @Builder
  ContentView() {
    if (this.widthBreakpoint >= WidthBreakpoint.WIDTH_MD) {
      Grid() {
        GridItem() { AuroraDashboard({ isDark: this.isDark }) }
        GridItem() { this.OverviewPanel() }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .width('100%').height('100%')
    } else {
      AuroraDashboard({ isDark: this.isDark })
    }
  }

  @Builder
  OverviewPanel() {
    Column({ space: 12 }) {
      Column({ space: 8 }) {
        Text($r('app.string.network_overview')).fontSize(16).fontWeight(FontWeight.Bold)
          .fontColor(adaptiveTextPrimary(this.isDark))

        this.ovItem($r('app.string.local_ip'), this.localIp)
        NetworkOverviewGateway({ isDark: this.isDark })
        this.ovItem($r('app.string.dns'), this.dns)
      }
      .width('100%').padding(16)
      .backgroundColor(this.isDark ? 'rgba(255,255,255,0.10)' : 'rgba(0,0,0,0.04)')
      .borderRadius(16)
      .borderWidth(1).borderColor(adaptiveDivider(this.isDark))
      .clip(true)

      // 推荐工具
      this.toolTip()
    }
    .width('100%').height('100%')
    .padding({ top: 56, left: 12, right: 12 })
  }

  @Builder ovItem(label: Resource, value: string) {
    Column({ space: 2 }) {
      Text(label).fontSize(12).fontColor(adaptiveTextSecondary(this.isDark))
      Text(value).fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor(adaptiveTextPrimary(this.isDark))
        .fontFamily('HarmonyOS Sans Mono')
    }.alignItems(HorizontalAlign.Start).width('100%')
  }

  @Builder toolTip() {
    Column({ space: 4 }) {
      Text($r('app.string.recommended_tools')).fontSize(12).fontWeight(600)
        .fontColor(adaptiveTextSecondary(this.isDark))
        .letterSpacing(0.15).textCase(TextCase.UpperCase)
        .width('100%').margin({ top: 8 })

      Row({ space: 8 }) {
        this.tipChip('Ping', 'ping')
        this.tipChip($r('app.string.dns'), 'dns')
        this.tipChip($r('app.string.port'), 'portscan')
      }
    }
  }

  @Builder tipChip(label: ResourceStr, route: RouteName) {
    Text(label)
      .fontSize(11).fontWeight(500)
      .fontColor(adaptivePrimaryLight(this.isDark))
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(adaptivePrimaryBg(this.isDark))
      .borderRadius(8)
      .onClick(() => { RouterManager.navigate(route) })
  }

  // ========== 平板横屏布局（md + 横屏）：垂直TabBar ==========
  @Builder
  landscapeTabBuilder(icon: Resource, label: ResourceStr, index: number) {
    Row({ space: 8 }) {
      Image(icon).width(20).height(20)
        .fillColor(index === this.currentIndex ? this.selectedColor() : this.unselectedColor())
      Text(label).fontSize(14).fontWeight(index === this.currentIndex ? 600 : 400)
        .fontColor(index === this.currentIndex ? this.selectedColor() : this.unselectedColor())
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .width('100%')
    .borderRadius(10)
    .backgroundColor(index === this.currentIndex
      ? adaptivePrimaryBg(this.isDark)
      : Color.Transparent)
    .animation({ duration: 250, curve: Curve.Friction })
  }

  // API 23+：平板横屏使用 HdsTabs 浮动垂直 TabBar
  @Builder
  LandscapeTabFloating() {
    HdsTabs() {
      TabContent() { this.ContentView() }
        .tabBar(this.landscapeTabBuilder($r('app.media.ic_home'), $r('app.string.tab_home'), 0))
      TabContent() { WifiListSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        .tabBar(this.landscapeTabBuilder($r('app.media.ic_wifi'), $r('app.string.tab_wifi'), 1))
      TabContent() { ChannelSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        .tabBar(this.landscapeTabBuilder($r('app.media.ic_chart'), $r('app.string.tab_channel'), 2))
      TabContent() { SpeedTestSection({ isDark: this.isDark }) }
        .tabBar(this.landscapeTabBuilder($r('app.media.ic_speed'), $r('app.string.tab_speed'), 3))
      TabContent() { ToolsSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        .tabBar(this.landscapeTabBuilder($r('app.media.ic_tool'), $r('app.string.tab_tools'), 4))
    }
    .onChange((index: number) => this.onTabChange(index))
    .barOverlap(true)
    .barPosition(BarPosition.Start)
    .vertical(true)
    .scrollable(false)
    .animationDuration(250)
    .barWidth(160)
    .barFloatingStyle({
      adaptToHandedness: true,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.ADAPTIVE,
        materialLevel: hdsMaterial.MaterialLevel.GENTLE,
      }
    })
    .width('100%').height('100%')
    .backgroundColor(this.isDark ? '#0A0D14' : COLOR_BG)
  }

  // 兼容 API 17-22：平板横屏经典 Tabs + AuroraTabBar（竖排）
  @Builder
  LandscapeTabClassic() {
    Stack({ alignContent: Alignment.Bottom }) {
      Tabs({
        index: this.currentIndex,
        controller: this.tabsController
      }) {
        TabContent() { this.ContentView() }
        TabContent() { WifiListSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        TabContent() { ChannelSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        TabContent() { SpeedTestSection({ isDark: this.isDark }) }
        TabContent() { ToolsSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
      }
      .barHeight(0)
      .scrollable(false)
      .animationDuration(0)
      .padding({ top: 36 })
      .onChange((index: number) => {
        this.currentIndex = index;
        this.globalInfoModel.currentTabIndex = index;
      })
      .width('100%')
      .height('100%')
      .opacity(this.contentOpacity)
      .translate({ x: 0, y: this.contentOffsetY })

      AuroraTabBar({
        currentIndex: this.currentIndex,
        isDarkMode: this.isDark,
        tabScales: this.tabScales,
        tabGlows: this.tabGlows,
        tabOffsetY: this.tabOffsetY,
        tabDotOpacity: this.tabDotOpacity,
        onTabSelected: (idx: number) => { this.onTabClick(idx) }
      })
    }
    .width('100%').height('100%')
    .backgroundColor(this.isDark ? '#0A0D14' : COLOR_BG)
  }

  @Builder
  TabletLandscapeLayout() {
    Stack() {
      if (this.isApi23) {
        this.LandscapeTabFloating()
      } else {
        this.LandscapeTabClassic()
      }

      // 顶部毛玻璃
      Column()
        .width('100%')
        .height(this.globalInfoModel.statusBarHeight + 56)
        .backdropBlur(12)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [this.isDark ? 'rgba(10,13,20,0.82)' : 'rgba(255,255,255,0.78)', 0.0],
            [this.isDark ? 'rgba(10,13,20,0.55)' : 'rgba(255,255,255,0.50)', 0.6],
            [this.isDark ? 'rgba(10,13,20,0.0)' : 'rgba(255,255,255,0.0)', 1.0]
          ]
        })
        .position({ x: 0, y: 0 })
        .padding({ top: this.globalInfoModel.statusBarHeight })
        .alignItems(HorizontalAlign.Center)
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%').height('100%')
    .backgroundColor(this.isDark ? '#0A0D14' : COLOR_BG)
  }

  // ========== PC 布局（lg）：SideBarContainer ==========
  @Builder
  pcTabItem(icon: Resource, label: ResourceStr, index: number) {
    Row({ space: 10 }) {
      Image(icon).width(22).height(22)
        .fillColor(index === this.currentIndex ? this.selectedColor() : this.unselectedColor())
      Text(label).fontSize(15).fontWeight(index === this.currentIndex ? 600 : 400)
        .fontColor(index === this.currentIndex ? this.selectedColor() : this.unselectedColor())
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ left: 8, right: 8, bottom: 2 })
    .width('100%')
    .borderRadius(10)
    .backgroundColor(index === this.currentIndex
      ? adaptivePrimaryBg(this.isDark)
      : Color.Transparent)
    .onClick(() => this.onTabChange(index))
    .animation({ duration: 250, curve: Curve.Friction })
  }

  @Builder
  PcLayout() {
    SideBarContainer(SideBarContainerType.Embed) {
      Column() {
        // 应用品牌
        Row({ space: 12 }) {
          Image($r('app.media.ic_wifi')).width(32).height(32)
            .fillColor(adaptivePrimary(this.isDark))
          Text($r('app.string.brand_title'))
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.isDark ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 48, bottom: 24 })

        Column() {
          this.pcTabItem($r('app.media.ic_home'), $r('app.string.tab_home'), 0)
          this.pcTabItem($r('app.media.ic_wifi'), $r('app.string.tab_wifi'), 1)
          this.pcTabItem($r('app.media.ic_chart'), $r('app.string.tab_channel'), 2)
          this.pcTabItem($r('app.media.ic_speed'), $r('app.string.tab_speed'), 3)
          this.pcTabItem($r('app.media.ic_tool'), $r('app.string.tab_tools'), 4)
        }
        .layoutWeight(1).width('100%').padding({ top: 8 })
      }
      .width(this.sideBarWidth).height('100%')
      .backgroundColor(this.isDark ? 'rgba(10,13,20,0.92)' : 'rgba(242,244,247,0.95)')

      Column() {
        if (this.currentIndex === 0) { AuroraDashboard({ isDark: this.isDark }) }
        else if (this.currentIndex === 1) { WifiListSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        else if (this.currentIndex === 2) { ChannelSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
        else if (this.currentIndex === 3) { SpeedTestSection({ isDark: this.isDark }) }
        else { ToolsSection({ isDark: this.isDark, deviceWidth: this.deviceWidth }) }
      }
      .width('100%').height('100%')
      .backgroundColor(this.isDark ? '#0A0D14' : COLOR_BG)
    }
    .width('100%').height('100%')
    .sideBarWidth(this.sideBarWidth)
    .showSideBar(true)
    .showControlButton(false)
    .animation({ duration: 300, curve: Curve.Friction })
  }

  // ── 横屏检测 ──
  private get isLandscape(): boolean {
    return this.deviceWidth > this.deviceHeight;
  }

  // ── 主入口 ──
  build() {
    if (this.widthBreakpoint >= WidthBreakpoint.WIDTH_LG) {
      this.PcLayout()
    } else if (this.isLandscape && this.widthBreakpoint >= WidthBreakpoint.WIDTH_MD) {
      this.TabletLandscapeLayout()
    } else {
      this.BottomTabLayout()
    }
  }
}
