import json

try:
    with open('assets/data/content.json', 'r') as f:
        content = f.read()
        json.loads(content)
        print("JSON is valid")
except json.decoder.JSONDecodeError as e:
    print(f"JSON Error: {e}")
    # print the context around the error
    error_index = e.pos
    start = max(0, error_index - 50)
    end = min(len(content), error_index + 50)
    print(content[start:end])
