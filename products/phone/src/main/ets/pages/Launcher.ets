import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PermissionManager, PermissionStatus } from 'wifi-base';

@Entry
@ComponentV2
struct Launcher {
  @Local isLoading: boolean = true;
  @Local showPermissionDenied: boolean = false;
  private permissionManager: PermissionManager | null = null;

  aboutToAppear(): void {
    this.checkAndRequestPermissions();
  }

  async checkAndRequestPermissions(): Promise<void> {
    try {
      const ctx = AppStorage.get<object>('abilityContext') as common.UIAbilityContext;
      if (!ctx) {
        this.isLoading = false;
        this.showPermissionDenied = true;
        return;
      }

      this.permissionManager = new PermissionManager(ctx);
      const status = this.permissionManager.checkPermissions();

      if (status === PermissionStatus.GRANTED) {
        this.navigateToHome();
        return;
      }

      const granted = await this.permissionManager.requestPermissions();
      if (granted) {
        this.navigateToHome();
      } else {
        this.isLoading = false;
        this.showPermissionDenied = true;
      }
    } catch {
      this.isLoading = false;
      this.showPermissionDenied = true;
    }
  }

  navigateToHome(): void {
    router.replaceUrl({ url: 'pages/Index' });
  }

  openSettings(): void {
    if (this.permissionManager) {
      this.permissionManager.openAppSettings();
    }
  }

  retryRequest(): void {
    this.isLoading = true;
    this.showPermissionDenied = false;
    this.checkAndRequestPermissions();
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

      if (this.isLoading) {
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
      } else {
        Column({ space: 24 }) {
          Text('需要权限才能继续')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)

          Text('WiFi 分析仪需要以下权限：\nWiFi 信息 · 大致位置 · 网络访问')
            .fontSize(14)
            .fontColor('#BBBBBB')
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })

          Button('前往设置授权')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#4A90D9')
            .borderRadius(24)
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .onClick(() => this.openSettings())

          Button('重新检测')
            .fontSize(14)
            .fontColor('#87CEEB')
            .backgroundColor(Color.Transparent)
            .onClick(() => this.retryRequest())
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}
