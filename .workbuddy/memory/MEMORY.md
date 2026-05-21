# WiFi分析仪项目长期记忆

## 项目基本信息
- **项目**: WiFi 分析仪 — HarmonyOS (OpenHarmony) 应用
- **功能**: WiFi扫描、信道分析、网络测速、网络工具箱(DNS/Ping/Traceroute/局域网扫描)
- **技术栈**: ArkUI + ArkTS, 模块化 HAR 架构
- **目标SDK**: 6.1.0(23)，兼容5.0.2(14)
- **目标设备**: 手机、平板、2合1设备

## 架构
- **模块**: entry(主入口) / core(WiFi引擎) / tools(DNS/Ping/Traceroute/LAN) / design-system(Aurora) / speed-test(测速)
- **状态管理**: `@Provide/@Consume` + AppStorage 全局共享
- **路由**: RouterManager 支持双模式导航
- **深色模式**: `@StorageLink('isDarkMode')` 全局共享，EntryAbility 中 `onConfigurationUpdate` 设置

## UI 设计系统 — Aurora WiFi
- **风格**: 天蓝极光科技风，主色 `#4A90D9` → `#87CEEB` 渐变
- **核心**: 毛玻璃(backdrop-blur+半透明+微光边框) + 悬浮TabBar + Scale点击动效 + AI助手FAB
- **深浅色适配**: `adaptiveTextPrimary/Secondary/Tertiary(isDark)` + `adaptiveCardBg(isDark)` 辅助函数
- **关键色值**: 暗色卡片 `rgba(26,39,68,0.85)` / 亮色卡片 `rgba(255,255,255,0.65)` / 亮色主文字 `#1E293B`
- **TabBar**: Stack底部悬浮, 90%宽, 72vp高, 选中`#007AFF`, 20vp安全区

## ArkTS 踩坑速查
1. **hitTestBehavior** — 用 `hitTestBehavior(HitTestMode.None)`，不是 `hitTestMode`
2. **UIAbilityContext** — `this.getUIContext().getHostContext()`，不是 `getContext()`
3. **内置组件不导入** — Column/Row/Stack/Text/Image 等不从 `@kit.ArkUI` 导入
4. **交集类型禁止** — `Partial<A> & Partial<B>` → 定义显式 interface
5. **字段索引访问禁止** — `obj[key]` → if-else 分支
6. **Curve.Spring 不存在** — 用 `Curve.FastOutSlowIn`
7. **animateTo** — 用 `this.getUIContext().animateTo()`，旧 `animateTo` 已废弃
8. **@Prop 复杂对象不可靠** — 拆成多个独立简单类型 @Prop，或在 @Watch 中不依赖复杂对象值
9. **@Builder 内禁止声明变量** — 用内联表达式
10. **deviceInfo 是命名空间** — 只能访问静态属性(`brand/deviceType/productModel`)，不能 `as Record` 或索引访问；**无 `model` 属性，用 `productModel`**
11. **catch 必须绑定变量** — `catch(e)` 而非 `catch{}`
12. **JSON.parse 需类型断言** — `JSON.parse(s) as Record<string, string>` 消除 any
13. **static interface 禁止** — ArkTS 不支持 `static interface`，接口必须声明在类外
14. **对象字面量返回类型禁止** — `(): { a: number }` 不合法，必须提取为命名 interface
15. **@StorageLink 禁止外部初始化** — 父组件不能给子组件 @StorageLink 属性赋值
16. **自定义属性名避免与内置冲突** — 如 `onClick` 与 `CustomComponent.onClick` 冲突，需改名
17. **COLOR_GLASS_SKY_DIVIDER 不存在** — 用 `COLOR_SKY_BLUE_DIVIDER`
18. **COLOR_SKY_BLUE_ACTIVE 不存在** — 用 `COLOR_GLASS_SKY_ACTIVE`
19. **GLASS_BLUR_10 不存在** — 用 `GLASS_BLUR_MD`(8) 或 `GLASS_BLUR_SM`(6)
20. **@Observed 装饰器** — PulseIndicator 等纯逻辑类如需 @ObjectLink 传递，必须加 @Observed
21. **@Consume 不需初始值** — @Consume 由 @Provide 注入，interface 类型不能 `new`，对象字面量初始化也不合法
22. **import 语句不能断裂** — 两个 import 不能合并写，缺 `import {` 开头会被当作逗号表达式（ArkTS 禁止逗号操作符）
23. **@ObjectLink 只接受 @State 传递** — 普通私有属性(private)不能传给 @ObjectLink；替代方案：用 @Prop 传所需的具体值（如 pulseOpacity 代替 pulser 对象）

## Native ICMP Ping (2026-05-16)
- **原因**: 华为审核驳回 TCP 伪Ping
- **实现**: C++ NAPI (`entry/src/main/cpp/`) + ArkTS 封装 (`NativePing.ets`)
- **API**: `OH_NetConn_QueryProbeResult` → `libnet_connection.so`
- **依赖**: API 20+ / HarmonyOS 6.0+
- **双模式**: 快速(1s) / 准确(3s)

## @ohos-rs/traceroute (2026-05-05)
- **版本**: ^0.1.2，ohpm 安装
- **API**: `traceRouteWithSignal(target, signal, options?)` + `onTrace` 实时回调
- **注意**: AbortSignal 只支持 `timeout`/`abort` 静态方法

