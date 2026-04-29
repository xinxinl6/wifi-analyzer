// ============================================
// Aurora WiFi V2 — 首页仪表盘组件
// API Level: 23+
// 极光天蓝 + 毛玻璃 + 沉浸光感设计
// ============================================

import {
  // Aurora 色彩
  COLOR_AURORA_PRIMARY,
  COLOR_AURORA_LIGHT,
  COLOR_AURORA_GLOW,
  COLOR_AURORA_DEEP,
  // 毛玻璃色彩
  COLOR_GLASS_SURFACE,
  COLOR_GLASS_SURFACE_MEDIUM,
  COLOR_GLASS_SURFACE_HIGH,
  COLOR_GLASS_CARD,
  COLOR_GLASS_BORDER_LIGHT,
  COLOR_GLASS_BORDER_MEDIUM,
  COLOR_GLASS_AURORA,
  COLOR_GLASS_AURORA_LIGHT,
  COLOR_GLASS_AURORA_BORDER,
  // 文字色（暗色模式）
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  // 文字色（浅色模式）
  COLOR_TEXT_LIGHT_PRIMARY,
  COLOR_TEXT_LIGHT_SECONDARY,
  COLOR_TEXT_LIGHT_TERTIARY,
  // 阴影
  COLOR_SHADOW_GLASS,
  COLOR_SHADOW_GLASS_STRONG,
  COLOR_SHADOW_AURORA,
  // 信号色
  SIGNAL_COLORS_AURORA,
  SIGNAL_COLORS_AURORA_BG,
  // 动效
  DURATION_FAST,
  DURATION_NORMAL,
  AnimationTapScale,
  // 半径
  RADIUS_CARD,
  RADIUS_BUTTON
} from '@wifi-analyzer/design-system'
import { SharedWifiState, NetworkDiagnosticsResult, defaultDiagnosticsResult, networkDiagnostics, RouterManager, RouteName } from '@wifi-analyzer/core'
import { AuroraSignalIndicator } from './AuroraGlassComponents'

// ============================================
// Aurora 连接状态卡片（极光渐变版）
// ============================================

@Component
export struct AuroraConnectionCard {
  @Consume('wifiState') wifiState: SharedWifiState
  @Prop isDarkMode: boolean = false

  @State private connected: boolean = false
  @State private cardScale: number = 1.0
  @State private signalColor: string = SIGNAL_COLORS_AURORA.none

