#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""WCAG 2.x 色彩对比度计算 — WiFi Analyzer HarmonyOS App"""

import json, math, re, os

def srgb_to_linear(c):
    c = c / 255.0
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    if len(hex_str) == 8:
        r = int(hex_str[0:2], 16)
        g = int(hex_str[2:4], 16)
        b = int(hex_str[4:6], 16)
        a = int(hex_str[6:8], 16) / 255.0
        return r, g, b, a
    elif len(hex_str) == 6:
        r = int(hex_str[0:2], 16)
        g = int(hex_str[2:4], 16)
        b = int(hex_str[4:6], 16)
        return r, g, b, 1.0
    else:
        raise ValueError(f"Invalid hex: {hex_str}")

def parse_color(s):
    """Parse color string to (R, G, B, A) tuple"""
    s = s.strip()
    # Try rgba(r,g,b,a)
    m = re.match(r'rgba?\s*\((\d+),(\d+),(\d+),([\d.]+)\)', s)
    if m:
        return int(m.group(1)), int(m.group(2)), int(m.group(3)), float(m.group(4))
    # Try #RRGGBBAA
    m = re.match(r'#([0-9a-fA-F]{8})', s)
    if m:
        return hex_to_rgb('#' + m.group(1))
    # Try #RRGGBB
    m = re.match(r'#([0-9a-fA-F]{6})', s)
    if m:
        return hex_to_rgb('#' + m.group(1))
    raise ValueError(f"Cannot parse color: {s}")

def composite_fg_bg(fg_r, fg_g, fg_b, fg_a, bg_r, bg_g, bg_b, bg_a):
    """Composite foreground over background using alpha blending"""
    out_a = fg_a + (bg_a * (1 - fg_a))
    if out_a < 0.001:
        return 0, 0, 0, 0
    out_r = ((fg_r * fg_a) + (bg_r * bg_a * (1 - fg_a))) / out_a
    out_g = ((fg_g * fg_a) + (bg_g * bg_a * (1 - fg_a))) / out_a
    out_b = ((fg_b * fg_a) + (bg_b * bg_a * (1 - fg_a))) / out_a
    return round(out_r), round(out_g), round(out_b), round(out_a, 4)

def relative_luminance(r, g, b):
    rs = srgb_to_linear(r)
    gs = srgb_to_linear(g)
    bs = srgb_to_linear(b)
    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs

def contrast_ratio(l1, l2):
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

def calc_contrast(fg_color, bg_color, base_bg=None):
    """
    Calculate contrast ratio between foreground and background colors.
    base_bg: the underlying surface behind semi-transparent backgrounds.
             For light mode: white (#FFFFFF). For dark mode: dark blue (#0F2942).
    Returns (ratio, fg_display_hex, bg_display_hex)
    """
    fr, fg, fb, fa = parse_color(fg_color)
    br, bb, bbb, ba = parse_color(bg_color)

    # If both opaque - simple calculation
    if fa >= 0.999 and ba >= 0.999:
        l1 = relative_luminance(fr, fg, fb)
        l2 = relative_luminance(br, bb, bbb)
        ratio = contrast_ratio(l1, l2)
        return ratio, f"{fr:02x}{fg:02x}{fb:02x}", f"{br:02x}{bb:02x}{bbb:02x}"

    # For semi-transparent colors, composite them over the base background
    if base_bg:
        bbr, bbg, bbb_b, bba = parse_color(base_bg)
        # First composite bg over base
        if ba < 0.999:
            br_c, bg_c, bbb_c, ba_c = composite_fg_bg(br, bb, bbb, ba, bbr, bbg, bbb_b, bba)
        else:
            br_c, bg_c, bbb_c, ba_c = br, bb, bbb, ba
        # Then composite fg over composited bg
        cr, cg, cb, ca = composite_fg_bg(fr, fg, fb, fa, br_c, bg_c, bbb_c, ba_c)
    else:
        # Direct compositing of fg over bg
        cr, cg, cb, ca_val = composite_fg_bg(fr, fg, fb, fa, br, bb, bbb, ba)
        # Use original bg for luminance comparison
        if ba < 0.999 and base_bg is None:
            # Need to estimate actual bg appearance
            br_c, bg_c, bbb_c = br, bb, bbb
        else:
            br_c, bg_c, bbb_c = br, bb, bbb
        cr, cg, cb = cr, cg, cb

    l1 = relative_luminance(cr, cg, cb)
    l2 = relative_luminance(br_c if ba >= 0.999 else br, bg_c if ba >= 0.999 else bb, bbb_c if ba >= 0.999 else bbb)
    ratio = contrast_ratio(l1, l2)

    fg_disp = f"{cr:02x}{cg:02x}{cb:02x}"
    bg_disp = f"{int(br_c):02x}{int(bg_c):02x}{int(bbb_c):02x}"
    return ratio, fg_disp, bg_disp


