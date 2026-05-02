# WiFi分析仪 - 将现有图标转换成分层资源
# =============================================
# 华为应用市场上架规范：
# 1. 正方形图标：1024x1024px
# 2. 分层资源：前景 + 背景两层
# 3. 背景层必须完全不透明
# 4. 前景层透明背景 + 图案
# =============================================

from PIL import Image
import os

# 输入图标路径（使用用户提供的原始图标）
INPUT_ICON = r'C:\Users\xinxin\Desktop\app_icon_1024_square.png'
OUTPUT_DIR = r'C:\Users\xinxin\wifi-analyzer\AppScope\resources\base\media'
SIZE = 1024


def main():
    # 读取原图标
    img = Image.open(INPUT_ICON)
    print(f'原图标: {img.size}, 模式: {img.mode}')

    # 转为 RGBA
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # 调整尺寸为 1024x1024
    if img.size != (SIZE, SIZE):
        img = img.resize((SIZE, SIZE), Image.LANCZOS)
        print(f'已调整尺寸到: {SIZE}x{SIZE}')

    # ============ 1. 背景层 - 白色填充（完全不透明）============
    bg = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 255))
    bg.save(os.path.join(OUTPUT_DIR, 'background.png'))
    print('[OK] background.png (白色背景, 1024x1024, 100%不透明)')

    # ============ 2. 前景层 - WiFi图标（透明背景）============
    fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

    for y in range(SIZE):
        for x in range(SIZE):
            pixel = img.getpixel((x, y))
            r, g, b, a = pixel
            # 如果不是白色/近白色，作为前景保留
            if not (r > 245 and g > 245 and b > 245):
                fg.putpixel((x, y), pixel)

    fg.save(os.path.join(OUTPUT_DIR, 'foreground.png'))
    print('[OK] foreground.png (WiFi图标, 透明背景, 1024x1024)')

    # ============ 3. 单色层 - WiFi图标（白色单色）============
    mono = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))

    for y in range(SIZE):
        for x in range(SIZE):
            pixel = img.getpixel((x, y))
            r, g, b, a = pixel
            # 如果不是白色/近白色，转为白色
            if not (r > 245 and g > 245 and b > 245):
                mono.putpixel((x, y), (255, 255, 255, 255))

    mono.save(os.path.join(OUTPUT_DIR, 'monochrome.png'))
    print('[OK] monochrome.png (WiFi白色图标, 1024x1024)')

    # ============ 验证 ============
    print('\n=== 验证结果 ===')

    bg_img = Image.open(os.path.join(OUTPUT_DIR, 'background.png'))
    fg_img = Image.open(os.path.join(OUTPUT_DIR, 'foreground.png'))

    bg_alpha = bg_img.split()[3]
    fg_alpha = fg_img.split()[3]

    opaque = sum(1 for p in bg_alpha.getdata() if p > 128)
    transparent = sum(1 for p in fg_alpha.getdata() if p < 128)

    print(f'背景不透明度: {100 * opaque / (SIZE * SIZE):.1f}%')
    print(f'前景透明像素: {100 * transparent / (SIZE * SIZE):.1f}%')

    print('\n' + '=' .center(50, '='))
    print('[SUCCESS] 分层图标生成完成！')
    print('=' .center(50, '='))
    print()
    print('华为应用市场上架检查项:')
    print('  ✅ 正方形尺寸 (1024x1024)')
    print('  ✅ 分层资源 (background + foreground)')
    print('  ✅ 背景层完全不透明')
    print('  ✅ 前景层透明背景')


if __name__ == '__main__':
    main()
