// WOL 提示信息卡 — Aurora WiFi V2

import {
  COLOR_CYAN, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_LG, FONT_SIZE_MD, FONT_SIZE_SM,
  FONT_WEIGHT_BOLD, FONT_WEIGHT_MEDIUM,
  SPACE_MD, SPACE_SM, SPACE_LG, SPACE_XS,
  GLASS_BLUR_LG, GLASS_SHADOW_LG,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextPrimary, adaptiveTextTertiary, adaptiveTextSecondary, adaptiveDivider
} from '@wifi-analyzer/design-system'
import { WolDevice, WolEngine } from '../wol/WolEngine'

// ==================== 提示信息卡 ====================
@Component
export struct WolInfoCard {
  @Prop isDarkMode: boolean = false
  onAddFromPreset: (name: string) => void = () => {}

  build() {
    Column({ space: SPACE_LG }) {
      // InfoCard
      this.InfoCard()

      // 快速添加预设
      this.QuickPresets()
    }
  }

  @Builder InfoCard() {
    Column({ space: SPACE_MD }) {
      Row({ space: SPACE_MD }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle().width(44).height(44)
            .fill(this.isDarkMode ? 'rgba(34,211,238,0.15)' : '#E0F7FE')
          Image($r('app.media.ic_wol')).width(24).height(24).fillColor(COLOR_CYAN)
        }
        Column({ space: 4 }) {
          Text($r('app.string.remote_wake'))
            .fontSize(FONT_SIZE_LG).fontColor(adaptiveTextPrimary(this.isDarkMode)).fontWeight(FONT_WEIGHT_BOLD)
          Text($r('app.string.remote_wake_desc'))
            .fontSize(FONT_SIZE_XS).fontColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 14, top: 14, bottom: 14 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({
      radius: GLASS_SHADOW_LG,
      color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : COLOR_GLASS_SKY_LIGHT,
      offsetX: 0,
      offsetY: 4
    })
    .clip(true)
  }

  @Builder QuickPresets() {
    Column({ space: SPACE_SM }) {
      Text($r('app.string.quick_add'))
        .fontSize(FONT_SIZE_SM).fontColor(adaptiveTextTertiary(this.isDarkMode)).alignSelf(ItemAlign.Start)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(WolEngine.DEVICE_PRESETS, (preset: WolDevice) => {
          Text(preset.name)
            .fontSize(FONT_SIZE_XS)
            .fontColor(COLOR_CYAN)
            .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
            .backgroundColor(this.isDarkMode ? 'rgba(34,211,238,0.15)' : '#E0F7FE')
            .borderRadius(999)
            .stateStyles({ pressed: { opacity: 0.8 } })
            .onClick(() => this.onAddFromPreset(preset.name))
        }, (preset: WolDevice): string => preset.name)
      }
      .width('100%')
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }
}
