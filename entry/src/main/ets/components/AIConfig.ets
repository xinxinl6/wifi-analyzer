// ============================================
// Aurora WiFi V2 — AI 模块配置
// API Level: 23+
// ============================================

// ============================================
// AI 消息数据结构
// ============================================

export interface AIMessage {
  id: string
  role: 'user' | 'assistant'
  content: string | Resource
  timestamp: number
  type?: 'text' | 'analysis' | 'suggestion' | 'warning'
}

// ============================================
// AI 功能配置
// ============================================

export interface AIFeatureItem {
  enabled: boolean
  title: ResourceStr
  icon: Resource
  description: ResourceStr
}

export interface AIFeatureMap {
  networkHealth: AIFeatureItem
  channelRecommend: AIFeatureItem
  anomalyAlert: AIFeatureItem
  optimizationTip: AIFeatureItem
}

export const AIFeatures: AIFeatureMap = {
  // 网络健康诊断
  networkHealth: {
    enabled: true,
    title: 'ai_feature_network_health',
    icon: $r('app.media.ic_health'),
    description: 'ai_feature_network_health_desc'
  },
  // 智能信道推荐
  channelRecommend: {
    enabled: true,
    title: 'ai_feature_channel_recommend',
    icon: $r('app.media.ic_channel'),
    description: 'ai_feature_channel_recommend_desc'
  },
  // 异常预警
  anomalyAlert: {
    enabled: true,
    title: 'ai_feature_anomaly_alert',
    icon: $r('app.media.ic_warning'),
    description: 'ai_feature_anomaly_alert_desc'
  },
  // 优化建议
  optimizationTip: {
    enabled: true,
    title: 'ai_feature_optimization_tip',
    icon: $r('app.media.ic_tip'),
    description: 'ai_feature_optimization_tip_desc'
  }
}

// ============================================
// AI 响应消息接口
// ============================================

interface AIMessageResponses {
  signal: string
  channel: string
  speed: string
  defaultMsg: string
}

// AI消息集合接口
interface AIMessagesMap {
  launchFailed: string
  welcome: string
  panelTitle: string
  onlineStatus: string
  placeholder: string
  responses: AIMessageResponses
}

// ============================================
// AI 消息配置（便于国际化）
// ============================================
export const AIMessages: AIMessagesMap = {
  // FAB 按钮失败消息
  launchFailed: 'ai_launch_failed',

  // 欢迎消息
  welcome: 'ai_welcome_message',

  // 面板标题
  panelTitle: 'ai_panel_title',

  // 在线状态
  onlineStatus: 'ai_online_status',

  // 输入占位符
  placeholder: 'ai_placeholder',

  // AI 响应消息
  responses: {
    signal: 'ai_response_signal',
    channel: 'ai_response_channel',
    speed: 'ai_response_speed',
    defaultMsg: 'ai_response_default'
  }
}

// ============================================
// 导出类型定义
// ============================================

export interface AuroraAIModuleExport {
  AIFabButton: object
  AIPanel: object
  AIAnalysisCard: object
  features: AIFeatureMap
  messages: AIMessagesMap
}
