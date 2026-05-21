// 权限拒绝弹窗组件

import {
  adaptiveTextPrimary,
  COLOR_SKY_BLUE,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_OVERLAY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SKY_ACTIVE
} from '@wifi-analyzer/design-system'

/**
 * PermissionDialog - 权限拒绝弹窗组件
 * 当用户拒绝权限申请后，引导用户去设置页面开启权限
 */
@Component
export struct PermissionDialog {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onOpenSettings: () => void = () => {}
  onExit: () => void = () => {}

  build() {
    Column() {
      Column() {
        // 标题
        Text($r('app.string.permission_dialog_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .margin({ bottom: 12 })

        // 提示文字
        Text($r('app.string.permission_dialog_content'))
          .fontSize(14)
          .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY)
          .textAlign(TextAlign.Center)
          .lineHeight(22)
          .margin({ bottom: 24 })

        // 按钮区域
        Row() {
          // 继续使用按钮（有限功能模式）
          Button($r('app.string.continue_usage'))
            .fontSize(15)
            .fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY)
            .backgroundColor(this.isDarkMode ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_SKY_ACTIVE)
            .borderRadius(12)
            .height(44)
            .layoutWeight(1)
            .onClick(() => {
              // 关闭弹窗，以有限功能模式继续
              this.onExit()
            })

          // 去设置按钮
          Button($r('app.string.go_to_settings'))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor(COLOR_SKY_BLUE)
            .borderRadius(12)
            .height(44)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.onOpenSettings()
            })
        }
      }
      .padding(24)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_SURFACE_MEDIUM)
      .borderRadius(20)
      .border({
        width: 1,
        color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SURFACE_LIGHT
      })
      .shadow({
        radius: 24,
        color: this.isDarkMode ? 'rgba(0,0,0,0.4)' : COLOR_GLASS_SKY_ACTIVE,
        offsetX: 0,
        offsetY: 8
      })
      .width('85%')
      .constraintSize({ maxWidth: 340 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_OVERLAY)
    .justifyContent(FlexAlign.Center)
  }
}
