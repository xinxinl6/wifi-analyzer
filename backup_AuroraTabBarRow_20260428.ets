// ==================== AuroraTabBarRow 备份 (2026-04-28) ====================
// 悬浮毛玻璃 TabBar，使用双 Stack + hitTestBehavior(None) 实现点击穿透
// SDK: 6.1.0(23) / 兼容 5.0.2(14)
// 踩坑: hitTestMode 只在新 SDK 的 Stack 上可用，SDK 6.1.0 正确 API 是 hitTestBehavior(HitTestMode.None)

  @Builder
  AuroraTabBarRow() {
    // 使用双 Stack 实现点击穿透
    // 内层 Stack：hitTestBehavior(None) 让透明区域穿透到外层
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景透明区域（无背景色=透明，点击穿透）
      Stack() {}
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)  // 透明区域完全不响应点击，点击穿透到下层

      // 顶层 Column：水平居中，承载毛玻璃 TabBar
      Column() {
        Row() {
          ForEach(TAB_ITEMS, (item: TabItem, index: number) => {
            Column() {
              Image(item.icon)
                .width(28)
                .height(28)
                .fillColor(this.currentIndex === index ? '#007AFF' : '#8E8E93')

              Text(item.title)
                .fontSize(12)
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.currentIndex === index ? '#007AFF' : '#8E8E93')
                .margin({ top: 4 })
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.onTabClick(index)
            })
          }, (item: TabItem, index: number) => index.toString())
        }
        .width('85%')   // TabBar 宽度 85%
        .height(80)     // TabBar 高度 80vp
        .padding({ top: 10, bottom: 12 })
        // === 毛玻璃效果 ===
        .backgroundColor('rgba(255, 255, 255, 0.68)')
        .backdropBlur(18)
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [
            ['rgba(255, 255, 255, 0.45)', 0],
            ['rgba(255, 255, 255, 0.14)', 0.5],
            ['rgba(255, 255, 255, 0.08)', 1]
          ]
        })
        .borderRadius(28)
        .border({
          width: { top: 0.5, bottom: 0 },
          color: {
            top: 'rgba(255, 255, 255, 0.78)',
            bottom: 'rgba(0, 0, 0, 0.04)'
          }
        })
        .shadow({
          radius: 24,
          color: 'rgba(0, 0, 0, 0.12)',
          offsetX: 0,
          offsetY: 6
        })
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .height(80)
      .position({ y: 40 })  // 底部安全区 20vp + 上方间距
    }
    .width('100%')
    .height(120)  // 内层 Stack 总高度（含底部安全区）
  }
