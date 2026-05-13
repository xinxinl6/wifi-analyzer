// 通用内容展示页面 — 用于隐私政策、用户协议、意见反馈
// 使用 RichText 显示富文本内容

import {
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  SPACE_LG, SAFE_AREA_TOP, SAFE_AREA_BOTTOM,
  FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_2XL,
  FONT_WEIGHT_BOLD,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000

@Component
export struct ContentPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  /** 页面标题 */
  private title: string = ''

  /** HTML 内容 */
  private htmlContent: string = ''

  /** 返回回调 */
  private onBack: () => void = () => {} // 默认空函数，避免可选参数报错

  build() {
    Stack() {
      // Aurora 天蓝渐变背景
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })

      // 主内容
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({ onBack: () => this.onBack() })
          Blank()
          Text(this.title)
            .fontSize(FONT_SIZE_LG)
            .fontWeight(FONT_WEIGHT_BOLD)
            .fontColor(Color.White)
          Blank()
          // 右侧留空以保持标题居中
          Column().width(40)
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        // 富文本内容区域
        Column() {
          RichText(this.htmlContent)
            .width('100%')
            .height('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: SAFE_AREA_BOTTOM })
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: 24 })
        .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
        .borderRadius(18)
        .backdropBlur(10)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
