import json
import time
import os

def update_version():
    file_path = 'assets/data/content.json'
    if not os.path.exists(file_path):
        print(f"Error: {file_path} not found.")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    data['version'] = int(time.time())

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Successfully updated version to {data['version']}")

if __name__ == '__main__':
    update_version()
