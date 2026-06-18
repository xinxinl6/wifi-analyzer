import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'Launcher';

// 所需权限列表
const REQUIRED_PERMISSIONS: Permissions[] = [
  'ohos.permission.GET_WIFI_INFO',
  'ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.INTERNET',
  'ohos.permission.GET_NETWORK_INFO',
];

@Entry
@ComponentV2
struct Launcher {
  @Local isRequesting: boolean = true;
  @Local showDeniedTip: boolean = false;

  aboutToAppear(): void {
    this.requestSystemPermissions();
  }

  async requestSystemPermissions(): Promise<void> {
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
      if (!ctx) {
        hilog.error(DOMAIN, TAG, '无法获取 context');
        this.isRequesting = false;
        this.showDeniedTip = true;
        return;
      }

      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(ctx, REQUIRED_PERMISSIONS);

      // 检查授权结果
      let allGranted = true;
      for (let i = 0; i < result.authResults.length; i++) {
        if (result.authResults[i] !== 0) {
          allGranted = false;
          break;
        }
      }

      if (allGranted) {
        hilog.info(DOMAIN, TAG, '权限已全部授权，进入首页');
        this.navigateToHome();
      } else {
        hilog.warn(DOMAIN, TAG, '部分或全部权限被拒绝');
        this.isRequesting = false;
        this.showDeniedTip = true;
      }
    } catch {
      hilog.error(DOMAIN, TAG, '权限请求异常');
      this.isRequesting = false;
      this.showDeniedTip = true;
    }
  }

  navigateToHome(): void {
    router.replaceUrl({ url: 'pages/Index' });
  }

  openSystemSettings(): void {
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
      if (ctx) {
        ctx.startAbility({
          bundleName: 'com.huawei.harmonyos.settings',
          abilityName: 'com.huawei.harmonyos.settings.MainAbility',
        });
      }
    } catch {
      hilog.warn(DOMAIN, TAG, '无法打开设置');
    }
  }

  retry(): void {
    this.isRequesting = true;
    this.showDeniedTip = false;
    this.requestSystemPermissions();
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

      if (this.isRequesting) {
        // 正在请求权限 — 显示加载
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
      } else if (this.showDeniedTip) {
        // 权限被拒绝 — 提示去设置
        Column({ space: 24 }) {
          Text('需要权限才能使用')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)

          Text('请前往系统设置中允许应用权限')
            .fontSize(14)
            .fontColor('#BBBBBB')

          Button('打开系统设置')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#4A90D9')
            .borderRadius(24)
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .onClick(() => this.openSystemSettings())

          Button('重试')
            .fontSize(14)
            .fontColor('#87CEEB')
            .backgroundColor(Color.Transparent)
            .onClick(() => this.retry())
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
