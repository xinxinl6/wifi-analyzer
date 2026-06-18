import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { WindowUtil, WINDOW_UTIL_KEY } from 'wifi-base';

@Entry
@ComponentV2
struct Index {
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local windowUtil: WindowUtil = AppStorageV2.connect(WindowUtil, WINDOW_UTIL_KEY)!;

  @Builder
  PagesMap(name: string) {
    // TODO: navigate to detail pages
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
