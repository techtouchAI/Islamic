import pytesseract
from pdf2image import convert_from_path
import json
import os
import re

def clean_arabic_text(text):
    text = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\xff]', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def extract_ocr(pdf_path, prefix, max_pages=15): # INCREASE PAGES
    print(f"Running OCR on {pdf_path}")
    dreams = []
    try:
        images = convert_from_path(pdf_path, first_page=3, last_page=max_pages) # skip title pages
        for i, img in enumerate(images):
            # Arabic OCR
            text = pytesseract.image_to_string(img, lang='ara')

            # Very simplistic parsing for typical dictionary/encyclopedia layouts
            lines = [line.strip() for line in text.split('\n') if len(line.strip()) > 5]

            current_title = f"{prefix} - {i+1}"
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
                        dreams.append({
                            "id": len(dreams) + 1,
                            "title": cleaned_title if len(cleaned_title) > 3 else f"{prefix} - جزء {len(dreams) + 1}",
                            "content": cleaned_content
                        })
                    current_title = f"{prefix} - تابع"
                    current_content = ""

            if current_content:
                cleaned_content = clean_arabic_text(current_content)
                if len(cleaned_content) > 50:
                    dreams.append({
                        "id": len(dreams) + 1,
                        "title": clean_arabic_text(current_title),
                        "content": cleaned_content
                    })

    except Exception as e:
        print(f"Error OCR {pdf_path}: {e}")
    return dreams

print("Starting OCR extraction for real data...")
dreams_quran = extract_ocr("/tmp/pdfs/quran_dreams.pdf", "رؤيا بالقرآن")
dreams_sirin = extract_ocr("/tmp/pdfs/sirin_dreams.pdf", "حلم لابن سيرين")
imam_ali = extract_ocr("/tmp/pdfs/imam_ali.pdf", "من الموسوعة")
prophet_duas = extract_ocr("/tmp/pdfs/prophet.pdf", "دعاء") # Also try OCR on prophet if pdfplumber failed

print(f"OCR Extracted: Quran: {len(dreams_quran)}, Sirin: {len(dreams_sirin)}, Imam: {len(imam_ali)}, Prophet: {len(prophet_duas)}")

# Only save if we found actual data
with open('assets/data/content.json', 'r', encoding='utf-8') as f:
    content = json.load(f)

if len(dreams_quran) > 0:
    content["dreams_quran"] = dreams_quran
if len(dreams_sirin) > 0:
    content["dreams_sirin"] = dreams_sirin
if len(prophet_duas) > 0:
    content["prophet_duas"] = prophet_duas
if len(imam_ali) > 0:
    content["imam_ali"] = imam_ali

with open('assets/data/content.json', 'w', encoding='utf-8') as f:
    json.dump(content, f, ensure_ascii=False, indent=2)

print("Updated content.json with real OCR data")
