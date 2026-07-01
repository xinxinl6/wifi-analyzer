// ============================================
// PulseIndicator — 通用脉冲动画状态管理
// 在 PingPage、PortScanPage、TraceroutePage、WolPage 中被重复实现，
// 现提取为公共组件，通过 isActive 控制动画启停。
// 适配 @ComponentV2 / @ObservedV2 架构
// ============================================

/**
 * 脉冲动画管理 — 纯逻辑类，不创建 UI 元素
 *
 * 用法：
 *   1. 在组件中创建 `private pulser: PulseIndicator = new PulseIndicator()`
 *   2. 在 build() 中绑定 opacity：`.opacity(this.pulser.isActive ? this.pulser.opacity : 1.0)`
 *   3. 在开始扫描时调用 `this.pulser.start()`
 *   4. 在停止/销毁时调用 `this.pulser.stop()`
 *   5. 在 aboutToDisappear 中调用 `this.pulser.stop()`
 */
@ObservedV2
export class PulseIndicator {
  /**
   * 当前透明度值（绑定到组件的 opacity 属性）
   */
  @Trace
  public opacity: number = 1.0

  /**
   * 是否正在运行
   */
  @Trace
  public isActive: boolean = false

  private timerId: number = -1

  /**
   * 开始脉冲动画
   * @param intervalMs 脉冲间隔（默认 800ms）
   */
  start(intervalMs: number = 800): void {
    if (this.isActive) {
      return // 防止重复启动
    }
    this.isActive = true
    this.opacity = 1.0
    // eslint-disable-next-line
    this.timerId = setInterval((): void => {
      this.opacity = this.opacity === 1.0 ? 0.3 : 1.0
    }, intervalMs) as number
  }

  /**
   * 停止脉冲动画，重置透明度为 1.0
   */
  stop(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
    this.isActive = false
    this.opacity = 1.0
  }
}
