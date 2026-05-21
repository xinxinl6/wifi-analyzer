// 端口扫描操作按钮组件

import {
  COLOR_PURPLE, COLOR_DANGER, COLOR_GLASS_SKY_SHADOW_MED,
  FONT_SIZE_MD, FONT_WEIGHT_BOLD,
  SPACE_MD,
  GLASS_SHADOW_SM,
  BackButtonCapsule,
  adaptiveTextPrimary
} from '@wifi-analyzer/design-system'

@Component
export struct PortActionButtons {
  @Prop isDarkMode: boolean = false
  @Prop isScanning: boolean = false

  onGoBack: () => void = () => {}
  onStop: () => void = () => {}
  onRestart: () => void = () => {}

  build() {
    Row({ space: SPACE_MD }) {
      // 返回按钮（返回空闲页，不退出）
      BackButtonCapsule({
        onBack: () => this.onGoBack()
      })

      if (this.isScanning) {
        Row() {
          Text($r('app.string.stop_action'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor(COLOR_DANGER)
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_DANGER, offsetX: 0, offsetY: 5 })
        .onClick(() => this.onStop())
      } else {
        Row() {
          Text($r('app.string.re_scan'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .padding({ top: 13, bottom: 13 })
        .backgroundColor(COLOR_PURPLE)
        .borderRadius(999)
        .shadow({ radius: GLASS_SHADOW_SM, color: COLOR_GLASS_SKY_SHADOW_MED, offsetX: 0, offsetY: 5 })
        .onClick(() => this.onRestart())
      }
    }
    .width('100%')
  }
}