# =============================================
# Define all color pairs to test
# =============================================

results = []

# ===== LIGHT MODE PAIRS (base_bg = white) =====
LIGHT_BASE = '#FFFFFF'
light_mode_pairs = [
    # (name, foreground, background, category, requirement)
    ('主文字 on 白色卡片', '#1E293B', 'rgba(255,255,255,0.85)', '正文', '4.5:1'),
    ('次文字 on 白色卡片', '#475569', 'rgba(255,255,255,0.85)', '正文', '4.5:1'),
    ('弱文字 on 白色卡片', '#64748B', 'rgba(255,255,255,0.85)', '正文', '4.5:1'),
    ('禁用文字 on 白色卡片', '#94A3B8', 'rgba(255,255,255,0.85)', '辅助文字', '3:1'),

    ('主文字 on 纯白背景', '#1E293B', '#FFFFFF', '正文', '4.5:1'),
    ('次文字 on 纯白背景', '#475569', '#FFFFFF', '正文', '4.5:1'),
    ('弱文字 on 纯白背景', '#64748B', '#FFFFFF', '正文', '4.5:1'),
    ('禁用文字 on 纯白背景', '#94A3B8', '#FFFFFF', '辅助文字', '3:1'),

    ('主文字 on 页面底色', '#1E293B', '#F8FAFC', '正文', '4.5:1'),
    ('次文字 on 页面底色', '#475569', '#F8FAFC', '正文', '4.5:1'),
    ('弱文字 on 页面底色', '#64748B', '#F8FAFC', '辅助文字', '3:1'),

    # Ping button: white text on SkyBlue
    ('按钮文字 on SkyBlue', '#FFFFFF', '#0EA5E9', '大字/图标', '3:1'),
    ('SkyBlue 文字 on 白卡片', '#0EA5E9', 'rgba(255,255,255,0.85)', '正文', '4.5:1'),
    ('SkyBlue 文字 on 纯白', '#0EA5E9', '#FFFFFF', '正文', '4.5:1'),

    # Functional colors on light card
    ('成功绿 on 白卡片', '#10B981', 'rgba(255,255,255,0.85)', '图标/标签', '3:1'),
    ('警告橙 on 白卡片', '#F59E0B', 'rgba(255,255,255,0.85)', '图标/标签', '3:1'),
    ('危险红 on 白卡片', '#EF4444', 'rgba(255,255,255,0.85)', '图标/标签', '3:1'),

    # Signal level text on signal background colors
    ('优秀信号色 on 优秀背景', '#10B981', '#ECFDF5', '标签文字', '4.5:1'),
    ('良好信号色 on 良好背景', '#00D4FF', '#E0F7FA', '标签文字', '4.5:1'),
    ('一般信号色 on 一般背景', '#F59E0B', '#FFFBEB', '标签文字', '4.5:1'),
    ('较差信号色 on 较差背景', '#EF4444', '#FEF2F2', '标签文字', '4.5:1'),

    # Tag backgrounds with Sky Blue text
    ('SkyBlue on 标签Bg(浅色)', '#0EA5E9', 'rgba(14,165,233,0.10)', '标签文字', '3:1'),
    ('SkyBlue on 标签Bg(选中态浅)', '#0EA5E9', 'rgba(14,165,233,0.08)', '标签文字', '3:1'),
    ('半透明SkyBlue(0.6) on 透明', 'rgba(14,165,233,0.6)', '#FFFFFF', '辅助文字', '3:1'),

    # Divider lines
    ('分割线(浅) on 白色', '#F0F2F5', '#FFFFFF', '装饰元素', '-'),
    ('分割线(强) on 白色', '#E8ECF1', '#FFFFFF', '装饰元素', '-'),

    # Aurora primary on white card
    ('Aurora主色 on 白卡片', '#4A90D9', 'rgba(255,255,255,0.85)', '正文', '4.5:1'),
]

