#!/usr/bin/env python3
"""Generate HTML contrast report from JSON results"""

import json, os

json_path = os.path.join(os.path.dirname(__file__), 'color-contrast-results.json')
with open(json_path, 'r', encoding='utf-8') as f:
    results = json.load(f)

# Add req_val for each result
for r in results:
    req = r.get('requirement', '-')
    if req != '-':
        r['req_val'] = float(req.replace(':1', ''))
    else:
        r['req_val'] = 0

html = '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>色彩对比度分析报告 — WiFi Analyzer</title>
<style>
  :root {
    --bg: #f8fafc; --card: #fff; --border: #e2e8f0;
    --text-primary: #1E293B; --text-secondary: #475569;
    --pass-bg: #ECFDF5; --pass-border: #10B98133; --pass-text: #059669;
    --fail-bg: #FEF2F2; --fail-border: #EF444433; --fail-text: #DC2626;
    --info-bg: #F0F9FF; --info-border: #0EA5E933; --info-text: #0369A1;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, "PingFang SC", "HarmonyOS Sans", sans-serif; background: var(--bg); color: var(--text-primary); padding: 20px; line-height: 1.6; }
  .container { max-width: 1200px; margin: 0 auto; }
  
  h1 { font-size: 24px; margin-bottom: 6px; color: #0F2942; display: flex; align-items: center; gap: 12px; }
  h1 .emoji { font-size: 32px; }
  .subtitle { color: var(--text-secondary); font-size: 14px; margin-bottom: 24px; }

  /* Summary Cards */
  .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 28px; }
  .sum-card { background: var(--card); border-radius: 14px; padding: 18px; border: 1px solid var(--border); text-align: center; }
  .sum-card .num { font-size: 36px; font-weight: 800; line-height: 1.1; }
  .sum-card .label { font-size: 13px; color: var(--text-secondary); margin-top: 4px; }
  .sum-card.pass .num { color: var(--pass-text); } .sum-card.fail .num { color: var(--fail-text); }
  .sum-card.info .num { color: var(--info-text); } .sum-card.total .num { color: #6366F1; }

  /* Section */
  h2 { font-size: 18px; margin: 28px 0 14px; padding-bottom: 8px; border-bottom: 2px solid var(--border); display: flex; align-items: center; gap: 8px; }
  h2.light-mode { border-color: #0EA5E9; color: #0369A1; }
  h2.dark-mode { border-color: #6366F1; color: #4338CA; }

  /* Table */
  table { width: 100%; border-collapse: separate; border-spacing: 0; background: var(--card); border-radius: 12px; overflow: hidden; border: 1px solid var(--border); font-size: 13px; }
  th { background: #F8FAFC; padding: 10px 12px; text-align: left; font-weight: 600; font-size: 12px; color: var(--text-secondary); white-space: nowrap; border-bottom: 1px solid var(--border); position: sticky; top: 0; }
  td { padding: 9px 12px; border-bottom: 1px solid #f1f5f9; vertical-align: middle; max-width: 280px; overflow: hidden; text-overflow: ellipsis; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #fafbfc; }

  .color-swatch { display: inline-flex; align-items: center; gap: 6px; }
  .swatch { width: 16px; height: 16px; border-radius: 4px; border: 1px solid rgba(0,0,0,0.1); flex-shrink: 0; vertical-align: middle; }
  .color-val { font-family: "SF Mono", Consolas, monospace; font-size: 11.5px; opacity: 0.85; }

  .ratio-bar-wrap { display: flex; align-items: center; gap: 8px; min-width: 140px; }
  .ratio-bar { flex: 1; height: 6px; border-radius: 3px; background: #E2E8F0; overflow: hidden; }
  .ratio-fill { height: 100%; border-radius: 3px; transition: width 0.3s; }
  .ratio-num { font-family: "SF Mono", Consolas, monospace; font-size: 13px; font-weight: 700; min-width: 58px; text-align: right; }

  .badge { display: inline-block; padding: 2px 10px; border-radius: 999px; font-size: 11.5px; font-weight: 700; letter-spacing: 0.3px; }
  .badge.PASS { background: var(--pass-bg); color: var(--pass-text); border: 1px solid var(--pass-border); }
  .badge.FAIL { background: var(--fail-bg); color: var(--fail-text); border: 1px solid var(--fail-border); }
  .badge.INFO { background: var(--info-bg); color: var(--info-text); border: 1px solid var(--info-border); }

  .cat-tag { font-size: 11px; padding: 1px 7px; border-radius: 4px; background: #F1F5F9; color: var(--text-secondary); }

  /* Fail highlight */
  tr.FAIL > td { background: #FFF5F5; }
  tr.FAIL:hover > td { background: #FFE8E8; }

  /* Legend */
  .legend { display: flex; gap: 16px; margin-bottom: 16px; font-size: 12px; color: var(--text-secondary); }
  .legend-item { display: flex; align-items: center; gap: 5px; }

  .fix-recommendation { background: linear-gradient(135deg, #FFFBEB, #FEFCE8); border: 1px solid #FCD34D44; border-radius: 12px; padding: 18px 22px; margin: 24px 0; }
  .fix-recommendation h3 { font-size: 15px; color: #92400E; margin-bottom: 10px; display: flex; align-items: center; gap: 8px; }
  .fix-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(340px, 1fr)); gap: 12px; }
  .fix-card { background: #fff; border-radius: 8px; padding: 12px 14px; border: 1px solid #FDE68A66; }
  .fix-card .fix-name { font-weight: 600; font-size: 13px; color: #1E293B; margin-bottom: 4px; }
  .fix-card .fix-detail { font-size: 12px; color: #78716C; }
  .fix-card .fix-action { font-size: 12px; color: #059669; font-weight: 500; margin-top: 4px; }

  @media(max-width:768px) {
    body { padding: 12px; }
    table { font-size: 11.5px; }
    th, td { padding: 7px 8px; }
  }
</style>
</head>
<body>
<div class="container">

<h1><span class="emoji">🎨</span> 色彩对比度分析报告</h1>
<p class="subtitle">WiFi Analyzer (HarmonyOS) &mdash; 标准: WCAG 2.x | 华为深色模式正文要求 11:1~15.1:1 | 检测时间: 2026-05-16'''

import datetime
html += datetime.datetime.now().strftime(' %H:%M')

html += '</p>'

# Count stats
total = len(results)
pass_count = sum(1 for r in results if r.get('status') == 'PASS')
fail_count = sum(1 for r in results if r.get('status') == 'FAIL')
info_count = sum(1 for r in results if r.get('status') == 'INFO')
light_results = [r for r in results if r['mode'] == '浅色模式']
dark_results = [r for r in results if r['mode'] == '深色模式']
light_fail = sum(1 for r in light_results if r['status'] == 'FAIL')
dark_fail = sum(1 for r in dark_results if r['status'] == 'FAIL')

html += f'''
<div class="summary">
  <div class="sum-card total"><div class="num">{total}</div><div class="label">总检测项</div></div>
  <div class="sum-card pass"><div class="num">{pass_count}</div><div class="label">通过 PASS ✅</div></div>
  <div class="sum-card fail"><div class="num">{fail_count}</div><div class="label">不通过 FAIL ❌</div></div>
  <div class="sum-card info"><div class="num">{info_count}</div><div class="label">信息项 ℹ️</div></div>
</div>

<div class="legend">
  <span class="legend-item">📐 正文 ≥ 4.5:1 (深色模式正文 ≥ 11:1)</span>
  <span class="legend-item">🏷️ 图标/标签 ≥ 3:1</span>
  <span class="legenditem">⚠️ 红色行 = 不合格</span>
</div>
'''

def ratio_to_color(ratio, req=4.5):
    pct = min(ratio / 15 * 100, 100)
    if ratio >= req * 1.5:
        return f"#10B981", pct
    elif ratio >= req:
        return f"#86EFAC", pct
    elif ratio >= req * 0.75:
        return f"#FBBF24", pct
    else:
        return f"#EF4444", pct

def make_color_swatch(color_str):
    """Generate HTML for a color swatch"""
    # Clean up color string for CSS
    clean = color_str.replace('(255,255,255,0.85)', '(255,255,255,0.85)').replace('(26,39,68,0.85)', '(26,39,68,0.85)')
    short = color_str[:22] if len(color_str) > 22 else color_str
    return f'<span class="color-swatch"><span class="swatch" style="background:{clean}" title="{color_str}"></span><span class="color-val">{short}</span></span>'


def build_table(mode_name, mode_results):
    th = '<tr>'
    th += '<th>#</th><th>控件名称</th><th>前景色</th><th>背景色</th><th>对比度</th><th>要求</th><th>状态</th>'
    th += '</tr>\n'
    
    rows = ''
    for i, r in enumerate(mode_results):
        if 'error' in r:
            continue
        st = r['status']
        req = r.get('requirement', '-')
        req_val = r.get('req_val', 0)
        fill_color, fill_pct = ratio_to_color(r['ratio'], req_val if req_val > 3 else 3)
        
        rows += f'<tr class="{st}">'
        rows += f'<td>{i+1}</td>'
        rows += f'<td style="font-weight:500">{r["name"]}</td>'
        rows += f'<td>{make_color_swatch(r["foreground"])}</td>'
        rows += f'<td>{make_color_swatch(r["background"])}</td>'
        
        bar_width = min(r['ratio'] / 15 * 100, 100)
        rows += f'<td><div class="ratio-bar-wrap"><div class="ratio-bar"><div class="ratio-fill" style="width:{bar_width:.0f}%;background:{fill_color}"></div></div><span class="ratio-num">{r["ratio"]}:1</span></div></td>'
        rows += f'<td><span class="cat-tag">{r["category"]}<br>{req}</span></td>'
        rows += f'<td><span class="badge {st}">{st}</span></td>'
        rows += '</tr>\n'
    
    return th + rows

html += f'<h2 class="light-mode">🌞 浅色模式 ({len(light_results)} 项, ❌{light_fail} 不合格)</h2>'
html += f'<table>{build_table("浅色模式", light_results)}</table>'

html += f'<h2 class="dark-mode">🌙 深色模式 ({len(dark_results)} 项, ❌{dark_fail} 不合格)</h2>'
html += f'<table>{build_table("深色模式", dark_results)}</table>'

# Fix recommendations section
fail_results = [r for r in results if r['status'] == 'FAIL']
if fail_results:
    html += '''
<div class="fix-recommendation">
<h3>🔧 修复建议</h3>
<div class="fix-grid">
'''

    fixes = [
        ('P0-深色: Glass次文字/Dark次文字 对比度不足', 'COLOR_TEXT_GLASS_SECONDARY (#FFFFFF99) 和 COLOR_TEXT_DARK_SECONDARY (#B8D4E8) 在暗色背景上仅 ~6:1~9.6:1，远低于华为 11:1 要求', '提亮到 #FFFFFFCC 或改用 #E0EEFF'),
        ('P0-浅色: SkyBlue (#0EA5E9) 在白底上太浅', '#0EA5E9 在白色背景上仅 2.77:1，作为正文颜色完全不可读', '改为 #007ACC (Darker Blue) 或 #0369A1，或改用深色文字+图标'),
        ('P0-浅色: Ping按钮白字在SkyBlue上不够', '#FFFFFF on #0EA5E9 仅 2.77:1 < 3:1', '加深按钮底色到 #007ACC 或使用 #0055AA'),
        ('P1-浅色: 功能色在白底上偏低', '成功绿(2.54:1)、警告橙(2.15:1) 均低于 3:1', '绿色加深到 #059669，橙色加深到 #D97706；或给功能色加文字描边/阴影'),
        ('P1-浅色: 信号等级标签文字不合格', '信号色在对应淡色背景上的对比度全部低于 4.5:1', '加深信号前景色或降低背景饱和度；或改用带边框的实心标签设计'),
        ('P1-浅色: Aurora主色在白卡片上不足', '#4A90D9 on 白卡片 = 3.34:1 < 4.5:1', '作为正文用时改用 #2563EB 或更深的蓝色变体'),
        ('P1-深色: TabBar非激活文字偏暗', '#64748B on TabBar暗底 = 3.07:1 < 4.5:1', '提亮到 #94A3B8 或 #CBD5E1'),
        ('P2-通用: Glass禁用文字偏弱', '#FFFFFF40 (25%白) 在任何背景上都接近不可读', '提高到 #FFFFFF80 或 #FFFFFF70'),
        ('P2-浅色: 禁用文字 #94A3B8 不够', '在白色上 2.56:1 < 3:1', '加深到 #8896A6 或 #7E8A9C'),
    ]

    for name, detail, action in fixes:
        html += f'<div class="fix-card">'
        html += f'<div class="fix-name">{name}</div>'
        html += f'<div class="fix-detail">{detail}</div>'
        html += f'<div class="fix-action">→ {action}</div>'
        html += '</div>\n'

    html += '</div></div>\n'

html += '''
<footer style="margin-top:36px; padding:16px 0; text-align:center; color:#94A3B8; font-size:12px;">
  Generated by WCAG Contrast Calculator v1.0 | WiFi Analyzer Project
</footer>
</div>
</body>
</html>'''

out_path = os.path.join(os.path.dirname(__file__), 'color-contrast-report.html')
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(html)
print(f"HTML报告已生成: {out_path}")
