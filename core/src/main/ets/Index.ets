// @wifi-analyzer/core
// 核心模块统一导出 — WiFi服务、扫描器、权限管理、网络诊断、数据模型

// 数据模型
export { WifiItem } from './models/WifiItem'
export { SpeedTestResult } from './models/SpeedTestResult'
export { ToolItem } from './models/ToolItem'

// WiFi 服务
export { IWifiService, WifiScanInfo, WifiLinkedInfo, ModernWifiService, WifiServiceFactory } from './wifi/WifiService'
export { WifiScanner, WifiScanResult } from './wifi/WifiScanner'
export { WifiDataManager, SharedWifiState } from './wifi/WifiDataManager'

// 权限管理
export { PermissionManager, PermissionStatus } from './permission/PermissionManager'

// 网络诊断
export { NetworkDiagnostics, NetworkDiagnosticsResult, defaultDiagnosticsResult, networkDiagnostics } from './network/NetworkDiagnostics'

// 网络配置常量
export {
  PublicIpConfig,
  DnsConfig,
  DiagnosticsConfig,
  PortScanConfig,
  ValidationPatterns,
  LoggerConfig,
  LogLevel
} from './config/NetworkConfig'

// 依赖注入容器
export { ServiceContainer, container, IServiceContainer } from './ServiceContainer'

// 路由管理器（供所有模块共享）
export { RouterManager, RouteName } from './router/RouterManager'
