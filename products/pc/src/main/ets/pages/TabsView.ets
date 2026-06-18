import { uiObserver } from '@kit.ArkUI';
import { SystemProperties } from '@ohos.system_lib';

interface WindowInfo {
  windowWidth: number;
  windowHeight: number;
}

@ComponentV2
export struct TabsView {
  @Param mainWindowInfo: WindowInfo;
  @Local currentBottomIndex: number = 0;
  @Env(SystemProperties.BREAK_POINT) breakpoint: uiObserver.WindowSizeLayoutBreakpointInfo;

  @Builder
  TabBuilder(icon: ResourceStr, label: ResourceStr, index: number) {
    Column() {
      Image(icon).width(24).height(24)
      Text(label).fontSize(10).margin({ top: 4 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .opacity(this.currentBottomIndex === index ? 1.0 : 0.6)
  }

  build() {
    HdsTabs({ index: this.currentBottomIndex, onIndexChange: (index: number) => {
      this.currentBottomIndex = index;
    } }) {
      TabContent() {
        Text('Dashboard').fontSize(20)
      }.tabBar(this.TabBuilder($r('app.media.ic_dashboard'), $r('app.string.tab_home'), 0))

      TabContent() {
        Text('WiFi').fontSize(20)
      }.tabBar(this.TabBuilder($r('app.media.ic_wifi'), $r('app.string.tab_wifi'), 1))

      TabContent() {
        Text('Channel').fontSize(20)
      }.tabBar(this.TabBuilder($r('app.media.ic_channel'), $r('app.string.tab_channel'), 2))

      TabContent() {
        Text('Speed Test').fontSize(20)
      }.tabBar(this.TabBuilder($r('app.media.ic_speed'), $r('app.string.tab_speed'), 3))

      TabContent() {
        Text('Tools').fontSize(20)
      }.tabBar(this.TabBuilder($r('app.media.ic_tools'), $r('app.string.tab_tools'), 4))
    }
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .vertical(false)
    .scrollable(false)
    .animationDuration(200)
    .clip(true)
    .width('100%')
    .height('100%')
  }
}
