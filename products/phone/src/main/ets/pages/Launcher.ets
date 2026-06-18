import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PermissionManager, PermissionStatus } from 'wifi-base';

@Entry
@ComponentV2
struct Launcher {
  @Local isLoading: boolean = true;
  @Local permissionStatus: string = 'checking';
  private permissionManager: PermissionManager | null = null;

  aboutToAppear(): void {
    this.checkAndRequestPermissions();
  }

  async checkAndRequestPermissions(): Promise<void> {
    try {
      // 获取 context 并初始化权限管理器
      const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
      if (!ctx) {
        this.isLoading = false;
        this.permissionStatus = 'no_context';
        return;
      }
      this.permissionManager = new PermissionManager(ctx);

      // 检查当前权限状态
      const status = this.permissionManager.checkPermissions();
      if (status === PermissionStatus.GRANTED) {
        this.navigateToHome();
        return;
      }

      // 请求权限
      const granted = await this.permissionManager.requestPermissions();
      if (granted) {
        this.navigateToHome();
      } else {
        this.isLoading = false;
        this.permissionStatus = 'denied';
      }
    } catch {
      this.isLoading = false;
      this.permissionStatus = 'error';
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
    this.permissionStatus = 'checking';
    this.checkAndRequestPermissions();
  }

  build() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Top,
          colors: [['#1a2a6c', 0.0], ['#4A90D9', 0.5], ['#87CEEB', 1.0]]
        })

      if (this.isLoading) {
        // 加载中
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
      } else if (this.permissionStatus === 'denied') {
        // 权限被拒绝 — 引导用户去设置
        Column({ space: 24 }) {
          Text('需要 WiFi 和相关网络权限')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)

          Text('WiFi 分析仪需要以下权限才能正常工作：\n• WiFi 信息\n• 大致位置\n• 网络访问')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .textAlign(TextAlign.Center)
            .padding({ left: 32, right: 32 })

          Button('前往设置授权')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#4A90D9')
            .borderRadius(24)
            .padding({ left: 32, right: 32, top: 12, bottom: 12 })
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
