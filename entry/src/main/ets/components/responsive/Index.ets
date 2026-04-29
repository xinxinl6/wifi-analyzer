// ============================================
// Aurora WiFi V2 — 响应式组件库索引
// ============================================

// 断点和设备类型
export {
  AuroraDeviceType,
  AuroraOrientation,
  AuroraLayoutMode,
  AuroraBreakpoints,
  getCurrentBreakpoint,
  getDeviceType,
  getLayoutMode,
  getOrientation,
  isLandscape,
  isPortrait,
  useBottomNav,
  useSideNav,
  isLargeScreen,
  isTablet,
  isPC,
  isFoldable,
  getWindowWidth,
  getWindowHeight,
  getScreenShortSide,
  getScreenLongSide,
  auroraResponsive,
  getContentMaxWidth,
  getGridColumns,
  getListColumns,
  getSidebarWidth
} from './AuroraBreakpoints'

// 布局组件
export {
  AuroraTabConfig,
  AuroraMainLayout,
  AuroraBottomNav,
  AuroraSideNav,
  AuroraContentContainer,
  AuroraDeviceLayout
} from './AuroraLayout'

// 网格组件
export {
  AuroraGrid,
  AuroraList,
  AuroraCardGrid,
  AuroraStackLayout
} from './AuroraGrid'

// 间距系统
export {
  AuroraSpacing,
  getPagePadding,
  getCardGap,
  getComponentGap,
  getVerticalSpace,
  getHorizontalSpace,
  AuroraSpacerV,
  AuroraSpacerH,
  AuroraSafeArea,
  AuroraCenterContainer,
  AuroraRadius,
  getResponsiveRadius,
  getCardRadius,
  getButtonRadius,
  AuroraShadow,
  getResponsiveShadow
} from './AuroraSpacing'
