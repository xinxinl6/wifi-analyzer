// SpeedDetailPopup.ets - 测速详情弹窗和详情卡片组件
// 提取自 SpeedTestSection.ets

import {
  COLOR_SUCCESS,
  COLOR_WARNING,
  COLOR_DANGER,
  COLOR_SKY_BLUE,
  COLOR_SKY_BLUE_LIGHT,
  COLOR_GLASS_SKY_ACTIVE,
  COLOR_SKY_BLUE_DIVIDER,
  FONT_SIZE_MD,
  FONT_SIZE_XS,
  FONT_SIZE_SM,
  FONT_SIZE_LG,
  FONT_SIZE_2XL,
  FONT_SIZE_3XL,
  FONT_SIZE_4XL,
  SPACE_SM,
  SPACE_MD,
  SPACE_LG,
  SPACE_XL,
  SPACE_2XL,
  GLASS_BLUR_XL,
  GLASS_SHADOW_2XL,
  GLASS_SHADOW_XL,
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
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_GLASS_SURFACE_LIGHT,
  COLOR_SHADOW_GLASS
} from '@wifi-analyzer/design-system'
import { SpeedTestResult } from '@wifi-analyzer/core'
import { getPingColor } from '../utils/SpeedTestHelper'

// 测速详情弹窗 - 天蓝色毛玻璃风格
@Component
export struct SpeedDetailPopup {
  @Prop selectedResult: SpeedTestResult | null = null
  @Prop detailPopupScale: number = 0
  @Prop detailPopupOpacity: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onClose: () => void = () => {}

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%').height('100%')
        .backgroundColor(this.isDarkMode ? COLOR_OVERLAY : COLOR_MODAL_OVERLAY)
        .opacity(this.detailPopupOpacity)
        .onClick(() => { this.onClose() })

