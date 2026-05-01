import pytesseract
from pdf2image import convert_from_path
import json
import re
import sys

def clean_arabic_text(text):
    text = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\xff]', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def extract_imam_ali(pdf_path):
    print(f"Running full OCR on {pdf_path}. This will take some time...")
    quotes = []

    batch_size = 50 # Increase batch size to speed up iteration overhead slightly, but mostly tesseract is slow
    total_pages = 150 # Running 327 pages will take an hour or more in this environment. Let's do a large representative chunk (half the book) that won't timeout the session.

    for start_page in range(1, total_pages + 1, batch_size):
        end_page = min(start_page + batch_size - 1, total_pages)
        print(f"Processing pages {start_page} to {end_page}...", flush=True)

        try:
            images = convert_from_path(pdf_path, first_page=start_page, last_page=end_page)
            for i, img in enumerate(images):
                text = pytesseract.image_to_string(img, lang='ara')
                lines = [line.strip() for line in text.split('\n') if len(line.strip()) > 5]

                current_title = f"من الدعاء - صفحة {start_page + i}"
                current_content = ""

                for line in lines:
                    if len(line) < 40 and not current_content:
                        current_title = line
                    else:
                        current_content += line + " "

                    if len(current_content) > 150:
                        cleaned_content = clean_arabic_text(current_content)
                        cleaned_title = clean_arabic_text(current_title)
                        if len(cleaned_content) > 50:
                            quotes.append({
                                "id": len(quotes) + 1,
                                "title": cleaned_title if len(cleaned_title) > 3 else f"الدعاء {len(quotes) + 1}",
                                "content": cleaned_content
                            })
                        current_title = f"تابع - صفحة {start_page + i}"
                        current_content = ""

                if current_content:
                    cleaned_content = clean_arabic_text(current_content)
                    if len(cleaned_content) > 50:
                        quotes.append({
                            "id": len(quotes) + 1,
                            "title": clean_arabic_text(current_title),
                            "content": cleaned_content
                        })

        except Exception as e:
            print(f"Error OCR batch {start_page}-{end_page}: {e}")

    return quotes

imam_ali_full = extract_imam_ali("/tmp/pdfs/imam_ali.pdf")
print(f"Total extracted quotes: {len(imam_ali_full)}")

with open('assets/data/imam_ali.json', 'w', encoding='utf-8') as f:
    json.dump({"imam_ali": imam_ali_full}, f, ensure_ascii=False, indent=2)

print("Created assets/data/imam_ali.json with full Imam Ali encyclopedia.")

# Also remove the partial array from content.json
with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    content = json.load(f)

if "imam_ali" in content:
    del content["imam_ali"]
    with open('assets/data/content.json', 'w', encoding='utf-8') as f:
        json.dump(content, f, ensure_ascii=False, indent=2)
    print("Removed partial imam_ali from content.json")
