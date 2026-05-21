// ============================================
// Device Utils - 设备相关工具函数
// ============================================

import { deviceInfo } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

// 日志 domain
const DOMAIN = 0x0000

/**
 * 检测当前是否运行在模拟器上
 * 判断依据：设备品牌、设备类型、设备型号等特征值
 * 注意：deviceInfo 是命名空间，只能访问已声明的静态属性
 */
export function isEmulatorDevice(): boolean {
  try {
    const brand: string = deviceInfo.brand || ''
    const deviceType: string = deviceInfo.deviceType || ''
    const model: string = deviceInfo.productModel || ''

    // 品牌特征：空/unknown/Emulator 通常为模拟器
    if (brand === '' || brand === 'unknown' || brand === 'Emulator') {
      return true
    }
    // 设备类型特征：default/phone 等通用类型可能是模拟器
    if (deviceType === 'default' || deviceType === 'Emulator') {
      return true
    }
    // 型号特征：含模拟器/SDK 关键字
    const lowerModel: string = model.toLowerCase()
    if (lowerModel.indexOf('emulator') >= 0 || lowerModel.indexOf('sdk') >= 0 ||
        lowerModel.indexOf('simulator') >= 0 || lowerModel.indexOf('virtual') >= 0) {
      return true
    }
    return false
  } catch (e) {
    hilog.warn(DOMAIN, 'testTag', '%{public}s', '[DeviceUtils] Failed to detect device type, assuming real device')
    return false
  }
}
