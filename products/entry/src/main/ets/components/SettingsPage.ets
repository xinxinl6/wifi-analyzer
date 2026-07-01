// SettingsPage — 已接入 $r() 国际化资源引用
import {
  adaptiveTextPrimary, adaptiveTextSecondary, adaptiveTextTertiary,
  adaptiveBorderCyan, adaptiveBtnBg, adaptiveBackgroundList,
  adaptiveGlowLarge, adaptiveGlowMedium,
  RADIUS_XL, SPACE_LG, SPACE_MD,
} from '@wifi-analyzer/design-system';
import { RouterManager } from '@wifi-analyzer/core';
import promptAction from '@ohos.promptAction';
import i18n from '@ohos.i18n';
import { checkUpdate } from '../utils/UpdateChecker';

function loadRes(name: string): string {
  try {
    return getContext().resourceManager.getStringByNameSync(name)
  } catch (_e) {
    return ''
  }
}

interface AboutItem {
  icon: string
  titleKey: Resource
  subtitleKey: Resource
}

@Builder
export function SettingsPageBuilder() {
  NavDestination() {
    SettingsPage()
  }
  .title($r('app.string.settings'))
  .hideTitleBar(true)
}

@Component
export struct SettingsPage {
  @StorageLink('isDarkMode') isDark: boolean = false
  private aboutItems: AboutItem[] = [
    { icon: 'ℹ️', titleKey: $r('app.string.about_us'), subtitleKey: $r('app.string.about_app') },
    { icon: '📄', titleKey: $r('app.string.privacy_policy'), subtitleKey: $r('app.string.privacy_desc') },
    { icon: '📋', titleKey: $r('app.string.user_agreement'), subtitleKey: $r('app.string.agreement_desc') },
    { icon: '💬', titleKey: $r('app.string.feedback'), subtitleKey: $r('app.string.feedback_desc') },
    { icon: '🌐', titleKey: $r('app.string.app_website'), subtitleKey: $r('app.string.website_url') },
  ]

  private getSystemLanguageDisplay(): string {
    try {
      const lang: string = i18n.getSystemLanguage()
      if (lang) {
        return lang.includes('zh') ? '简体中文' : 'English'
      }
    } catch (_e) {}
    return '简体中文'
  }

  private onLanguageTap(): void {
    const isZh: boolean = i18n.getSystemLanguage().includes('zh')
    promptAction.showDialog({
      title: '选择语言 / Select Language',
      message: isZh
        ? '请在系统设置 > 语言与地区 中切换语言，切换后重启应用生效。'
        : 'Please go to Settings > Language & Region to switch language, then restart the app.',
      buttons: [
        { text: '简体中文', color: '#317AF7' },
        { text: 'English', color: '#317AF7' }
      ],
      alignment: DialogAlignment.Bottom
    }).then((res) => {
      if (res.index === 0 && !isZh) {
        promptAction.showToast({ message: loadRes('language_switch_zh'), duration: 2000 })
      } else if (res.index === 1 && isZh) {
        promptAction.showToast({ message: loadRes('language_switch_en'), duration: 2000 })
      }
    })
  }

