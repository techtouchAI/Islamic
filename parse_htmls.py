import json
import time

def add_version():
    with open('assets/data/content.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    data['version'] = int(time.time())

    with open('assets/data/content.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

add_version()
