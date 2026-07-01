// RouterManager - 统一路由管理（v2 简化版）
// 仅保留 NavPathStack 模式（移除 AppStorage 条件渲染模式）
// 参照 MultiFinancialManagement 的 HdsNavigation + NavPathStack 模式
// 位于 core 模块，供所有 HAR 模块共享

import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = '[RouterManager]'

// 页面名称常量（与 CommonConstants 保持一致，避免循环依赖）
const PING_PAGE: string = 'PingPage'
const DNS_PAGE: string = 'DnsPage'
const TRACEROUTE_PAGE: string = 'TraceroutePage'
const PORT_SCAN_PAGE: string = 'PortScanPage'
const SUBNET_PAGE: string = 'SubnetPage'
const IP_GEO_PAGE: string = 'IpGeoPage'
const POE_PAGE: string = 'PoePage'
const LAN_SCAN_PAGE: string = 'LanScanPage'
const SETTINGS_PAGE: string = 'SettingsPage'

// 路由名称
export type RouteName =
  | 'ping' | 'traceroute' | 'dns'
  | 'portscan' | 'subnet' | 'ipgeo' | 'poe'
  | 'lanscan' | 'settings' | 'speedtest'

// 路由名 → NavDestination 注册名映射（与 Index.ets PagesMap 保持一致）
const SPEEDTEST_PAGE: string = 'SpeedTestPage'

const ROUTE_TO_PAGE: Record<string, string> = {
  'ping':       PING_PAGE,
  'traceroute': TRACEROUTE_PAGE,
  'dns':        DNS_PAGE,
  'portscan':   PORT_SCAN_PAGE,
  'subnet':     SUBNET_PAGE,
  'ipgeo':      IP_GEO_PAGE,
  'poe':        POE_PAGE,
  'lanscan':    LAN_SCAN_PAGE,
  'settings':   SETTINGS_PAGE,
  'speedtest':  SPEEDTEST_PAGE,
}

export class RouterManager {
  // NavPathStack 模式
  private static navPathStack: NavPathStack | null = null

  // 路由变更回调
  private static callbacks: Array<(route: string | null) => void> = []

  // Tab 变更回调
  private static tabCallbacks: Array<(tabIndex: number) => void> = []

  // 设置 NavPathStack（使用现有栈，与Navigation共享）
  static createStack(existingStack?: NavPathStack): NavPathStack {
    if (existingStack) {
      RouterManager.navPathStack = existingStack
      return existingStack
    }
    const stack: NavPathStack = new NavPathStack()
    RouterManager.navPathStack = stack
    return stack
  }

  // 获取 NavPathStack
  static getNavPathStack(): NavPathStack | null {
    return RouterManager.navPathStack
  }

  // 导航到指定页面
  static navigate(route: RouteName, param?: Object): void {
    const stack = RouterManager.navPathStack
    if (!stack) {
      hilog.error(DOMAIN, TAG, 'NavPathStack not initialized')
      return
    }
    const pageName = ROUTE_TO_PAGE[route]
    if (!pageName) {
      hilog.error(DOMAIN, TAG, 'Unknown route: %{public}s', route)
      return
    }
    stack.pushPathByName(pageName, param)
    RouterManager.notifyChange(route)
  }

  // 导航到指定 Tab
  static navigateToTab(tabIndex: number): void {
    if (tabIndex < 0 || tabIndex > 4) {
      hilog.error(DOMAIN, TAG, 'Invalid tab index: %{public}d', tabIndex)
      return
    }
    RouterManager.notifyTabChange(tabIndex)
  }

  // 订阅 Tab 变更
  static subscribeTab(callback: (tabIndex: number) => void): () => void {
    RouterManager.tabCallbacks.push(callback)
    return () => {
      const index = RouterManager.tabCallbacks.indexOf(callback)
      if (index > -1) {
        RouterManager.tabCallbacks.splice(index, 1)
      }
    }
  }

  // 通知所有 Tab 订阅者
  private static notifyTabChange(tabIndex: number): void {
    for (const callback of RouterManager.tabCallbacks) {
      callback(tabIndex)
    }
  }

  // 返回上一页
  static goBack(): boolean {
    const stack = RouterManager.navPathStack
    if (stack && stack.size() > 0) {
      stack.pop()
      if (stack.size() === 0) {
        RouterManager.notifyChange(null)
      }
      return true
    }
    return false
  }

  // 返回到根页面
  static goHome(): void {
    const stack = RouterManager.navPathStack
    if (stack && stack.size() > 0) {
      stack.clear()
    }
    RouterManager.notifyChange(null)
  }

  // 检查是否有可返回的页面
  static canGoBack(): boolean {
    const stack = RouterManager.navPathStack
    return stack !== null && stack.size() > 0
  }

  // 检查是否在子页面中
  static isInSubPage(): boolean {
    const stack = RouterManager.navPathStack
    return stack !== null && stack.size() > 0
  }

  // 获取导航栈大小
  static getStackSize(): number {
    const stack = RouterManager.navPathStack
    return stack ? stack.size() : 0
  }

  // 订阅路由变更
  static subscribe(callback: (route: string | null) => void): () => void {
    RouterManager.callbacks.push(callback)
    return () => {
      const index = RouterManager.callbacks.indexOf(callback)
      if (index > -1) {
        RouterManager.callbacks.splice(index, 1)
      }
    }
  }

  // 通知所有订阅者
  private static notifyChange(route: string | null): void {
    for (const callback of RouterManager.callbacks) {
      callback(route)
    }
  }
}
