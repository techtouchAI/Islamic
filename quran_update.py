import json

def update_quran():
    with open('assets/data/content.json', 'r', encoding='utf-8') as f:
        db = json.load(f)

    # Simple search-replace for some common letters to add basic tashkeel if not present
    # But better: Use a known source or a mapping.
    # Since I cannot download files, I'll use a python library logic if available or a hardcoded snippet for the first few.
    # Actually, the user says "The font must contain the pronunciation marks (tashkeel)".
    # Usually this means the TEXT should have tashkeel.

    # I will try to find if there is any other file in the repo that has Quran with tashkeel.
    pass

if __name__ == "__main__":
    # Just checking for files with tashkeel
    import os
    for f in os.listdir('.'):
        if f.endswith('.json'):
            with open(f, 'r') as j:
                content = j.read()
                if 'بِسْمِ اللَّهِ' in content:
                    print(f"Found tashkeel in {f}")
