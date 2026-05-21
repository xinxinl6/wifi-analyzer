# WiFi 分析仪上线前全检报告

**日期**：2026-05-16
**场景**：上线前检查（代码审查 + 安全审计 + QA测试）
**参与成员**：产品评审员 + 安全官 + QA主管

---

## 📌 TL;DR（执行摘要）

- 整体结论：🟡 **有条件通过** — 存在 5 项阻塞项需上线前修复
- 阻塞项数量：5（安全 2 + 合规 1 + 功能 1 + 体验 1）
- 下一步：修复 5 项阻塞项后可上线；11 项重要问题建议首版迭代修复

---

## 🎯 核心结论卡片

| 项目 | 内容 |
|------|------|
| Go / No-Go | 🟡 条件 Go |
| 严重度分布 | 🔴 7 / 🟠 15 / 🟡 14 / 🟢 6 |
| 关键行动项 | 5 条阻塞项 + 11 条重要修复 |
| 建议负责人 | 开发者（xinxinl6） |

---

## 1. 各成员核心结论

### 🔍 产品评审员（代码审查）
- 核心判断：🟠 Conditional Go — 2 项严重（状态管理双路径、PingEngine 双重 resolve）+ 11 项重要
- 关键建议：统一 wifiState 更新入口；PingEngine 添加 resolved 标志位；测速结果标注"估算值"；WiFi 扫描频率降至 10-15 秒

### 🛡️ 安全官（OWASP+STRIDE 审计）
- 核心判断：🟠 Conditional Go — 2 项严重（签名密钥明文、证书目录未排除）+ 4 项高危
- 关键建议：立即移除 build-profile 密码 + 创建 .gitignore + 轮换证书；HTTP→HTTPS；日志脱敏；WebView 加固；Release 日志级别

### ✅ QA主管（QA测试与发布）
- 核心判断：🟠 Conditional Go — 3 项严重（硬编码中文85+处、隐私邮箱为QQ号、真机fallback无提示+权限拒绝强制退出）+ 4 项较高
- 关键建议：替换隐私邮箱为企业邮箱；真机 fallback 需显示提示；权限拒绝改为有限功能而非 terminateApp

---

## 2. 综合审查发现（去重合并后按严重度排序）

### 🔴 严重（7 项 — 上线前必须修复）

| # | 类别 | 位置 | 问题描述 | 建议 | 来源 |
|---|------|------|---------|------|------|
| S-1 | 安全 | `build-profile.json5` | 签名密钥密码明文存储（keyPassword/storePassword） | 移除密码，改用环境变量或签名配置文件 | 安全官 |
| S-2 | 安全 | `Key/` 目录 | 完整发布签名证书（.p12/.cer/.p7b）在项目根目录，无 .gitignore 排除 | 创建 .gitignore 排除 Key/，轮换已泄露证书 | 安全官 |
| S-3 | 合规 | `AboutPage.ets:35,61` | 隐私政策联系方式为个人 QQ 邮箱，华为审核可能拒绝 | 替换为企业邮箱或官方反馈渠道 | QA |
| S-4 | 功能 | `AuroraDashboard.ets:810` | 真机 fallback 数据无任何提示，用户误以为是真实 WiFi 数据 | 改为：模拟器显示"模拟数据"提示，真机显示"数据获取受限"提示 | QA+安全 |
| S-5 | 体验 | `PermissionManager.ets` | 权限拒绝后调用 `terminateApp()` 强制退出应用 | 改为允许无权限下使用有限功能（如查看已缓存数据） | QA |
| S-6 | 代码 | `Index.ets` + `AuroraDashboard.ets` | wifiState 存在 @Provide/@Consume 和 AppStorage 两条更新路径，可能状态不一致 | 统一为单一更新源，子组件只读消费 | 产品 |
| S-7 | 代码 | `PingEngine.ets:177-206` | TCP Ping 的 connect 回调和 setTimeout 超时可能同时 resolve Promise | 添加 resolved 标志位防止双重 resolve | 产品 |

### 🟠 重要（15 项 — 本迭代建议修复）

