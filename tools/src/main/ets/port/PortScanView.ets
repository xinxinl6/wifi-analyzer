// 端口扫描视图组件

import {
  COLOR_PRIMARY, COLOR_SUCCESS, COLOR_DANGER, COLOR_WARNING, COLOR_INFO, COLOR_PURPLE,
  COLOR_TEXT_PRIMARY, COLOR_TEXT_TERTIARY, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_SM, SPACE_MD, SPACE_LG,
  GLASS_BLUR_LG,
  GLASS_SHADOW_SM, GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_BORDER,
  COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_ACTIVE,
  COLOR_GLASS_SKY_SHADOW_MED,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider
} from '@wifi-analyzer/design-system'

// 端口扫描结果接口
export interface PortScanResult {
  port: number
  service: string
  status: 'open' | 'closed' | 'filtered' | 'unknown'
}

@Component
export struct PortScanView {
  @Prop isDarkMode: boolean = false
  @Prop inputText: string = ''
  @Prop isScanning: boolean = false
  @Prop viewMode: string = 'idle'
  @Prop scannedCount: number = 0
  @Prop totalPorts: number = 0
  @Prop currentPort: number = 0
  @Prop openPorts: PortScanResult[] = []
  @Prop pulseOpacity: number = 1.0

  onGoBack: () => void = () => {}
  onStop: () => void = () => {}
  onRestart: () => void = () => {}

  getProgressPercent(): number {
    if (this.totalPorts === 0) return 0
    return Math.round((this.scannedCount / this.totalPorts) * 100)
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'open': return COLOR_SUCCESS
      case 'closed': return COLOR_DANGER
      case 'filtered': return COLOR_WARNING
      default: return COLOR_TEXT_TERTIARY
    }
  }

  getStatusText(status: string): string | Resource {
    switch (status) {
      case 'open': return $r('app.string.port_status_open_label')
      case 'closed': return $r('app.string.port_status_closed_label')
      case 'filtered': return $r('app.string.port_status_filtered_label')
      default: return $r('app.string.port_status_unknown_label')
    }
  }

  build() {
    Scroll() {
      Column({ space: SPACE_LG }) {
        this.TargetInfoCard()
        if (this.isScanning) {
          this.ProgressCard()
        }
        if (this.openPorts.length > 0) {
          this.OpenPortsCard()
        }
      }
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_MD, bottom: 100 })
      .width('100%')
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }

  // 目标信息卡
  @Builder TargetInfoCard() {
    Row({ space: SPACE_MD }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle().width(44).height(44)
          .fill(this.isDarkMode ? COLOR_PURPLE : COLOR_GLASS_SKY_LIGHT)
          .opacity(this.isScanning ? this.pulseOpacity : 1.0)
        Circle().width(36).height(36)
          .fill(COLOR_PURPLE)
        Image($r('app.media.ic_port')).width(18).height(18).fillColor(adaptiveTextPrimary(this.isDarkMode))
      }

      Column({ space: 4 }) {
        Text(this.inputText)
          .fontSize(FONT_SIZE_LG)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.isScanning) {
          Row({ space: 4 }) {
            Circle().width(5).height(5).fill(COLOR_PURPLE).opacity(this.pulseOpacity)
            Text($r('app.string.scanning_ports'))
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_PURPLE)
          }
        } else if (this.viewMode === 'result') {
          Row({ space: 4 }) {
            Circle().width(5).height(5).fill(COLOR_SUCCESS)
            Text($r('app.string.scan_complete'))
              .fontSize(FONT_SIZE_XS)
              .fontColor(COLOR_SUCCESS)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // 进度卡片
  @Builder ProgressCard() {
    Column({ space: SPACE_MD }) {
      Row() {
        Text($r('app.string.scan_progress'))
          .fontSize(FONT_SIZE_MD)
          .fontColor(adaptiveTextPrimary(this.isDarkMode))
          .fontWeight(FONT_WEIGHT_BOLD)
        Blank()
        Text(String(this.scannedCount) + '/' + String(this.totalPorts))
          .fontSize(FONT_SIZE_XS)
          .fontColor(COLOR_PURPLE)
      }
      .width('100%')

      // 进度条
      Row() {
        Column()
          .height(6)
          .borderRadius(3)
          .backgroundColor(COLOR_PURPLE)
          .width(String(this.getProgressPercent()) + '%')
        Blank()
      }
      .width('100%')
      .height(6)
      .borderRadius(3)
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)

      Text($r('app.string.current_port') + ': ' + (this.currentPort > 0 ? String(this.currentPort) : '...'))
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
  }

  // 开放端口列表
  @Builder OpenPortsCard() {
    Column({ space: 0 }) {
      Row() {
        Row({ space: 6 }) {
          Text('📊').fontSize(14)
          Text($r('app.string.open_ports'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
            .fontWeight(FONT_WEIGHT_BOLD)
        }
        Blank()
        Text() {
          Span(String(this.openPorts.length))
          Span(' ')
          Span($r('app.string.port_count_ports'))
        }
        .fontSize(FONT_SIZE_XS)
        .fontColor(COLOR_SUCCESS)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .backgroundColor(this.isDarkMode ? 'rgba(16,185,129,0.15)' : COLOR_GLASS_SKY_TAG_BG)
        .borderRadius(999)
      }
      .width('100%')
      .padding({ left: 16, right: 14, top: 14, bottom: 12 })

      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))

      Column({ space: 0 }) {
        ForEach(this.openPorts, (port: PortScanResult, index: number) => {
          this.PortItem(port, index)
        }, (port: PortScanResult, index: number): string => String(index + '_' + port.port))
      }
      .padding({ left: 14, right: 14, top: 8, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }

  @Builder PortItem(port: PortScanResult, index: number) {
    Row({ space: SPACE_SM }) {
      Text(String(port.port))
        .fontSize(FONT_SIZE_SM)
        .fontColor(COLOR_PURPLE)
        .fontWeight(FONT_WEIGHT_BOLD)
        .width(50)
        .textAlign(TextAlign.Center)

      Text(port.service)
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.getStatusText(port.status))
        .fontSize(FONT_SIZE_XS)
        .fontColor(this.getStatusColor(port.status))
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })

    if (index < this.openPorts.length - 1) {
      Column().width('100%').height(0.5).backgroundColor(adaptiveDivider(this.isDarkMode))
    }
  }
}
