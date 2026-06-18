/**
 * WiFi分析仪 — 通用常量
 */

export class CommonConstants {
  /** AppStorage 键名前缀 */
  static readonly KEY_PREFIX: string = 'wifiAnalyzer';

  /** 窗口工具 */
  static readonly WINDOW_UTIL_KEY: string = CommonConstants.KEY_PREFIX + 'WindowUtil';

  /** 页面名称 */
  static readonly HOME_PAGE: string = 'HomePage';
  static readonly WIFI_SCAN_PAGE: string = 'WifiScanPage';
  static readonly CHANNEL_PAGE: string = 'ChannelPage';
  static readonly SPEED_TEST_PAGE: string = 'SpeedTestPage';
  static readonly TOOLS_PAGE: string = 'ToolsPage';

  /** 网络工具页面名称 */
  static readonly PING_PAGE: string = 'PingPage';
  static readonly DNS_PAGE: string = 'DnsPage';
  static readonly TRACEROUTE_PAGE: string = 'TraceroutePage';
  static readonly PORT_SCAN_PAGE: string = 'PortScanPage';
  static readonly SUBNET_PAGE: string = 'SubnetPage';
  static readonly IP_GEO_PAGE: string = 'IpGeoPage';
  static readonly POE_PAGE: string = 'PoePage';
  static readonly MAC_LOOKUP_PAGE: string = 'MacLookupPage';
  static readonly WOL_PAGE: string = 'WolPage';
  static readonly LAN_SCAN_PAGE: string = 'LanScanPage';
  static readonly ROAM_TEST_PAGE: string = 'RoamTestPage';

  /** WiFi 扫描间隔 (ms) */
  static readonly WIFI_SCAN_INTERVAL: number = 12000;

  /** 测速默认时长 (s) */
  static readonly SPEED_TEST_DURATION: number = 12;

  /** 暗色模式 key */
  static readonly IS_DARK_MODE_KEY: string = 'isDarkMode';
}
