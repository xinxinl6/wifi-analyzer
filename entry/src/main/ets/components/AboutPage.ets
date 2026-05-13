// 关于页面 — 参考爱快风格：应用图标 + 版本 + 功能列表 + 底部信息
import {
  COLOR_PRIMARY, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_SURFACE, COLOR_BACKGROUND, COLOR_BORDER, COLOR_DIVIDER,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_MD, RADIUS_LG, SAFE_AREA_BOTTOM, SAFE_AREA_TOP, GLASS_BLUR_LG, GLASS_SHADOW_LG, GLASS_SHADOW_XL,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { RouterManager } from '@wifi-analyzer/core'
import promptAction from '@ohos.promptAction'

// 内容页面的 HTML 模板
const PRIVACY_POLICY_HTML: string =
  '<h2>隐私政策</h2>' +
  '<p>更新时间：2026年5月</p>' +
  '<p>WlAN-分析仪（以下简称"本应用"）尊重并保护用户隐私。本隐私政策将说明我们如何收集、使用和保护您的个人信息。</p>' +
  '<h3>1. 信息收集</h3>' +
  '<p>本应用仅在您主动授权的情况下收集以下信息：</p>' +
  '<ul>' +
  '<li><b>位置信息</b>：用于扫描附近的WiFi网络（HarmonyOS系统要求）</li>' +
  '<li><b>WiFi信息</b>：用于显示网络状态、信号强度、信道分析</li>' +
  '</ul>' +
  '<h3>2. 信息使用</h3>' +
  '<p>收集的信息仅用于本应用内的功能展示，不会上传至任何服务器。</p>' +
  '<h3>3. 数据存储</h3>' +
  '<p>所有数据仅存储在您的设备本地，不会传输到外部。</p>' +
  '<h3>4. 第三方服务</h3>' +
  '<p>本应用不集成任何第三方分析或广告SDK。</p>' +
  '<h3>5. 联系我们</h3>' +
  '<p>如有隐私相关问题，请联系：1218478630@qq.com</p>'

const USER_AGREEMENT_HTML: string =
  '<h2>用户协议</h2>' +
  '<p>更新时间：2026年5月</p>' +
  '<p>欢迎使用WlAN-分析仪。使用本应用即表示您同意以下条款。</p>' +
  '<h3>1. 服务说明</h3>' +
  '<p>本应用提供WiFi扫描、网络诊断、信号分析等功能。功能仅限个人学习研究使用。</p>' +
  '<h3>2. 使用规范</h3>' +
  '<ul>' +
  '<li>不得将本应用用于任何非法目的</li>' +
  '<li>不得破解、反编译或修改本应用</li>' +
  '<li>不得利用本应用进行网络攻击或侵犯他人权益</li>' +
  '</ul>' +
  '<h3>3. 免责声明</h3>' +
  '<p>本应用按"现状"提供，不保证功能完全无间断或错误。在法律允许的范围内，开发者不承担任何间接损失责任。</p>' +
  '<h3>4. 知识产权</h3>' +
  '<p>本应用及其所有内容的知识产权归开发者所有。</p>' +
  '<h3>5. 协议变更</h3>' +
  '<p>我们可能适时修改本协议，修改后的协议一经发布即生效。</p>'

const FEEDBACK_HTML: string =
  '<h2>意见反馈</h2>' +
  '<p>感谢您使用WlAN-分析仪！</p>' +
  '<h3>联系方式</h3>' +
  '<ul>' +
  '<li>邮箱：1218478630@qq.com</li>' +
  '<li>GitHub：xinxinl6/wifi-analyzer</li>' +
  '</ul>' +
  '<h3>功能建议</h3>' +
  '<p>如您有新功能想法或改进建议，欢迎通过以上方式联系我们。我们非常重视每个用户的反馈意见。</p>' +
  '<h3>问题反馈</h3>' +
  '<p>如果遇到Bug或异常情况，请提供以下信息：</p>' +
  '<ul>' +
  '<li>设备型号与系统版本</li>' +
  '<li>问题发生的具体操作步骤</li>' +
  '<li>错误截图（如有）</li>' +
  '</ul>'

// 协议内容纯文本版本
const PRIVACY_TEXT: string =
  '隐私政策\n\n' +
  '更新时间：2026年5月\n\n' +
  'WlAN-分析仪（以下简称"本应用"）尊重并保护用户隐私。本隐私政策将说明我们如何收集、使用和保护您的个人信息。\n\n' +
  '1. 信息收集\n' +
  '本应用仅在您主动授权的情况下收集以下信息：\n' +
  '• 位置信息：用于扫描附近的WiFi网络（HarmonyOS系统要求）\n' +
  '• WiFi信息：用于显示网络状态、信号强度、信道分析\n\n' +
  '2. 信息使用\n' +
  '收集的信息仅用于本应用内的功能展示，不会上传至任何服务器。\n\n' +
  '3. 数据存储\n' +
  '所有数据仅存储在您的设备本地，不会传输到外部。\n\n' +
  '4. 第三方服务\n' +
  '本应用不集成任何第三方分析或广告SDK。\n\n' +
  '5. 联系我们\n' +
  '如有隐私相关问题，请联系：1218478630@qq.com'

const AGREEMENT_TEXT: string =
  '用户协议\n\n' +
  '更新时间：2026年5月\n\n' +
  '欢迎使用WlAN-分析仪。使用本应用即表示您同意以下条款。\n\n' +
  '1. 服务说明\n' +
  '本应用提供WiFi扫描、网络诊断、信号分析等功能。功能仅限个人学习研究使用。\n\n' +
  '2. 使用规范\n' +
  '• 不得将本应用用于任何非法目的\n' +
  '• 不得破解、反编译或修改本应用\n' +
  '• 不得利用本应用进行网络攻击或侵犯他人权益\n\n' +
  '3. 免责声明\n' +
  '本应用按"现状"提供，不保证功能完全无间断或错误。在法律允许的范围内，开发者不承担任何间接损失责任。\n\n' +
  '4. 知识产权\n' +
  '本应用及其所有内容的知识产权归开发者所有。\n\n' +
  '5. 协议变更\n' +
  '我们可能适时修改本协议，修改后的协议一经发布即生效。'

const FEEDBACK_TEXT: string =
  '意见反馈\n\n' +
  '感谢您使用WlAN-分析仪！\n\n' +
  '联系方式\n' +
  '• 邮箱：1218478630@qq.com\n' +
  '• GitHub：xinxinl6/wifi-analyzer\n\n' +
  '功能建议\n' +
  '如您有新功能想法或改进建议，欢迎通过以上方式联系我们。我们非常重视每个用户的反馈意见。\n\n' +
  '问题反馈\n' +
  '如果遇到Bug或异常情况，请提供以下信息：\n' +
  '• 设备型号与系统版本\n' +
  '• 问题发生的具体操作步骤\n' +
  '• 错误截图（如有）'

// ==================== 列表项接口 ====================
interface AboutListItem {
  label: Resource | string
  value: Resource | string
  action: string
  showArrow: boolean
}

// ==================== 通用协议弹窗组件 ====================
@CustomDialog
struct AgreementDialog {
  @Consume isDarkMode: boolean = false
  controller: CustomDialogController = new CustomDialogController({ builder: '' })
  dialogTitle: string = ''
  plainTextContent: string = ''

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.dialogTitle)
          .fontSize(FONT_SIZE_LG)
          .fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
        Blank()
        Text('×')
          .fontSize(28)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
          .onClick(() => { this.controller.close() })
      }
      .width('100%')
      .padding({ left: SPACE_LG, right: SPACE_SM, top: SPACE_LG, bottom: SPACE_MD })

      Divider()
        .color(adaptiveDivider(this.isDarkMode))
        .strokeWidth(0.5)

      // 内容区域 - 使用 Text 组件显示纯文本
      Scroll() {
        Text(this.plainTextContent)
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextSecondary(this.isDarkMode))
          .width('100%')
          .lineHeight(24)
      }
      .width('100%')
      .layoutWeight(1)
      .padding(SPACE_LG)
    }
    .width('90%')
    .height('70%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(RADIUS_LG)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_XL, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 8 })
    .clip(true)
  }
}

// ==================== 组件 ====================
@Component
export struct AboutPage {
  @Consume isDarkMode: boolean = false

  // 应用版本信息
  private appVersion: string = 'v1.0.1'
  private buildNumber: string = '1000001'

  // 弹窗控制器
  @State dialogController: CustomDialogController | null = null
  @State dialogTitle: string = ''
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
                  .shadow({ radius: 16, color: '#1A0066FF', offsetX: 0, offsetY: 4 })
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
                  .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.60)')
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
            .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(74,144,217,0.10)', offsetX: 0, offsetY: 4 })
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
      this.dialogTitle = '隐私政策'
      this.dialogTextContent = PRIVACY_TEXT
      this.showDialog()
    } else if (action === 'agreement') {
      // 用户协议弹窗
      this.dialogTitle = '用户协议'
      this.dialogTextContent = AGREEMENT_TEXT
      this.showDialog()
    } else if (action === 'feedback') {
      // 意见反馈弹窗
      this.dialogTitle = '意见反馈'
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
