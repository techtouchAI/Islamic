import json

# The user stated: "ثالثا خيرة القران الكريم يظهر بدون محتوى."
# In task 2 I decoupled "istikhara" from "dreams".
# So the data in `assets/data/content.json` should have `istikhara` array. Let's check it.
with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

if 'istikhara' in data:
    istikhara_content = data['istikhara']
    print(f"istikhara length: {len(istikhara_content)}")
else:
    print("istikhara not found in data keys!")

