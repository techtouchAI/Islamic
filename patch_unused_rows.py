import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("final rowsCount = (totalCells / 7).ceil();", "")

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
