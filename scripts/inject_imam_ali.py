import json

with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    content = json.load(f)

with open('assets/data/imam_ali.json', 'r', encoding='utf-8') as f:
    imam_ali = json.load(f)

# The app uses DataManager.getItems() which looks inside content["content"].
# Wait, let's look at DataManager: _db!['content'][section]
# If it's missing 'content' wrapper, it fails.
if "content" not in content:
    content["content"] = {}

content["content"]["imam_ali"] = imam_ali["imam_ali"]

# Remove top level arrays if they were misplaced
if "imam_ali" in content and isinstance(content["imam_ali"], list):
    del content["imam_ali"]
if "dreams_quran" in content and isinstance(content["dreams_quran"], list):
    content["content"]["dreams_quran"] = content["dreams_quran"]
    del content["dreams_quran"]
if "dreams_sirin" in content and isinstance(content["dreams_sirin"], list):
    content["content"]["dreams_sirin"] = content["dreams_sirin"]
    del content["dreams_sirin"]
if "prophet_duas" in content and isinstance(content["prophet_duas"], list):
    content["content"]["prophet_duas"] = content["prophet_duas"]
    del content["prophet_duas"]

# Define imam ali in sections if not exists or update it
if "sections" not in content:
    content["sections"] = {}

content["sections"]["imam_ali"] = {
    "title": "موسوعة الإمام علي (ع)",
    "icon": "shield",
    "color": "0xFFD4AF37",
    "visible_home": True
}

with open('assets/data/content.json', 'w', encoding='utf-8') as f:
    json.dump(content, f, ensure_ascii=False, indent=2)

print("Injected imam_ali into content.json under content wrapper successfully")
