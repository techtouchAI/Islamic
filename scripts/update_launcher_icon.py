import json
import base64
import os

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

    # Extract base64 part
    header, encoded = b64_str.split(',', 1)
    img_data = base64.b64decode(encoded)

    # Densities to update
    densities = ["hdpi", "mdpi", "xhdpi", "xxhdpi", "xxxhdpi"]

    for d in densities:
        icon_path = f"android/app/src/main/res/mipmap-{d}/ic_launcher.png"
        os.makedirs(os.path.dirname(icon_path), exist_ok=True)
        with open(icon_path, 'wb') as f:
            f.write(img_data)
        print(f"Updated launcher icon for {d}")

if __name__ == "__main__":
    update_icons()
