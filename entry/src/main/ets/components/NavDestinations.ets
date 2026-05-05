// NavDestination 包装组件
// 将 tools HAR 模块的子页面包装为 NavDestination 供 Navigation 使用
// 每个 @Builder 函数注册在 router_map.json 中

import { RouterManager } from '@wifi-analyzer/core'
import { TraceroutePage, DnsLookupPage, PortScanPage, SubnetCalcPage, IpGeoPage,
  PoeCalcPage, MacLookupPage, WolPage, LanScanPage, RoamTestPage } from '@wifi-analyzer/tools'
import { PingTestPage } from './PingTestPage'
import { AboutPage } from './AboutPage'
import { ChannelPage } from './ChannelPage'

// ==================== NavDestination 包装函数 ====================
// 每个子页面包裹在 NavDestination 中，提供标题栏和返回按钮
// 注：hideBackButton 从 SDK 15 开始支持，当前 compatibleSdkVersion 为 14
// 默认 hideBackButton(false)，不需要显式设置

// Ping 测试
@Builder
function PingTestPageBuilder(name: string, param: Object) {
  NavDestination() {
    PingTestPage()
  }
  .title($r('app.string.ping_test'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// 关于页面
@Builder
function AboutPageBuilder(name: string, param: Object) {
  NavDestination() {
    AboutPage()
  }
  .title($r('app.string.about_wifi_analyzer'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// 路由追踪
@Builder
function TraceroutePageBuilder(name: string, param: Object) {
  NavDestination() {
    TraceroutePage()
  }
  .title($r('app.string.traceroute'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// DNS 查询
@Builder
function DnsLookupPageBuilder(name: string, param: Object) {
  NavDestination() {
    DnsLookupPage()
  }
  .title($r('app.string.dns_lookup'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// 端口扫描
@Builder
function PortScanPageBuilder(name: string, param: Object) {
  NavDestination() {
    PortScanPage()
  }
  .title($r('app.string.port_scan'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// 子网计算
@Builder
function SubnetCalcPageBuilder(name: string, param: Object) {
  NavDestination() {
    SubnetCalcPage()
  }
  .title($r('app.string.subnet_calc'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// IP 归属地
@Builder
function IpGeoPageBuilder(name: string, param: Object) {
  NavDestination() {
    IpGeoPage()
  }
  .title($r('app.string.ip_geo'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// PoE 功耗计算
@Builder
function PoeCalcPageBuilder(name: string, param: Object) {
  NavDestination() {
    PoeCalcPage()
  }
  .title($r('app.string.poe_calc'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// MAC 地址查询
@Builder
function MacLookupPageBuilder(name: string, param: Object) {
  NavDestination() {
    MacLookupPage()
  }
  .title($r('app.string.mac_lookup'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// Wake on LAN
@Builder
function WolPageBuilder(name: string, param: Object) {
  NavDestination() {
    WolPage()
  }
  .title($r('app.string.wake_on_lan'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// 局域网扫描
@Builder
function LanScanPageBuilder(name: string, param: Object) {
  NavDestination() {
    LanScanPage()
  }
  .title($r('app.string.lan_scan'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// 漫游测试
@Builder
function RoamTestPageBuilder(name: string, param: Object) {
  NavDestination() {
    RoamTestPage()
  }
  .title($r('app.string.roam_test'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}

// 信道分析
@Builder
function ChannelPageBuilder(name: string, param: Object) {
  NavDestination() {
    ChannelPage()
  }
  .title($r('app.string.channel_analysis'))
  .onBackPressed(() => {
    RouterManager.goBack()
    return true
  })
}
