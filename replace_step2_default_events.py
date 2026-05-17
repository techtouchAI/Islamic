with open("lib/ui/calendar/hijri_calendar_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# I need to filter the default events list to show the upcoming events for the current month.
# I will modify `_events.length` to `_upcomingEvents.length` and `_events[index]` to `_upcomingEvents[index]`
# Wait, let's keep it simple. It asks "If no day is selected, default to showing the upcoming events for the current month."
# The `_events` array is all 143 events. We can filter it based on `pageHijri.hMonth`.

list_search2 = """                    itemCount: _selectedDay != null ? _selectedDayEvents.length : _events.length,
                    itemBuilder: (context, index) {
                      final event = _selectedDay != null ? _selectedDayEvents[index] : _events[index];"""

list_replace2 = """                    itemCount: _selectedDay != null ? _selectedDayEvents.length : _events.where((e) => int.tryParse(e['month']?.toString() ?? '-1') == pageHijri.hMonth).length,
                    itemBuilder: (context, index) {
                      final monthEvents = _events.where((e) => int.tryParse(e['month']?.toString() ?? '-1') == pageHijri.hMonth).toList();
                      final event = _selectedDay != null ? _selectedDayEvents[index] : monthEvents[index];"""

content = content.replace(list_search2, list_replace2)

with open("lib/ui/calendar/hijri_calendar_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)
