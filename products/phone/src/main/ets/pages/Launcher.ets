import { router } from '@kit.ArkUI';

/**
 * Launcher — 启动页
 * 直接跳转到首页，不在此处理权限。
 * 权限请求在用户首次使用具体功能时由系统自然触发。
 */
@Entry
@ComponentV2
struct Launcher {
  aboutToAppear(): void {
    // 短暂延迟后跳转首页，给启动动画一点时间
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/Index' });
    }, 800);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [['#1a2a6c', 0.0], ['#4A90D9', 0.5], ['#87CEEB', 1.0]]
        })

      Column({ space: 16 }) {
        Text('WlAN-分析仪')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        LoadingProgress()
          .width(40)
          .height(40)
          .color(Color.White)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