# ===== DARK MODE PAIRS (base_bg = dark blue) =====
DARK_BASE = '#0F2942'
dark_mode_pairs = [
    # Glass text colors (with alpha) on dark glass card
    ('Glass主文字(90%白) on 暗色卡片', '#FFFFFFE6', 'rgba(26,39,68,0.85)', '正文(Dark)', '11:1'),
    ('Glass次文字(60%白) on 暗色卡片', '#FFFFFF99', 'rgba(26,39,68,0.85)', '正文(Dark)', '11:1'),
    ('Glass弱文字(40%白) on 暗色卡片', '#FFFFFF66', 'rgba(26,39,68,0.85)', '辅助文字(Dark)', '3:1'),
    ('Glass禁用(25%白) on 暗色卡片', '#FFFFFF40', 'rgba(26,39,68,0.85)', '禁用(Dark)', '3:1'),

    # Dark mode opaque text colors on dark card
    ('Dark主文字 on 暗色卡片', '#F0F8FF', 'rgba(26,39,68,0.85)', '正文(Dark)', '11:1'),
    ('Dark次文字 on 暗色卡片', '#B8D4E8', 'rgba(26,39,68,0.85)', '正文(Dark)', '11:1'),
    ('Dark弱文字 on 暗色卡片', '#7AA3C0', 'rgba(26,39,68,0.85)', '辅助文字(Dark)', '3:1'),

    # On pure dark background (page-level)
    ('Glass主文字 on 深蓝背景顶', '#FFFFFFE6', '#0F2942', '正文(Dark)', '11:1'),
    ('Glass次文字 on 深蓝背景顶', '#FFFFFF99', '#0F2942', '正文(Dark)', '11:1'),
    ('Glass弱文字 on 深蓝背景顶', '#FFFFFF66', '#0F2942', '辅助文字(Dark)', '3:1'),
    ('Dark主文字 on 深蓝背景顶', '#F0F8FF', '#0F2942', '正文(Dark)', '11:1'),
    ('Dark次文字 on 深蓝背景顶', '#B8D4E8', '#0F2942', '正文(Dark)', '11:1'),
    ('Dark弱文字 on 深蓝背景顶', '#7AA3C0', '#0F2942', '辅助文字(Dark)', '3:1'),

    # Sky Blue on dark surfaces
    ('SkyBlue on 暗色卡片', '#0EA5E9', 'rgba(26,39,68,0.85)', '正文(Dark)', '4.5:1'),
    ('SkyBlue on 深蓝背景', '#0EA5E9', '#0F2942', '正文(Dark)', '4.5:1'),

    # Functional colors on dark card
    ('成功绿 on 暗色卡片', '#10B981', 'rgba(26,39,68,0.85)', '图标/标签', '3:1'),
    ('警告橙 on 暗色卡片', '#F59E0B', 'rgba(26,39,68,0.85)', '图标/标签', '3:1'),
    ('危险红 on 暗色卡片', '#EF4444', 'rgba(26,39,68,0.85)', '图标/标签', '3:1'),

    # Tab bar colors
    ('TabBar激活文字 on TabBar暗底', '#E2E8F0', 'rgba(30,41,59,0.75)', 'Tab文字', '4.5:1'),
    ('TabBar非激活 on TabBar暗底', '#64748B', 'rgba(30,41,59,0.75)', 'Tab文字', '4.5:1'),

    # Tags with text on dark mode
    ('SkyBlue on 标签Bg(暗色选中)', '#0EA5E9', 'rgba(14,165,233,0.15)', '标签文字', '3:1'),
    ('SkyBlue on 半透明灰标签Bg(暗色)', '#0EA5E9', 'rgba(148,163,184,0.12)', '标签文字', '3:1'),
    ('警告橙 on 灰标签Bg(暗色)', '#F59E0B', 'rgba(148,163,184,0.12)', '标签文字', '3:1'),

    # Aurora colors on dark
    ('Aurora主色 on 暗色卡片', '#4A90D9', 'rgba(26,39,68,0.85)', '正文(Dark)', '4.5:1'),
    ('Aurora亮色 on 暗色卡片', '#87CEEB', 'rgba(26,39,68,0.85)', '正文(Dark)', '4.5:1'),

    # Divider on dark
    ('分割线(暗) on 暗色卡片', 'rgba(255,255,255,0.08)', 'rgba(26,39,68,0.85)', '装饰元素', '-'),

    # Icon circle bg with emoji/text
    ('emoji/icon on SkyActive圆圈', '#000000', 'rgba(14,165,233,0.12)', '图标', '3:1'),

    # Arrow symbol
    ('箭头符号(50%skyblue) on 白卡片', 'rgba(14,165,233,0.5)', 'rgba(255,255,255,0.85)', '装饰元素', '-'),
    ('箭头符号(SkyBlue) on 暗色卡片', '#0EA5E9', 'rgba(26,39,68,0.85)', '装饰元素', '-'),
]


