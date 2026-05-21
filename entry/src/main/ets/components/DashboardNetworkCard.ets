import { COLOR_TEXT_PRIMARY, COLOR_TEXT_SECONDARY, COLOR_TEXT_TERTIARY,
  COLOR_SURFACE, COLOR_CARD_SHADOW, COLOR_BACKGROUND,
  FONT_SIZE_XS, FONT_SIZE_SM, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL,
  FONT_WEIGHT_MEDIUM, FONT_WEIGHT_BOLD,
  SPACE_XL, SPACE_MD, SPACE_LG, SPACE_SM,
  CARD_RADIUS, CARD_SHADOW_RADIUS, RADIUS_MD,
  isMediumOrLarger } from '@wifi-analyzer/design-system'

@Component
export struct DashboardNetworkCard {
  @Prop isDarkMode: boolean = false
  @Prop localIp: string = ''
  @Prop gateway: string = ''
  @Prop dns: string = ''
  @Prop publicIp: string = ''
  @Prop connected: boolean = false

  // 单个网络信息条目
  @Builder InfoItem(label: Resource, value: Resource | string, icon: Resource) {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Image(icon).width(14).height(14).fillColor(COLOR_TEXT_SECONDARY)
        Text(label).fontSize(FONT_SIZE_XS).fontColor(COLOR_TEXT_SECONDARY)
      }
      .alignItems(VerticalAlign.Center)
      .alignSelf(ItemAlign.Start)

      Text(value)
        .fontSize(FONT_SIZE_LG)
        .fontWeight(FONT_WEIGHT_BOLD)
        .fontColor(COLOR_TEXT_PRIMARY)
        .textAlign(TextAlign.Start)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .alignSelf(ItemAlign.Start)
    }
    .padding({ left: SPACE_MD, right: SPACE_MD, top: SPACE_MD, bottom: SPACE_MD })
    .backgroundColor(COLOR_BACKGROUND)
    .borderRadius(RADIUS_MD)
    .width('100%')
    .height('100%')
  }

  build() {
    Column({ space: SPACE_MD }) {
      // 标题栏
      Row() {
        Text($r('app.string.network_info'))
          .fontSize(FONT_SIZE_XL)
          .fontColor(COLOR_TEXT_SECONDARY)
          .fontWeight(FONT_WEIGHT_MEDIUM)
      }
      .width('100%')

      // 未连接时显示占位提示，已连接时显示网格
      if (this.connected) {
        // 信息网格（大屏4列单行，普通屏幕2列2行）
        Grid() {
          GridItem() { this.InfoItem($r('app.string.local_ip'), this.localIp !== '--' ? this.localIp : $r('app.string.not_obtained'), $r('app.media.ic_device')) }
          GridItem() { this.InfoItem($r('app.string.public_ip'), this.publicIp !== '--' ? this.publicIp : $r('app.string.not_obtained'), $r('app.media.ic_route')) }
          GridItem() { this.InfoItem($r('app.string.gateway'), this.gateway !== '--' ? this.gateway : $r('app.string.not_obtained'), $r('app.media.ic_route')) }
          GridItem() { this.InfoItem($r('app.string.dns_server'), this.dns !== '--' ? this.dns : $r('app.string.not_obtained'), $r('app.media.ic_dns')) }
        }
        .columnsTemplate(isMediumOrLarger() ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
        .rowsTemplate(isMediumOrLarger() ? '1fr' : '1fr 1fr')
        .columnsGap(SPACE_MD).rowsGap(SPACE_SM)
        .width('100%').height(isMediumOrLarger() ? 80 : 140)
      } else {
        // 未连接时显示占位提示
        Column({ space: 8 }) {
          Text($r('app.string.connect_wifi_hint'))
            .fontSize(FONT_SIZE_MD)
            .fontColor(COLOR_TEXT_TERTIARY)
            .fontWeight(FONT_WEIGHT_MEDIUM)
          Text($r('app.string.network_info_auto_show'))
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_TEXT_SECONDARY)
        }
        .width('100%')
        .padding({ top: SPACE_LG, bottom: SPACE_LG })
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding(SPACE_XL)
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(CARD_RADIUS + 4)
    .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
  }
}
