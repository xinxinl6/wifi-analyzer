// 隐私政策同意弹窗组件

import {
  adaptiveTextPrimary,
  COLOR_SKY_BLUE,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_OVERLAY,
  COLOR_MODAL_OVERLAY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_TEXT_LIGHT_TERTIARY,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_AURORA,
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_GLASS_STRONG
} from '@wifi-analyzer/design-system'

/**
 * PrivacyDialog - 隐私政策同意弹窗组件
 * 华为审核要求：必须先同意隐私政策才能请求权限
 */
@Component
export struct PrivacyDialog {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @Prop privacyAgreed: boolean = false
  onAgree: () => void = () => {}
  onDisagree: () => void = () => {}

  build() {
    Column() {
      Column() {
        // 应用图标 + 标题
        Text($r('app.string.app_name_wifi_analyzer'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .margin({ bottom: 4 })

        Text($r('app.string.privacy_agreement_title'))
          .fontSize(13)
          .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY)
          .margin({ bottom: 16 })

        // 协议内容滚动区
        Scroll() {
          Column() {
            // 隐私政策摘要
            this.buildPrivacySection(
              $r('app.string.privacy_policy'),
              '更新时间：2026年5月\n\n' +
              'WlAN-分析仪（以下简称"本应用"）尊重并保护用户隐私。\n\n' +
              '【信息收集】\n' +
              '• 位置信息：用于扫描附近的WiFi网络（HarmonyOS系统要求）\n' +
              '• WiFi信息：用于显示网络状态、信号强度、信道分析\n\n' +
              '【信息使用】\n' +
              '收集的信息仅用于本应用内的功能展示，不会上传至任何服务器。\n\n' +
              '【数据存储】\n' +
              '所有数据仅存储在您的设备本地。\n\n' +
              '【第三方服务】\n' +
              '本应用不集成任何第三方分析或广告SDK。\n\n' +
              '联系我们：1218478630@qq.com'
            )

            Divider().color(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SURFACE_LIGHT)

            // 用户协议摘要
            this.buildPrivacySection(
              $r('app.string.user_agreement'),
              '更新时间：2026年5月\n\n' +
              '欢迎使用WlAN-分析仪。使用本应用即表示您同意以下条款。\n\n' +
              '【服务说明】\n' +
              '提供WiFi扫描、网络诊断、信号分析等功能。功能仅限个人学习研究使用。\n\n' +
              '【使用规范】\n' +
              '• 不得将本应用用于任何非法目的\n' +
              '• 不得破解、反编译或修改本应用\n\n' +
              '【免责声明】\n' +
              '本应用按"现状"提供，不保证功能完全无间断或错误。'
            )
          }
          .padding({ bottom: 8 })
        }
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .constraintSize({ maxHeight: 300 })
        .margin({ bottom: 20 })

        // 按钮区域
        Row() {
          // 不同意按钮
          Button($r('app.string.btn_disagree'))
            .fontSize(15)
            .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY)
            .backgroundColor(this.isDarkMode ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_SKY_ACTIVE)
            .borderRadius(12)
            .height(44)
            .layoutWeight(1)
            .onClick(() => {
              this.onDisagree()
            })

          // 同意并继续按钮
          Button($r('app.string.btn_agree_and_continue'))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(COLOR_TEXT_GLASS_PRIMARY)
            .backgroundColor(COLOR_SKY_BLUE)
            .borderRadius(12)
            .height(44)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.onAgree()
            })
        }
      }
      .padding(24)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : 'rgba(255,255,255,0.94)')
      .borderRadius(24)
      .border({
        width: 1,
        color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SURFACE_LIGHT
      })
      .shadow({
        radius: 28,
        color: this.isDarkMode ? COLOR_SHADOW_GLASS_STRONG : COLOR_SHADOW_GLASS_STRONG,
        offsetX: 0,
        offsetY: 10
      })
      .width('90%')
      .constraintSize({ maxWidth: 360 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.65)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 点击遮罩不做任何事（必须明确选择）
    })
  }

  @Builder
  buildPrivacySection(title: string | Resource, content: string) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .margin({ bottom: 8 })

      Text(content)
        .fontSize(12.5)
        .lineHeight(21)
        .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 4, bottom: 4 })
  }
}
