// 尺寸设计系统
// 间距系统 (基于4px基准)
export const SPACE_XS = 4
export const SPACE_SM = 8
export const SPACE_MD = 12
export const SPACE_LG = 16
export const SPACE_XL = 20
export const SPACE_2XL = 24
export const SPACE_3XL = 28
export const SPACE_4XL = 32
export const SPACE_5XL = 40
export const SPACE_6XL = 48

// 圆角系统
export const RADIUS_XS = 2
export const RADIUS_SM = 4
export const RADIUS_MD = 8
export const RADIUS_LG = 12
export const RADIUS_XL = 16
export const RADIUS_2XL = 20
export const RADIUS_3XL = 24
export const RADIUS_FULL = 999

// 图标尺寸系统 (基于96×96超高分辨率图标)
export const ICON_SIZE_XXS = 12
export const ICON_SIZE_XS = 16
export const ICON_SIZE_SM = 20
export const ICON_SIZE_MD = 24
export const ICON_SIZE_LG = 28
export const ICON_SIZE_XL = 32
export const ICON_SIZE_2XL = 40
export const ICON_SIZE_3XL = 48
export const ICON_SIZE_4XL = 64
export const ICON_SIZE_5XL = 96

// 组件尺寸
export const BUTTON_HEIGHT_SM = 32
export const BUTTON_HEIGHT_MD = 40
export const BUTTON_HEIGHT_LG = 48

export const INPUT_HEIGHT = 44
export const TAB_BAR_HEIGHT = 72

// 卡片尺寸
export const CARD_PADDING = 20
export const CARD_RADIUS = 16
export const CARD_SHADOW_RADIUS = 8

// 图表尺寸
export const GAUGE_SIZE_XS = 44
export const GAUGE_SIZE_SM = 64
export const GAUGE_SIZE_MD = 100
export const GAUGE_SIZE_LG = 180
export const GAUGE_SIZE_XL = 200

// 线条宽度
export const STROKE_WIDTH_XS = 1
export const STROKE_WIDTH_SM = 2
export const STROKE_WIDTH_MD = 4
export const STROKE_WIDTH_LG = 6
export const STROKE_WIDTH_XL = 8
export const STROKE_WIDTH_2XL = 12
export const STROKE_WIDTH_3XL = 16

// 玻璃效果尺寸
export const GLASS_BLUR_SM = 6
export const GLASS_BLUR_MD = 8
export const GLASS_BLUR_LG = 12
export const GLASS_BLUR_XL = 14
export const GLASS_BLUR_XXL = 16
export const GLASS_BLUR_MAX = 24

export const GLASS_SHADOW_SM = 8
export const GLASS_SHADOW_MD = 12
export const GLASS_SHADOW_LG = 14
export const GLASS_SHADOW_XL = 16
export const GLASS_SHADOW_2XL = 20
export const GLASS_SHADOW_3XL = 24
export const GLASS_SHADOW_MAX = 28

// 安全区尺寸（状态栏 + 底部手势条）
// 真实值由 EntryAbility 通过 getWindowAvoidArea 获取并存入 AppStorage
// 取值 56 覆盖挖孔屏/刘海屏等高状态栏设备，确保审核不重叠
export const SAFE_AREA_TOP: number = 56
export const SAFE_AREA_BOTTOM: number = 24

// Tab 栏底部安全间距（Tab Bar 72 + margin bottom 12 + SAFE_AREA_BOTTOM）
export const TAB_BAR_SAFE_BOTTOM: number = 108
