import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

# Update _getNextEvent bug
old_next_event = """  _UpcomingEventInfo? _getNextEvent() {
    int y = _displayedHijri.hYear;
    int m = _displayedHijri.hMonth;
    int d = (_selectedDay ?? _realTodayHDay ?? 1) + 1;"""

new_next_event = """  _UpcomingEventInfo? _getNextEvent() {
    int y = _displayedHijri.hYear;
    int m = _displayedHijri.hMonth;
    int d = 1;

    // If we are on the current month, start from the selected day or today
    if (_todayHijri != null && y == _todayHijri!.hYear && m == _todayHijri!.hMonth) {
      d = (_selectedDay ?? _realTodayHDay ?? 1) + 1;
    }"""

content = content.replace(old_next_event, new_next_event)

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
