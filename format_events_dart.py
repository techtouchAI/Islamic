import json

with open("extracted_events.json", "r", encoding="utf-8") as f:
    events = json.load(f)

dart_list_content = "  final List<dynamic> _events = [\n"
for event in events:
    # Escape quotes and backslashes for dart string
    title = event['title'].replace("\\", "\\\\").replace("'", "\\'").replace("\n", " ")
    dart_list_content += f"    {{\"title\": '{title}', \"day\": {event['day']}, \"month\": {event['month']}}},\n"
dart_list_content += "  ];\n"

with open("extracted_events_dart.txt", "w", encoding="utf-8") as f:
    f.write(dart_list_content)
print("Dart list formatted and saved to extracted_events_dart.txt")
