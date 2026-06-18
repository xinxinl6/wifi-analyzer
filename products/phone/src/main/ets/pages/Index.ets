import { AppStorageV2 } from '@kit.ArkUI';
import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { WindowUtil, WINDOW_UTIL_KEY, CommonConstants } from 'wifi-base';
import { TabsView } from './TabsView';

@Entry
@ComponentV2
struct Index {
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local windowUtil: WindowUtil = AppStorageV2.connect(WindowUtil, WINDOW_UTIL_KEY)!;
  @Local bottomNavi: number = 0;

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
