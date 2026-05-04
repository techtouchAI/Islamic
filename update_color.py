import json

with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

if 'settings' in data and 'primary_color' in data['settings']:
    data['settings']['primary_color'] = '0xFF2196F3'

with open('assets/data/content.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
