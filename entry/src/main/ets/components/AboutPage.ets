// 关于页面 — 参考爱快风格：应用图标 + 版本 + 功能列表 + 底部信息
import {
  COLOR_PRIMARY, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_SURFACE, COLOR_BACKGROUND, COLOR_BORDER, COLOR_DIVIDER,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XS, SPACE_SM, SPACE_MD, SPACE_LG, SPACE_XL,
  RADIUS_MD, RADIUS_LG, SAFE_AREA_BOTTOM
} from '@wifi-analyzer/design-system'
import { RouterManager } from '@wifi-analyzer/core'

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
  // 应用版本信息
  private appVersion: string = 'v1.0.1'
  private buildNumber: string = '1000001'

  // 列表数据
  private listItems: AboutListItem[] = [
    { label: $r('app.string.check_update'), value: '', action: 'checkUpdate', showArrow: true },
    { label: $r('app.string.privacy_policy'), value: '', action: 'privacy', showArrow: true },
    { label: $r('app.string.user_agreement'), value: '', action: 'agreement', showArrow: true },
    { label: $r('app.string.feedback'), value: '', action: 'feedback', showArrow: true },
  ]

  // ==================== 构建 ====================
  build() {
    Column() {
      // 顶部返回按钮栏
      Row() {
        Row() {
          Text('←')
            .fontSize(20)
            .fontColor(COLOR_PRIMARY)
          Text($r('app.string.back'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(COLOR_PRIMARY)
            .fontWeight(FONT_WEIGHT_MEDIUM)
        }
        .padding({ left: 4, right: 12, top: 6, bottom: 6 })
        .borderRadius(20)
        .backgroundColor(COLOR_SURFACE)
        .onClick(() => RouterManager.goBack())

        Blank()
      }
      .width('100%')
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: SAFE_AREA_BOTTOM })
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
              .fontColor(COLOR_TEXT_PRIMARY)

            // 版本号
            Text() {
              Span($r('app.string.version_prefix'))
              Span(' ' + this.appVersion)
            }
              .fontSize(FONT_SIZE_SM)
              .fontColor(COLOR_TEXT_TERTIARY)
              .margin({ bottom: 32 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(COLOR_BACKGROUND)

          // ===== 功能列表区域 =====
          Column({ space: 0 }) {
            ForEach(this.listItems, (item: AboutListItem, index: number) => {
              Column() {
                Row() {
                  Text(item.label)
                    .fontSize(FONT_SIZE_MD)
                    .fontColor(COLOR_TEXT_PRIMARY)
                    .layoutWeight(1)

                  if (item.value !== '') {
                    Text(item.value)
                      .fontSize(FONT_SIZE_SM)
                      .fontColor(COLOR_TEXT_TERTIARY)
                      .margin({ right: 4 })
                  }

                  if (item.showArrow) {
                    Image($r('app.media.ic_arrow_right'))
                      .width(16)
                      .height(16)
                      .fillColor(COLOR_TEXT_TERTIARY)
                  }
                }
                .width('100%')
                .height(52)
                .padding({ left: SPACE_LG, right: SPACE_LG })
                .backgroundColor(COLOR_SURFACE)
                .onClick(() => { this.onItemClick(item.action) })

                // 分割线（最后一项不显示）
                if (index < this.listItems.length - 1) {
                  Divider()
                    .color(COLOR_DIVIDER)
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
              .fontColor(COLOR_TEXT_TERTIARY)
              .textAlign(TextAlign.Center)

            Text() {
              Span($r('app.string.build_number'))
              Span(': ' + this.buildNumber)
            }
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_TEXT_TERTIARY)
              .textAlign(TextAlign.Center)

            Text($r('app.string.copyright'))
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_TEXT_TERTIARY)
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
      .backgroundColor(COLOR_BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_BACKGROUND)
  }

  // ==================== 列表项点击 ====================
  onItemClick(action: string): void {
    if (action === 'checkUpdate') {
      // TODO: 检查更新
    } else if (action === 'privacy') {
      // TODO: 隐私政策
    } else if (action === 'agreement') {
      // TODO: 用户协议
    } else if (action === 'feedback') {
      // TODO: 意见反馈
    }
  }
}