  // 根据模式获取文字颜色
  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  private get textSecondary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_SECONDARY : COLOR_TEXT_LIGHT_SECONDARY
  }

  private get textTertiary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
  }

  aboutToAppear(): void {
    this.updateState()
  }

  private updateState(): void {
    this.connected = this.wifiState.connectedSsid !== '' && this.wifiState.connectedSsid !== '<unknown ssid>'

    const signal = this.wifiState.connectedSignal
    if (signal > -50) {
      this.signalColor = SIGNAL_COLORS_AURORA.excellent
    } else if (signal > -65) {
      this.signalColor = SIGNAL_COLORS_AURORA.good
    } else if (signal > -80) {
      this.signalColor = SIGNAL_COLORS_AURORA.fair
    } else {
      this.signalColor = SIGNAL_COLORS_AURORA.poor
    }
  }

  private getSignalLevel(): string {
    const signal = this.wifiState.connectedSignal
    if (signal > -50) return 'excellent'
    if (signal > -65) return 'good'
    if (signal > -80) return 'fair'
    return 'poor'
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        // 左侧：WiFi 图标 + 状态
        Stack({ alignContent: Alignment.Center }) {
          // 外层光晕
          Circle()
            .width(64)
            .height(64)
            .fill(this.connected ? `${this.signalColor}30` : 'rgba(148,163,184,0.15)')

          // 内层光晕
          Circle()
            .width(52)
            .height(52)
            .fill(this.connected ? `${this.signalColor}20` : 'rgba(148,163,184,0.1)')

          // WiFi 图标
          Image($r('app.media.ic_wifi'))
            .width(28)
            .height(28)
            .fillColor(this.connected ? this.signalColor : '#64748B')
        }
        .width(64)
        .height(64)

        // 文字信息
        Column({ space: 6 }) {
          // 状态标签
          Row({ space: 6 }) {
            Text(this.wifiState.isScanning ? '扫描中' : (this.connected ? '已连接' : '未连接'))
              .fontSize(12)
              .fontColor(this.connected ? this.textSecondary : this.textTertiary)

            if (this.connected) {
              Circle()
                .width(6)
                .height(6)
                .fill('#00D97E')
            }
          }

          // SSID 名称
          Text(this.connected ? this.wifiState.connectedSsid : '无网络连接')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 详细信息
          if (this.connected) {
            Row({ space: 8 }) {
              Text(`${this.wifiState.connectedFreq}GHz`)
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text('·')
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text(`CH ${this.wifiState.connectedChannel}`)
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text('·')
                .fontSize(12)
                .fontColor(this.textTertiary)
              Text(`${this.wifiState.connectedSignal} dBm`)
                .fontSize(12)
                .fontColor(this.textTertiary)
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .constraintSize({ minWidth: 0 })

        // 右侧：信号强度指示器
        if (this.connected) {
          Column({ space: 4 }) {
            AuroraSignalIndicator({
              signalLevel: this.getSignalLevel(),
              signalLabel: '',
              showLabel: false,
              indicatorSize: 'large'
            })

            Text(`${this.wifiState.connectedSignal}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.signalColor)
              .margin({ top: 4 })

            Text('dBm')
              .fontSize(10)
              .fontColor(this.textTertiary)
          }
        }
      }
    }
    .width('100%')
    .padding(20)
    // Aurora 极光渐变背景
    .backgroundColor(COLOR_GLASS_CARD)
    .border({
      width: 1,
      color: COLOR_GLASS_BORDER_MEDIUM,
      radius: RADIUS_CARD
    })
    .shadow({
      radius: 20,
      color: COLOR_SHADOW_AURORA,
      offsetX: 0,
      offsetY: 4
    })
    .scale({ x: this.cardScale, y: this.cardScale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        animateTo(AnimationTapScale, () => {
          this.cardScale = 0.98
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.cardScale = 1.0
        })
      }
    })
  }
}

// ============================================
// Aurora 网络信息网格
// ============================================

@Component
export struct AuroraNetworkGrid {
  @Consume('wifiState') wifiState: SharedWifiState
  @Prop isDarkMode: boolean = false
  @State diagnostics: NetworkDiagnosticsResult = defaultDiagnosticsResult

  // 根据模式获取文字颜色
  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  private get textTertiary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_TERTIARY : COLOR_TEXT_LIGHT_TERTIARY
  }

  aboutToAppear(): void {
    networkDiagnostics.loadDiagnostics()
    this.diagnostics = networkDiagnostics.getCurrentResult()
  }

  @Builder
  InfoGridItem(label: string, value: string, icon: Resource) {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Image(icon)
          .width(14)
          .height(14)
          .fillColor(COLOR_AURORA_PRIMARY)
        Text(label)
          .fontSize(11)
          .fontColor(this.textTertiary)
      }
      .alignItems(VerticalAlign.Center)

      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(COLOR_GLASS_SURFACE_MEDIUM)
    .borderRadius(12)
    .border({
      width: 1,
      color: COLOR_GLASS_BORDER_LIGHT,
      radius: 12
    })
  }

  build() {
    Column({ space: 12 }) {
      // 标题
      Row() {
        Text('网络信息')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)

        Blank()

        // AI 分析入口
        Row({ space: 4 }) {
          Image($r('app.media.ic_ai_assistant'))
            .width(14)
            .height(14)
            .fillColor(COLOR_AURORA_PRIMARY)
          Text('AI分析')
            .fontSize(12)
            .fontColor(COLOR_AURORA_PRIMARY)
        }
        .padding(6)
        .backgroundColor(COLOR_GLASS_AURORA_LIGHT)
        .borderRadius(8)
      }
      .width('100%')

      // 信息网格
      Grid() {
        GridItem() {
          this.InfoGridItem('本地IP', this.diagnostics.localIp || '--', $r('app.media.ic_device'))
        }
        GridItem() {
          this.InfoGridItem('公网IP', this.diagnostics.publicIp || '--', $r('app.media.ic_route'))
        }
        GridItem() {
          this.InfoGridItem('网关', this.diagnostics.gateway || '--', $r('app.media.ic_route'))
        }
        GridItem() {
          this.InfoGridItem('DNS', this.diagnostics.dns || '--', $r('app.media.ic_dns'))
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .height(160)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLOR_GLASS_CARD)
    .borderRadius(RADIUS_CARD)
    .border({
      width: 1,
      color: COLOR_GLASS_BORDER_LIGHT,
      radius: RADIUS_CARD
    })
  }
}

// ============================================
// Aurora 快速工具网格
// ============================================

@Component
export struct AuroraToolsGrid {
  @Prop isDarkMode: boolean = false
  @State private toolScale: number = 1.0

  // 根据模式获取文字颜色
  private get textPrimary(): string {
    return this.isDarkMode ? COLOR_TEXT_GLASS_PRIMARY : COLOR_TEXT_LIGHT_PRIMARY
  }

  @Builder
  ToolCard(title: string, icon: Resource, bgColor: string, iconColor: string, index: number, action: string) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        // 图标背景
        Column()
          .width(48)
          .height(48)
          .borderRadius(14)
          .backgroundColor(bgColor)
          .shadow({
            radius: 8,
            color: `${iconColor}25`,
            offsetX: 0,
            offsetY: 2
          })

        // 图标
        Image(icon)
          .width(24)
          .height(24)
          .fillColor(iconColor)
      }

      // 标题
      Text(title)
        .fontSize(12)
        .fontColor(this.textPrimary)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(COLOR_GLASS_SURFACE)
    .borderRadius(14)
    .border({
      width: 1,
      color: COLOR_GLASS_BORDER_LIGHT,
      radius: 14
    })
    .scale({ x: this.toolScale, y: this.toolScale })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        animateTo(AnimationTapScale, () => {
          this.toolScale = 0.92
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        animateTo({
          duration: DURATION_NORMAL,
          curve: Curve.EaseOut
        }, () => {
          this.toolScale = 1.0
        })
      }
    })
    .onClick(() => {
      const routeMap: Record<string, RouteName> = {
        'roamtest': 'roamtest',
        'finddevice': 'finddevice'
      }
      const route = routeMap[action]
      if (route) {
        RouterManager.navigate(route)
      }
    })
  }

  build() {
    Column({ space: 12 }) {
      // 标题
      Row() {
        Text('快速工具')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textPrimary)

        Blank()

        Text('更多')
          .fontSize(12)
          .fontColor(COLOR_AURORA_PRIMARY)
      }
      .width('100%')

      // 工具网格
      Grid() {
        GridItem() {
          this.ToolCard('漫游测试', $r('app.media.ic_roaming'), 'rgba(74,144,217,0.15)', COLOR_AURORA_PRIMARY, 0, 'roamtest')
        }
        GridItem() {
          this.ToolCard('设备发现', $r('app.media.ic_device'), 'rgba(0,217,126,0.15)', '#00D97E', 1, 'finddevice')
        }
        GridItem() {
          this.ToolCard('周边WiFi', $r('app.media.ic_surround'), 'rgba(135,206,235,0.15)', COLOR_AURORA_LIGHT, 2, '')
        }
        GridItem() {
          this.ToolCard('信道分析', $r('app.media.ic_channel'), 'rgba(139,92,246,0.15)', '#8B5CF6', 3, '')
        }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
      .height(110)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLOR_GLASS_CARD)
    .borderRadius(RADIUS_CARD)
    .border({
      width: 1,
      color: COLOR_GLASS_BORDER_LIGHT,
      radius: RADIUS_CARD
    })
  }
}

// ============================================
// Aurora 极光装饰背景
// ============================================

@Component
export struct AuroraBackground {
  build() {
    Stack() {
      // 基础渐变背景已在 Index.ets 设置

      // 极光装饰光晕 1 - 使用更大的透明圆形代替 blur
      Circle()
        .width(300)
        .height(300)
        .fill('rgba(74,144,217,0.06)')
        .position({ x: -80, y: -80 })

      // 极光装饰光晕 2
      Circle()
        .width(200)
        .height(200)
        .fill('rgba(135,206,235,0.05)')
        .position({ x: '70%', y: '55%' })

      // 极光装饰光晕 3
      Circle()
        .width(150)
        .height(150)
        .fill('rgba(74,144,217,0.04)')
        .position({ x: '75%', y: '15%' })
    }
    .width('100%')
    .height('100%')
    .zIndex(-1)
  }
}

// ============================================
// Aurora 首页主组件
// ============================================

@Component
export struct AuroraDashboard {
  @Consume('wifiState') wifiState: SharedWifiState
  @Prop isDarkMode: boolean = false

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          // 连接状态卡片
          AuroraConnectionCard({ isDarkMode: this.isDarkMode })

          // 网络信息网格
          AuroraNetworkGrid({ isDarkMode: this.isDarkMode })

          // 快速工具网格
          AuroraToolsGrid({ isDarkMode: this.isDarkMode })

          // 底部安全区
          Row()
            .height(100)
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}