// ============================================
// HM7 字体排版系统（HarmonyOS Sans）
// 沉浸光感字号层级：28/22/20/18/16/14/12/10sp
// Display: 28sp Bold | Hero: 24-32sp Bold | Body: 16sp Regular
// 详见项目根目录 DESIGN.md
// ============================================

// 字体大小系统（HM7 语义化命名）
export const FONT_SIZE_XXS = 12       // 微型文字：图表标签、角标、MAC 地址
export const FONT_SIZE_XS = 14       // 辅助文字：标签、脚注、说明文字
export const FONT_SIZE_SM = 14       // 次要正文：列表副标题
export const FONT_SIZE_MD = 16       // 正文主体：列表项名称、卡片正文
export const FONT_SIZE_LG = 16       // 小标题：卡片区块标题
export const FONT_SIZE_XL = 18       // 段落标题：卡片标题、内容区标题
export const FONT_SIZE_2XL = 18      // 列表标题：WiFi 列表项名称
export const FONT_SIZE_3XL = 20      // 页面标题
export const FONT_SIZE_4XL = 22      // 大号数字：仪表盘数值
export const FONT_SIZE_5XL = 24      // 超大数字
export const FONT_SIZE_6XL = 26      // 展示级数字
export const FONT_SIZE_7XL = 28      // 展示级大标题 (Display)
export const FONT_SIZE_8XL = 32      // 英雄数字
export const FONT_SIZE_9XL = 36      // 超大标题
export const FONT_SIZE_10XL = 40     // 特大标题
export const FONT_SIZE_11XL = 48     // 展示标题（最大）

// 字重系统
export const FONT_WEIGHT_LIGHTER = FontWeight.Lighter
export const FONT_WEIGHT_NORMAL = FontWeight.Normal
export const FONT_WEIGHT_MEDIUM = FontWeight.Medium
export const FONT_WEIGHT_BOLD = FontWeight.Bold
export const FONT_WEIGHT_BOLDER = FontWeight.Bolder

// 行高系统（HM7 规范）
export const LINE_HEIGHT_TIGHT = 1.3
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
