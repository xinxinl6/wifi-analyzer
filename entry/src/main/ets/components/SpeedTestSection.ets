// 测速页组件 - 天蓝色透明毛玻璃悬浮风格
// 功能：测速节点选择、真实HTTP测速、实时速度显示、历史记录
// 风格：天蓝色渐变 + 透明毛玻璃 + 悬浮卡片

import { COLOR_SUCCESS, COLOR_WARNING, COLOR_DANGER,
  COLOR_BACKGROUND, COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_SKY_BLUE, COLOR_SKY_BLUE_LIGHT, COLOR_SKY_BLUE_GAUGE_BG, COLOR_SKY_BLUE_DIVIDER,
  COLOR_GLASS_WHITE, COLOR_GLASS_WHITE_SOLID, COLOR_GLASS_SKY,
  COLOR_GLASS_SKY_SOLID, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  COLOR_GLASS_SKY_ACTIVE, COLOR_GLASS_SKY_TAG_BG, COLOR_GLASS_SKY_TAG_BORDER,
  COLOR_CLOUD_1, COLOR_CLOUD_2,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL, FONT_SIZE_2XL, FONT_SIZE_3XL, FONT_SIZE_4XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD, FONT_WEIGHT_NORMAL,
  SPACE_MD, SPACE_SM, SPACE_LG, SPACE_XL, SPACE_2XL,
  GAUGE_SIZE_XL, STROKE_WIDTH_3XL,
  RADIUS_SM, RADIUS_MD, RADIUS_LG, RADIUS_XL, RADIUS_2XL, RADIUS_3XL,
  GLASS_BLUR_LG, GLASS_BLUR_XL, GLASS_BLUR_MAX,
  GLASS_SHADOW_SM, GLASS_SHADOW_MD, GLASS_SHADOW_LG, GLASS_SHADOW_XL,
  GLASS_SHADOW_2XL, GLASS_SHADOW_3XL, GLASS_SHADOW_MAX,
  TAB_BAR_SAFE_BOTTOM,
  // 暗色模式自适应工具
  adaptiveBackgroundList,
  adaptiveGlowLarge,
  adaptiveGlowMedium,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_GLASS_DARK_SURFACE,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER } from '@wifi-analyzer/design-system'
import { SpeedTestResult } from '@wifi-analyzer/core'
import { SpeedTestEngine, SERVER_NODES, SpeedTestCallbacks, ServerNode } from '@wifi-analyzer/speed-test'

@Component
export struct SpeedTestSection {
  // 状态
  @Consume('isDarkMode') isDarkMode: boolean
  @State selectedServerIndex: number = 0
  @State showServerPanel: boolean = false
  @State serverPopupScale: number = 0
  @State serverPopupOpacity: number = 0
  @State isTesting: boolean = false
  @State currentPhase: string = 'idle'
  @State displaySpeed: number = 0
  @State displayPing: number = 0
  @State displayJitter: number = 0
  @State displayDownloadSpeed: number = 0
  @State displayUploadSpeed: number = 0
  @State phaseLabel: string = ''
  @State gaugeProgress: number = 0
  @State historyList: Array<SpeedTestResult> = []

  private engine: SpeedTestEngine = new SpeedTestEngine()

  aboutToAppear(): void {
    this.loadHistory()
  }

  aboutToDisappear(): void {
    // 防止测速中离开页面导致内存泄漏
    if (this.isTesting && this.engine.running) {
      console.info('[SpeedTest] Component destroyed, cancelling test')
      this.engine.cancel()
    }
  }

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