## DNS DoH 查询重构 (2026-05-16)
- **方案**: HTTP DNS (DoH) JSON-over-HTTPS，选了指定DNS服务器→请求对应DoH接口
- **服务器**: 阿里/Google/Cloudflare 各有 DoH JSON API；系统默认走 `connection.getAddressesByName()`
- **记录**: 支持 A/AAAA/CNAME/MX/NS/TXT 6种并行查询
- **持久化**: DataPreferences，store=`dns_lookup_history`，上限50条

## GitHub 仓库
- **地址**: https://github.com/xinxinl6/wifi-analyzer
- **用户**: xinxinl6 / 1218478630@QQ.COM
- **可见性**: Public，默认分支 main

## 项目约定
- 中文注释和日志(hilog)
- 资源字符串外部化到 string.json
- 设计 token 集中在 design-system 模块
- 配置常量集中管理 — `core/src/main/ets/config/NetworkConfig.ets`
- 错误处理用 try-catch + 用户友好提示

## 构建命令
- DevEco Studio: Build → Build HAP(s)/APP(s)
- 命令行: `hvigorw.bat assembleHap`（需设置 `DEVECO_SDK_HOME`）

## 上线前全检结果 (2026-05-16)
- **结论**: 🟡 有条件通过 — 5项阻塞项
- **阻塞项**: ①签名密钥明文 ②隐私邮箱QQ ③真机fallback无提示 ④权限拒绝terminateApp ⑤PingEngine双重resolve
- **报告**: `deliverables/gstack/pre-launch-check-wifi-analyzer-2026-05-16.md`
- **修复状态**: ✅ P0(7项) + P1(11项) 全部修复完成 (2026-05-16)
- **修复摘要**: 签名密钥清空+gitignore; QQ邮箱→outlook; fallback双模式提示; 权限弹窗改有限功能; PingEngine防双重resolve; wifiState统一; HTTP→HTTPS; 日志脱敏; WebView加固; Release日志INFO; 扫描频率12s; 排序降序; 测速标注"估算/模拟"; IP API统一; console→hilog

## 隐私政策前置流程 (2026-05-16)
- **触发**: 华为审核驳回 — "同意隐私政策前获取位置信息"
- **实现**: Index.ets 启动时 `checkPrivacyAgreement()` → DataPreferences 读状态 → 未同意则弹窗
- **弹窗**: 毛玻璃卡片，含隐私政策+用户协议 Scroll 内容区，「不同意」(terminateSelf) /「同意并继续」(保存+请求权限)
- **持久化**: DataPreferences, store=`privacy_agreement`, key=`user_agreed`
- **关键**: 权限请求必须在用户点击「同意」之后才触发

## 权限返回重检流程 (2026-05-16)
- **触发**: 华为审核驳回 — "跳转设置页面无获取位置权限选项，需删除后台后进入应用才弹出权限申请"
- **根因**: `requestPermissionsAndScan()` 只执行一次；`openAppSettings` URI 不够精确
- **修复1 — onPageShow()**: Index.ets 新增 `onPageShow()` 生命周期钩子，从设置/后台返回时自动重检权限（条件：privacyAgreed && !permissionGranted）
- **修复2 — recheckPermissionsOnReturn()**: 异步重调 `PermissionManager.requestPermissions()`，已授权→扫描，仍拒绝→重新弹引导弹窗
- **修复3 — openAppSettings URI优化**: 首选 `permission_manager_apps`(权限管理页)，fallback 到 `application_info_entry` 等
- **关键 ArkTS 知识**: Page 组件支持 `onPageShow()/onPageHide()` 生命周期方法，每次页面可见性变化时触发

## 大文件拆分 (2026-05-20)
- **范围**: tools 11个Page + entry 12个大组件，全部按网络层拆分
- **新增文件**: 94个（tools 51个 + entry 43个），总计 ~10,500 行
- **模式**: @Prop 传数据 + 函数属性传事件回调，不用 @Link
- **桶文件**: AuroraGlassComponents.ets / AuroraAIModule.ets 改为 re-export 桶文件，外部导入零变化
- **通用组件**: tools/common/ 下 9 个 Common* 组件（尚未被 Page 引用，待逐步替换）
- **工具类**: PingStatsHelper / GatewayDetector / SpeedTestHelper / SpeedTestStorage / TabAnimationHelper / DeviceUtils / ChannelCalculator
- **仍偏大的文件**: LanScanPage(376), SubnetResultSection(255), PoeResultSection(248), PingResultView(271), PortScanView(223)

## 资源统一 — 硬编码替换 (2026-05-18)
- **范围**: entry + tools + speed-test 模块所有 .ets 文件
- **颜色替换**: ~300+处 → design-system Token (COLOR_OVERLAY/COLOR_GLASS_*/COLOR_SHADOW_*/adaptiveText*等)
- **字符串替换**: ~19处UI硬编码中文 → $r('app.string.xxx')
- **新增string.json**: entry 3个 + tools 7个 = 10个条目
- **新增en_US/string.json**: 176行英文翻译
- **P2剩余(合理保留)**:
  - 颜色 ~103处: #FFFFFF白色文字(8处)、暗亮模式三元rgba、渐变数组、Engine数据配置色
  - 中文 ~9处UI: 全在Engine数据层文件，非UI组件
  - 建议补充: COLOR_TEXT_ON_COLOR Token、浅色卡片背景Token(#EEF2FF/#ECFDF5/#F5F3FF)
- **变更统计**: 67文件, +4031/-11260行

## 签名配置 (2026-05-16)
- **build-profile.json5**: `signingConfigs` 设为 `[]`（开发阶段由 DevEco Studio 自动签名）
- **原因**: 密码明文不安全；空字符串长度<32报错

---
*最后更新: 2026-05-18*
