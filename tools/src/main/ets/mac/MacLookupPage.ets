// MAC 地址查询页面组件 — 天蓝色透明毛玻璃悬浮风格

import {
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium,
  SPACE_LG, SAFE_AREA_TOP, SAFE_AREA_BOTTOM, GLASS_BLUR_LG,
  GLASS_SHADOW_XL, COLOR_GLASS_SKY_LIGHT
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { MacLookupEngine, MacLookupResult } from '../maclookup/MacLookupEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import { MacIdleView } from './MacIdleView'
import { MacResultView } from './MacResultView'
import promptAction from '@ohos.promptAction'

@Component
export struct MacLookupPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State inputText: string = ''
  @State viewMode: string = 'idle'
  @State result: MacLookupResult = {
    mac: '', vendor: '', country: '', address: '',
    prefix: '', type: 'unknown', status: 'error',
    errorMessage: '', queryTime: 0, source: 'local'
  }
  @State historyList: string[] = []
  private engine: MacLookupEngine = new MacLookupEngine()

  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
      return ''
    }
  }

  aboutToAppear(): void {
    this.historyList = this.engine.getHistory()
  }

  private validateInput(mac: string): string {
    const trimmed = mac.trim()
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }
    if (trimmed.length > 17) {
      return this.getString($r('app.string.err_input_too_long'))
    }
    if (!ValidationPatterns.isValidMac(trimmed)) {
      return this.getString($r('app.string.err_invalid_mac'))
    }
    return ''
  }

  async doQuery(): Promise<void> {
    const mac: string = this.inputText.trim()
    const errorMsg = this.validateInput(mac)
    if (errorMsg !== '') {
      promptAction.showToast({ message: errorMsg, duration: 2000 })
      return
    }
    this.viewMode = 'querying'
    const queryResult: MacLookupResult = await this.engine.lookup(mac)
    this.result = queryResult
    this.viewMode = 'result'
    this.historyList = this.engine.getHistory()
  }

  // ==================== 页面入口 ====================
  build() {
    Stack() {
      // ===== Aurora 天蓝渐变背景 =====
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: adaptiveBackgroundList(this.isDarkMode)
        })

      // 极光装饰光晕
      Circle()
        .width(280)
        .height(280)
        .fill(adaptiveGlowLarge(this.isDarkMode))
        .position({ x: -60, y: -60 })

      Circle()
        .width(180)
        .height(180)
        .fill(adaptiveGlowMedium(this.isDarkMode))
        .position({ x: '68%', y: '45%' })

      // 主内容
      Column() {
        // 顶部返回按钮栏
        Row() {
          BackButtonGlass({ onBack: () => RouterManager.goBack() })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          MacIdleView({
            isDarkMode: this.isDarkMode,
            inputText: this.inputText,
            historyList: this.historyList,
            onInputChange: (value: string) => { this.inputText = value },
            onSubmit: () => this.doQuery(),
            onQuickTap: (mac: string) => {
              this.inputText = mac
              this.doQuery()
            },
            onHistoryTap: (mac: string) => {
              this.inputText = mac
              this.doQuery()
            }
          })
        } else {
          MacResultView({
            isDarkMode: this.isDarkMode,
            result: this.result,
            onBack: () => RouterManager.goBack(),
            onReQuery: () => this.doQuery(),
            onEdit: () => { this.viewMode = 'idle' }
          })
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }
}
