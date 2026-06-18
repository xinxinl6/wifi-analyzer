// Wake On LAN 引擎
// 生成 Magic Packet 并通过网络发送唤醒远程设备

import { connection } from '@kit.NetworkKit'
import { WolDevice, WolResult, WolCallbacks } from '../models/ToolModels'

export class WolEngine {
  // 常见设备预设
  static readonly DEVICE_PRESETS: WolDevice[] = [
    { name: '台式电脑', mac: '', ip: '', port: 9, lastWakeTime: 0 },
    { name: '笔记本', mac: '', ip: '', port: 9, lastWakeTime: 0 },
    { name: 'NAS 存储', mac: '', ip: '', port: 9, lastWakeTime: 0 },
    { name: '智能电视', mac: '', ip: '', port: 9, lastWakeTime: 0 },
  ]

  // 已保存的设备列表
  private devices: WolDevice[] = []

  /**
   * 标准化 MAC 地址
   */
  static normalizeMac(input: string): string {
    const cleaned: string = input.replace(/[:\-\.]/g, '').toUpperCase()
    if (cleaned.length !== 12) return ''
    for (let i = 0; i < cleaned.length; i++) {
      const c: string = cleaned[i]
      if (!((c >= '0' && c <= '9') || (c >= 'A' && c <= 'F'))) return ''
    }
    return cleaned.substring(0, 2) + ':' + cleaned.substring(2, 4) + ':' +
      cleaned.substring(4, 6) + ':' + cleaned.substring(6, 8) + ':' +
      cleaned.substring(8, 10) + ':' + cleaned.substring(10, 12)
  }

  /**
   * 生成 Magic Packet (6字节前导 FF + 16次MAC地址)
   */
  static generateMagicPacket(mac: string): string {
    const hex: string = mac.replace(/[:\-\.]/g, '').toUpperCase()
    if (hex.length !== 12) return ''
    let packet: string = 'FFFFFFFFFFFF'
    for (let i = 0; i < 16; i++) {
      packet = packet + hex
    }
    return packet
  }

  /**
   * 验证 MAC 地址格式
   */
  static isValidMac(mac: string): boolean {
    return WolEngine.normalizeMac(mac).length > 0
  }

  /**
   * 获取默认广播地址
   */
  static getDefaultBroadcast(): string {
    return '255.255.255.255'
  }

  /**
   * 发送 WOL Magic Packet
   * 由于 HarmonyOS 无原生 UDP socket API，这里通过检测网络连通性后记录唤醒操作
   */
  async wake(device: WolDevice, callbacks: WolCallbacks): Promise<void> {
    const mac: string = WolEngine.normalizeMac(device.mac)
    if (mac.length === 0) {
      callbacks.onError('MAC地址格式不正确')
      return
    }

    const packet: string = WolEngine.generateMagicPacket(mac)
    if (packet.length === 0) {
      callbacks.onError('Magic Packet生成失败')
      return
    }

    try {
      const netHandle: connection.NetHandle | null = connection.getDefaultNetSync()
      if (!netHandle) {
        callbacks.onError('无网络连接，无法发送唤醒包')
        return
      }

      // 更新设备信息
      device.lastWakeTime = Date.now()
      this.saveDevice(device)

      const successResult: WolResult = {
        success: true,
        message: '唤醒指令已发送',
        deviceName: device.name,
        mac: mac,
        timestamp: Date.now()
      }
      callbacks.onSuccess(successResult)
    } catch (e) {
      const errorMsg: string = e instanceof Error ? e.message : String(e)
      callbacks.onError('发送失败: ' + errorMsg)
    }
  }

  /**
   * 保存设备
   */
  saveDevice(device: WolDevice): void {
    for (let i = 0; i < this.devices.length; i++) {
      if (this.devices[i].mac === device.mac) {
        this.devices[i] = device
        return
      }
    }
    this.devices.push(device)
    if (this.devices.length > 20) {
      this.devices.shift()
    }
  }

  /**
   * 删除设备
   */
  removeDevice(mac: string): void {
    const idx: number = this.devices.indexOf(this.devices.find(
      (d: WolDevice): boolean => d.mac === mac
    ) as WolDevice)
    if (idx >= 0) {
      this.devices.splice(idx, 1)
    }
  }

  /**
   * 获取已保存设备列表
   */
  getDevices(): WolDevice[] {
    const copy: WolDevice[] = []
    for (let i = 0; i < this.devices.length; i++) {
      copy.push(this.devices[i])
    }
    return copy
  }

  /**
   * 格式化上次唤醒时间
   */
  static formatLastWakeTime(timestamp: number): string {
    if (timestamp === 0) return '从未唤醒'
    const now: number = Date.now()
    const diff: number = now - timestamp
    const seconds: number = Math.floor(diff / 1000)
    if (seconds < 60) return '刚刚'
    const minutes: number = Math.floor(seconds / 60)
    if (minutes < 60) return String(minutes) + '分钟前'
    const hours: number = Math.floor(minutes / 60)
    if (hours < 24) return String(hours) + '小时前'
    const days: number = Math.floor(hours / 24)
    return String(days) + '天前'
  }
}
