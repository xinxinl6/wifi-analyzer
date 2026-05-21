// 关于页面 — 参考爱快风格：应用图标 + 版本 + 功能列表 + 底部信息
import {
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER, COLOR_AURORA_PRIMARY,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_2XL,
  FONT_WEIGHT_BOLD,
  SPACE_LG,
  RADIUS_LG, SAFE_AREA_BOTTOM, SAFE_AREA_TOP, GLASS_BLUR_LG, GLASS_SHADOW_LG,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextTertiary, adaptiveDivider, adaptiveCardBg,
  COLOR_CARD_DARK_SOLID, COLOR_SHADOW_AURORA, COLOR_SHADOW_GLASS_STRONG
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { RouterManager } from '@wifi-analyzer/core'
import promptAction from '@ohos.promptAction'
import { AgreementDialog } from './AgreementDialog'
import {
  PRIVACY_TEXT,
  AGREEMENT_TEXT,
  FEEDBACK_TEXT,
  PRIVACY_POLICY_HTML,
  USER_AGREEMENT_HTML,
  FEEDBACK_HTML
} from './AboutTexts'

// ==================== 列表项接口 ====================
interface AboutListItem {
  label: Resource | string
  value: Resource | string
  action: string
  showArrow: boolean
}

// ==================== 组件 ====================
@Component
export struct AboutPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  // 应用版本信息
  private appVersion: string = 'v1.0.1'
  private buildNumber: string = '1000001'

  // 弹窗控制器
  @State dialogController: CustomDialogController | null = null
  @State dialogTitle: ResourceStr = ''
  @State dialogTextContent: string = ''

  // 列表数据
  private listItems: AboutListItem[] = [
    { label: $r('app.string.check_update'), value: '', action: 'checkUpdate', showArrow: true },
    { label: $r('app.string.privacy_policy'), value: '', action: 'privacy', showArrow: true },
    { label: $r('app.string.user_agreement'), value: '', action: 'agreement', showArrow: true },
    { label: $r('app.string.feedback'), value: '', action: 'feedback', showArrow: true },
  ]

  // ==================== 构建 ====================
  build() {
    Stack() {
      // ===== Aurora 天蓝渐变背景 =====
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

      // ===== 主内容层 =====
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP, bottom: SAFE_AREA_BOTTOM })
        .alignItems(VerticalAlign.Center)

        // ===== 内容区域 =====
        Scroll() {
          Column({ space: 0 }) {

            // ===== 应用 LOGO 区域 =====
            Column({ space: 8 }) {
              // 应用图标
              Column() {
                Image($r('app.media.icon'))
                  .width(80)
                  .height(80)
                  .borderRadius(18)
                  .shadow({ radius: 16, color: COLOR_AURORA_PRIMARY, offsetX: 0, offsetY: 4 })
              }
              .margin({ top: 4, bottom: 4 })

              // 应用名称
              Text($r('app.string.app_name_wifi_analyzer'))
                .fontSize(FONT_SIZE_2XL)
                .fontWeight(FONT_WEIGHT_BOLD)
                .fontColor(adaptiveTextPrimary(this.isDarkMode))

              // 版本号
              Text() {
                Span($r('app.string.version_prefix'))
                Span(' ' + this.appVersion)
              }
                .fontSize(FONT_SIZE_SM)
                .fontColor(adaptiveTextTertiary(this.isDarkMode))
                .margin({ bottom: 32 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)

            // ===== 功能列表区域 =====
            Column({ space: 0 }) {
              ForEach(this.listItems, (item: AboutListItem, index: number) => {
                Column() {
                  Row() {
                    Text(item.label)
                      .fontSize(FONT_SIZE_MD)
                      .fontColor(adaptiveTextPrimary(this.isDarkMode))
                      .layoutWeight(1)

                    if (item.value !== '') {
                      Text(item.value)
                        .fontSize(FONT_SIZE_SM)
                        .fontColor(adaptiveTextTertiary(this.isDarkMode))
                        .margin({ right: 4 })
                    }

                    if (item.showArrow) {
                      Image($r('app.media.ic_arrow_right'))
                        .width(16)
                        .height(16)
                        .fillColor(adaptiveTextTertiary(this.isDarkMode))
                    }
                  }
                  .width('100%')
                  .height(52)
                  .padding({ left: SPACE_LG, right: SPACE_LG })
                  .backgroundColor(adaptiveCardBg(this.isDarkMode))
                  .onClick(() => { this.onItemClick(item.action) })

                  // 分割线（最后一项不显示）
                  if (index < this.listItems.length - 1) {
                    Divider()
                      .color(adaptiveDivider(this.isDarkMode))
                      .strokeWidth(0.5)
                      .padding({ left: SPACE_LG })
                      .margin({ left: SPACE_LG })
                  }
                }
                .width('100%')
              })
            }
            .width('100%')
            .borderRadius(RADIUS_LG)
            .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
            .borderWidth(1.5)
            .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
            .backdropBlur(GLASS_BLUR_LG)
            .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_GLASS_STRONG : COLOR_SHADOW_AURORA, offsetX: 0, offsetY: 4 })
            .clip(true)
            .margin({ left: 16, right: 16, top: 8 })
            .width('calc(100% - 32vp)')

            // ===== 底部信息 =====
            Column({ space: 6 }) {
              Text() {
                Span($r('app.string.contact_address'))
                Span('：1218478630@qq.com')
              }
                .fontSize(FONT_SIZE_XS)
                .fontColor(adaptiveTextTertiary(this.isDarkMode))
                .textAlign(TextAlign.Center)

              Text() {
                Span($r('app.string.build_number'))
                Span(': ' + this.buildNumber)
              }
                .fontSize(FONT_SIZE_XS)
                .fontColor(adaptiveTextTertiary(this.isDarkMode))
                .textAlign(TextAlign.Center)

              Text($r('app.string.copyright'))
                .fontSize(FONT_SIZE_XS)
                .fontColor(adaptiveTextTertiary(this.isDarkMode))
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 32, bottom: 48 })
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
        }
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 列表项点击 ====================
  onItemClick(action: string): void {
    if (action === 'checkUpdate') {
      // 检查更新：显示"当前已是最新版本"
      promptAction.showToast({
        message: $r('app.string.check_update_latest'),
        duration: 2000
      })
    } else if (action === 'privacy') {
      // 隐私政策弹窗
      this.dialogTitle = $r('app.string.privacy_policy')
      this.dialogTextContent = PRIVACY_TEXT
      this.showDialog()
    } else if (action === 'agreement') {
      // 用户协议弹窗
      this.dialogTitle = $r('app.string.user_agreement')
      this.dialogTextContent = AGREEMENT_TEXT
      this.showDialog()
    } else if (action === 'feedback') {
      // 意见反馈弹窗
      this.dialogTitle = $r('app.string.feedback')
      this.dialogTextContent = FEEDBACK_TEXT
      this.showDialog()
    }
  }

  // 显示协议弹窗
  private showDialog(): void {
    if (this.dialogController) {
      this.dialogController.close()
    }
    this.dialogController = new CustomDialogController({
      builder: AgreementDialog({
        dialogTitle: this.dialogTitle,
        plainTextContent: this.dialogTextContent
      }),
      customStyle: true
    })
    this.dialogController.open()
  }
}
