// 工具箱页组件 — 纯工具列表，子页面导航由 RouterManager 处理
import { COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY, COLOR_SURFACE,
  COLOR_DIVIDER_WEAK, COLOR_CARD_SHADOW,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_WEIGHT_MEDIUM,
  SPACE_MD, SPACE_LG, RADIUS_LG, CARD_SHADOW_RADIUS,
  TAB_BAR_SAFE_BOTTOM,
  // 暗色模式自适应工具
  adaptiveBackgroundList,
  adaptiveGlowLarge,
  adaptiveGlowMedium,
  adaptiveTextPrimary,
  adaptiveTextSecondary,
  adaptiveTextTertiary,
  adaptiveCardBg,
  COLOR_TEXT_GLASS_PRIMARY,
  COLOR_TEXT_GLASS_SECONDARY,
  COLOR_TEXT_GLASS_TERTIARY,
  COLOR_GLASS_DARK_SURFACE,
  COLOR_GLASS_DARK_CARD,
  COLOR_GLASS_DARK_BORDER } from '@wifi-analyzer/design-system'
import { ToolItem, RouterManager, RouteName } from '@wifi-analyzer/core'
import { isMediumOrLarger } from '../utils/ResponsiveUtils'

// 工具数据（统一数据源，大屏/手机共用）
const DIAGNOSTIC_TOOLS: ToolItem[] = [
  { name: $r('app.string.ping_test'), desc: $r('app.string.desc_test_latency'), icon: $r('app.media.ic_ping'), color: '#0066FF', action: 'ping' },
  { name: $r('app.string.traceroute'), desc: $r('app.string.desc_trace_route'), icon: $r('app.media.ic_route'), color: '#00D4FF', action: 'traceroute' },
  { name: $r('app.string.dns_lookup'), desc: $r('app.string.desc_dns_check'), icon: $r('app.media.ic_dns'), color: '#10B981', action: 'dns' },
  { name: $r('app.string.port_scan'), desc: $r('app.string.desc_port_check'), icon: $r('app.media.ic_port'), color: '#8B5CF6', action: 'portscan' }
]

const NETWORK_TOOLS: ToolItem[] = [
  { name: $r('app.string.subnet_calc'), desc: $r('app.string.desc_subnet_calc'), icon: $r('app.media.ic_subnet'), color: '#F59E0B', action: 'subnet' },
  { name: $r('app.string.poe_calc'), desc: $r('app.string.desc_poe_calc'), icon: $r('app.media.ic_poe'), color: '#EF4444', action: 'poe' },
  { name: $r('app.string.ip_geo'), desc: $r('app.string.desc_ip_query'), icon: $r('app.media.ic_ip'), color: '#EC4899', action: 'ipgeo' },
  { name: $r('app.string.mac_lookup'), desc: $r('app.string.desc_mac_query'), icon: $r('app.media.ic_mac'), color: '#6366F1', action: 'maclookup' }
]

const ADVANCED_TOOLS: ToolItem[] = [
  { name: $r('app.string.wake_on_lan'), desc: $r('app.string.desc_wol'), icon: $r('app.media.ic_wol'), color: '#14B8A6', action: 'wol' },
  { name: $r('app.string.lan_scan'), desc: $r('app.string.desc_lan_scan'), icon: $r('app.media.ic_lan'), color: '#A855F7', action: 'lanscan' },
  { name: $r('app.string.roam_test'), desc: $r('app.string.desc_roam_test'), icon: $r('app.media.ic_roaming'), color: '#F97316', action: 'roamtest' },
  { name: $r('app.string.find_device'), desc: $r('app.string.desc_find_device'), icon: $r('app.media.ic_device'), color: '#059669', action: 'finddevice' }
]

@Component
export struct ToolsSection {
  @Consume('isDarkMode') isDarkMode: boolean
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

