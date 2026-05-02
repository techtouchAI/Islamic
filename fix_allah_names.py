import json

# 1. Names of allah are loaded from `allah_names.json` probably, or it's empty in content.json!
with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

if 'names_allah' in data and len(data['names_allah']) == 0:
    with open('allah_names.json', 'r', encoding='utf-8') as f2:
        allah_names = json.load(f2)
        data['names_allah'] = allah_names['data']

with open('assets/data/content.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Injected names of allah into content.json")

