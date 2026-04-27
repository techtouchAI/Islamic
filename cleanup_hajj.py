import json
import re

def cleanup():
    path = "assets/data/content.json"
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    stories = data.get("content", {}).get("stories", [])
    original_count = len(stories)

    # Filter: keep only items where the title does NOT contain English characters
    # focusing specifically on the Hajj items identified previously.
    new_stories = [
        it for it in stories
        if not re.search('[a-zA-Z]', it.get('title', ''))
    ]

    data["content"]["stories"] = new_stories
    new_count = len(new_stories)

    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Cleanup complete. Stories reduced from {original_count} to {new_count}.")

if __name__ == "__main__":
    cleanup()
