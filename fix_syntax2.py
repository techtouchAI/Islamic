import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

search_str = r'''                  \)\)\.toList\(\),
                \),
              const SizedBox\(height: 8\),'''

replace_str = r'''                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),'''

content = re.sub(search_str, replace_str, content)

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