      // 主内容
      Column({ space: SPACE_LG }) {
        this.buildServerSelector()
        this.buildGaugeCard()
        this.buildActionButton()
        if (this.currentPhase === 'done') {
          this.buildDetailCard()
        }
        if (!this.isTesting) {
          this.buildHistoryCard()
        }
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: SPACE_LG, right: SPACE_LG, top: SPACE_LG, bottom: TAB_BAR_SAFE_BOTTOM })
      .width('100%')
      .layoutWeight(1)

      if (this.showServerPanel) {
        this.buildServerPopup()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 节点选择器 - 天蓝色毛玻璃
  @Builder buildServerSelector() {
    Row({ space: 12 }) {
      Column() {
        Text('📡').fontSize(FONT_SIZE_4XL)
      }
      .width(42).height(42)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,0.20)' : COLOR_GLASS_SKY_ACTIVE)
      .borderRadius(14)

      Column({ space: 4 }) {
        Text($r('app.string.select_speed_server')).fontSize(FONT_SIZE_LG).fontColor(adaptiveTextSecondary(this.isDarkMode))
        Text(this.getServerName()).fontSize(FONT_SIZE_2XL).fontWeight(FONT_WEIGHT_MEDIUM).fontColor(adaptiveTextPrimary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text('›').fontSize(FONT_SIZE_3XL).fontColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_SKY_BLUE)
      }
      .width(28).height(28)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,0.15)' : COLOR_GLASS_SKY_TAG_BG)
      .borderRadius(8)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_ACTIVE, offsetX: 0, offsetY: 4 })
    .backdropBlur(GLASS_BLUR_LG)
    .borderWidth(1)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : 'rgba(255,255,255,0.6)')
    .onClick(() => { this.showServerPanelWithAnimation() })
  }

  // 测速仪表盘 - 天蓝色渐变毛玻璃
  @Builder buildGaugeCard() {
    Column({ space: 0 }) {
      Column({ space: 0 }) {
        // 顶部状态标签
        Row() {
          if (this.isTesting && this.phaseLabel.length > 0) {
            Row({ space: 6 }) {
              Circle().width(6).height(6).fill(this.getGaugeColor())
              Text(this.getSpeedLabelResource()).fontSize(FONT_SIZE_LG).fontColor(COLOR_SKY_BLUE)
            }
          } else if (this.currentPhase === 'done') {
            Row({ space: 6 }) {
              Circle().width(6).height(6).fill(COLOR_SUCCESS)
              Text($r('app.string.speed_test_complete')).fontSize(FONT_SIZE_LG).fontColor(COLOR_SKY_BLUE)
            }
          } else {
            Text($r('app.string.speed_test_title')).fontSize(FONT_SIZE_LG).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 24, bottom: 16 })

        // 仪表盘主体
        Stack() {
          // 外圈渐变背景
          Circle().width(GAUGE_SIZE_XL).height(GAUGE_SIZE_XL)
            .fill(this.isDarkMode ? 'rgba(74,144,217,0.12)' : COLOR_SKY_BLUE_GAUGE_BG)

          // 背景轨道
          Circle().width(GAUGE_SIZE_XL - 16).height(GAUGE_SIZE_XL - 16)
            .fill(this.isDarkMode ? 'rgba(20,38,72,0.90)' : 'rgba(255,255,255,0.90)')
            .strokeWidth(1)
            .stroke(COLOR_SKY_BLUE_DIVIDER)

          // 进度弧
          Circle().width(GAUGE_SIZE_XL - 16).height(GAUGE_SIZE_XL - 16)
            .fillOpacity(0)
            .stroke(this.getGaugeColor())
            .strokeWidth(STROKE_WIDTH_3XL)
            .strokeDashArray([this.getGaugeArcLength(), 400])
            .rotate({ angle: -90 })
            .shadow({ radius: GLASS_SHADOW_MD, color: this.getGaugeShadowColor(), offsetX: 0, offsetY: 0 })

          // 中心数值
          Column({ space: 4 }) {
            Text(this.currentPhase === 'ping' ? 'ms' : 'Mbps')
              .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).letterSpacing(3)
            Text(this.formatDisplaySpeed())
              .fontSize(58).fontWeight(FontWeight.Bold).fontColor(COLOR_SKY_BLUE).letterSpacing(-2)
            Text(this.getSpeedLabelResource())
              .fontSize(FONT_SIZE_XL).fontColor(adaptiveTextSecondary(this.isDarkMode))
          }
        }
        .width(GAUGE_SIZE_XL).height(GAUGE_SIZE_XL).margin({ top: 10, bottom: 10 })

        // 下方实时数据（测速中或完成时显示）
        if (this.isTesting || this.currentPhase === 'done') {
          Row() {
            // 下载速度
            Column({ space: SPACE_SM }) {
              Text(this.displayDownloadSpeed > 0 ? this.displayDownloadSpeed.toFixed(1) : '--')
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.currentPhase === 'download' ? COLOR_SKY_BLUE : adaptiveTextPrimary(this.isDarkMode))
              Row({ space: 3 }) {
                Text('↓').fontSize(FONT_SIZE_XS).fontColor(COLOR_SKY_BLUE)
                Text('Mbps').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)

            Column().width(1).height(44).backgroundColor(COLOR_SKY_BLUE_DIVIDER)

            // 延迟
            Column({ space: SPACE_SM }) {
              Text(this.displayPing > 0 ? this.displayPing.toFixed(0) : '--')
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.currentPhase === 'ping' ? COLOR_WARNING : adaptiveTextPrimary(this.isDarkMode))
              Row({ space: 3 }) {
                Text('⊙').fontSize(FONT_SIZE_XS).fontColor(COLOR_WARNING)
                Text('ms').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)

            Column().width(1).height(44).backgroundColor(COLOR_SKY_BLUE_DIVIDER)

            // 上传速度
            Column({ space: SPACE_SM }) {
              Text(this.displayUploadSpeed > 0 ? this.displayUploadSpeed.toFixed(1) : '--')
                .fontSize(22).fontWeight(FontWeight.Bold)
                .fontColor(this.currentPhase === 'upload' ? COLOR_SUCCESS : adaptiveTextPrimary(this.isDarkMode))
              Row({ space: 3 }) {
                Text('↑').fontSize(FONT_SIZE_XS).fontColor(COLOR_SUCCESS)
                Text('Mbps').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .padding({ left: SPACE_2XL, right: SPACE_2XL, top: SPACE_LG, bottom: SPACE_LG })
        }
      }
      .width('100%')
      .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE_SOLID)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .shadow({ radius: GLASS_SHADOW_2XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(14,165,233,0.15)', offsetX: 0, offsetY: 8 })
    }
    .width('100%')
    .borderRadius(24)
    .shadow({ radius: GLASS_SHADOW_3XL, color: COLOR_SKY_BLUE_DIVIDER, offsetX: 0, offsetY: 8 })
    .clip(true)
  }

  // 开始/停止按钮 — 居中悬浮胶囊风格
  @Builder buildActionButton() {
    Row() {
      Text(this.isTesting ? $r('app.string.stop_test') : $r('app.string.start_test'))
        .fontSize(FONT_SIZE_2XL)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor('#FFFFFF')
        .letterSpacing(1)
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 48, right: 48, top: 14, bottom: 14 })
    .backgroundColor(this.isTesting ? 'rgba(239,68,68,0.85)' : COLOR_SKY_BLUE)
    .borderRadius(999)
    .shadow({ radius: GLASS_SHADOW_2XL, color: this.isTesting ? 'rgba(239,68,68,0.4)' : 'rgba(14,165,233,0.45)', offsetX: 0, offsetY: 6 })
    .onClick(() => {
      if (this.isTesting) {
        this.engine.cancel()
      } else {
        this.startSpeedTest()
      }
    })
  }

  // 详情卡片 - 天蓝色毛玻璃
  @Builder buildDetailCard() {
    Column({ space: 16 }) {
      Row() {
        Row({ space: 8 }) {
          Circle().width(8).height(8).fill(COLOR_SUCCESS)
          Text($r('app.string.test_result')).fontSize(FONT_SIZE_3XL).fontWeight(FONT_WEIGHT_BOLD).fontColor(adaptiveTextPrimary(this.isDarkMode))
        }
        Text(this.getServerName()).fontSize(FONT_SIZE_LG).fontColor(adaptiveTextSecondary(this.isDarkMode))
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
            .fontSize(32).fontWeight(FontWeight.Bold).fontColor(this.getPingColor())
          Text('ms').fontSize(FONT_SIZE_SM).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      }.width('100%')
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(20)
    .shadow({ radius: GLASS_SHADOW_2XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_ACTIVE, offsetX: 0, offsetY: 4 })
    .backdropBlur(GLASS_BLUR_XL)
    .borderWidth(1)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
  }

  // 历史记录 - 天蓝色毛玻璃
  @Builder buildHistoryCard() {
    Column({ space: 14 }) {
      Row() {
        Row({ space: 8 }) {
          Text('📊').fontSize(FONT_SIZE_3XL)
          Text($r('app.string.speed_history')).fontSize(FONT_SIZE_3XL).fontWeight(FONT_WEIGHT_BOLD).fontColor(adaptiveTextPrimary(this.isDarkMode))
        }
      }.width('100%')

      if (this.historyList.length > 0) {
        ForEach(this.historyList.slice(0, 5), (item: SpeedTestResult) => {
          this.buildHistoryRow(item)
        }, (item: SpeedTestResult): string => item.timestamp)
      } else {
        Column({ space: 12 }) {
          Text('📈').fontSize(42)
          Text($r('app.string.no_test_record')).fontSize(FONT_SIZE_XL).fontColor(adaptiveTextSecondary(this.isDarkMode))
        }
        .width('100%')
        .padding({ top: 28, bottom: 28 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(20)
    .backdropBlur(GLASS_BLUR_XL)
    .borderWidth(1)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_SKY_LIGHT)
    .shadow({ radius: GLASS_SHADOW_XL, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_SKY_BLUE_GAUGE_BG, offsetX: 0, offsetY: 3 })
  }

  @Builder buildHistoryRow(item: SpeedTestResult) {
    Row({ space: 12 }) {
      Column().width(3).height(56).borderRadius(2)
        .linearGradient({ angle: 180, colors: [[COLOR_SKY_BLUE, 0.0], [COLOR_SKY_BLUE_LIGHT, 1.0]] })

      Column({ space: SPACE_SM }) {
        Row({ space: 20 }) {
          Row({ space: SPACE_SM }) {
            Text('↓').fontSize(FONT_SIZE_LG).fontColor(COLOR_SKY_BLUE).fontWeight(FontWeight.Bold)
            Text(item.downloadSpeed.toFixed(1)).fontSize(FONT_SIZE_2XL).fontWeight(FONT_WEIGHT_MEDIUM).fontColor(adaptiveTextPrimary(this.isDarkMode))
            Text('Mbps').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
          Row({ space: SPACE_SM }) {
            Text('↑').fontSize(FONT_SIZE_LG).fontColor(COLOR_SUCCESS).fontWeight(FontWeight.Bold)
            Text(item.uploadSpeed.toFixed(1)).fontSize(FONT_SIZE_2XL).fontWeight(FONT_WEIGHT_MEDIUM).fontColor(adaptiveTextPrimary(this.isDarkMode))
            Text('Mbps').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
          }
        }
        Text(item.timeLabel).fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

      Column({ space: 2 }) {
        Text(item.pingMs.toFixed(0)).fontSize(FONT_SIZE_4XL).fontWeight(FONT_WEIGHT_BOLD)
          .fontColor(item.pingMs < 30 ? COLOR_SUCCESS : (item.pingMs < 80 ? COLOR_WARNING : COLOR_DANGER))
        Text('ms').fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
      }
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(
        this.isDarkMode ?
          (item.pingMs < 30 ? 'rgba(16,185,129,0.25)' : (item.pingMs < 80 ? 'rgba(245,158,11,0.25)' : 'rgba(239,68,68,0.25)')) :
          (item.pingMs < 30 ? 'rgba(16,185,129,0.1)' : (item.pingMs < 80 ? 'rgba(245,158,11,0.1)' : 'rgba(239,68,68,0.1)'))
      )
      .borderRadius(12)
    }
    .width('100%')
  }

  // 节点选择弹窗 - WiFi详细卡片样式 + 线性弹出动画
  @Builder buildServerPopup() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩
      Column()
        .width('100%').height('100%')
        .backgroundColor(this.isDarkMode ? 'rgba(0,0,0,0.55)' : 'rgba(0,0,0,0.25)')
        .opacity(this.serverPopupOpacity)
        .onClick(() => { this.hideServerPanelWithAnimation() })

      // 弹窗内容 - 线性缩放动画，居中显示
      Column() {
        // 拖动手柄
        Column().width(36).height(4).backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.2)' : 'rgba(74,144,217,0.40)').borderRadius(2)
          .margin({ top: 12, bottom: 14 })

        // 标题栏
        Row() {
          Text($r('app.string.select_speed_server'))
            .fontSize(FONT_SIZE_3XL).fontWeight(FONT_WEIGHT_BOLD).fontColor(adaptiveTextPrimary(this.isDarkMode))
          Blank()
          Column() {
            Text('✕').fontSize(FONT_SIZE_2XL).fontColor(this.isDarkMode ? 'rgba(255,255,255,0.7)' : COLOR_SKY_BLUE)
          }
          .width(36).height(36)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.1)' : COLOR_GLASS_SKY_TAG_BG)
          .borderRadius(10)
          .onClick(() => { this.hideServerPanelWithAnimation() })
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 14 })

        Column().width('100%').height(0.5).backgroundColor(this.isDarkMode ? 'rgba(255,255,255,0.08)' : 'rgba(74,144,217,0.15)')

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
                    .backgroundColor(this.isDarkMode ? 'rgba(74,144,217,0.2)' : COLOR_GLASS_SKY_TAG_BG)
                    .borderRadius(8)
                    .margin({ right: 8 })
                }
                if (index === this.selectedServerIndex) {
                  Text('✓').fontSize(FONT_SIZE_XL).fontColor(this.isDarkMode ? 'rgba(255,255,255,0.9)' : COLOR_SKY_BLUE).fontWeight(FontWeight.Bold)
                }
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 12, right: 16 })
              .backgroundColor(index === this.selectedServerIndex ? (this.isDarkMode ? 'rgba(74,144,217,0.15)' : COLOR_GLASS_SKY_ACTIVE) : 'transparent')
              .borderRadius(12)
              .onClick(() => {
                this.selectedServerIndex = index
                this.hideServerPanelWithAnimation()
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
      .width('88%')  // 宽度改为88%，居中显示
      .constraintSize({ maxHeight: '55%' })
      // WiFi 详细卡片样式：半透明白色 + 毛玻璃边框 + 阴影
      .backgroundColor(this.isDarkMode ? 'rgba(20,38,72,0.78)' : 'rgba(255,255,255,0.78)')
      .borderRadius(20)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.10)', offsetX: 0, offsetY: 2 })
      .backdropBlur(10)
      .borderWidth(1)
      .borderColor(this.isDarkMode ? 'rgba(255,255,255,0.10)' : 'rgba(255,255,255,0.20)')
      // 线性弹出动画：中心缩放
      .scale({ x: this.serverPopupScale, y: this.serverPopupScale, centerX: '50%', centerY: '50%' })
    }
  }

  // 显示弹窗（线性动画）
  private showServerPanelWithAnimation(): void {
    this.showServerPanel = true
    this.getUIContext().animateTo({
      duration: 280,
      curve: Curve.Linear,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {}
    }, () => {
      this.serverPopupOpacity = 1
      this.serverPopupScale = 1
    })
  }

  // 关闭弹窗（线性动画）
  private hideServerPanelWithAnimation(): void {
    this.getUIContext().animateTo({
      duration: 220,
      curve: Curve.Linear,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.showServerPanel = false
        this.serverPopupScale = 0
        this.serverPopupOpacity = 0
      }
    }, () => {
      this.serverPopupOpacity = 0
      this.serverPopupScale = 0
    })
  }

  // 核心方法
  startSpeedTest(): void {
    this.isTesting = true
    this.currentPhase = 'idle'
    this.displaySpeed = 0
    this.displayPing = 0
    this.displayJitter = 0
    this.displayDownloadSpeed = 0
    this.displayUploadSpeed = 0
    this.phaseLabel = ''
    this.gaugeProgress = 0

    const serverId: string = SERVER_NODES[this.selectedServerIndex].id
    const callbacks: SpeedTestCallbacks = {
      onPhaseChanged: (phase: string): void => { this.onPhaseChanged(phase) },
      onDownloadProgress: (speed: number): void => { this.onDownloadProgress(speed) },
      onUploadProgress: (speed: number): void => { this.onUploadProgress(speed) },
      onPingResult: (ping: number, jitter: number): void => { this.onPingResult(ping, jitter) },
      onComplete: (result: SpeedTestResult): void => { this.onComplete(result) },
      onError: (error: string): void => { this.onError(error) },
      onCancelled: (): void => { this.onCancelled() }
    }

    this.engine.startTest(serverId, '', callbacks)
  }

  private onPhaseChanged(phase: string): void {
    this.currentPhase = phase
    switch (phase) {
      case 'ping': this.phaseLabel = 'ping'; this.gaugeProgress = 0.05; break
      case 'download':
        this.phaseLabel = 'download'
        this.gaugeProgress = 0.25
        break
      case 'upload':
        this.phaseLabel = 'upload'
        this.gaugeProgress = 0.7
        this.displaySpeed = this.displayDownloadSpeed
        break
      case 'done':
        this.phaseLabel = 'done'
        this.gaugeProgress = 1.0
        this.displaySpeed = this.displayDownloadSpeed
        break
    }
  }

  private onDownloadProgress(speed: number): void {
    this.displaySpeed = speed
    this.displayDownloadSpeed = speed
    const progress: number = Math.min(speed / 300, 0.65)
    this.gaugeProgress = 0.25 + progress * 0.45
  }

  private onUploadProgress(speed: number): void {
    this.displaySpeed = speed
    this.displayUploadSpeed = speed
  }

  private onPingResult(ping: number, jitter: number): void {
    this.displayPing = ping
    this.displayJitter = jitter
    this.gaugeProgress = 0.15
  }

  private onComplete(result: SpeedTestResult): void {
    console.log('[SpeedTest] Complete:', JSON.stringify(result))
    this.isTesting = false
    this.displayDownloadSpeed = result.downloadSpeed
    this.displayUploadSpeed = result.uploadSpeed
    this.displayPing = result.pingMs
    this.displayJitter = result.jitterMs
    this.displaySpeed = result.downloadSpeed
    this.currentPhase = 'done'
    this.addToHistory(result)
  }

  private onError(error: string): void {
    console.error('[SpeedTest] Error:', error)
    this.isTesting = false
    this.currentPhase = 'error'
    this.phaseLabel = 'error'
  }

  private onCancelled(): void {
    this.isTesting = false
    this.currentPhase = 'idle'
    this.displaySpeed = 0
    this.phaseLabel = 'cancelled'
  }

  private addToHistory(result: SpeedTestResult): void {
    const newList: Array<SpeedTestResult> = [result]
    for (let i = 0; i < this.historyList.length; i++) {
      newList.push(this.historyList[i])
    }
    while (newList.length > 20) {
      newList.pop()
    }
    this.historyList = newList
    this.saveHistory(newList)
  }

  private saveHistory(list: Array<SpeedTestResult>): void {
    try {
      const jsonStr: string = JSON.stringify(list)
      AppStorage.set('speedtest_history', jsonStr)
    } catch (e) {
      console.warn('[SpeedTest] Failed to save history:', e)
    }
  }

  private loadHistory(): void {
    try {
      const savedValue: Object | null | undefined = AppStorage.get('speedtest_history')
      const jsonStr: string = (savedValue !== null && savedValue !== undefined) ? String(savedValue) : '[]'
      const parsed: Array<SpeedTestResult> = JSON.parse(jsonStr)
      if (parsed && parsed.length > 0) {
        this.historyList = parsed
      }
    } catch (e) {
      this.historyList = []
    }
  }

  private getServerName(): string {
    if (this.selectedServerIndex < SERVER_NODES.length) {
      return SERVER_NODES[this.selectedServerIndex].name
    }
    return $r('app.string.unknown').toString()
  }

  private formatDisplaySpeed(): string {
    if (this.currentPhase === 'idle' || (this.displaySpeed <= 0 && !this.isTesting)) {
      return '0.0'
    }
    return this.displaySpeed.toFixed(1)
  }

  private getSpeedLabelResource(): Resource {
    if (this.currentPhase === 'done') return $r('app.string.download_speed')
    if (this.currentPhase === 'download') return $r('app.string.download_in_progress')
    if (this.currentPhase === 'upload') return $r('app.string.upload_in_progress')
    if (this.currentPhase === 'ping') return $r('app.string.latency_testing')
    return $r('app.string.tap_to_start')
  }

  private getPingColor(): string {
    if (this.displayPing < 30) return COLOR_SUCCESS
    if (this.displayPing < 80) return COLOR_WARNING
    return COLOR_DANGER
  }

  private getGaugeShadowColor(): string {
    switch (this.currentPhase) {
      case 'ping': return 'rgba(251,191,36,0.5)'
      case 'download': return 'rgba(14,165,233,0.5)'
      case 'upload': return 'rgba(52,211,153,0.5)'
      case 'done': return 'rgba(52,211,153,0.5)'
      case 'error': return 'rgba(248,113,113,0.5)'
      default: return 'rgba(14,165,233,0.3)'
    }
  }

  private getGaugeColor(): string {
    switch (this.currentPhase) {
      case 'ping': return COLOR_WARNING
      case 'download': return COLOR_SKY_BLUE
      case 'upload': return COLOR_SUCCESS
      case 'done': return COLOR_SUCCESS
      case 'error': return COLOR_DANGER
      case 'idle': return COLOR_SKY_BLUE
      default: return COLOR_SKY_BLUE
    }
  }

  private getGaugeArcLength(): number {
    // 基于 GAUGE_SIZE_XL - 16（内圈直径）计算真实圆周长
    const diameter: number = GAUGE_SIZE_XL - 16
    const circumference: number = Math.round(Math.PI * diameter)
    return Math.max(circumference * this.gaugeProgress, 0)
  }
}
