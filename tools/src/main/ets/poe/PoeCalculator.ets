// POE (Power over Ethernet) 计算引擎 V2
// 计算 PoE 供电功率、线缆损耗、供电预算
// 优化：使用 IEEE 标准定义，基于 PD 端实际可用功率计算

// PoE 标准接口
export interface PoeStandard {
  name: string
  type: string           // Type 1/2/3/4
  powerAtPse: number     // PSE端输出功率 (W)
  powerAtPd: number      // PD端可用功率 (W) - IEEE 标准定义
  voltage: number        // 供电电压 (V)
  current: number        // 最大线对电流 (A)
  pairs: string          // 供电线对
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
  cableLossPercent: number   // 线缆损耗百分比（相对于 PSE 输出）
  powerDelivered: number     // 实际送达功率 (W)
  remainingBudget: number    // 剩余预算 (W)
  isSufficient: boolean      // 是否满足需求
  maxCableLength: number     // 最大推荐长度 (米)
  efficiency: number         // 供电效率 (%) - 基于 PD 端
  voltageDrop: number        // 电压降 (V)
  currentFlow: number        // 工作电流 (A)
  powerAtPse: number        // PSE 端实际输出 (W)
}

// 线缆规格数据（基于 TIA-568-C.2 标准，100米长度下的电阻）
export interface CableSpec {
  gauge: number        // AWG 线规
  resistance: number   // 每公里电阻 (Ohm/km) - 导体电阻
  maxCurrent: number    // 最大持续电流 (A) - 单根导线
  diameter: number     // 导线直径 (mm)
  label: string        // 显示名称
}

// 设备类型预设
export interface DevicePreset {
  name: string
  power: number    // 功率 (W)
  icon: string
}

export class PoeCalculator {
  // PoE 标准（基于 IEEE 802.3af/at/bt）
  static readonly STANDARDS: PoeStandard[] = [
    {
      name: '802.3af (PoE)',
      type: 'Type 1',
      powerAtPse: 15.4,
      powerAtPd: 12.95,
      voltage: 48,
      current: 0.35,
      pairs: '2对',
      pins: '1,2/3,6',
      description: '基础PoE，适用于IP电话、无线AP',
    },
    {
      name: '802.3at (PoE+)',
      type: 'Type 2',
      powerAtPse: 30,
      powerAtPd: 25.5,
      voltage: 50,
      current: 0.6,
      pairs: '2对',
      pins: '1,2/3,6',
      description: '增强PoE，适用于PTZ摄像头、视频电话',
    },
    {
      name: '802.3bt (PoE++)',
      type: 'Type 3',
      powerAtPse: 60,
      powerAtPd: 51,
      voltage: 50,
      current: 0.6,
      pairs: '4对',
      pins: '全4对线',
      description: '高功率PoE，适用于LED照明、楼宇对讲',
    },
    {
      name: '802.3bt (4PPoE)',
      type: 'Type 4',
      powerAtPse: 90,
      powerAtPd: 71.3,
      voltage: 55,
      current: 0.96,
      pairs: '4对',
      pins: '全4对线',
      description: '超高功率PoE，适用于瘦终端、显示器',
    },
  ]

