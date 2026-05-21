import { COLOR_TEXT_PRIMARY, COLOR_PRIMARY, COLOR_SUCCESS, COLOR_INFO,
  COLOR_SURFACE, COLOR_CARD_SHADOW,
  FONT_SIZE_XS, FONT_SIZE_MD, FONT_SIZE_LG, FONT_SIZE_XL,
  FONT_WEIGHT_MEDIUM,
  SPACE_MD, SPACE_XL, SPACE_SM,
  CARD_RADIUS, CARD_SHADOW_RADIUS,
  isMediumOrLarger } from '@wifi-analyzer/design-system'
import { RouterManager } from '@wifi-analyzer/core'

@Component
export struct DashboardToolsGrid {
  @Prop isDarkMode: boolean = false
  onToolClick: (toolName: string) => void = () => {}

  // 工具项（毛玻璃图标：渐变 PNG 自身作背景，白色图案，无需 fillColor）
  @Builder ToolItem(name: Resource, icon: Resource, bgColor: string, iconColor: string, isChannelTool: boolean = false, targetTab: number = -1, toolAction: string = '') {
    Column({ space: SPACE_SM }) {
      Stack({ alignContent: Alignment.Center }) {
        // 毛玻璃图标：图标自身是渐变背景+白色图案，无需 Circle 和 fillColor
        Image(icon).width(44).height(44)
      }
      .width(54)
      .height(54)

      Text(name)
        .fontSize(FONT_SIZE_MD)
        .fontColor(COLOR_TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT_MEDIUM)
    }
    .padding({ top: SPACE_SM, bottom: 4 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .stateStyles({
      pressed: { opacity: 0.75 }
    })
    .onClick(() => {
      // 工具子页面：统一通过 RouterManager 导航
      if (toolAction === 'roamtest') {
        RouterManager.navigate('roamtest')
        this.onToolClick('roamtest')
      } else if (isChannelTool) {
        AppStorage.set('currentTab', 2)
        this.onToolClick('channel_analysis')
      } else if (targetTab >= 0) {
        AppStorage.set('currentTab', targetTab)
        if (targetTab === 1) {
          this.onToolClick('surround_wifi')
        }
      }
    })
  }

  build() {
    Column({ space: SPACE_MD }) {
      // 标题栏
      Row() {
        Text($r('app.string.quick_tools'))
          .fontSize(FONT_SIZE_XL)
          .fontColor(COLOR_TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT_MEDIUM)
        Blank()
      }
      .width('100%')

      // 工具网格（大屏4列单行，普通屏幕2列2行）
      Grid() {
        GridItem() { this.ToolItem($r('app.string.roam_test'), $r('app.media.ic_roaming'), '#EEF2FF', COLOR_PRIMARY, false, -1, 'roamtest') }
        GridItem() { this.ToolItem($r('app.string.tab_wifi'), $r('app.media.ic_surround'), '#ECFDF5', COLOR_SUCCESS, false, 1) }
        GridItem() { this.ToolItem($r('app.string.channel_analysis'), $r('app.media.ic_channel'), '#F0EBFF', COLOR_INFO, true) }
      }
      .columnsTemplate(isMediumOrLarger() ? '1fr 1fr 1fr' : '1fr 1fr')
      .rowsTemplate(isMediumOrLarger() ? '1fr' : '1fr 1fr')
      .columnsGap(SPACE_MD).rowsGap(SPACE_MD)
      .width('100%').height(isMediumOrLarger() ? 100 : 180)
      .padding(SPACE_XL)
      .backgroundColor(COLOR_SURFACE)
      .borderRadius(CARD_RADIUS + 4)
      .shadow({ radius: CARD_SHADOW_RADIUS, color: COLOR_CARD_SHADOW, offsetX: 0, offsetY: 2 })
    }
  }
}
