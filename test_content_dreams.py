import json

with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("dreams_categories present?", 'dreams_categories' in data)
if 'dreams_categories' in data:
    dreams = data['dreams_categories']
    print(f"Number of letters: {len(dreams)}")
    for d in dreams[:2]:
        print(f"Cat {d['id']}: {d['title']} -> {len(d.get('items', []))} items")
        print(d['items'][:1])