| # | 类别 | 位置 | 问题描述 | 建议 | 来源 |
|---|------|------|---------|------|------|
| H-1 | 安全 | `IpGeoEngine.ets` | HTTP 明文查询 IP 归属地（ip-api.com 等） | 改为 HTTPS API | 安全官 |
| H-2 | 安全 | `Traceroute/LAN/PortScan` | HTTP 明文探测，存在中间人攻击风险 | 评估是否可改 HTTPS，或添加证书校验 | 安全官 |
| H-3 | 安全 | `WifiScanner.ets` 等多文件 | hilog 直接输出 WiFi SSID + BSSID，位置隐私泄露 | 脱敏处理（SSID 只显示前3字符+BSSID 掩码） | 安全官 |
| H-4 | 安全 | `AuroraDashboard.ets` WebView | 百度搜索 WebView 无安全限制 | 禁用文件访问 + 限制 JS 接口 + URL 白名单完善 | 安全官 |
| H-5 | 安全 | `LoggerConfig` | Release 构建日志级别仍为 DEBUG | Release 设为 INFO/WARN | 安全官 |
| H-6 | 代码 | `PingEngine.ets:6-7` | 旧式 `@ohos.net.*` 导入，应迁移到 `@kit.NetworkKit` | 统一迁移 | 产品 |
| H-7 | 代码 | `SpeedTestEngine.ets:273-287` | 下载速度用 Math.random() 模拟，非真实测速 | UI 标注"估算值"；后续改用 on('dataReceive') 计算真实速度 | 产品 |
| H-8 | 代码 | `SpeedTestEngine.ets:329-347` | 上传速度完全模拟（下载速度 × 随机比例） | UI 明确标注"上传速度为估算值" | 产品 |
| H-9 | 代码 | `Index.ets:171-176` | 每 5 秒执行完整 WiFi 扫描，频率过高 | 降至 10-15 秒；仅前台执行；监听 wifiStateChange 事件 | 产品 |
| H-10 | 代码 | `WifiScanner.ets:289` | sort 排序方向错误（升序而非降序），信号最弱排最前 | 改为 `b.signal - a.signal` 降序 | 产品 |
| H-11 | 代码 | `NetworkDiagnostics.ets:193-198` | 公网 IP API 列表硬编码，与 NetworkConfig.PublicIpConfig 不同步 | 统一使用 PublicIpConfig | 产品 |
| H-12 | QA | 多文件（85+处） | 大量硬编码中文字符串未外部化到 string.json | 逐步迁移至 $r() 引用 | QA |
| H-13 | QA | `AuroraDashboard.ets:70-83` | 模拟器检测仅检查 brand 字段，逻辑简陋 | 补充 deviceType/model 检查 | QA |
| H-14 | QA | 多页面 | 加载/空状态处理部分缺失（LAN扫描、端口扫描等） | 补充空数据提示 | QA |
| H-15 | QA | `RouterManager` | 多页面快速点击可能导致并发导航、UI 叠加 | 添加导航锁 | QA |

### 🟡 一般（14 项 — 下一迭代修复）

| # | 类别 | 位置 | 问题描述 | 来源 |
|---|------|------|---------|------|
| M-1 | 安全 | DNS/Ping 历史用 DataPreferences 明文存储 | 安全官 |
| M-2 | 安全 | NAPI NativePing 缺少输入长度/范围校验 | 安全官 |
| M-3 | 安全 | 端口扫描 SSRF 防护不完整（未检查 IPv6/域名解析内网） | 安全官 |
| M-4 | 代码 | PingEngine as Record<> 类型断言绕过类型检查 | 产品 |
| M-5 | 代码 | PingEngine declare class 覆盖全局类型 | 产品 |
| M-6 | 代码 | 多处 catch(e) 直接 `as Error` 不合规 | 产品 |
| M-7 | 代码 | WebviewController 在类声明时直接 new | 产品 |
| M-8 | 代码 | WifiListSection 未使用的 @State itemScales | 产品 |
| M-9 | 代码 | Tab 动画 5 个 @State 数组频繁替换 | 产品 |
| M-10 | 代码 | AuroraBackground 光晕未设置 hitTestBehavior(None) | 产品 |
| M-11 | QA | 应用名 "WlAN" 疑似应为 "WLAN" | QA |
| M-12 | QA | 50+ 处 console.log/warn/error 未清理 | QA |
| M-13 | QA | NetworkConfig 默认网关 192.168.1.1 硬编码 | QA |
| M-14 | QA | AboutPage 隐私政策/用户协议内容全量硬编码 | QA |

