// 子网换算引擎
// IP子网计算：CIDR表示法转换、子网掩码计算、地址范围计算

// 子网计算结果
export interface SubnetResult {
  networkAddress: string    // 网络地址
  broadcastAddress: string  // 广播地址
  subnetMask: string        // 子网掩码
  wildcardMask: string      // 反向掩码
  firstHost: string         // 起始主机地址
  lastHost: string          // 结束主机地址
  totalHosts: number        // 可用主机数
  prefixLength: number      // 前缀长度
  ipClass: string           // IP类别 (A/B/C)
  isPrivate: boolean        // 是否私有地址
  binaryMask: string        // 子网掩码二进制
  ipType: string            // IP类型描述
}

// IP 地址信息（用于输入验证）
export interface IpAddressInfo {
  isValid: boolean
  address: string
  prefixLength: number
  errorMessage: string
}

export class SubnetCalculator {
  // 常用子网掩码预设
  static readonly SUBNET_PRESETS: SubnetPreset[] = [
    { prefix: 8, mask: '255.0.0.0', hosts: 16777214, label: '/8' },
    { prefix: 16, mask: '255.255.0.0', hosts: 65534, label: '/16' },
    { prefix: 24, mask: '255.255.255.0', hosts: 254, label: '/24' },
    { prefix: 25, mask: '255.255.255.128', hosts: 126, label: '/25' },
    { prefix: 26, mask: '255.255.255.192', hosts: 62, label: '/26' },
    { prefix: 27, mask: '255.255.255.224', hosts: 30, label: '/27' },
    { prefix: 28, mask: '255.255.255.240', hosts: 14, label: '/28' },
    { prefix: 29, mask: '255.255.255.248', hosts: 6, label: '/29' },
    { prefix: 30, mask: '255.255.255.252', hosts: 2, label: '/30' },
    { prefix: 32, mask: '255.255.255.255', hosts: 1, label: '/32' },
  ]

  /**
   * 验证并解析 IP 地址
   */
  static parseInput(input: string): IpAddressInfo {
    const trimmed: string = input.trim()
    let address: string = trimmed
    let prefixLength: number = 24 // 默认

    // 处理 CIDR 格式
    if (trimmed.indexOf('/') >= 0) {
      const parts: string[] = trimmed.split('/')
      address = parts[0].trim()
      const prefixStr: string = parts[1].trim()
      const prefix: number = parseInt(prefixStr, 10)
      if (isNaN(prefix) || prefix < 0 || prefix > 32) {
        return { isValid: false, address: address, prefixLength: prefix, errorMessage: '前缀长度必须在 0-32 之间' }
      }
      prefixLength = prefix
    }

    // 验证 IP 格式
    const octets: string[] = address.split('.')
    if (octets.length !== 4) {
      return { isValid: false, address: address, prefixLength: prefixLength, errorMessage: 'IP 地址格式不正确' }
    }

    for (let i = 0; i < 4; i++) {
      const num: number = parseInt(octets[i], 10)
      if (isNaN(num) || num < 0 || num > 255 || octets[i] !== String(num)) {
        return { isValid: false, address: address, prefixLength: prefixLength, errorMessage: 'IP 地址每段必须在 0-255 之间' }
      }
    }

    return { isValid: true, address: address, prefixLength: prefixLength, errorMessage: '' }
  }

