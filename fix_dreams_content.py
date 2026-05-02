import json

with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

with open('dreams.json', 'r', encoding='utf-8') as f:
    dreams = json.load(f)

data['dreams_categories'] = dreams

with open('assets/data/content.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Merged scraped dreams into content.json")
