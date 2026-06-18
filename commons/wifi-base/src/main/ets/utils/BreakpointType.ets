/**
 * WiFi分析仪 — 断点适配泛型工具类
 * 借鉴 MultiFinancialManagement 项目的 BreakpointType 模式
 *
 * 断点定义:
 *   SM: < 520vp   — 手机竖屏
 *   MD: 520-840vp — 手机横屏/小折叠
 *   LG: 840-1200vp— 平板竖屏/折叠展开
 *   XL: > 1200vp  — 平板横屏/PC/2合1
 */

export class BreakpointType<T> {
  private sm: T;
  private md: T;
  private lg: T;
  private xl: T;

  constructor(sm: T, md: T, lg: T, xl: T) {
    this.sm = sm;
    this.md = md;
    this.lg = lg;
    this.xl = xl;
  }

  getValue(widthBp: WidthBreakpoint): T {
    let value: T;
    switch (widthBp) {
      case WidthBreakpoint.WIDTH_XS:
      case WidthBreakpoint.WIDTH_SM:
        value = this.sm;
        break;
      case WidthBreakpoint.WIDTH_MD:
        value = this.md;
        break;
      case WidthBreakpoint.WIDTH_LG:
        value = this.lg;
        break;
      case WidthBreakpoint.WIDTH_XL:
        value = this.xl;
        break;
      default:
        value = this.sm;
        break;
    }
    return value;
  }
}

/**
 * 根据窗口宽度数值获取断点
 */
export function getWidthBpByWidth(width: number): WidthBreakpoint {
  if (width < 520) {
    return WidthBreakpoint.WIDTH_SM;
  } else if (width < 840) {
    return WidthBreakpoint.WIDTH_MD;
  } else if (width < 1200) {
    return WidthBreakpoint.WIDTH_LG;
  } else {
    return WidthBreakpoint.WIDTH_XL;
  }
}

/**
 * 响应式间距/尺寸常量工具
 */
export class ResponsiveSpacing {
  static readonly PAGE_PADDING: BreakpointType<number>[] = [
    new BreakpointType(16, 16, 24, 24),   // 页面左右间距
    new BreakpointType(16, 20, 24, 32),   // 卡片内部 padding
    new BreakpointType(8, 12, 16, 16),    // 列表项间距
    new BreakpointType(12, 16, 24, 24),   // Section 间距
  ];

  static readonly CARD_COLUMNS: BreakpointType<number> = new BreakpointType(1, 2, 3, 4);

  static readonly TOOL_GRID_COLUMNS: BreakpointType<number> = new BreakpointType(2, 3, 4, 6);

  static readonly FONT_SIZE_TITLE: BreakpointType<number> = new BreakpointType(20, 22, 24, 28);

  static readonly FONT_SIZE_BODY: BreakpointType<number> = new BreakpointType(14, 15, 16, 18);
}
