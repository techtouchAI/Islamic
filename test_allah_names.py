import json

with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

if 'names_allah' in data:
    names = data['names_allah']
    print(f"Names of Allah length: {len(names)}")
    if len(names) > 0:
        print(names[:2])
