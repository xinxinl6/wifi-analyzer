import { WindowInfo } from 'wifi-base';
import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { WifiScanner, WifiViewModel } from '@wifi-analyzer/wifi-scan';

@ComponentV2
export struct TabsView {
  @Param mainWindowInfo: WindowInfo = new WindowInfo();
  @Local currentBottomIndex: number = 0;
  private wifiViewModel: WifiViewModel = new WifiViewModel();

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
      // Tab 0 — Dashboard
      TabContent() {
        Column() {
          Text('网络概览').fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .margin({ top: 40, bottom: 20 })

          Text('设备: ' + (this.wifiViewModel.getStats().total > 0 ?
            this.wifiViewModel.getStats().bestSsid : '未扫描'))
            .fontSize(16).fontColor($r('sys.color.font_secondary'))

          Text('信号强度: ' + this.wifiViewModel.getStats().avgRssi + ' dBm')
            .fontSize(16).fontColor($r('sys.color.font_secondary')).margin({ top: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .tabBar(this.TabBuilder($r('app.string.tab_home'), 0))

      // Tab 1 — WiFi 列表
      TabContent() {
        Column() {
          Text('WiFi 扫描').fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary')).margin({ top: 40, bottom: 20 })
          Text('附近网络: ' + this.wifiViewModel.getScanner().scanResults.length + ' 个')
            .fontSize(16).fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .tabBar(this.TabBuilder($r('app.string.tab_wifi'), 1))

      // Tab 2 — 信道
      TabContent() {
        Column() {
          Text('信道分析').fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary')).margin({ top: 40, bottom: 20 })
          Text('2.4GHz / 5GHz 信道占用').fontSize(16)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .tabBar(this.TabBuilder($r('app.string.tab_channel'), 2))

      // Tab 3 — 测速
      TabContent() {
        Column() {
          Text('网络测速').fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary')).margin({ top: 40, bottom: 20 })
          Text('开始测试').fontSize(16)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .tabBar(this.TabBuilder($r('app.string.tab_speed'), 3))

      // Tab 4 — 工具箱
      TabContent() {
        Column() {
          Text('网络工具箱').fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary')).margin({ top: 40, bottom: 20 })
          Text('11 种网络工具').fontSize(16)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
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
