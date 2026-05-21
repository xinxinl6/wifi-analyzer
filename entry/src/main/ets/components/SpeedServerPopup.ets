// SpeedServerPopup.ets - 测速节点选择弹窗组件
// 提取自 SpeedTestSection.ets

import {
  COLOR_SKY_BLUE,
  COLOR_SKY_BLUE_LIGHT,
  COLOR_GLASS_SKY_ACTIVE,
  COLOR_SKY_BLUE_DIVIDER,
  COLOR_TEXT_TERTIARY,
  FONT_SIZE_MD,
  FONT_SIZE_2XL,
  FONT_SIZE_3XL,
  FONT_SIZE_XL,
  FONT_SIZE_LG,
  SPACE_SM,
  GLASS_BLUR_LG,
  GLASS_BLUR_XL,
  GLASS_SHADOW_XL,
  GLASS_SHADOW_2XL,
  GLASS_BLUR_MD,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_WHITE,
  COLOR_GLASS_SKY_TAG_BG,
  COLOR_GLASS_BORDER,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_OVERLAY,
  COLOR_MODAL_OVERLAY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_GLASS_SKY,
  COLOR_SHADOW_GLASS
} from '@wifi-analyzer/design-system'
import { SERVER_NODES, ServerNode } from '@wifi-analyzer/speed-test'

// 节点选择器 - 天蓝色毛玻璃
@Component
export struct SpeedServerSelector {
  @Prop selectedServerIndex: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onServerSelectorClick: () => void = () => {}

  build() {
    Row({ space: 12 }) {
      Column() {
        Text('📡').fontSize(FONT_SIZE_3XL)
      }
      .width(42).height(42)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_ACTIVE)
      .borderRadius(14)

      Column({ space: 4 }) {
        Text($r('app.string.select_speed_server')).fontSize(FONT_SIZE_2XL).fontColor(adaptiveTextSecondary(this.isDarkMode))
        Text(this.getServerName()).fontSize(FONT_SIZE_3XL).fontWeight(FontWeight.Medium).fontColor(adaptiveTextPrimary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text('›').fontSize(FONT_SIZE_3XL).fontColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_SKY_BLUE)
      }
      .width(28).height(28)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(8)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_ACTIVE, offsetX: 0, offsetY: 4 })
    .backdropBlur(GLASS_BLUR_LG)
    .borderWidth(1)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER_LIGHT)
    .onClick(() => { this.onServerSelectorClick() })
  }

  private getServerName(): string | Resource {
    if (this.selectedServerIndex < SERVER_NODES.length) {
      return SERVER_NODES[this.selectedServerIndex].name
    }
    return $r('app.string.unknown')
  }
}

// 节点选择弹窗 - WiFi详细卡片样式 + 线性弹出动画
@Component
export struct SpeedServerPopup {
  @Prop selectedServerIndex: number = 0
  @Prop serverPopupScale: number = 0
  @Prop serverPopupOpacity: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onClose: () => void = () => {}
  onServerSelect: (index: number) => void = () => {}

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%').height('100%')
        .backgroundColor(this.isDarkMode ? COLOR_OVERLAY : COLOR_MODAL_OVERLAY)
        .opacity(this.serverPopupOpacity)
        .onClick(() => { this.onClose() })

      // 弹窗内容 - 线性缩放动画，居中显示
      Column() {
        // 拖动手柄
        Column().width(36).height(4).backgroundColor(this.isDarkMode ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_AURORA).borderRadius(2)
          .margin({ top: 12, bottom: 14 })

        // 标题栏
        Row() {
          Text($r('app.string.select_speed_server'))
            .fontSize(FONT_SIZE_3XL).fontWeight(FontWeight.Bold).fontColor(adaptiveTextPrimary(this.isDarkMode))
          Blank()
          Column() {
            Text('✕').fontSize(FONT_SIZE_2XL).fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_SKY_BLUE)
          }
          .width(36).height(36)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.isDarkMode ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(10)
          .onClick(() => { this.onClose() })
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 14 })

        Column().width('100%').height(0.5).backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_AURORA)

        // 节点列表
        Scroll() {
          Column({ space: 3 }) {
            ForEach(SERVER_NODES, (server: ServerNode, index: number) => {
              Row() {
                // 选中指示竖线
                Column().width(4).height(24).borderRadius(2)
                  .backgroundColor(index === this.selectedServerIndex ? COLOR_SKY_BLUE : 'transparent')
                  .margin({ right: 12 })
                Text(server.name)
                  .fontSize(FONT_SIZE_2XL)
                  .fontColor(index === this.selectedServerIndex ? COLOR_SKY_BLUE : adaptiveTextPrimary(this.isDarkMode))
                  .layoutWeight(1)
                if (server.latencyMs > 0) {
                  Text(server.latencyMs + 'ms')
                    .fontSize(FONT_SIZE_MD).fontColor(adaptiveTextTertiary(this.isDarkMode))
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor(this.isDarkMode ? COLOR_GLASS_AURORA_LIGHT : COLOR_GLASS_SKY_TAG_BG)
                    .borderRadius(8)
                    .margin({ right: 8 })
                }
                if (index === this.selectedServerIndex) {
                  Text('✓').fontSize(FONT_SIZE_XL).fontColor(this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_SKY_BLUE).fontWeight(FontWeight.Bold)
                }
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 12, right: 16 })
              .backgroundColor(index === this.selectedServerIndex ? (this.isDarkMode ? COLOR_GLASS_AURORA : COLOR_GLASS_SKY_ACTIVE) : 'transparent')
              .borderRadius(12)
              .onClick(() => {
                this.onServerSelect(index)
              })
            }, (server: ServerNode): string => server.id)
          }
          .padding({ left: 12, right: 12, top: 10, bottom: 24 })
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .width('100%')
      }
      .width('88%')
      .constraintSize({ maxHeight: '55%' })
      // WiFi 详细卡片样式：半透明白色 + 毛玻璃边框 + 阴影
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(20)
      .shadow({ radius: 8, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 2 })
      .backdropBlur(10)
      .borderWidth(1)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      // 线性弹出动画：中心缩放
      .scale({ x: this.serverPopupScale, y: this.serverPopupScale, centerX: '50%', centerY: '50%' })
    }
  }
}
