import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { WindowUtil, CommonConstants } from 'wifi-base';
import { TabsView } from './TabsView';

@Entry
@ComponentV2
struct Index {
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local windowUtil: WindowUtil = new WindowUtil();

  @Builder
  PagesMap(name: string) {
    if (name === CommonConstants.PING_PAGE) {
      // TODO: PingPage()
    } else if (name === CommonConstants.DNS_PAGE) {
      // TODO: DnsPage()
    }
  }

  build() {
    HdsNavigation(this.pageStack) {
      TabsView({ mainWindowInfo: this.windowUtil.mainWindowInfo })
    }
    .mode(NavigationMode.Stack)
    .titleMode(HdsNavigationTitleMode.MINI)
    .navDestination(this.PagesMap)
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}
