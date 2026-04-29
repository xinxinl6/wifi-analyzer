# WiFi Analyzer 图标设计规范

## 图标文件位置

所有SVG图标源文件位于：
```
entry/src/main/resources/rawfile/icons.svg
```

## 图标变体说明

| 变体 | 文件名 | 背景色 | 适用场景 |
|------|--------|--------|----------|
| Classic | wifi-icon | 白色 | 浅色模式 · 应用商店 |
| Dark | wifi-icon-dark | 深空蓝 #0A1628 | 深色模式 |
| Gradient | wifi-icon-gradient | 蓝青渐变 | 品牌强调 |
| Spectrum | wifi-icon-spectrum | 白色 | 简约风格 |

## 导出步骤

### 1. 使用 Figma/Sketch 导出

1. 打开 `rawfile/icons.svg`
2. 将每个图标单独导出为 PNG
3. 推荐分辨率：
   - 1024 × 1024 px (应用商店)
   - 180 × 180 px (@3x 主屏幕)
   - 120 × 120 px (@2x 主屏幕)
   - 512 × 512 px (平板)
   - 48 × 48 px (通用小图标)

### 2. 放入 media 目录

将导出的 PNG 文件放入：
```
entry/src/main/resources/base/media/
```

### 3. 命名规范

```
ic_home.png      - 首页图标
ic_wifi.png      - WiFi图标
ic_chart.png     - 信道图表图标
ic_speed.png     - 测速图标
ic_tool.png      - 工具箱图标
ic_battery.png   - 电池图标
ic_arrow_down.png  - 下拉箭头
ic_arrow_up.png    - 上传箭头
ic_arrow_right.png - 右箭头
ic_ping.png      - Ping图标
ic_route.png     - 路由追踪图标
ic_dns.png       - DNS图标
ic_port.png      - 端口扫描图标
ic_subnet.png    - 子网图标
ic_poe.png       - POE图标
ic_ip.png        - IP查询图标
ic_mac.png       - MAC查询图标
ic_wol.png       - 唤醒图标
ic_lan.png       - 局域网图标
ic_roaming.png   - 漫游图标
ic_device.png    - 设备图标
ic_surround.png  - 周边WiFi图标
ic_channel.png   - 信道分析图标
```

## 主图标设计

主图标 (App Icon) 建议使用 **Classic** 版本：
- 画布尺寸：1024 × 1024 px
- 圆角半径：180 px
- 渐变色：#0066FF → #00D4FF

## 颜色规范

| 用途 | 色值 | 说明 |
|------|------|------|
| 主色 | #0066FF | 科技蓝 |
| 辅色 | #00D4FF | 信号青 |
| 强调 | #00FF88 | 信号绿 |
| 成功 | #10B981 | 连接成功 |
| 警告 | #F59E0B | 中等信号 |
| 错误 | #EF4444 | 断开/弱信号 |
| 背景 | #F8FAFC | 云白 |
| 深色背景 | #0A1628 | 深空蓝 |

## 尺寸规格

| 用途 | 尺寸 | 倍率 |
|------|------|------|
| 应用商店 | 1024×1024 | 1x |
| iPhone主屏幕 | 180×180 | @3x |
| iPhone主屏幕 | 120×120 | @2x |
| iPad Pro | 167×167 | @2x |
| iPad | 152×152 | @2x |
| PWA | 192×192 | - |
| PWA | 512×512 | - |
