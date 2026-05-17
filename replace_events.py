import re

with open("lib/ui/calendar/hijri_calendar_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

with open("extracted_events_dart.txt", "r", encoding="utf-8") as f:
    new_events = f.read()
    # Need to match the definition `List<dynamic> _events = [`
    new_events = "List<dynamic> _events = [\n" + new_events.split('[\n')[1]

# Use regex to find and replace the _events list
pattern = re.compile(r'List<dynamic> _events = \[.*?\];', re.DOTALL)
new_content = pattern.sub(new_events.strip() + ";", content)

with open("lib/ui/calendar/hijri_calendar_screen.dart", "w", encoding="utf-8") as f:
    f.write(new_content)

print("Replaced _events in lib/ui/calendar/hijri_calendar_screen.dart")