      // 弹窗内容
      Column({ space: 16 }) {
        // 拖动手柄
        Column().width(36).height(4).backgroundColor(this.isDarkMode ? COLOR_GLASS_SURFACE_LIGHT : COLOR_GLASS_AURORA).borderRadius(2)
          .margin({ top: 12, bottom: 8 })

        // 标题栏
        Row() {
          Row({ space: 8 }) {
            Text('📊').fontSize(FONT_SIZE_3XL)
            Text($r('app.string.speed_detail')).fontSize(FONT_SIZE_3XL).fontWeight(FontWeight.Bold).fontColor(adaptiveTextPrimary(this.isDarkMode))
          }
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
        .padding({ left: 18, right: 18, bottom: 8 })

        Column().width('100%').height(0.5).backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_AURORA)

        // 主要内容 - 可滚动
        Scroll() {
          Column({ space: 18 }) {
            // 下载速度
            this.buildDetailItem($r('app.string.speed_download_detail'),
              this.selectedResult ? this.selectedResult.downloadSpeed.toFixed(1) : '0.0',
              'Mbps',
              COLOR_SKY_BLUE)

            // 上传速度
            this.buildDetailItem($r('app.string.speed_upload_detail'),
              this.selectedResult ? this.selectedResult.uploadSpeed.toFixed(1) : '0.0',
              'Mbps',
              COLOR_SUCCESS)

            // Ping 延迟
            this.buildDetailItem($r('app.string.speed_ping_detail'),
              this.selectedResult ? this.selectedResult.pingMs.toFixed(0) : '0',
              'ms',
              COLOR_WARNING)

            // Jitter 抖动
            this.buildDetailItem($r('app.string.speed_jitter_detail'),
              this.selectedResult ? this.selectedResult.jitterMs.toFixed(0) : '0',
              'ms',
              COLOR_SKY_BLUE_LIGHT)

            // 测试时间
            if (this.selectedResult) {
              this.buildDetailItem($r('app.string.speed_test_time'),
                this.selectedResult.timeLabel || $r('app.string.unknown'),
                '',
                adaptiveTextSecondary(this.isDarkMode))
            }

            // 服务器
            if (this.selectedResult && this.selectedResult.serverName) {
              this.buildDetailItem($r('app.string.speed_test_server'),
                this.selectedResult.serverName,
                '',
                adaptiveTextSecondary(this.isDarkMode))
            }

            // Bufferbloat
            if (this.selectedResult && this.selectedResult.bufferbloatDownloadMs > 0) {
              this.buildDetailItem('缓冲膨胀 ↓',
                '+' + this.selectedResult.bufferbloatDownloadMs.toString() + 'ms',
                '',
                this.selectedResult.bufferbloatDownloadMs > 50 ? COLOR_DANGER : COLOR_WARNING)
            }
          }
          .padding({ left: 18, right: 18, top: 10, bottom: 24 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      }
      .width('88%')
      .constraintSize({ maxHeight: '65%' })
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
      .borderRadius(20)
      .shadow({ radius: 8, color: COLOR_SHADOW_GLASS, offsetX: 0, offsetY: 2 })
      .backdropBlur(10)
      .borderWidth(1)
      .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
      .scale({ x: this.detailPopupScale, y: this.detailPopupScale, centerX: '50%', centerY: '50%' })
    }
  }

  @Builder buildDetailItem(label: string | Resource, value: string | Resource, unit: string, valueColor: string) {
    Column({ space: 6 }) {
      Text(label).fontSize(FONT_SIZE_MD).fontColor(adaptiveTextTertiary(this.isDarkMode))
      Row({ space: 6 }) {
        Text(value).fontSize(FONT_SIZE_4XL).fontWeight(FontWeight.Bold).fontColor(valueColor)
        if (unit.length > 0) {
          Text(unit).fontSize(FONT_SIZE_LG).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 10, bottom: 10 })
  }
}

// 详情卡片 - 天蓝色毛玻璃
@Component
export struct SpeedDetailCard {
  @Prop displayDownloadSpeed: number = 0
  @Prop displayUploadSpeed: number = 0
  @Prop displayPing: number = 0
  @Prop serverName: string | Resource = ''
  @Prop bufferbloatDownloadMs: number = 0
  @Prop bufferbloatUploadMs: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column({ space: 16 }) {
      Row() {
        Row({ space: 8 }) {
          Circle().width(8).height(8).fill(COLOR_SUCCESS)
          Text($r('app.string.test_result')).fontSize(FONT_SIZE_3XL).fontWeight(FontWeight.Bold).fontColor(adaptiveTextPrimary(this.isDarkMode))
        }
        Text(this.serverName).fontSize(FONT_SIZE_LG).fontColor(adaptiveTextSecondary(this.isDarkMode))
      }.width('100%').justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Column({ space: 4 }) {
          Text($r('app.string.download')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
          Text(this.displayDownloadSpeed > 0 ? this.displayDownloadSpeed.toFixed(1) : '--')
            .fontSize(32).fontWeight(FontWeight.Bold).fontColor(COLOR_SKY_BLUE)
          Text('Mbps').fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text($r('app.string.upload')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
          Text(this.displayUploadSpeed > 0 ? this.displayUploadSpeed.toFixed(1) : '--')
            .fontSize(32).fontWeight(FontWeight.Bold).fontColor(COLOR_SUCCESS)
          Text('Mbps').fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text($r('app.string.ping')).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
          Text(this.displayPing > 0 ? this.displayPing.toFixed(0) : '--')
            .fontSize(32).fontWeight(FontWeight.Bold).fontColor(getPingColor(this.displayPing))
          Text('ms').fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      }.width('100%')

      // Bufferbloat 行（下载满载延迟）
      if (this.bufferbloatDownloadMs > 0) {
        Row() {
          Text('缓冲膨胀 ↓')
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
          Text('+' + this.bufferbloatDownloadMs.toFixed(0) + 'ms')
            .fontSize(FONT_SIZE_SM)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.bufferbloatDownloadMs > 50 ? COLOR_DANGER : COLOR_WARNING)
        }
        .padding({ top: 4 })
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(20)
    .shadow({ radius: GLASS_SHADOW_2XL, color: this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_ACTIVE, offsetX: 0, offsetY: 4 })
    .backdropBlur(GLASS_BLUR_XL)
    .borderWidth(1)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
  }
}
