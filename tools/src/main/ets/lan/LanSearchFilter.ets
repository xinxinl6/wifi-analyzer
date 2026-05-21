// 搜索栏 + 筛选标签 — Aurora WiFi V2

import {
  COLOR_PRIMARY, COLOR_SHADOW_DARK,
  FONT_SIZE_XS, FONT_SIZE_MD,
  FONT_WEIGHT_MEDIUM,
  SPACE_XS, SPACE_SM,
  RADIUS_3XL,
  GLASS_BLUR_LG,
  GLASS_SHADOW_SM,
  COLOR_GLASS_DARK_CARD, COLOR_GLASS_DARK_BORDER, COLOR_GLASS_WHITE, COLOR_GLASS_BORDER, COLOR_GLASS_SKY_LIGHT,
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary, adaptiveDivider,
  adaptiveCardBg
} from '@wifi-analyzer/design-system'

// ==================== 筛选类型 ====================

export enum FilterType {
  ALL = 'all',
  ONLINE = 'online',
  ROUTER = 'router',
  COMPUTER = 'computer'
}

// ==================== 搜索栏 + 筛选标签 ====================
@Component
export struct LanSearchFilter {
  @Prop isDarkMode: boolean = false
  @Prop searchKeyword: string = ''
  @Prop currentFilter: FilterType = FilterType.ALL
  onSearchChange: (value: string) => void = () => {}
  onFilterChange: (filter: FilterType) => void = () => {}
  onResetFilter: () => void = () => {}

  build() {
    Column({ space: 0 }) {
      this.SearchBar()
      this.FilterTags()
    }
  }

  // ==================== 搜索框 ====================
  @Builder SearchBar() {
    Row({ space: SPACE_SM }) {
      Image($r('app.media.ic_lan'))
        .width(20)
        .height(20)
        .fillColor(COLOR_PRIMARY)

      TextInput({ placeholder: $r('app.string.lan_search_hint'), text: this.searchKeyword })
        .placeholderColor(adaptiveTextTertiary(this.isDarkMode))
        .fontSize(FONT_SIZE_MD)
        .fontColor(adaptiveTextPrimary(this.isDarkMode))
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .height(44)
        .onChange((val: string) => this.onSearchChange(val))

      if (this.searchKeyword !== '') {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_mac'))
            .width(16)
            .height(16)
            .fillColor(adaptiveTextTertiary(this.isDarkMode))
        }
        .width(28)
        .height(28)
        .backgroundColor(adaptiveDivider(this.isDarkMode))
        .onClick(() => this.onSearchChange(''))
      }
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 13, bottom: 13 })
    .backgroundColor(this.isDarkMode ? COLOR_GLASS_DARK_CARD : COLOR_GLASS_WHITE)
    .borderRadius(18)
    .borderWidth(1.5)
    .borderColor(this.isDarkMode ? COLOR_GLASS_DARK_BORDER : COLOR_GLASS_BORDER)
    .backdropBlur(GLASS_BLUR_LG)
    .shadow({ radius: GLASS_SHADOW_SM, color: this.isDarkMode ? COLOR_SHADOW_DARK : COLOR_GLASS_SKY_LIGHT, offsetX: 0, offsetY: 4 })
  }

  // ==================== 筛选标签 ====================
  @Builder FilterTags() {
    Row({ space: SPACE_SM }) {
      this.FilterTag($r('app.string.lan_only_online'), FilterType.ONLINE)
      this.FilterTag($r('app.string.lan_router'), FilterType.ROUTER)
      this.FilterTag($r('app.string.lan_computer'), FilterType.COMPUTER)
      this.FilterTag($r('app.string.lan_all'), FilterType.ALL, true)
    }
    .width('100%')
  }

  @Builder FilterTag(label: string | Resource, type: FilterType, isReset: boolean = false) {
    Text(label)
      .fontSize(FONT_SIZE_XS)
      .fontColor(this.currentFilter === type && !isReset ? Color.White : (isReset ? COLOR_PRIMARY : adaptiveTextSecondary(this.isDarkMode)))
      .fontWeight(FONT_WEIGHT_MEDIUM)
      .padding({ left: SPACE_SM, right: SPACE_SM, top: SPACE_XS, bottom: SPACE_XS })
      .backgroundColor(this.currentFilter === type && !isReset ? COLOR_PRIMARY : (isReset ? (this.isDarkMode ? 'rgba(16,185,129,0.18)' : 'rgba(16,185,129,0.12)') : adaptiveCardBg(this.isDarkMode)))
      .borderRadius(RADIUS_3XL)
      .border({ width: (this.currentFilter === type || isReset) ? 0 : 1, color: adaptiveDivider(this.isDarkMode) })
      .stateStyles({ pressed: { opacity: 0.8 } })
      .onClick(() => {
        if (isReset) {
          this.onResetFilter()
        } else {
          this.onFilterChange(type)
        }
      })
  }
}
