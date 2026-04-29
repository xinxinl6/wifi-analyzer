// POE (Power over Ethernet) 计算引擎
// 计算 PoE 供电功率、线缆损耗、供电预算

// PoE 标准接口
export interface PoeStandard {
  name: string
  type: string           // Type 1/2/3/4
  powerAtPse: number     // PSE端输出功率 (W)
  powerAtPd: number      // PD端可用功率 (W)
  voltage: number        // 供电电压 (V)
  current: number        // 最大电流 (A)
  pins: string           // 供电线脚
  description: string    // 描述
}

// 计算配置
export interface PoeCalcConfig {
  cableLength: number      // 线缆长度 (米)
  cableGauge: number       // 线规 (AWG)
  standardIndex: number    // PoE标准索引
  devicePower: number      // 设备功率需求 (W)
}

// 计算结果
export interface PoeCalcResult {
  standard: PoeStandard
  cableLoss: number          // 线缆损耗 (W)
  cableLossPercent: number   // 线缆损耗百分比
  powerDelivered: number     // 实际送达功率 (W)
  remainingBudget: number    // 剩余预算 (W)
  isSufficient: boolean      // 是否满足需求
  maxCableLength: number     // 最大推荐长度 (米)
  efficiency: number         // 供电效率 (%)
}

// 线缆规格数据
export interface CableSpec {
  gauge: number        // AWG
  resistance: number   // 每公里电阻 (Ohm/km)
  label: string        // 显示名称
}

// 设备类型预设
export interface DevicePreset {
  name: string
  power: number    // 功率 (W)
  icon: string
}

export class PoeCalculator {
  // PoE 标准
  static readonly STANDARDS: PoeStandard[] = [
    {
      name: '802.3af (PoE)',
      type: 'Type 1',
      powerAtPse: 15.4,
      powerAtPd: 12.95,
      voltage: 48,
      current: 0.35,
      pins: '2对 (1,2/3,6)',
      description: '基础PoE，适用于IP电话、无线AP',
    },
    {
      name: '802.3at (PoE+)',
      type: 'Type 2',
      powerAtPse: 30,
      powerAtPd: 25.5,
      voltage: 50,
      current: 0.6,
      pins: '2对 (1,2/3,6)',
      description: '增强PoE，适用于PTZ摄像头、视频电话',
    },
    {
      name: '802.3bt (PoE++)',
      type: 'Type 3',
      powerAtPse: 60,
      powerAtPd: 51,
      voltage: 50,
      current: 0.6,
      pins: '4对 (全4对线)',
      description: '高功率PoE，适用于LED照明、楼宇对讲',
    },
    {
      name: '802.3bt (4PPoE)',
      type: 'Type 4',
      powerAtPse: 90,
      powerAtPd: 71.3,
      voltage: 55,
      current: 0.96,
      pins: '4对 (全4对线)',
      description: '超高功率PoE，适用于瘦终端、显示器',
    },
  ]

  // 常用线缆规格
  static readonly CABLE_SPECS: CableSpec[] = [
    { gauge: 22, resistance: 16.14, label: 'AWG22 (0.64mm)' },
    { gauge: 23, resistance: 20.36, label: 'AWG23 (0.57mm)' },
    { gauge: 24, resistance: 25.67, label: 'AWG24 (0.51mm)' },
    { gauge: 25, resistance: 32.37, label: 'AWG25 (0.45mm)' },
    { gauge: 26, resistance: 40.81, label: 'AWG26 (0.40mm)' },
  ]

  // 常见设备功率预设
  static readonly DEVICE_PRESETS: DevicePreset[] = [
    { name: 'IP电话', power: 3, icon: '📞' },
    { name: '无线AP', power: 12, icon: '📡' },
    { name: '固定摄像头', power: 5, icon: '📷' },
    { name: 'PTZ摄像头', power: 20, icon: '🎥' },
    { name: '门禁控制器', power: 5, icon: '🔐' },
    { name: 'LED照明', power: 45, icon: '💡' },
    { name: '信息显示牌', power: 60, icon: '🖥' },
  ]

  /**
   * 获取默认配置
   */
  static getDefaultConfig(): PoeCalcConfig {
    const config: PoeCalcConfig = {
      cableLength: 100,
      cableGauge: 24,
      standardIndex: 1,
      devicePower: 12.95,
    }
    return config
  }

  /**
   * 计算 PoE 功率
   */
  static calculate(config: PoeCalcConfig): PoeCalcResult {
    const standard: PoeStandard = PoeCalculator.STANDARDS[config.standardIndex]

    // 获取线缆电阻
    const cableSpec: CableSpec | undefined = PoeCalculator.CABLE_SPECS.find(
      (spec: CableSpec): boolean => spec.gauge === config.cableGauge
    )
    const resistance: number = cableSpec ? cableSpec.resistance : 25.67

    // 计算线缆电阻（双向回路）
    const cableResistance: number = (resistance / 1000) * config.cableLength * 2

    // 计算电流 I = P / V
    const current: number = standard.powerAtPse / standard.voltage

    // 线缆损耗 P_loss = I^2 * R
    const cableLoss: number = Math.round(current * current * cableResistance * 1000) / 1000

    // 实际送达功率
    const powerDelivered: number = Math.round((standard.powerAtPse - cableLoss) * 100) / 100

    // 损耗百分比
    const cableLossPercent: number = standard.powerAtPse > 0
      ? Math.round((cableLoss / standard.powerAtPse) * 10000) / 100
      : 0

    // 剩余预算
    const remainingBudget: number = Math.round(Math.max(0, powerDelivered - config.devicePower) * 100) / 100

    // 是否满足
    const isSufficient: boolean = powerDelivered >= config.devicePower

    // 最大推荐长度（送达功率降到设备需求时的长度）
    const maxCableLength: number = PoeCalculator.calcMaxCableLength(standard, config.cableGauge, config.devicePower)

    // 供电效率
    const efficiency: number = standard.powerAtPse > 0
      ? Math.round((powerDelivered / standard.powerAtPse) * 10000) / 100
      : 0

    const result: PoeCalcResult = {
      standard: standard,
      cableLoss: cableLoss,
      cableLossPercent: cableLossPercent,
      powerDelivered: Math.max(0, powerDelivered),
      remainingBudget: remainingBudget,
      isSufficient: isSufficient,
      maxCableLength: maxCableLength,
      efficiency: efficiency,
    }
    return result
  }

  /**
   * 计算最大推荐线缆长度
   */
  private static calcMaxCableLength(standard: PoeStandard, gauge: number, requiredPower: number): number {
    const cableSpec: CableSpec | undefined = PoeCalculator.CABLE_SPECS.find(
      (spec: CableSpec): boolean => spec.gauge === gauge
    )
    if (!cableSpec) return 100

    const resistancePerKm: number = cableSpec.resistance
    const current: number = standard.powerAtPse / standard.voltage
    const allowedLoss: number = standard.powerAtPse - requiredPower

    if (allowedLoss <= 0) return 0
    if (current <= 0) return 9999

    // P_loss = I^2 * R * L * 2 / 1000
    // L = P_loss * 1000 / (I^2 * R * 2)
    const maxLen: number = (allowedLoss * 1000) / (current * current * resistancePerKm * 2)
    return Math.round(maxLen)
  }
}
