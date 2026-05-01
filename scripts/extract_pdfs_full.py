import pdfplumber
import json
import re

def clean_arabic_text(text):
    if not text:
        return ""
    # Remove weird artifacts and normalize spaces
    text = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\xff]', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def parse_prophet_duas(pdf_path):
    print(f"Extracting prophet duas from {pdf_path}")
    duas = []
    taweez = []

    try:
        with pdfplumber.open(pdf_path) as pdf:
            full_text = ""
            for page in pdf.pages:
                text = page.extract_text()
                if text:
                    full_text += text + "\n\n"

            # A very simplistic split logic based on common patterns in such books
            # Often, duas start with numbers or specific markers. We will split by double newlines or similar.
            paragraphs = full_text.split('\n\n')
            id_counter = 1
            current_dua = ""

            for p in paragraphs:
                p = clean_arabic_text(p)
                if len(p) > 20: # skip very short headers or numbers
                    if "تعويذة" in p or "عوذة" in p:
                        taweez.append({"id": len(taweez)+1, "title": f"تعويذة {len(taweez)+1}", "content": p})
                    else:
                        duas.append({"id": len(duas)+1, "title": f"دعاء {len(duas)+1}", "content": p})

            # If nothing was extracted, fallback to a single block
            if not duas:
                duas.append({"id": 1, "title": "أدعية النبي", "content": clean_arabic_text(full_text[:5000])})

    except Exception as e:
        print(f"Error parsing {pdf_path}: {e}")

    return duas, taweez

def parse_imam_ali(pdf_path):
    print(f"Extracting Imam Ali from {pdf_path}")
    quotes = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            # Only process first 10 pages to avoid timeout, it's a huge file
            for i, page in enumerate(pdf.pages[:10]):
                text = page.extract_text()
                if text:
                    cleaned = clean_arabic_text(text)
                    if len(cleaned) > 50:
                        quotes.append({
                            "id": len(quotes) + 1,
                            "title": f"من دعائه (ع) - {len(quotes)+1}",
                            "content": cleaned
                        })
    except Exception as e:
        print(f"Error parsing {pdf_path}: {e}")
    return quotes

def parse_dreams_structured(pdf_path, prefix):
    print(f"Extracting dreams from {pdf_path}")
    dreams = []
    try:
        with pdfplumber.open(pdf_path) as pdf:
            # Process first 20 pages
            for i, page in enumerate(pdf.pages[:20]):
                text = page.extract_text()
                if text:
                    cleaned = clean_arabic_text(text)
                    if len(cleaned) > 20:
                        # Split by some heuristic, maybe newlines
                        parts = cleaned.split('.')
                        for p in parts:
                            p = p.strip()
                            if len(p) > 30:
                                dreams.append({
                                    "id": len(dreams) + 1,
                                    "title": f"تفسير {prefix} {len(dreams)+1}",
                                    "content": p + "."
                                })
    except Exception as e:
        print(f"Error parsing {pdf_path}: {e}")
    return dreams

print("Starting extraction...")
prophet_duas, prophet_taweez = parse_prophet_duas("/tmp/pdfs/prophet.pdf")
dreams_quran = parse_dreams_structured("/tmp/pdfs/quran_dreams.pdf", "رؤيا")
dreams_sirin = parse_dreams_structured("/tmp/pdfs/sirin_dreams.pdf", "حلم")
imam_ali = parse_imam_ali("/tmp/pdfs/imam_ali.pdf")

print(f"Extracted {len(prophet_duas)} prophet duas")
print(f"Extracted {len(dreams_quran)} quran dreams")
print(f"Extracted {len(dreams_sirin)} sirin dreams")
print(f"Extracted {len(imam_ali)} imam ali quotes")

data = {
    "prophet_duas": prophet_duas,
    "prophet_taweez": prophet_taweez,
    "dreams_quran": dreams_quran,
    "dreams_sirin": dreams_sirin,
    "imam_ali": imam_ali
}

with open('/tmp/extracted_data.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Extraction complete!")
