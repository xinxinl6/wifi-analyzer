/**
 * MaterialLevelMenu — 材质级别选择菜单
 * 参照 Spatialization 项目的材质级别切换功能
 * 用户可选择 ADAPTIVE / IMMERSIVE / IMMERSIVE_HIGH
 */

import { preferences } from '@kit.ArkData';
import {
  GlobalInfoModel,
  MaterialLevelType,
  MATERIAL_LEVEL_LABELS
} from '../model/GlobalInfoModel';
import Logger from '../utils/Logger';

const TAG = '[MaterialLevelMenu]';
const STORE_NAME = 'ui_settings';
const KEY_MATERIAL_LEVEL = 'material_level';

@Component
export struct MaterialLevelMenu {
  @StorageLink('isDarkMode') isDarkMode: boolean = true;

  @State currentLevel: MaterialLevelType = MaterialLevelType.IMMERSIVE;

  aboutToAppear(): void {
    this.loadSavedLevel();
  }

  private async loadSavedLevel(): Promise<void> {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, STORE_NAME);
      const saved = await prefs.get(KEY_MATERIAL_LEVEL, 1);
      this.currentLevel = (saved !== null && saved !== undefined) ? saved as MaterialLevelType : MaterialLevelType.IMMERSIVE;
    } catch (e) {
      Logger.warn(TAG + ' Failed to load material level: ' + JSON.stringify(e));
    }
  }

  private async setLevel(level: MaterialLevelType): Promise<void> {
    this.currentLevel = level;
    GlobalInfoModel.getInstance().materialLevel = level;
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, STORE_NAME);
      await prefs.put(KEY_MATERIAL_LEVEL, level);
      await prefs.flush();
      Logger.info(TAG + ' Material level saved: ' + level);
    } catch (e) {
      Logger.warn(TAG + ' Failed to save material level: ' + JSON.stringify(e));
    }
  }

  build() {
    Column({ space: 8 }) {
      Text('毛玻璃材质级别')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFFE6' : '#1E293B')

      ForEach(
        [MaterialLevelType.ADAPTIVE, MaterialLevelType.IMMERSIVE, MaterialLevelType.IMMERSIVE_HIGH],
        (level: MaterialLevelType) => {
          Row({ space: 12 }) {
            Radio({ value: 'level_' + level, group: 'materialGroup' })
              .checked(this.currentLevel === level)
              .onChange(() => { this.setLevel(level); })

            Text(MATERIAL_LEVEL_LABELS[level])
              .fontSize(14)
              .fontColor(this.isDarkMode ? '#FFFFFFCC' : '#475569')
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
          .onClick(() => { this.setLevel(level); })
        }
      )
    }
    .padding(16)
    .width('100%')
  }
}
