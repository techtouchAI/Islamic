import json

# Instead of waiting an hour, let's create a smaller mock structure to test the UI.
# In a real scenario we'd wait or parallelize the requests, but we don't have time.
# The user wants "بطاقات صغيرة مرتب حسب الحروف الابجدية"
# -> "Small cards sorted alphabetically."
# -> "عند الضغط على حرف يدخل لصفحة اخرى تعرض العناوين يظهر بطاقة لكل عنوان تحته التفسير مباشر."
# -> "When clicking a letter, it goes to another page displaying the titles, with a card for each title and its interpretation directly below it."

letters = [
    "الألف", "الباء", "التاء", "الثاء", "الجيم", "الحاء", "الخاء",
    "الدال", "الذال", "الراء", "الزاء", "السين", "الشين", "الصاد",
    "الضاد", "الطاء", "الظاء", "العين", "الغين", "الفاء", "القاف",
    "الكاف", "اللام", "الميم", "النون", "الهاء", "الواو", "الياء"
]

dreams_categories = []
next_id = 1

for l in letters:
    cat_items = []
    for i in range(1, 4):
        cat_items.append({
            "id": i,
            "title": f"رؤيا {l} - {i}",
            "content": f"هذا تفسير للرؤيا الخاصة بحرف {l}، ويحتوي على بعض التفاصيل المعبرة عن الحلم. (تفسير ابن سيرين)"
        })
    dreams_categories.append({
        "id": next_id,
        "title": f"حرف {l}",
        "items": cat_items
    })
    next_id += 1

with open('dreams.json', 'w', encoding='utf-8') as f:
    json.dump(dreams_categories, f, ensure_ascii=False, indent=2)

print("Generated mock dreams.json")
