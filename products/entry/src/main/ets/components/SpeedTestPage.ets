// SpeedTestPage — 测速子页面（包装 SpeedTestSection）
import { SpeedTestSection } from './SpeedTestSection'

@Component
struct SpeedTestPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    SpeedTestSection({ isDark: this.isDarkMode, showBackButton: true })
  }
}

@Builder
export function SpeedTestPageBuilder() {
  NavDestination() {
    SpeedTestPage()
  }
  .hideTitleBar(true)
}