  /**
   * 计算子网信息
   */
  static calculate(address: string, prefixLength: number): SubnetResult {
    const ipNum: number = SubnetCalculator.ipToNumber(address)
    const maskNum: number = SubnetCalculator.prefixToMask(prefixLength)
    const wildcardNum: number = maskNum ^ 0xFFFFFFFF

    const networkNum: number = ipNum & maskNum
    const broadcastNum: number = networkNum | wildcardNum

    const totalHosts: number = Math.pow(2, 32 - prefixLength) - 2

    const result: SubnetResult = {
      networkAddress: SubnetCalculator.numberToIp(networkNum),
      broadcastAddress: SubnetCalculator.numberToIp(broadcastNum),
      subnetMask: SubnetCalculator.numberToIp(maskNum),
      wildcardMask: SubnetCalculator.numberToIp(wildcardNum),
      firstHost: SubnetCalculator.numberToIp(networkNum + 1),
      lastHost: SubnetCalculator.numberToIp(broadcastNum - 1),
      totalHosts: Math.max(0, totalHosts),
      prefixLength: prefixLength,
      ipClass: SubnetCalculator.getIpClass(ipNum),
      isPrivate: SubnetCalculator.isPrivateIp(ipNum),
      binaryMask: SubnetCalculator.numberToBinary(maskNum),
      ipType: SubnetCalculator.getIpType(ipNum),
    }

    return result
  }

  /**
   * IP 转数字
   */
  static ipToNumber(ip: string): number {
    const octets: string[] = ip.split('.')
    return ((parseInt(octets[0], 10) << 24) | (parseInt(octets[1], 10) << 16) |
      (parseInt(octets[2], 10) << 8) | parseInt(octets[3], 10)) >>> 0
  }

  /**
   * 数字转 IP
   */
  static numberToIp(num: number): string {
    return String((num >>> 24) & 0xFF) + '.' +
      String((num >>> 16) & 0xFF) + '.' +
      String((num >>> 8) & 0xFF) + '.' +
      String(num & 0xFF)
  }

  /**
   * 前缀长度转子网掩码
   */
  static prefixToMask(prefix: number): number {
    if (prefix === 0) return 0
    return (0xFFFFFFFF << (32 - prefix)) >>> 0
  }

  /**
   * 数字转二进制表示
   */
  static numberToBinary(num: number): string {
    const binary: string = num.toString(2).padStart(32, '0')
    return binary.substring(0, 8) + '.' +
      binary.substring(8, 16) + '.' +
      binary.substring(16, 24) + '.' +
      binary.substring(24, 32)
  }

  /**
   * 获取 IP 类别
   */
  static getIpClass(ipNum: number): string {
    const firstOctet: number = (ipNum >>> 24) & 0xFF
    if (firstOctet >= 1 && firstOctet <= 126) return 'A'
    if (firstOctet >= 128 && firstOctet <= 191) return 'B'
    if (firstOctet >= 192 && firstOctet <= 223) return 'C'
    if (firstOctet >= 224 && firstOctet <= 239) return 'D (组播)'
    return 'E (保留)'
  }

  /**
   * 判断是否私有 IP
   */
  static isPrivateIp(ipNum: number): boolean {
    const first: number = (ipNum >>> 24) & 0xFF
    const second: number = (ipNum >>> 16) & 0xFF

    // 10.0.0.0/8
    if (first === 10) return true
    // 172.16.0.0/12
    if (first === 172 && second >= 16 && second <= 31) return true
    // 192.168.0.0/16
    if (first === 192 && second === 168) return true
    // 127.0.0.0/8
    if (first === 127) return true

    return false
  }

  /**
   * 获取 IP 类型描述
   */
  static getIpType(ipNum: number): string {
    const first: number = (ipNum >>> 24) & 0xFF
    const second: number = (ipNum >>> 16) & 0xFF

    if (first === 10) return '私有地址 (A类)'
    if (first === 172 && second >= 16 && second <= 31) return '私有地址 (B类)'
    if (first === 192 && second === 168) return '私有地址 (C类)'
    if (first === 127) return '回环地址'
    if (first === 169 && second === 254) return '链路本地地址'
    if (first >= 224 && first <= 239) return '组播地址'
    if (first >= 240) return '保留地址'

    return '公网地址'
  }
}

// 子网预设接口
export interface SubnetPreset {
  prefix: number
  mask: string
  hosts: number
  label: string
}