print("=" * 95)
print("色彩对比度分析报告 - WiFi Analyzer (HarmonyOS)")
print("标准: WCAG 2.x | 华为深色模式正文要求 11:1~15.1:1")
print("=" * 95)

all_pairs = []
for name, fg, bg, cat, req in light_mode_pairs:
    all_pairs.append(('浅色模式', name, fg, bg, cat, req, LIGHT_BASE))
for name, fg, bg, cat, req in dark_mode_pairs:
    all_pairs.append(('深色模式', name, fg, bg, cat, req, DARK_BASE))

for mode_name, name, fg, bg, cat, req, base_bg in all_pairs:
    try:
        ratio, fg_hex, bg_hex = calc_contrast(fg, bg, base_bg=base_bg)
        req_val = float(req.replace(':1', '')) if req != '-' else 0

        if req == '-':
            status = 'INFO'
        elif ratio >= req_val:
            status = 'PASS'
        else:
            status = 'FAIL'

        results.append({
            'mode': mode_name,
            'name': name,
            'foreground': fg,
            'background': bg,
            'fg_composited': fg_hex,
            'bg_composited': bg_hex,
            'ratio': round(ratio, 2),
            'category': cat,
            'requirement': req,
            'status': status,
        })
    except Exception as e:
        results.append({
            'mode': mode_name, 'name': name, 'foreground': fg, 'background': bg,
            'error': str(e), 'status': 'ERROR'
        })

# Print results table
for mode in ['浅色模式', '深色模式']:
    mode_results = [r for r in results if r['mode'] == mode]
    print(f"\n{'='*70}")
    print(f"  {mode} ({len(mode_results)} 项检测)")
    print(f"{'-'*70}")
    print(f"{'控件名称':<38} {'前景色':<20} {'背景色':<22} {'比值':>7} {'要求':>7} {'状态':>6}")
    print(f"{'-'*38} {'-'*20} {'-'*22} {'-'*7} {'-'*7} {'-'*6}")

    for r in mode_results:
        if 'error' in r:
            print(f"{r['name']:<38} ERROR: {r['error']}")
        else:
            marker = '❌ FAIL' if r['status'] == 'FAIL' else ('✅ PASS' if r['status'] == 'PASS' else 'ℹ️ INFO')
            fg_s = r['foreground'][:18]
            bg_s = r['background'][:20]
            req_s = r['requirement']
            print(f"{r['name']:<38} {fg_s:<20} {bg_s:<22} {r['ratio']:>5.2f}:1 {req_s:>7} {marker:>6}")

# Summary
print(f"\n{'='*70}")
total_fail = sum(1 for r in results if r['status'] == 'FAIL')
total_pass = sum(1 for r in results if r['status'] == 'PASS')
total_info = sum(1 for r in results if r['status'] == 'INFO')
print(f"汇总: ✅ PASS={total_pass}   ❌ FAIL={total_fail}   ℹ️ INFO={total_info}/{len(results)}")

if total_fail > 0:
    print(f"\n⚠️ 以下 {total_fail} 项不满足华为审核要求:")
    print(f"{'-'*70}")
    print(f"{'模式':<8} {'控件名称':<36} {'实际值':>8} {'要求':>8} {'差距':>8}")
    print(f"{'-'*70}")
    for r in results:
        if r['status'] == 'FAIL':
            req_str = r['requirement'].replace(':1', '')
            req_val = float(req_str) if req_str.replace('.','').isdigit() else 0
            gap = req_val - r['ratio']
            print(f"{r['mode']:<8} {r['name']:<36} {r['ratio']:>7.2f}:1 {r['requirement']:>8} {gap:>+7.2f}")

# Save JSON
out_path = os.path.join(os.path.dirname(__file__), 'color-contrast-results.json')
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)
print(f"\n结果已保存到: {out_path}")
