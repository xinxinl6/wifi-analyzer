// ============================================
// 简单事件总线实现
// 用于组件间通信，替代 @kit.BasicOpsKit emitter
// ============================================

type EventCallback = (...args: Object[]) => void

class EventBusClass {
  private listeners: Map<number, EventCallback[]> = new Map()

  /**
   * 订阅事件
   * @param eventId 事件 ID
   * @param callback 回调函数
   * @returns 取消订阅函数
   */
  on(eventId: number, callback: EventCallback): () => void {
    const callbacks = this.listeners.get(eventId) || []
    callbacks.push(callback)
    this.listeners.set(eventId, callbacks)

    // 返回取消订阅函数
    return () => {
      const cbs = this.listeners.get(eventId) || []
      const index = cbs.indexOf(callback)
      if (index > -1) {
        cbs.splice(index, 1)
      }
    }
  }

  /**
   * 发布事件
   * @param eventId 事件 ID
   * @param args 传递给回调的参数
   */
  emit(eventId: number, ...args: Object[]): void {
    const callbacks = this.listeners.get(eventId) || []
    callbacks.forEach(callback => {
      try {
        callback(...args)
      } catch (e) {
        console.error(`[EventBus] Error in callback for event ${eventId}:`, e)
      }
    })
  }

  /**
   * 取消订阅所有事件
   */
  off(eventId?: number): void {
    if (eventId !== undefined) {
      this.listeners.delete(eventId)
    } else {
      this.listeners.clear()
    }
  }
}

// 单例导出
export const EventBus = new EventBusClass()
