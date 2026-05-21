# WlAN-02 (wifi-analyzer) 测速模块分析 & 四方对比

> 分析时间：2026-05-21  
> 项目位置：`C:\Users\xinxin\WlAN-02`  
> 框架：HarmonyOS (ArkTS/Stage 模型)  
> 代码语言：ArkTS + Native C++ (libpingnative.so)

---

## 一、WlAN-02 测速架构

### 1.1 核心文件

```
speed-test/src/main/ets/
  ├── SpeedTestEngine.ets    ← 测速引擎主类 (410行)
  └── Index.ets              ← 模块入口

entry/src/main/ets/
  ├── utils/SpeedTestHelper.ets    ← UI辅助（颜色/格式化）
  ├── utils/SpeedTestStorage.ets   ← 本地存储
  ├── utils/NativePing.ets         ← ICMP Native Ping (C++ NAPI)
  ├── utils/PingStatsHelper.ets    ← Ping统计计算
  ├── utils/PingStorage.ets        ← Ping历史存储
  └── components/
      ├── SpeedTestSection.ets      ← 测速UI入口
      ├── SpeedGauge.ets            ← 仪表盘动画
      ├── SpeedDetailPopup.ets      ← 详情弹窗
      ├── SpeedHistoryList.ets      ← 历史记录
      ├── SpeedServerPopup.ets      ← 节点选择
      ├── PingTestPage.ets          ← Ping测试页
      ├── PingLiveChart.ets         ← 实时Ping图
      ├── PingIdleView.ets          ← Ping空闲视图
      ├── PingTestingView.ets       ← Ping进行中
      ├── PingStatsCard.ets         ← Ping统计卡片
      ├── PingHistoryModal.ets      ← Ping历史弹窗
      └── PingTrendChart.ets        ← 趋势图
```

### 1.2 引擎流程

```
startTest(serverId, networkType, callbacks)
  │
  ├─ 阶段1: measurePing()
  │   └─ 4次 HTTP GET → 计算平均延迟 + 标准差(抖动)
  │
  ├─ 阶段2: measureDownloadSpeed()
  │   ├─ HTTP Range GET (前5MB)
  │   ├─ 同时 300ms定时器模拟渐进速度
  │   └─ 返回 maxSpeed 或 fallback
  │
  ├─ 阶段3: measureUploadSimulated()
  │   └─ 基于下载速度 × (25%~50%) 的模拟值
  │
  └─ onComplete(result)
```

### 1.3 服务器节点（硬编码 5 个 CDN 镜像站）

| ID | 名称 | 测速URL | PingURL |
|----|------|---------|---------|
| beijing | 北京·阿里云 | `mirrors.aliyun.com/.../Packages.gz` | `mirrors.aliyun.com/` |
| shanghai | 上海·腾讯云 | `mirrors.tencent.com/.../Packages.gz` | `mirrors.tencent.com/` |
| guangzhou | 广州·华为云 | `repo.huaweicloud.com/.../Packages.xz` | `repo.huaweicloud.com/` |
| shenzhen | 深圳·网易 | `mirrors.163.com/.../Packages.gz` | `mirrors.163.com/` |
| hangzhou | 杭州·百度云 | `cdn.bcebos.com/.../testfile` | `www.baidu.com/` |

### 1.4 Ping 能力（双重实现）

| 方式 | 实现 | 说明 |
|------|------|------|
| **HTTP Ping** (SpeedTestEngine) | `http.createHttp().request(pingUrl)` | 测速流程中的延迟测量，4次取平均 |
| **ICMP Ping** (NativePing) | `libpingnative.so` → `OH_NetConn_QueryProbeResult` | 真正的 ICMP 探测，支持丢包率/抖动/最小最大RTT |

`NativePing` 的能力远强于 SpeedTestEngine 里的 HTTP Ping，但**测速流程用的是 HTTP Ping**。

---

## 二、四方对比总表

