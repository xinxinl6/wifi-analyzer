// ToolModels.ets
// 网络工具模块共享模型类型
// 所有引擎返回的结构化结果、配置、回调接口

// ==================== Ping 模型 ====================

export interface PingResult {
  index: number
  host: string
  address: string
  time: number
  ttl: number
  status: 'success' | 'timeout' | 'error'
  errorMessage: string
}

export interface PingStats {
  sent: number
  received: number
  lost: number
  lossRate: number
  minTime: number
  maxTime: number
  avgTime: number
  totalTime: number
}

export interface PingConfig {
  host: string
  count: number
  timeout: number
  interval: number
}

export interface PingCallbacks {
  onResult?: (result: PingResult) => void
  onProgress?: (sent: number, received: number) => void
  onComplete?: (results: PingResult[], stats: PingStats) => void
  onError?: (message: string) => void
}

// ==================== DNS 查询模型 ====================

export type DnsRecordType = 'A' | 'AAAA' | 'CNAME' | 'MX' | 'NS' | 'TXT'

export type IpFamily = 'IPv4' | 'IPv6' | 'All'

export interface DnsRecord {
  type: DnsRecordType
  value: string
  ttl: number
}

export interface DnsResult {
  domain: string
  records: DnsRecord[]
  queryTime: number
  server: string
  status: 'success' | 'error'
  errorMessage: string
}

export interface DnsLookupConfig {
  domain: string
  dnsServer: string
  timeout: number
  family?: IpFamily
}

export interface DnsServerPreset {
  name: string
  address: string
  color: string
  apiUrl: string
}

export interface DnsHistoryEntry {
  domain: string
  server: string
  timestamp: number
  recordCount: number
  queryTime: number
}

// ==================== Traceroute 模型 ====================

export interface TracerouteHop {
  hopIndex: number
  address: string
  latency: number
  allRtt: number[]
  status: 'success' | 'timeout' | 'error'
  hostname: string
}

export interface TracerouteConfig {
  targetHost: string
  maxHops: number
  timeout: number
  probesPerHop: number
  intervalMs: number
}

export interface TracerouteStats {
  totalHops: number
  successHops: number
  failedHops: number
  avgLatency: number
  maxLatency: number
  minLatency: number
  totalLatency: number
}

export interface TracerouteCallbacks {
  onHopUpdate?: (hops: TracerouteHop[]) => void
  onComplete?: (hops: TracerouteHop[]) => void
  onError?: (message: string) => void
}

export interface DnsResolveResult {
  address: string
  hostname: string
}

// ==================== 端口扫描模型 ====================

export interface PortScanResult {
  port: number
  status: 'open' | 'closed' | 'filtered' | 'error'
  service: string
  latency: number
}

export interface PortScanCallbacks {
  onProgress: (scanned: number, total: number, currentPort: number) => void
  onPortFound: (port: PortScanResult) => void
  onComplete: (results: PortScanResult[]) => void
  onError: (message: string) => void
}

export interface PortPreset {
  name: string
  description: string
  ports: number[]
}

// ==================== 子网计算模型 ====================

export interface SubnetResult {
  networkAddress: string
  broadcastAddress: string
  subnetMask: string
  wildcardMask: string
  firstHost: string
  lastHost: string
  totalHosts: number
  prefixLength: number
  ipClass: string
  isPrivate: boolean
  binaryMask: string
  ipType: string
}

export interface IpAddressInfo {
  isValid: boolean
  address: string
  prefixLength: number
  errorMessage: string
}

export interface SubnetPreset {
  prefix: number
  mask: string
  hosts: number
  label: string
}

// ==================== IP 归属查询模型 ====================

export interface IpGeoResult {
  ip: string
  country: string
  province: string
  city: string
  isp: string
  district: string
  latitude: number
  longitude: number
  timezone: string
  queryTime: number
  status: 'success' | 'error'
  errorMessage: string
}

// ==================== PoE 计算模型 ====================

export interface PoeStandard {
  name: string
  type: string
  powerAtPse: number
  powerAtPd: number
  voltage: number
  current: number
  pairs: string
  pins: string
  description: string
}

export interface PoeCalcConfig {
  cableLength: number
  cableGauge: number
  standardIndex: number
  devicePower: number
}

export interface PoeResult {
  standard: PoeStandard
  cableLoss: number
  cableLossPercent: number
  powerDelivered: number
  remainingBudget: number
  isSufficient: boolean
  maxCableLength: number
  efficiency: number
  voltageDrop: number
  currentFlow: number
  powerAtPse: number
}

export interface CableSpec {
  gauge: number
  resistance: number
  maxCurrent: number
  diameter: number
  label: string
}

export interface DevicePreset {
  name: string
  power: number
  icon: string
}

// ==================== MAC 查询模型 ====================

export interface MacResult {
  mac: string
  vendor: string
  country: string
  address: string
  prefix: string
  type: string
  status: 'success' | 'not_found' | 'error'
  errorMessage: string
  queryTime: number
  source: string
}

// ==================== WOL 模型 ====================

export interface WolDevice {
  name: string
  mac: string
  ip: string
  port: number
  lastWakeTime: number
}

export interface WolResult {
  success: boolean
  message: string
  deviceName: string
  mac: string
  timestamp: number
}

export interface WolCallbacks {
  onSuccess: (result: WolResult) => void
  onError: (message: string) => void
}

// ==================== 局域网扫描模型 ====================

export interface LanDevice {
  ip: string
  mac: string
  hostname: string
  status: 'online' | 'offline' | 'scanning'
  vendor: string
  port: number
  latency: number
  firstSeen: number
  lastSeen: number
  probeMethod: string
}

export interface LanScanCallbacks {
  onProgress: (scanned: number, total: number, currentIp: string) => void
  onDeviceFound: (device: LanDevice) => void
  onComplete: (devices: LanDevice[]) => void
  onError: (message: string) => void
}

export interface LanNetworkInfo {
  localIp: string
  gateway: string
  subnetMask: string
  networkPrefix: string
  hostCount: number
}

// ==================== 漫游测试模型 ====================

export interface RoamEvent {
  timestamp: number
  fromBssid: string
  toBssid: string
  rssiBefore: number
  rssiAfter: number
  duration: number
}

export interface RoamTestConfig {
  intervalMs: number
  durationSec: number
  targetBssid: string
}

export interface RoamTestCallbacks {
  onUpdate: (info: RoamTestInfo) => void
  onRoamDetected: (event: RoamEvent) => void
  onComplete: (summary: RoamTestSummary) => void
  onError: (message: string) => void
}

export interface RoamTestInfo {
  isRunning: boolean
  currentBssid: string
  currentRssi: number
  elapsedSec: number
  totalSec: number
  roamCount: number
  avgRssi: number
  bssidHistory: BssidRecord[]
}

export interface BssidRecord {
  bssid: string
  rssi: number
  timestamp: number
}

export interface RoamTestSummary {
  totalDuration: number
  roamCount: number
  roamEvents: RoamEvent[]
  avgRssi: number
  minRssi: number
  maxRssi: number
  bssidCount: number
  stabilityScore: number
}

export interface WifiInfo {
  bssid: string
  rssi: number
  ssid: string
}
