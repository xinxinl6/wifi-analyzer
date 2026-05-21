// 通用统计单元格 — label + value + color

import {
  FONT_SIZE_XS, FONT_SIZE_LG,
  FONT_WEIGHT_BOLD,
  SPACE_XS,
  adaptiveTextTertiary
} from '@wifi-analyzer/design-system'

@Component
export struct CommonStatCell {
  @Prop label: string = ''
  @Prop value: string = ''
  @Prop valueColor: string = ''

  build() {
    Column({ space: SPACE_XS }) {
      Text(this.label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(false))
      Text(this.value)
        .fontSize(FONT_SIZE_LG)
        .fontColor(this.valueColor)
        .fontWeight(FONT_WEIGHT_BOLD)
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }
}