  // 常用线缆规格（基于 CAT5e/CAT6 标准）
  static readonly CABLE_SPECS: CableSpec[] = [
    { gauge: 22, resistance: 16.14, maxCurrent: 0.82, diameter: 0.643, label: 'AWG22 (0.64mm)' },
    { gauge: 23, resistance: 20.36, maxCurrent: 0.68, diameter: 0.574, label: 'AWG23 (0.57mm)' },
    { gauge: 24, resistance: 25.67, maxCurrent: 0.577, diameter: 0.511, label: 'AWG24 (0.51mm)' },
    { gauge: 25, resistance: 32.37, maxCurrent: 0.481, diameter: 0.455, label: 'AWG25 (0.45mm)' },
    { gauge: 26, resistance: 40.81, maxCurrent: 0.401, diameter: 0.405, label: 'AWG26 (0.40mm)' },
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
   * 计算 PoE 功率（V2 优化版本）
   *
   * 计算逻辑：
   * 1. 基于 PSE 输出功率计算工作电流：I = P_pse / V
   * 2. 线缆来回回路电阻：R = (Ohm/km * L * 2) / 1000
   * 3. 电压降：V_drop = I * R
   * 4. 线缆损耗：P_loss = I² * R
   * 5. 实际送达功率：P_delivered = P_pse - P_loss
   * 6. 供电效率：Efficiency = P_delivered / P_pse * 100%
   */
  static calculate(config: PoeCalcConfig): PoeCalcResult {
    const standard: PoeStandard = PoeCalculator.STANDARDS[config.standardIndex]

    // 获取线缆规格
    const cableSpec: CableSpec | undefined = PoeCalculator.CABLE_SPECS.find(
      (spec: CableSpec): boolean => spec.gauge === config.cableGauge
    )
    const resistancePerKm: number = cableSpec ? cableSpec.resistance : 25.67

    // ========== 核心计算 ==========

    // 工作电流（基于 PSE 输出功率）
    // 对于 4 对线 PoE，电流在每对线上分配
    const isFourPair: boolean = standard.pairs === '4对'
    const currentPerPair: number = standard.powerAtPse / standard.voltage

    // 电流系数：4对线时每对承担一半电流
    const currentFactor: number = isFourPair ? 2 : 1
    const currentFlow: number = currentPerPair / currentFactor

    // 线缆电阻（来回回路）
    // R = Ohm/km * 长度(km) * 2(来回)
    const cableResistance: number = (resistancePerKm * config.cableLength * 2) / 1000

    // 电压降
    // V_drop = I * R
    const voltageDrop: number = Math.round(currentFlow * cableResistance * 1000) / 1000

    // 线缆损耗（功率）
    // P_loss = I² * R
    const cableLoss: number = Math.round(currentFlow * currentFlow * cableResistance * 1000) / 1000

    // PSE 端实际输出功率（考虑线缆损耗后）
    const powerAtPse: number = Math.round((standard.powerAtPse - cableLoss) * 1000) / 1000

    // 实际送达功率
    const powerDelivered: number = Math.max(0, powerAtPse)

    // 损耗百分比（相对于 PSE 标称输出）
    const cableLossPercent: number = standard.powerAtPse > 0
      ? Math.round((cableLoss / standard.powerAtPse) * 10000) / 100
      : 0

    // 供电效率 = 实际送达功率 / PSE 标称输出
    const efficiency: number = standard.powerAtPse > 0
      ? Math.round((powerDelivered / standard.powerAtPse) * 10000) / 100
      : 0

    // 剩余预算 = 送达功率 - 设备需求
    const remainingBudget: number = Math.round(Math.max(0, powerDelivered - config.devicePower) * 100) / 100

    // 是否满足设备需求
    const isSufficient: boolean = powerDelivered >= config.devicePower

    // 最大推荐长度（基于设备需求功率计算）
    const maxCableLength: number = PoeCalculator.calcMaxCableLength(
      standard,
      config.cableGauge,
      config.devicePower
    )

    const result: PoeCalcResult = {
      standard: standard,
      cableLoss: cableLoss,
      cableLossPercent: cableLossPercent,
      powerDelivered: powerDelivered,
      remainingBudget: remainingBudget,
      isSufficient: isSufficient,
      maxCableLength: maxCableLength,
      efficiency: efficiency,
      voltageDrop: voltageDrop,
      currentFlow: Math.round(currentFlow * 1000) / 1000,
      powerAtPse: powerAtPse,
    }
    return result
  }

  /**
   * 计算最大推荐线缆长度
   *
   * 基于设备需求功率，计算在满足该功率的情况下，
   * 线缆最大允许长度
   *
   * 推导：
   * - 设备需求功率 P_device
   * - PSE 标称输出 P_pse
   * - 允许损耗 P_loss = P_pse - P_device
   * - 工作电流 I = P_pse / V
   * - 线缆电阻 R = P_loss / I²
   * - 最大长度 L = R * 1000 / (Ohm/km * 2)
   */
  private static calcMaxCableLength(standard: PoeStandard, gauge: number, requiredPower: number): number {
    const cableSpec: CableSpec | undefined = PoeCalculator.CABLE_SPECS.find(
      (spec: CableSpec): boolean => spec.gauge === gauge
    )
    if (!cableSpec) return 100

    const resistancePerKm: number = cableSpec.resistance
    const isFourPair: boolean = standard.pairs === '4对'

    // 工作电流
    const currentPerPair: number = standard.powerAtPse / standard.voltage
    const currentFactor: number = isFourPair ? 2 : 1
    const currentFlow: number = currentPerPair / currentFactor

    // 允许的功率损耗
    const allowedLoss: number = standard.powerAtPse - requiredPower

    if (allowedLoss <= 0) return 0
    if (currentFlow <= 0) return 9999

    // 线缆电阻 R = P_loss / I²
    const cableResistance: number = allowedLoss / (currentFlow * currentFlow)

    // 最大长度 L = R * 1000 / (Ohm/km * 2)
    const maxLen: number = (cableResistance * 1000) / (resistancePerKm * 2)

    return Math.round(maxLen)
  }

  /**
   * 计算电压降百分比
   * 用于判断电压降是否在可接受范围内
   */
  static calcVoltageDropPercent(voltageDrop: number, nominalVoltage: number): number {
    return Math.round((voltageDrop / nominalVoltage) * 10000) / 100
  }

  /**
   * 判断线缆长度是否在推荐范围内
   */
  static isCableLengthAcceptable(cableLength: number, maxLength: number): boolean {
    return cableLength <= maxLength
  }

  /**
   * 获取线缆状态描述
   */
  static getCableStatus(cableLength: number, maxLength: number, efficiency: number): string {
    const lengthRatio: number = cableLength / maxLength
    if (lengthRatio > 1) return 'exceeded'
    if (lengthRatio > 0.8) return 'warning'
    if (efficiency < 80) return 'low_efficiency'
    return 'good'
  }
}
