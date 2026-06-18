import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { WindowUtil } from 'wifi-base';
import { TabsView } from './TabsView';

@Entry
@ComponentV2
struct Index {
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack();
  @Local windowUtil: WindowUtil = new WindowUtil();

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
