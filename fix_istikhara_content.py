import json
import subprocess

original_content = subprocess.check_output(['git', 'show', 'HEAD~3:assets/data/content.json']).decode('utf-8')
original_data = json.loads(original_content)

istikhara_items = original_data.get('dreams', [])

with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

data['istikhara'] = istikhara_items

with open('assets/data/content.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Restored istikhara content")

