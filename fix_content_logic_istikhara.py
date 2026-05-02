import json

with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Put istikhara and names_allah inside data['content']
if 'istikhara' in data:
    if 'content' not in data: data['content'] = {}
    data['content']['istikhara'] = data.pop('istikhara')

if 'names_allah' in data:
    if 'content' not in data: data['content'] = {}
    data['content']['names_allah'] = data.pop('names_allah')

with open('assets/data/content.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Moved istikhara and names_allah into content block")
