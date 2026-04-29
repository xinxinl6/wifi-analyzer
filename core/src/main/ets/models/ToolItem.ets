// 工具项目数据模型

export interface ToolItem {
  name: Resource | string
  desc: Resource | string
  icon: Resource
  color: string
  action?: string  // 点击动作：'ping' 等，空字符串表示未实现
}
