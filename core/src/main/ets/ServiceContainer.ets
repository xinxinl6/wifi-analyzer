// ServiceContainer - 统一依赖注入容器
// 统一管理所有单例服务，支持测试替换

import { WifiScanner } from './wifi/WifiScanner'
import { WifiDataManager } from './wifi/WifiDataManager'
import { PermissionManager } from './permission/PermissionManager'
import { NetworkDiagnostics } from './network/NetworkDiagnostics'

// 服务接口定义
export interface IServiceContainer {
  getWifiScanner(): WifiScanner
  getWifiDataManager(): WifiDataManager
  getPermissionManager(): PermissionManager
  getNetworkDiagnostics(): NetworkDiagnostics
}

// 默认实现
class DefaultServiceContainer implements IServiceContainer {
  private _wifiScanner: WifiScanner | null = null
  private _wifiDataManager: WifiDataManager | null = null
  private _permissionManager: PermissionManager | null = null
  private _networkDiagnostics: NetworkDiagnostics | null = null

  getWifiScanner(): WifiScanner {
    if (!this._wifiScanner) {
      this._wifiScanner = WifiScanner.getInstance()
    }
    return this._wifiScanner
  }

  getWifiDataManager(): WifiDataManager {
    if (!this._wifiDataManager) {
      this._wifiDataManager = WifiDataManager.getInstance()
    }
    return this._wifiDataManager
  }

  getPermissionManager(): PermissionManager {
    if (!this._permissionManager) {
      this._permissionManager = PermissionManager.getInstance()
    }
    return this._permissionManager
  }

  getNetworkDiagnostics(): NetworkDiagnostics {
    if (!this._networkDiagnostics) {
      this._networkDiagnostics = NetworkDiagnostics.getInstance()
    }
    return this._networkDiagnostics
  }
}

// 测试容器（支持替换实现）
class TestServiceContainer implements IServiceContainer {
  private _wifiScanner: WifiScanner | null = null
  private _wifiDataManager: WifiDataManager | null = null
  private _permissionManager: PermissionManager | null = null
  private _networkDiagnostics: NetworkDiagnostics | null = null

  private testWifiScanner: WifiScanner | null = null
  private testWifiDataManager: WifiDataManager | null = null
  private testPermissionManager: PermissionManager | null = null
  private testNetworkDiagnostics: NetworkDiagnostics | null = null

  setWifiScanner(s: WifiScanner): void { this.testWifiScanner = s }
  setWifiDataManager(d: WifiDataManager): void { this.testWifiDataManager = d }
  setPermissionManager(p: PermissionManager): void { this.testPermissionManager = p }
  setNetworkDiagnostics(n: NetworkDiagnostics): void { this.testNetworkDiagnostics = n }

  getWifiScanner(): WifiScanner {
    if (this.testWifiScanner !== null) {
      return this.testWifiScanner
    }
    if (!this._wifiScanner) {
      this._wifiScanner = WifiScanner.getInstance()
    }
    return this._wifiScanner
  }

  getWifiDataManager(): WifiDataManager {
    if (this.testWifiDataManager !== null) {
      return this.testWifiDataManager
    }
    if (!this._wifiDataManager) {
      this._wifiDataManager = WifiDataManager.getInstance()
    }
    return this._wifiDataManager
  }

  getPermissionManager(): PermissionManager {
    if (this.testPermissionManager !== null) {
      return this.testPermissionManager
    }
    if (!this._permissionManager) {
      this._permissionManager = PermissionManager.getInstance()
    }
    return this._permissionManager
  }

  getNetworkDiagnostics(): NetworkDiagnostics {
    if (this.testNetworkDiagnostics !== null) {
      return this.testNetworkDiagnostics
    }
    if (!this._networkDiagnostics) {
      this._networkDiagnostics = NetworkDiagnostics.getInstance()
    }
    return this._networkDiagnostics
  }
}

// 全局容器实例
let _container: IServiceContainer = new DefaultServiceContainer()
let _isTestMode: boolean = false

export class ServiceContainer {
  // 获取当前容器
  static getInstance(): IServiceContainer {
    return _container
  }

  // 设置测试容器（测试时使用）
  static setTestContainer(container: IServiceContainer): void {
    _container = container
    _isTestMode = true
  }

  // 重置为默认容器
  static reset(): void {
    _container = new DefaultServiceContainer()
    _isTestMode = false
  }

  // 便捷方法：获取具体服务
  static getWifiScanner(): WifiScanner {
    return _container.getWifiScanner()
  }

  static getWifiDataManager(): WifiDataManager {
    return _container.getWifiDataManager()
  }

  static getPermissionManager(): PermissionManager {
    return _container.getPermissionManager()
  }

  static getNetworkDiagnostics(): NetworkDiagnostics {
    return _container.getNetworkDiagnostics()
  }

  // 检查是否为测试模式
  static isTestMode(): boolean {
    return _isTestMode
  }
}

// 快捷导入
export const container: IServiceContainer = ServiceContainer.getInstance()
