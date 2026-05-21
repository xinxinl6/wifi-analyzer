// 通用详情行组件 — label + value 横向排列

import {
  FONT_SIZE_XS, FONT_SIZE_SM,
  FONT_WEIGHT_MEDIUM,
  adaptiveTextPrimary, adaptiveTextTertiary
} from '@wifi-analyzer/design-system'

@Component
export struct CommonDetailRow {
  @Prop isDarkMode: boolean = false
  @Prop label: string | Resource = ''
  @Prop value: string | Resource = ''
  @Prop valueColor: string = ''
  @Prop labelWidth: number = 70

  build() {
    Row() {
      Text(this.label)
        .fontSize(FONT_SIZE_XS)
        .fontColor(adaptiveTextTertiary(this.isDarkMode))
        .width(this.labelWidth)
      Text(this.value)
        .fontSize(FONT_SIZE_SM)
        .fontColor(this.valueColor.length > 0 ? this.valueColor : adaptiveTextPrimary(this.isDarkMode))
        .fontWeight(FONT_WEIGHT_MEDIUM)
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }
}