      // 主内容层
      Scroll() {
        if (isMediumOrLarger()) {
          // 大屏：2 列布局
          Column({ space: 16 }) {
            Row({ space: 16 }) {
              // 左列：诊断 + 网络
              Column({ space: 16 }) {
                this.ToolSection($r('app.string.diagnostic_tools'), DIAGNOSTIC_TOOLS)
                this.ToolSection($r('app.string.network_tools'), NETWORK_TOOLS)
              }
              .layoutWeight(1)

              // 右列：高级 + 关于
              Column({ space: 16 }) {
                this.ToolSection($r('app.string.advanced_tools'), ADVANCED_TOOLS)
                this.AboutSection()
              }
              .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .padding({ left: 16, right: 16, top: SPACE_LG, bottom: TAB_BAR_SAFE_BOTTOM })
        } else {
          // 手机：单列布局
          Column({ space: 16 }) {
            this.ToolSection($r('app.string.diagnostic_tools'), DIAGNOSTIC_TOOLS)
            this.ToolSection($r('app.string.network_tools'), NETWORK_TOOLS)
            this.ToolSection($r('app.string.advanced_tools'), ADVANCED_TOOLS)
            this.AboutSection()
          }
          .padding({ left: 16, right: 16, top: SPACE_LG, bottom: TAB_BAR_SAFE_BOTTOM })
        }
      }
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // 关于入口
  @Builder AboutSection() {
    Column({ space: 0 }) {
      Text($r('app.string.other'))
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .width('100%')
        .padding({ left: 8, bottom: 6 })

      Row({ space: 12 }) {
        Row() {
          Image($r('app.media.icon'))
            .width(36)
            .height(36)
        }
        .width(36)
        .height(36)
        .borderRadius(9)
        .backgroundColor('#0066FF')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Column({ space: 2 }) {
          Text($r('app.string.about_wifi_analyzer'))
            .fontSize(FONT_SIZE_MD)
            .fontWeight(FONT_WEIGHT_MEDIUM)
            .fontColor(adaptiveTextPrimary(this.isDarkMode))
          Text($r('app.string.version_info'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('›')
          .fontSize(20)
          .fontColor(adaptiveTextTertiary(this.isDarkMode))
          .lineHeight(20)
      }
      .width('100%')
      .height(60)
      .padding({ left: 14, right: 14 })
      .backgroundColor(this.isDarkMode ? 'rgba(20,38,72,0.85)' : COLOR_SURFACE)
      .borderRadius(RADIUS_LG)
      .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 1 })
      .onClick(() => { RouterManager.navigate('about') })
    }
    .width('100%')
  }

  // ==================== Builder: 工具分类区块 ====================
  @Builder ToolSection(title: Resource | string, items: ToolItem[]) {
    Column({ space: 0 }) {
      // 分组标题
      Text(title)
        .fontSize(FONT_SIZE_SM)
        .fontColor(adaptiveTextSecondary(this.isDarkMode))
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .width('100%')
        .padding({ left: 8, bottom: 6 })

      // 合并卡片
      Column({ space: 0 }) {
        ForEach(items, (item: ToolItem, index: number) => {
          Column() {
            Row({ space: 12 }) {
              // 彩色圆角图标背景
              Row() {
                Image(item.icon)
                  .width(36)
                  .height(36)
              }
              .width(36)
              .height(36)
              .borderRadius(9)
              .backgroundColor(item.color)
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)

              // 名称 + 描述
              Column({ space: 2 }) {
                Text(item.name)
                  .fontSize(FONT_SIZE_MD)
                  .fontWeight(FONT_WEIGHT_MEDIUM)
                  .fontColor(adaptiveTextPrimary(this.isDarkMode))
                Text(item.desc)
                  .fontSize(FONT_SIZE_XS)
                  .fontColor(adaptiveTextTertiary(this.isDarkMode))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              // 右箭头
              Text('›')
                .fontSize(20)
                .fontColor(adaptiveTextTertiary(this.isDarkMode))
                .lineHeight(20)
            }
            .width('100%')
            .height(60)
            .padding({ left: 14, right: 14 })
            .onClick(() => {
              if (item.action !== undefined && item.action !== '') {
                RouterManager.navigate(item.action as RouteName)
              }
            })

            // 分割线（最后一项不显示）
            if (index < items.length - 1) {
              Divider()
                .color(COLOR_DIVIDER_WEAK)
                .strokeWidth(0.6)
                .margin({ left: 62 })
            }
          }
          .width('100%')
        })
      }
      .width('100%')
      .backgroundColor(this.isDarkMode ? 'rgba(20,38,72,0.85)' : COLOR_SURFACE)
      .borderRadius(RADIUS_LG)
      .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 1 })
      .clip(true)
    }
    .width('100%')
  }
}