| 维度 | **WlAN-02** (你的项目) | **全球网测** (信通院) | **Speedtest** (Ookla) | **花瓣测速** (华为) |
|------|:---:|:---:|:---:|:---:|
| **平台** | HarmonyOS | Android | Android/iOS (KMM) | Android (HMS) |
| **引擎规模** | 410行 ArkTS | ~40MB DEX (加密) | ~40MB DEX + native | ~17MB DEX + HMS Core |
| | | | | |
| **下载测速** | ✅ HTTP Range 5MB | ✅ HTTP 大文件 | ✅ TCP/UDP/CDN 多线程 | ✅ HMS NetworkKit |
| **上传测速** | ⚠️ **模拟值** (下载x比例) | ✅ HTTP POST | ✅ TCP/UDP 多线程 | ✅ HMS NetworkKit |
| **Ping** | ✅ HTTP GET + ICMP Native | ✅ ICMP/UDP/HTTP | ✅ ICMP/UDP/HTTP + DoH | ✅ HMS NetDiag |
| **抖动** | ✅ 标准差 | ✅ | ✅ mean/p10/p90 | ✅ |
| **丢包率** | ✅ ICMP (NativePing) | ❌ | ❌ | ✅ |
| | | | | |
| **节点数** | 5 个硬编码 | ~1,000 API 动态 | ~16,000 API 动态 | 云端 AGC 代理 |
| **节点来源** | CDN 镜像站 | 自有测速服务器 | 全球运营商部署 | 华为 CDN |
| **节点选择** | 用户手动选 | 位置自动匹配 | Ping 最优 | AI 预测模型 |
| **测试文件** | Ubuntu Packages.gz (~50KB) | 专有大文件 | 大小可调随机数据 | HMS 下发 |
| | | | | |
| **原生引擎** | 无（纯 ArkTS） | `libGSCore.so` | `libandroidsharedsuite.so` | 无（HMS 系统服务） |
| **HTTP 库** | `@kit.NetworkKit` | `libcurl.so` | OkHttp 4 | hwhttp (定制 OkHttp) |
| **ICMP Ping** | ✅ `libpingnative.so` (NAPI) | ❌ | ❌ | ❌（Cronet 替代） |
| | | | | |
| **WiFi 分析** | ✅ 核心功能 | ❌ | ❌ | ✅ |
| **AP 检测** | ✅ WiFi Scanner | ❌ | ❌ | ✅ WiFi Squatter |
| **信号图表** | ✅ 实时 | ❌ | ❌ | ❌ |
| **网络诊断** | ❌ | ✅ DNS/DIG | ❌ (基础 DoH) | ✅ 全模组 |
| **游戏延迟** | ❌ | ✅ 配置列表 | ✅ CellRebel SDK | ✅ 专项 |
| **视频测速** | ❌ | ✅ 嵌入Web | ✅ 内建播放 | ✅ 内建播放 |
| | | | | |
| **逆向难度** | 源码开放 ✅ | 360加固 ❌ | 无加固 ✅ | 无加固 + HMS Core ❌ |
| **代码质量** | ArkTS, 结构清晰 | 传统 Java, 混淆 | KMM, 工程化最好 | Kotlin, HMS 深度绑定 |

---

## 三、测速准确度对比

| 环节 | WlAN-02 | 商业 App | 差距原因 |
|------|:---:|:---:|------|
| **下载** | ⚠️ 偏低 | ✅ 准确 | 单线程 HTTP Range 5MB vs 多线程 TCP 大文件 |
| **上传** | ❌ **假的** | ✅ 真实 | 模拟值，非真实上传 |
| **Ping** | ✅ 可用 | ✅ 准确 | HTTP Ping 受 CDN 路由影响，不如 ICMP |
| **抖动** | ✅ 基本对 | ✅ 多维度 | 只有标准差，缺乏 p10/p90 分位数 |
| **丢包** | ✅ 准确 | ❌ 无 | NativePing ICMP 比商业App都强！ |
| **节点选择** | ❌ 固定 | ✅ 动态 | 5 个硬编码 vs 上千节点智能匹配 |

---

## 四、WlAN-02 的独特优势

### 4.1 真正的 ICMP 丢包率测量

```
全球网测:  ❌ 无丢包率
Speedtest: ❌ 无丢包率  
花瓣测速:  ✅ 有，但依赖 HMS Core
WlAN-02:   ✅ 独立 ICMP Native Ping，支持丢包率/最小/最大/平均RTT/标准差
```

`libpingnative.so` 基于 `OH_NetConn_QueryProbeResult`，这是 HarmonyOS 系统级的网络探测 API，精度高于任何应用层实现。

### 4.2 WiFi 分析 + 测速一体化

三个商业 App 都**只有测速**，而 WlAN-02 是 WiFi 分析器 + 测速工具的结合。信号强度、信道分析、AP 扫描等功能是独家的。

---

## 五、改进建议

### 高优先级

| # | 改进点 | 当前 | 建议 |
|---|--------|------|------|
| 1 | **上传测速** | 模拟值 | 实现真实 HTTP POST 上传 |
| 2 | **节点扩展** | 5 个硬编码 | 接入 Speedtest.net 公开节点或自建 |
| 3 | **多线程下载** | 单线程 Range | 并发 Chunk 下载 |
| 4 | **大文件测试** | 50KB .gz | 至少 100MB，或动态生成 |

### 中优先级

| # | 改进点 | 建议 |
|---|--------|------|
| 5 | NativePing 集成到测速流程 | 用 ICMP 替代 HTTP Ping 做延迟测量 |
| 6 | 测速节点 API | 像全球网测一样动态获取节点列表 |
| 7 | Jitter 分位数 | 增加 p10/p90/IQM 抖动指标 |

---

## 六、总结

| | WlAN-02 | 最推荐学习对象 |
|------|------|------|
| **想增强测速准确度** | 当前够用但不专业 | → Speedtest 的实现方式 |
| **想增加真实上传** | 完全是假的 | → 全球网测的 HTTP POST 方案 |
| **想丰富功能** | 缺诊断/视频/游戏 | → 花瓣测速的模块清单 |
| **ICMP Ping** | **你已经是最强的** | 不用学别人 |

你的 ICMP Native Ping 是所有四个里最强的（真正的丢包率 + 全 RTT 指标），Speedtest 和全球网测都没有这个能力。**最大的短板是上传是假的**，其次是节点太少太固定。把这两个补上，就已经是一个专业级测速工具了。