// ============================================
// Aurora WiFi V2 — AI 智能助手模块
// API Level: 23+
// ============================================

// 统一导出所有子组件和配置
export { AuroraAIFabButton } from './AuroraAIFabButton'
export { AuroraAIPanel } from './AuroraAIPanel'
export { AuroraAIAnalysisCard } from './AuroraAIAnalysisCard'
export { AIFeatures, AIMessages } from './AIConfig'
export type {
  AIMessage,
  AIFeatureItem,
  AIFeatureMap,
  AIMessageResponses,
  AIMessagesMap,
  AuroraAIModuleExport
} from './AIConfig'

// ============================================
// 保持向后兼容的导出
// ============================================

import { AuroraAIFabButton } from './AuroraAIFabButton'
import { AuroraAIPanel } from './AuroraAIPanel'
import { AuroraAIAnalysisCard } from './AuroraAIAnalysisCard'
import { AIFeatures, AIMessages, AuroraAIModuleExport } from './AIConfig'

export const AuroraAIModule: AuroraAIModuleExport = {
  AIFabButton: AuroraAIFabButton,
  AIPanel: AuroraAIPanel,
  AIAnalysisCard: AuroraAIAnalysisCard,
  features: AIFeatures,
  messages: AIMessages
}
