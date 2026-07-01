import { BaseAbility } from 'wifi-base';
import { PingStorage } from '../utils/PingStorage';
import { AbilityConstant, Want } from '@kit.AbilityKit';

export default class EntryAbility extends BaseAbility {
  protected pageUrl: string = 'pages/Launcher';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam);
    PingStorage.init(this.context);
  }
}
