# Aurora WiFi — 天蓝极光设计系统

## 设计哲学

**Aurora WiFi** 是一种将无线信号的流动感与极光的神秘绚丽融合的设计语言。它源自对数字通信世界优雅秩序的追求——WiFi波纹如同北极光般在深邃的天空中流动，科学与艺术在此交汇。

设计强调「智能即美感」的理念。信号强度不再只是冰冷的数字，而是通过流动的渐变色块和脉动的光晕呈现；网络状态如同极光般在不同色彩间自然过渡，为用户提供即时的视觉反馈和情感共鸣。

---

## 核心设计原则

- **极光流动感**：动态渐变、柔和过渡、脉动光效作为核心视觉语言
- **天蓝渐变**：天际蓝 (#4A90D9) → 极光青 (#87CEEB) → 晨曦白 (#F0F8FF)
- **毛玻璃通透**：backdrop-blur + 半透明 + 微光边框，层次分明
- **悬浮光感**：内发光、渐变光晕、浮动元素营造沉浸深度
- **响应式动效**：点击反馈、状态转换、微交互精心打磨
- **智能AI集成**：AI分析、预测建议、自然语言交互

---

## 色彩系统

### 主色调 — 极光天蓝

| 名称 | 色值 | 用途 |
|------|------|------|
| Aurora Primary | `#4A90D9` | 主品牌色、按钮、关键元素 |
| Aurora Light | `#87CEEB` | 渐变过渡、轻量强调 |
| Aurora Deep | `#1E5F9E` | 深色变体、悬停状态 |
| Aurora Glow | `#A8D4F5` | 光晕效果、背景装饰 |

### 辅助色系

| 名称 | 色值 | 用途 |
|------|------|------|
| Signal Excellent | `#00D97E` | 优秀信号、成功状态 |
| Signal Good | `#4ADE80` | 良好信号、正向状态 |
| Signal Fair | `#FBBF24` | 一般信号、警告状态 |
| Signal Poor | `#F87171` | 较差信号、错误状态 |

### 中性色系

| 名称 | 色值 | 用途 |
|------|------|------|
| Surface Glass | `#FFFFFF1A` | 毛玻璃背景 (10%白) |
| Surface Glass Light | `#FFFFFF33` | 浅毛玻璃 (20%白) |
| Border Glow | `#FFFFFF40` | 光晕边框 (25%白) |
| Text Primary | `#FFFFFFE6` | 主文字 (90%白) |
| Text Secondary | `#FFFFFF99` | 次文字 (60%白) |
| Text Tertiary | `#FFFFFF66` | 弱文字 (40%白) |

### 深色主题变体

| 名称 | 色值 | 用途 |
|------|------|------|
| Background Dark | `#0A1628` | 深色背景基底 |
| Background Deep | `#061220` | 更深背景层 |
| Surface Dark | `#1A2744` | 深色表面 |
| Card Dark | `#0F1E36` | 深色卡片 |

---

## 毛玻璃效果系统

### 毛玻璃层级

```css
/* 基础毛玻璃 — 轻度模糊 */
.glass-base {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

/* 中度毛玻璃 — 卡片/导航 */
.glass-medium {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.25);
  box-shadow:
    0 4px 24px rgba(0, 0, 0, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

/* 高度毛玻璃 — 悬浮元素/模态 */
.glass-high {
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(30px);
  -webkit-backdrop-filter: blur(30px);
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.15),
    inset 0 1px 0 rgba(255, 255, 255, 0.3);
}
```

### 光晕效果

```css
/* 极光光晕 */
.glow-aurora {
  box-shadow:
    0 0 20px rgba(74, 144, 217, 0.3),
    0 0 40px rgba(74, 144, 217, 0.2),
    0 0 60px rgba(74, 144, 217, 0.1);
}

/* 内发光边框 */
.glow-border {
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow:
    inset 0 0 20px rgba(74, 144, 217, 0.1),
    0 1px 0 rgba(255, 255, 255, 0.2);
}
```

---

## 悬浮导航设计

### 底部TabBar规格

| 属性 | 值 |
|------|-----|
| 高度 | 72px + 安全区 |
| 圆角 | 24px (顶部) |
| 背景 | 毛玻璃中度 + 渐变遮罩 |
| 阴影 | `0 -4px 20px rgba(0,0,0,0.15)` |
| 内边距 | 12px 水平 |
| 间距 | 均分宽度 |

### 导航项状态

| 状态 | 样式变化 |
|------|----------|
| 默认 | 图标40%透明度，文字40%透明度 |
| 悬停/聚焦 | 图标60%透明度，文字60%透明度 |
| 选中 | 图标100%亮度 + 光晕背景，文字100%亮度 |
| 点击 | Scale(0.92) + 波纹扩散 |

---

## 动效系统

### 基础动效参数

| 类型 | 时长 | 缓动曲线 |
|------|------|----------|
| 微交互 | 150ms | ease-out |
| 状态切换 | 300ms | cubic-bezier(0.4, 0, 0.2, 1) |
| 页面过渡 | 400ms | cubic-bezier(0.16, 1, 0.3, 1) |
| 加载动画 | 1000ms+ | linear (循环) |

### 点击反馈动效

```css
/* 按压缩小 */
.tap-press {
  transform: scale(0.92);
  transition: transform 150ms ease-out;
}

/* 波纹扩散 */
.ripple {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.3);
  transform: scale(0);
  animation: ripple-expand 400ms ease-out forwards;
}

@keyframes ripple-expand {
  to {
    transform: scale(2.5);
    opacity: 0;
  }
}
```

### 呼吸光晕动效

```css
/* 脉冲呼吸 */
@keyframes pulse-glow {
  0%, 100% {
    box-shadow: 0 0 20px rgba(74, 144, 217, 0.3);
  }
  50% {
    box-shadow: 0 0 40px rgba(74, 144, 217, 0.5);
  }
}

.pulse-animate {
  animation: pulse-glow 2s ease-in-out infinite;
}

/* 浮游动画 */
@keyframes float {
  0%, 100% { transform: translateY(0px); }
  50% { transform: translateY(-8px); }
}

.float-animate {
  animation: float 3s ease-in-out infinite;
}
```

---

## AI功能模块

### AI助手入口

- 悬浮AI按钮（右下角）
- 渐变极光色 + 脉冲动画
- 点击展开AI对话面板

### 智能分析功能

1. **网络健康诊断** — AI分析信号质量、延迟、丢包率
2. **智能信道推荐** — 基于环境AI推荐最优信道
3. **异常预警** — 预测性网络问题提醒
4. **优化建议** — 个性化网络优化方案

---

## 页面结构

| 页面 | 功能 | 特色设计 |
|------|------|----------|
| 首页仪表盘 | 连接状态、信号强度、快速工具、AI助手 | 极光渐变大卡片、动态信号环 |
| WiFi列表 | 周围AP列表、筛选、信号排行 | 毛玻璃列表项、滑动交互 |
| 信道分析 | 2.4/5GHz频段、占用图、推荐 | 流光柱状图、动态可视化 |
| 测速面板 | 节点选择、速度仪表、历史 | 极速仪表盘、数字跳动 |
| 工具箱 | Ping、路由追踪等网络工具 | 悬浮图标网格、AI辅助输入 |
| AI助手 | 智能问答、网络诊断 | 对话式毛玻璃面板 |

---

## 图标规范

图标采用统一的 Aurora 风格：
- 简洁的线条和几何形状
- 天蓝渐变色系
- 脉动呼吸动画效果
- 支持深色/浅色/极光模式

### 图标尺寸

| 用途 | 尺寸 |
|------|------|
| TabBar图标 | 24px |
| 功能图标 | 32px / 44px |
| 装饰图标 | 64px+ |
| 状态图标 | 16px |

---

## 无障碍标准

- 色彩对比度 ≥ 4.5:1 (WCAG AA)
- 触摸目标 ≥ 44px
- 支持减弱动效偏好
- 支持屏幕阅读器
- 焦点指示器清晰可见

---

## 响应式断点

| 设备 | 宽度 | 布局调整 |
|------|------|----------|
| 手机 | < 600px | 单列/双列网格 |
| 平板 | 600-1024px | 三列网格 |
| 大屏 | > 1024px | 四列网格 + 侧边栏 |

---

*设计系统版本：2.0 Aurora*
*最后更新：2026-04-27*
