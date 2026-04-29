// ============================================
// Aurora WiFi V2 — 响应式网格组件
// ============================================

import { AuroraBreakpoints, auroraResponsive, getWindowWidth } from './AuroraBreakpoints'

// ============================================
// Aurora 响应式网格
// ============================================
@Component
export struct AuroraGrid {
  // 单列最小宽度
  @Prop minColumnWidth: number = 160
  // 最大列数
  @Prop maxColumns: number = 6
  // 间距
  @Prop gap: number = 16
  // 边距
  @Prop padding: number = 16

  // 内容构建器
  @BuilderParam itemBuilder: (index: number) => void = this.defaultBuilder
  // 数据项数量
  @Prop itemCount: number = 0

  @Builder
  defaultBuilder(index: number) {
    Column()
      .width('100%')
      .height(80)
      .backgroundColor('rgba(255,255,255,0.1)')
      .borderRadius(12)
  }

  build() {
    Column() {
      Grid() {
        ForEach(this.getItems(), (item: number, index: number) => {
          GridItem() {
            this.itemBuilder(index)
          }
          .columnStart(this.getColumnStart(index))
          .columnEnd(this.getColumnEnd(index))
        }, (item: number) => item.toString())
      }
      .columnsTemplate(this.getColumnsTemplate())
      .columnsGap(this.gap)
      .rowsGap(this.gap)
      .padding(this.padding)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  private getColumnsCount(): number {
    const available = getWindowWidth() - (this.padding * 2)
    const count = Math.floor(available / this.minColumnWidth)
    return Math.min(Math.max(count, 1), this.maxColumns)
  }

  private getItems(): number[] {
    return Array.from({ length: this.itemCount }, (_, i) => i)
  }

  private getColumnsTemplate(): string {
    const cols = this.getColumnsCount()
    return Array(cols).fill('1fr').join(' ')
  }

  private getColumnStart(index: number): number {
    return 0
  }

  private getColumnEnd(index: number): number {
    return 0
  }
}

// ============================================
// Aurora 自适应列表
// ============================================
@Component
export struct AuroraList {
  @Prop itemHeight: number = 72
  @Prop showDivider: boolean = true
  @Prop dividerIndent: number = 16

  @BuilderParam itemBuilder: (index: number) => void = this.defaultBuilder
  @Prop itemCount: number = 0

  @Builder
  defaultBuilder(index: number) {
    Row() {
      Text(`Item ${index}`)
        .fontColor('#FFFFFF')
    }
    .width('100%')
    .height(this.itemHeight)
    .padding({ left: 16, right: 16 })
  }

  build() {
    List() {
      ForEach(this.getItems(), (item: number) => {
        ListItem() {
          this.itemBuilder(item)
        }
        .swipeAction({ end: this.buildSwipeAction(item) })
      }, (item: number) => item.toString())
    }
    .width('100%')
    .height('100%')
    .divider(this.showDivider ? {
      strokeWidth: 0.5,
      color: 'rgba(255,255,255,0.08)',
      startMargin: this.dividerIndent,
      endMargin: this.dividerIndent
    } : null)
  }

  @Builder
  buildSwipeAction(index: number) {
    Row() {
      Text('删除')
        .fontColor('#FFFFFF')
        .backgroundColor('#EF4444')
        .padding({ left: 20, right: 20 })
        .height('100%')
    }
  }

  private getItems(): number[] {
    return Array.from({ length: this.itemCount }, (_, i) => i)
  }
}

// ============================================
// Aurora 卡片网格
// ============================================
@Component
export struct AuroraCardGrid {
  // 手机列数
  @Prop phoneColumns: number = 1
  // 平板列数
  @Prop tabletColumns: number = 2
  // PC列数
  @Prop pcColumns: number = 3
  // 间距
  @Prop gap: number = 16

  @BuilderParam cardBuilder: (index: number) => void = this.defaultBuilder
  @Prop cardCount: number = 0

  @Builder
  defaultBuilder(index: number) {
    Column()
      .width('100%')
      .height(120)
      .backgroundColor('rgba(255,255,255,0.08)')
      .borderRadius(16)
      .border({ width: 0.5, color: 'rgba(255,255,255,0.1)', radius: 16 })
  }

  build() {
    Column() {
      this.buildGrid()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildGrid() {
    Grid() {
      ForEach(this.getItems(), (item: number) => {
        GridItem() {
          this.cardBuilder(item)
        }
      }, (item: number) => item.toString())
    }
    .columnsTemplate(this.getColumnsTemplate())
    .columnsGap(this.gap)
    .rowsGap(this.gap)
    .padding(auroraResponsive(16, 12, 24))
    .width('100%')
    .height('100%')
  }

  private getColumnsCount(): number {
    const width = getWindowWidth()
    if (width >= AuroraBreakpoints.XXL) return this.pcColumns
    if (width >= AuroraBreakpoints.LG) return this.tabletColumns
    return this.phoneColumns
  }

  private getColumnsTemplate(): string {
    const cols = this.getColumnsCount()
    return Array(cols).fill('1fr').join(' ')
  }

  private getItems(): number[] {
    return Array.from({ length: this.cardCount }, (_, i) => i)
  }
}

// ============================================
// Aurora Stack 布局（设备适配）
// ============================================
@Component
export struct AuroraStackLayout {
  // 布局方向
  @Prop direction: Axis = Axis.Vertical
  // 主轴对齐
  @Prop mainAlign: FlexAlign = FlexAlign.Start
  // 交叉轴对齐
  @Prop crossAlign: HorizontalAlign = HorizontalAlign.Start
  // 间距
  @Prop space: number = 16

  @BuilderParam childBuilder: () => void = this.defaultBuilder

  @Builder
  defaultBuilder() {
    Text('Content')
  }

  build() {
    if (this.direction === Axis.Horizontal) {
      Row() {
        this.childBuilder()
      }
      .width('100%')
      .height('100%')
      .justifyContent(this.mainAlign)
      .alignItems(this.crossAlign === HorizontalAlign.Start ? VerticalAlign.Top :
                      this.crossAlign === HorizontalAlign.End ? VerticalAlign.Bottom : VerticalAlign.Center)
      .space(this.space)
    } else {
      Column() {
        this.childBuilder()
      }
      .width('100%')
      .height('100%')
      .alignItems(this.crossAlign)
      .justifyContent(this.mainAlign)
      .space(this.space)
    }
  }
}