---

## ✅ 行动清单

### 上线前必须修复（5 项阻塞）

| # | 行动 | 负责方 | 紧急度 | 期望完成 |
|---|------|--------|--------|---------|
| 1 | **移除 build-profile.json5 中的 keyPassword/storePassword**，改用环境变量；创建 .gitignore 排除 Key/ 目录；轮换已暴露的签名证书 | 开发者 | P0 | 上线前 |
| 2 | **替换隐私政策中的 QQ 邮箱为企业邮箱/官方渠道**（AboutPage.ets:35,61） | 开发者 | P0 | 上线前 |
| 3 | **修改 fallback 提示逻辑**：模拟器显示"模拟数据"提示，真机显示"数据获取受限，部分信息可能不准确"提示 | 开发者 | P0 | 上线前 |
| 4 | **权限拒绝改为有限功能模式**，移除 terminateApp() 调用 | 开发者 | P0 | 上线前 |
| 5 | **PingEngine 添加 resolved 标志位**，防止 TCP connect 和 setTimeout 同时 resolve | 开发者 | P0 | 上线前 |

### 首版迭代修复（11 项重要）

| # | 行动 | 负责方 | 紧急度 |
|---|------|--------|--------|
| 6 | 统一 wifiState 更新入口（单一数据源） | 开发者 | P1 |
| 7 | HTTP→HTTPS（IpGeoEngine、Traceroute/LAN 探测） | 开发者 | P1 |
| 8 | hilog 脱敏（SSID/BSSID 掩码输出） | 开发者 | P1 |
| 9 | WebView 加固（禁用文件访问 + URL 白名单完善） | 开发者 | P1 |
| 10 | Release 日志级别设为 INFO/WARN | 开发者 | P1 |
| 11 | 统一旧式 API 导入到 @kit.* | 开发者 | P1 |
| 12 | WiFi 扫描频率降至 10-15 秒 + 仅前台执行 | 开发者 | P1 |
| 13 | 修复 wifiList 排序方向（升序→降序） | 开发者 | P1 |
| 14 | 测速结果 UI 标注"估算值" | 开发者 | P1 |
| 15 | 统一公网 IP API 配置（删除硬编码列表） | 开发者 | P1 |
| 16 | 清理 50+ 处 console.log/warn/error | 开发者 | P1 |

---

## ⚠️ 待完善 / 已知局限

- **硬编码中文字符串（85+处）**：本次未列为阻塞项（仅面向中文市场），但华为可能要求多语言支持就绪度，建议尽快迁移
- **伪测速问题**：下载/上传速度均为模拟/估算，非真实测量，首版需在 UI 明确标注
- **模拟器检测简陋**：仅检查 brand 字段，工程机/定制设备可能误判
- **编译警告 32 项**：未在本次评估中逐项验证，建议在 DevEco Studio 中完整构建后清理
- **应用名 "WlAN" 拼写**：疑似应为 "WLAN"，需确认品牌意图

---

## 📚 成员产出索引

- gstack-product-reviewer（产品评审员）原始产出：代码审查报告（30 项发现，Conditional Go）
- gstack-security-officer（安全官）原始产出：安全审计报告（14 项发现，Conditional Go，含 OWASP+STRIDE 建模）
- gstack-qa-lead（QA主管）原始产出：QA 测试评估报告（14 项发现，Conditional Go，含 8 大功能覆盖验证）

---

> 本报告由软件工坊 AI 协作生成，关键决策请由工程负责人复核。
