// 子网预设标签区域组件

import {
  COLOR_WARNING,
  FONT_SIZE_XS, FONT_SIZE_SM,
  SPACE_XS, SPACE_SM,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_WHITE, COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER,
  COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextTertiary,
} from '@wifi-analyzer/design-system'
import { SubnetPreset } from '../subnet/SubnetCalculator'

@Component
export struct SubnetPresetSection {
  @Prop isDarkMode: boolean = false
  @Prop presets: SubnetPreset[] = []
  onPresetTap: (preset: SubnetPreset) => void = () => {}

  build() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.common_subnets'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode))
        .alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.presets, (preset: SubnetPreset) => {
          Text(preset.label)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_WARNING)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.isDarkMode ? 'rgba(245,158,11,0.15)' : '#FEF3C7')
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onPresetTap(preset))
        }, (preset: SubnetPreset): string => preset.label)
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_LG, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
    .clip(true)
  }
}
