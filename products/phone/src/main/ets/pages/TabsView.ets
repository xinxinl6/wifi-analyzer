import { WindowInfo } from 'wifi-base';
import { hdsMaterial } from '@kit.UIDesignKit';

@ComponentV2
export struct TabsView {
  @Param mainWindowInfo: WindowInfo = new WindowInfo();
  @Local currentBottomIndex: number = 0;

  @Builder
  TabBuilder(label: ResourceStr, index: number) {
    Column() {
      Text(label).fontSize(12).fontWeight(FontWeight.Medium)
        .fontColor(this.currentBottomIndex === index ?
          $r('sys.color.icon_emphasize') : $r('sys.color.icon_primary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    HdsTabs() {
      TabContent() {
        Text('Dashboard').fontSize(20).fontColor($r('sys.color.font_primary'))
      }
      .tabBar(this.TabBuilder($r('app.string.tab_home'), 0))

      TabContent() {
        Text('WiFi').fontSize(20).fontColor($r('sys.color.font_primary'))
      }
      .tabBar(this.TabBuilder($r('app.string.tab_wifi'), 1))

      TabContent() {
        Text('信道').fontSize(20).fontColor($r('sys.color.font_primary'))
      }
      .tabBar(this.TabBuilder($r('app.string.tab_channel'), 2))

      TabContent() {
        Text('测速').fontSize(20).fontColor($r('sys.color.font_primary'))
      }
      .tabBar(this.TabBuilder($r('app.string.tab_speed'), 3))

      TabContent() {
        Text('工具箱').fontSize(20).fontColor($r('sys.color.font_primary'))
      }
      .tabBar(this.TabBuilder($r('app.string.tab_tools'), 4))
    }
    .onChange((index: number) => {
      this.currentBottomIndex = index;
    })
    .barOverlap(true)
    .barPosition(BarPosition.End)
    .vertical(false)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.ALL])
    .width('100%')
    .height('100%')
    .barWidth('100%')
    .barHeight(56)
    .barFloatingStyle({
      barBottomMargin: Math.max(this.mainWindowInfo.naviIndicatorHeight, 16),
      adaptToHandedness: false,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE,
      },
    })
  }
}
