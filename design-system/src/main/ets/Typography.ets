// 字体排版设计系统
// 语义化字体层级：每个令牌对应明确的 UI 语义

// 字体大小系统（语义化命名）
export const FONT_SIZE_XXS = 13       // 微型文字：图表标签、角标
export const FONT_SIZE_XS = 14       // 辅助文字：标签、脚注、说明文字
export const FONT_SIZE_SM = 15       // 次要正文：列表副标题、辅助信息（与 XS 同值，语义区分）
export const FONT_SIZE_MD = 16       // 正文主体：列表项名称、卡片正文（与 XS 同值，语义区分）
export const FONT_SIZE_LG = 17       // 小标题：卡片区块标题、列表分组标题
export const FONT_SIZE_XL = 18       // 段落标题：卡片标题、内容区标题
export const FONT_SIZE_2XL = 19     // 列表标题：WiFi 列表项名称
export const FONT_SIZE_3XL = 20      // 页面标题：页面主标题
export const FONT_SIZE_4XL = 21      // 大号数字：仪表盘数值、关键数据
export const FONT_SIZE_5XL = 22      // 超大数字：重要统计
export const FONT_SIZE_6XL = 24      // 展示级数字
export const FONT_SIZE_7XL = 26      // 展示级大标题
export const FONT_SIZE_8XL = 28      // 英雄数字
export const FONT_SIZE_9XL = 32      // 超大标题
export const FONT_SIZE_10XL = 36     // 特大标题
export const FONT_SIZE_11XL = 48     // 展示标题（最大）

// 字重系统（仅保留 ArkTS 支持的枚举值）
export const FONT_WEIGHT_LIGHTER = FontWeight.Lighter
export const FONT_WEIGHT_NORMAL = FontWeight.Normal
export const FONT_WEIGHT_MEDIUM = FontWeight.Medium
export const FONT_WEIGHT_BOLD = FontWeight.Bold
export const FONT_WEIGHT_BOLDER = FontWeight.Bolder

// 行高系统
export const LINE_HEIGHT_TIGHT = 1.2
export const LINE_HEIGHT_NORMAL = 1.5
export const LINE_HEIGHT_RELAXED = 1.75

// 文本样式接口
export interface TextStyle {
  fontSize: number
  fontWeight: FontWeight
}

// 文本样式预定义实例
export const TEXT_STYLE_TITLE: TextStyle = {
  fontSize: FONT_SIZE_4XL,
  fontWeight: FONT_WEIGHT_BOLD
}

export const TEXT_STYLE_SUBTITLE: TextStyle = {
  fontSize: FONT_SIZE_LG,
  fontWeight: FONT_WEIGHT_MEDIUM
}

export const TEXT_STYLE_BODY: TextStyle = {
  fontSize: FONT_SIZE_MD,
  fontWeight: FONT_WEIGHT_NORMAL
}

export const TEXT_STYLE_CAPTION: TextStyle = {
  fontSize: FONT_SIZE_SM,
  fontWeight: FONT_WEIGHT_NORMAL
}

export const TEXT_STYLE_LABEL: TextStyle = {
  fontSize: FONT_SIZE_XS,
  fontWeight: FONT_WEIGHT_MEDIUM
}
