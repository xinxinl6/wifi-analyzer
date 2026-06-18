@Entry
@ComponentV2
struct Launcher {
  @Local isLoading: boolean = true;

  build() {
    Stack() {
      Column() {}.width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Bottom, colors: [['#4A90D9', 0], ['#1a2a6c', 1]] })

      Column() {
        Image($r('app.media.app_icon')).width(80).height(80).borderRadius(16)
        Text($r('app.string.app_name')).fontSize(24).fontColor(Color.White).margin({ top: 16 })
        LoadingProgress().margin({ top: 32 }).width(32).height(32)
      }
    }.width('100%').height('100%')
  }
}
