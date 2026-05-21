// IP 归属查询页面组件 — 天蓝色透明毛玻璃悬浮风格

import {
  SPACE_LG, SPACE_MD, SAFE_AREA_TOP,
  adaptiveBackgroundList, adaptiveGlowLarge, adaptiveGlowMedium
} from '@wifi-analyzer/design-system'
import { BackButtonGlass } from '@wifi-analyzer/design-system'
import { IpGeoEngine, IpGeoResult } from '../ipgeo/IpGeoEngine'
import { RouterManager, ValidationPatterns } from '@wifi-analyzer/core'
import promptAction from '@ohos.promptAction'
import { IpGeoIdleView } from './IpGeoIdleView'
import { IpGeoResultView } from './IpGeoResultView'

@Component
export struct IpGeoPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State inputText: string = ''
  @State viewMode: string = 'idle'
  @State isQuerying: boolean = false
  @State result: IpGeoResult = {
    ip: '', country: '', province: '', city: '', isp: '',
    district: '', latitude: 0, longitude: 0, timezone: '',
    queryTime: 0, status: 'error', errorMessage: '',
  }
  @State myIp: string = ''
  @State isDetectingMyIp: boolean = true
  private engine: IpGeoEngine = new IpGeoEngine()

  private getString(str: Resource): string {
    try {
      const ctx = this.getUIContext().getHostContext()
      return ctx ? ctx.resourceManager.getStringSync(str.id) : ''
    } catch (e) {
      return ''
    }
  }

  aboutToAppear(): void {
    this.myIp = ''
    this.detectMyIp()
  }

  private async detectMyIp(): Promise<void> {
    this.isDetectingMyIp = true
    const ip: string = await this.engine.queryMyIp()
    if (ip.length > 0) {
      this.myIp = ip
    } else {
      this.myIp = ''
    }
    this.isDetectingMyIp = false
  }

  private validateInput(ip: string): string {
    const trimmed = ip.trim()
    if (trimmed.length === 0) {
      return this.getString($r('app.string.err_empty_input'))
    }
    if (trimmed.length > 45) {
      return this.getString($r('app.string.err_input_too_long'))
    }
    if (!ValidationPatterns.isValidIpv4(trimmed) && !ValidationPatterns.isValidDomain(trimmed)) {
      return this.getString($r('app.string.err_invalid_ip_or_domain'))
    }
    return ''
  }

  async doQuery(): Promise<void> {
    const ip: string = this.inputText.trim()
    const errorMsg = this.validateInput(ip)
    if (errorMsg !== '') {
      promptAction.showToast({ message: errorMsg, duration: 2000 })
      return
    }
    this.isQuerying = true
    this.viewMode = 'querying'
    const queryResult: IpGeoResult = await this.engine.query(ip)
    this.result = queryResult
    this.isQuerying = false
    this.viewMode = 'result'
  }

  queryMyIpGeo(): void {
    if (typeof this.myIp === 'string') {
      this.inputText = this.myIp
    }
    this.doQuery()
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
          BackButtonGlass({
            onBack: () => {
              if (this.viewMode !== 'idle') {
                this.viewMode = 'idle'
              } else {
                RouterManager.goBack()
              }
            }
          })
          Blank()
        }
        .width('100%')
        .padding({ left: SPACE_LG, right: SPACE_LG, top: SAFE_AREA_TOP })
        .alignItems(VerticalAlign.Center)

        if (this.viewMode === 'idle') {
          IpGeoIdleView({
            isDarkMode: this.isDarkMode,
            inputText: this.inputText,
            myIp: this.myIp,
            isDetectingMyIp: this.isDetectingMyIp,
            onInputChange: (v) => { this.inputText = v },
            onSubmit: () => this.doQuery(),
            onQueryMyIp: () => this.queryMyIpGeo()
          })
        } else {
          IpGeoResultView({
            isDarkMode: this.isDarkMode,
            result: this.result,
            isQuerying: this.isQuerying,
            onBack: () => { this.viewMode = 'idle' },
            onReQuery: () => this.doQuery(),
            onEdit: () => {
              this.viewMode = 'idle'
              this.inputText = this.result.ip
            }
          })
        }
      }
      .width('100%').height('100%')
    }
    .width('100%').height('100%')
  }
}
