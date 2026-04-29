// RouterManager - 统一路由管理
// 支持两种模式：
// 1. NavPathStack 模式（Navigation + NavDestination）
// 2. AppStorage 模式（条件渲染，兼容 API 22）
// 位于 core 模块，供所有 HAR 模块共享

// 路由名称
export type RouteName =
  | 'ping'
  | 'traceroute'
  | 'dns'
  | 'portscan'
  | 'subnet'
  | 'ipgeo'
  | 'poe'
  | 'maclookup'
  | 'wol'
  | 'lanscan'
  | 'roamtest'
  | 'finddevice'
  | 'about'

// 路由名 → AppStorage key 映射
const ROUTE_TO_STORAGE_KEY: Record<string, string> = {
  'ping': 'showPingPage',
  'traceroute': 'showTraceroutePage',
  'dns': 'showDnsPage',
  'portscan': 'showPortScanPage',
  'subnet': 'showSubnetPage',
  'ipgeo': 'showIpGeoPage',
  'poe': 'showPoePage',
  'maclookup': 'showMacLookupPage',
  'wol': 'showWolPage',
  'lanscan': 'showLanScanPage',
  'roamtest': 'showRoamTestPage',
  'finddevice': 'showFindDevicePage',
  'about': 'showAboutPage',
}

// 路由名 → NavDestination 注册名映射
const ROUTE_TO_PAGE: Record<string, string> = {
  'ping': 'PingTestPage',
  'traceroute': 'TraceroutePage',
  'dns': 'DnsLookupPage',
  'portscan': 'PortScanPage',
  'subnet': 'SubnetCalcPage',
  'ipgeo': 'IpGeoPage',
  'poe': 'PoeCalcPage',
  'maclookup': 'MacLookupPage',
  'wol': 'WolPage',
  'lanscan': 'LanScanPage',
  'roamtest': 'RoamTestPage',
  'finddevice': 'FindDevicePage',
  'about': 'AboutPage',
}

export class RouterManager {
  // NavPathStack 模式（可选）
  private static navPathStack: NavPathStack | null = null

  // 当前模式
  private static useNavPathStack: boolean = false

  // 路由变更回调
  private static callbacks: Array<(route: string | null) => void> = []

  // 初始化 NavPathStack 模式
  static initNavPathStack(stack: NavPathStack): void {
    RouterManager.navPathStack = stack
    RouterManager.useNavPathStack = true
  }

  // 初始化 AppStorage 模式（API 22 兼容）
  static initAppStorageMode(): void {
    RouterManager.useNavPathStack = false
    // 初始化所有页面状态为 false
    for (const key of Object.values(ROUTE_TO_STORAGE_KEY)) {
      AppStorage.set(key, false)
    }
  }

  // 获取 NavPathStack
  static getNavPathStack(): NavPathStack | null {
    return RouterManager.navPathStack
  }

  // 导航到指定页面
  static navigate(route: RouteName, param?: Object): void {
    if (RouterManager.useNavPathStack && RouterManager.navPathStack) {
      // NavPathStack 模式
      const pageName = ROUTE_TO_PAGE[route]
      if (!pageName) {
        console.error('[RouterManager] Unknown route:', route)
        return
      }
      RouterManager.navPathStack.pushPathByName(pageName, param)
    } else {
      // AppStorage 模式
      const key = ROUTE_TO_STORAGE_KEY[route]
      if (!key) {
        console.error('[RouterManager] Unknown route:', route)
        return
      }
      AppStorage.set(key, true)
    }
    RouterManager.notifyChange(route)
  }

  // 返回上一页
  static goBack(): boolean {
    if (RouterManager.useNavPathStack && RouterManager.navPathStack) {
      if (RouterManager.navPathStack.size() > 0) {
        RouterManager.navPathStack.pop()
        if (RouterManager.navPathStack.size() === 0) {
          RouterManager.notifyChange(null)
        }
        return true
      }
      return false
    } else {
      // AppStorage 模式：关闭所有页面
      for (const key of Object.values(ROUTE_TO_STORAGE_KEY)) {
        AppStorage.set(key, false)
      }
      RouterManager.notifyChange(null)
      return true
    }
  }

  // 返回到根页面
  static goHome(): void {
    if (RouterManager.useNavPathStack && RouterManager.navPathStack) {
      if (RouterManager.navPathStack.size() > 0) {
        RouterManager.navPathStack.clear()
      }
    } else {
      // AppStorage 模式：关闭所有页面
      for (const key of Object.values(ROUTE_TO_STORAGE_KEY)) {
        AppStorage.set(key, false)
      }
    }
    RouterManager.notifyChange(null)
  }

  // 检查是否有可返回的页面
  static canGoBack(): boolean {
    if (RouterManager.useNavPathStack && RouterManager.navPathStack) {
      return RouterManager.navPathStack.size() > 0
    }
    // AppStorage 模式：检查是否有页面打开
    for (const key of Object.values(ROUTE_TO_STORAGE_KEY)) {
      if (AppStorage.get<boolean>(key) === true) {
        return true
      }
    }
    return false
  }

  // 获取导航栈大小
  static getStackSize(): number {
    if (RouterManager.useNavPathStack && RouterManager.navPathStack) {
      return RouterManager.navPathStack.size()
    }
    let count = 0
    for (const key of Object.values(ROUTE_TO_STORAGE_KEY)) {
      if (AppStorage.get<boolean>(key) === true) {
        count++
      }
    }
    return count
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
