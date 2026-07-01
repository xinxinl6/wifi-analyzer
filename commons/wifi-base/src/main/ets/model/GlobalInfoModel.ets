/**
 * GlobalInfoModel — 全局数据模型（单例模式）
 * 不使用 @ObservedV2/@Trace，因为 AppStorage 不支持存储装饰类实例
 * 通过全局单例 + @State/@Local 在组件中响应式使用
 */

/** 材质级别枚举 */
export enum MaterialLevelType {
  ADAPTIVE = 0,
  IMMERSIVE = 1,
  IMMERSIVE_HIGH = 2
}

/** 材质级别名称（按索引对应 MaterialLevelType） */
export const MATERIAL_LEVEL_LABELS: string[] = ['自适应', '沉浸', '高沉浸'];

/** 材质级别 → MaterialLevel 数值映射（0=ADAPTIVE, 1=PRIMARY, 2=SECONDARY） */
export function toMaterialLevelValue(level: MaterialLevelType): number {
  switch (level) {
    case MaterialLevelType.ADAPTIVE:
      return 0;
    case MaterialLevelType.IMMERSIVE:
      return 1;
    case MaterialLevelType.IMMERSIVE_HIGH:
      return 2;
    default:
      return 0;
  }
}

/**
 * GlobalInfoModel — 全局数据模型（单例）
 * 通过 GlobalInfoModel.getInstance() 获取全局唯一实例
 */
export class GlobalInfoModel {
  private static instance: GlobalInfoModel | null = null;

  /** 宽度断点 */
  public widthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  /** 高度断点 */
  public heightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;
  /** 导航指示器高度 (vp) */
  public naviIndicatorHeight: number = 0;
  /** 状态栏高度 (vp) */
  public statusBarHeight: number = 0;
  /** 设备宽度 (vp) */
  public deviceWidth: number = 0;
  /** 设备高度 (vp) */
  public deviceHeight: number = 0;
  /** 深色模式 — Aurora v3 Dark-First 默认深色 */
  public isDarkMode: boolean = true;
  /** 当前 Tab 索引 */
  public currentTabIndex: number = 0;
  /** 毛玻璃材质级别（用户可切换） */
  public materialLevel: MaterialLevelType = MaterialLevelType.IMMERSIVE;
  /** 是否在子页面中 */
  public isInSubPage: boolean = false;

  constructor() {}

  static getInstance(): GlobalInfoModel {
    if (!GlobalInfoModel.instance) {
      GlobalInfoModel.instance = new GlobalInfoModel();
    }
    return GlobalInfoModel.instance;
  }
}
