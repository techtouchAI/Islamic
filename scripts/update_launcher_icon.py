import json
import base64
import os
import io
from PIL import Image

def update_icons():
    json_path = "assets/data/content.json"
    if not os.path.exists(json_path):
        return

    with open(json_path, 'r') as f:
        data = json.load(f)

    b64_str = data.get('settings', {}).get('custom_logo_base64')
    if not b64_str or not b64_str.startswith('data:image'):
        print("No custom Base64 logo found. Skipping launcher icon update.")
        return

    try:
        # Extract base64 part
        header, encoded = b64_str.split(',', 1)
        img_data = base64.b64decode(encoded)

        # Load and convert image using Pillow to ensure valid PNG format
        img = Image.open(io.BytesIO(img_data))
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        # Sizes for different densities (Standard launcher icon sizes)
        sizes = {
            "mdpi": 48,
            "hdpi": 72,
            "xhdpi": 96,
            "xxhdpi": 144,
            "xxxhdpi": 192
        }

        for d, size in sizes.items():
            icon_path = f"android/app/src/main/res/mipmap-{d}/ic_launcher.png"
            os.makedirs(os.path.dirname(icon_path), exist_ok=True)

            # Resize and save
            resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
            resized_img.save(icon_path, "PNG")
            print(f"Updated and validated launcher icon for {d} ({size}x{size})")

    except Exception as e:
        print(f"Error processing custom logo: {e}")
        print("Falling back to default icons.")

if __name__ == "__main__":
    update_icons()
