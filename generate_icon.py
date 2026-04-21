from PIL import Image, ImageDraw

def create_icon(size):
    # Primary color (Gold)
    gold = (212, 175, 55)
    # Background (Dark Green/Black)
    bg = (20, 20, 20)

    img = Image.new('RGB', (size, size), bg)
    draw = ImageDraw.Draw(img)

    # Draw a simple mosque dome shape
    padding = size // 5
    center = size // 2

    # Dome
    draw.pieslice([padding, padding, size-padding, size-padding], 180, 0, fill=gold)
    # Minaret
    draw.rectangle([center - size//20, padding//2, center + size//20, padding*2], fill=gold)
    # Crescent
    draw.ellipse([center - size//15, padding//4, center + size//15, padding], outline=gold, width=size//30)

    return img

sizes = {
    "hdpi": 72,
    "mdpi": 48,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192
}

for name, size in sizes.items():
    icon = create_icon(size)
    icon.save(f"android/app/src/main/res/mipmap-{name}/ic_launcher.png")
    print(f"Generated {name} icon")