  private async onCheckUpdate(): Promise<void> {
    promptAction.showToast({ message: loadRes('update_checking'), duration: 1000 })
    const result = await checkUpdate()
    if (result.errorMsg) {
      const errMsg = result.errorMsg.includes('connect')
        ? loadRes('update_network_error') : loadRes('update_error')
      promptAction.showToast({ message: errMsg, duration: 2000 })
      return
    }
    if (!result.hasUpdate) {
      promptAction.showToast({ message: loadRes('update_latest') + ' v' + result.currentVersion, duration: 2000 })
      return
    }
    promptAction.showDialog({
      title: loadRes('update_new_found') + ' ' + result.remoteInfo!.version,
      message: loadRes('update_content') + ':\n' + (result.remoteInfo!.changelog && result.remoteInfo!.changelog.length > 0
        ? result.remoteInfo!.changelog.join('\n') : loadRes('update_no_info')),
      buttons: [
        { text: loadRes('update_now'), color: '#317AF7' },
        { text: loadRes('update_later'), color: '#9CA3AF' }
      ],
      alignment: DialogAlignment.Bottom
    }).then((res) => {
      if (res.index === 0 && result.remoteInfo!.downloadUrl) {
        promptAction.showToast({ message: loadRes('update_download') + ': ' + result.remoteInfo!.downloadUrl, duration: 3000 })
      }
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景渐变
      Column().width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Bottom, colors: adaptiveBackgroundList(this.isDark) })

      // 装饰光晕（与路由追踪页统一）
      Circle().width(280).height(280).fill(adaptiveGlowLarge(this.isDark)).position({ x: -80, y: -80 })
      Circle().width(200).height(200).fill(adaptiveGlowMedium(this.isDark)).position({ x: '70%', y: '50%' })

      Column() {
        // 顶部标题栏
        Row({ space: 12 }) {
          Row() { Text('←').fontSize(18).fontWeight(700).fontColor(adaptiveTextSecondary(this.isDark)) }
            .width(36).height(36).justifyContent(FlexAlign.Center).borderRadius(8)
            .backgroundColor(adaptiveBtnBg(this.isDark))
            .onClick(() => { RouterManager.goBack() })
          Text($r('app.string.settings')).fontSize(20).fontWeight(700).fontColor(adaptiveTextPrimary(this.isDark))
        }.width('100%').padding({ left: 20, right: 20, top: 44, bottom: 12 })

        Scroll() {
          Column({ space: SPACE_MD }) {
            // ═══ 通用 ═══
            this.sectionTitle($r('app.string.general'))
            Column({ space: 0 }) {
              // 语言
              Row({ space: 12 }) {
                Text($r('app.string.language')).fontSize(15).fontWeight(500).fontColor(adaptiveTextPrimary(this.isDark)).layoutWeight(1)
                Text(this.getSystemLanguageDisplay()).fontSize(14).fontColor(adaptiveTextTertiary(this.isDark))
                Text('›').fontSize(16).fontColor(adaptiveTextTertiary(this.isDark)).opacity(0.3)
              }.width('100%').height(48).padding({ left: SPACE_LG, right: SPACE_LG }).onClick(() => { this.onLanguageTap() })
              this.divider()
              // 检查更新
              Row({ space: 12 }) {
                Text($r('app.string.check_update')).fontSize(15).fontWeight(500).fontColor(adaptiveTextPrimary(this.isDark)).layoutWeight(1)
                Text('›').fontSize(16).fontColor(adaptiveTextTertiary(this.isDark)).opacity(0.3)
              }.width('100%').height(48).padding({ left: SPACE_LG, right: SPACE_LG }).onClick(() => { this.onCheckUpdate() })
            }.width('100%')
              .backgroundColor(this.isDark ? 'rgba(30,41,59,0.3)' : 'rgba(255,255,255,0.3)')
              .borderRadius(RADIUS_XL)

            // ═══ 关于 ═══
            this.sectionTitle($r('app.string.about'))
            Column({ space: 0 }) {
              ForEach(this.aboutItems, (item: AboutItem, index: number) => {
                this.aboutRow(item.icon, item.titleKey, item.subtitleKey, () => {
                  this.onAboutItemTap(index)
                })
                if (index < this.aboutItems.length - 1) {
                  this.divider()
                }
              })
            }.width('100%')
              .backgroundColor(this.isDark ? 'rgba(30,41,59,0.3)' : 'rgba(255,255,255,0.3)')
              .borderRadius(RADIUS_XL)

          }.padding({ left: 20, right: 20, bottom: 40 })
        }.align(Alignment.Top).layoutWeight(1).scrollBar(BarState.Off)
      }.width('100%').height('100%')
    }.width('100%').height('100%')
  }

  private onAboutItemTap(index: number): void {
    if (index === 0) {
      promptAction.showDialog({
        title: loadRes('about_us'),
        message: loadRes('about_content'),
        buttons: [{ text: loadRes('close'), color: '#317AF7' }], alignment: DialogAlignment.Bottom
      })
    } else if (index === 1) {
      promptAction.showDialog({
        title: loadRes('privacy_policy'),
        message: loadRes('privacy_content'),
        buttons: [{ text: loadRes('close'), color: '#317AF7' }], alignment: DialogAlignment.Bottom
      })
    } else if (index === 2) {
      promptAction.showDialog({
        title: loadRes('user_agreement'),
        message: loadRes('agreement_content'),
        buttons: [{ text: loadRes('close'), color: '#317AF7' }], alignment: DialogAlignment.Bottom
      })
    } else if (index === 3) {
      promptAction.showDialog({
        title: loadRes('feedback'),
        message: loadRes('feedback_content'),
        buttons: [{ text: loadRes('close'), color: '#317AF7' }], alignment: DialogAlignment.Bottom
      })
    } else if (index === 4) {
      promptAction.showDialog({
        title: loadRes('app_website'),
        message: 'www.xinnxin.cn',
        buttons: [{ text: loadRes('close'), color: '#317AF7' }], alignment: DialogAlignment.Bottom
      })
    }
  }

  @Builder sectionTitle(title: Resource) {
    Text(title).fontSize(13).fontWeight(700).fontColor(adaptiveTextTertiary(this.isDark))
      .width('100%').padding({ top: 8, bottom: 6, left: 4 })
      .textCase(TextCase.UpperCase).letterSpacing(0.5)
  }

  @Builder aboutRow(icon: string, title: Resource, subtitle: Resource, onClick: () => void) {
    Row({ space: 12 }) {
      Text(icon).fontSize(18).width(28).textAlign(TextAlign.Center)
      Column({ space: 2 }) {
        Text(title).fontSize(15).fontWeight(500).fontColor(adaptiveTextPrimary(this.isDark))
        Text(subtitle).fontSize(11).fontColor(adaptiveTextTertiary(this.isDark)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text('›').fontSize(16).fontColor(adaptiveTextTertiary(this.isDark)).opacity(0.3)
    }.width('100%').height(56).padding({ left: SPACE_LG, right: SPACE_LG }).onClick(() => { onClick() })
  }

  @Builder divider() {
    Row().width('100%').height(0.5)
      .backgroundColor(adaptiveBorderCyan(this.isDark)).opacity(0.1)
      .margin({ left: SPACE_LG, right: SPACE_LG })
  }
}
