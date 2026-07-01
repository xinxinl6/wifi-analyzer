/**
 * WiFi分析仪 — 断点适配泛型工具类
 * 升级为 Spatialization 项目的对象参数模式
 *
 * 断点定义:
 *   SM: < 520vp   — 手机竖屏
 *   MD: 520-840vp — 手机横屏/小折叠
 *   LG: 840-1200vp— 平板竖屏/折叠展开
 *   XL: > 1200vp  — 平板横屏/PC/2合1
 */

export interface BreakpointTypeOptions<T> {
  xs?: T;
  sm: T;
  md: T;
  lg: T;
  xl?: T;
}

export class BreakpointType<T> {
  private xs: T;
  private sm: T;
  private md: T;
  private lg: T;
  private xl: T;

  constructor(param: BreakpointTypeOptions<T>) {
    this.xs = param.xs ?? param.sm;
    this.sm = param.sm;
    this.md = param.md;
    this.lg = param.lg;
    this.xl = param.xl ?? param.lg;
  }

  getValue(widthBp: WidthBreakpoint): T {
    if (widthBp === WidthBreakpoint.WIDTH_XS) {
      return this.xs;
    }
    if (widthBp === WidthBreakpoint.WIDTH_SM) {
      return this.sm;
    }
    if (widthBp === WidthBreakpoint.WIDTH_MD) {
      return this.md;
    }
    if (widthBp === WidthBreakpoint.WIDTH_XL) {
      return this.xl;
    }
    return this.lg;
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
    new BreakpointType({ sm: 16, md: 16, lg: 24, xl: 24 }),   // 页面左右间距
    new BreakpointType({ sm: 16, md: 20, lg: 24, xl: 32 }),   // 卡片内部 padding
    new BreakpointType({ sm: 8, md: 12, lg: 16, xl: 16 }),    // 列表项间距
    new BreakpointType({ sm: 12, md: 16, lg: 24, xl: 24 }),   // Section 间距
  ];

  static readonly CARD_COLUMNS: BreakpointType<number> = new BreakpointType({ sm: 1, md: 2, lg: 3, xl: 4 });

  static readonly TOOL_GRID_COLUMNS: BreakpointType<number> = new BreakpointType({ sm: 2, md: 3, lg: 4, xl: 6 });

  static readonly FONT_SIZE_TITLE: BreakpointType<number> = new BreakpointType({ sm: 20, md: 22, lg: 24, xl: 28 });

  static readonly FONT_SIZE_BODY: BreakpointType<number> = new BreakpointType({ sm: 14, md: 15, lg: 16, xl: 18 });
}
