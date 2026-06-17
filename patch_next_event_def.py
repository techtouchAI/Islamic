import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

old_get_next_event = """  _UpcomingEventInfo? _getNextEvent(HijriCalendar today) {
    int y = today.hYear;
    int m = today.hMonth;
    int d = today.hDay + 1;

    for (int i = 0; i < 60; i++) {
      if (d > 30) {
        d = 1;
        m++;
        if (m > 12) {
          m = 1;
          y++;
        }
      }

      final events = CalendarRepository.getEventsForDay(y, m, d);
      if (events.isNotEmpty) {
        return _UpcomingEventInfo(
            event: events.first, hDay: d, hMonth: m, hYear: y);
      }
      final astro = CalendarRepository.getAstronomicalEventsForDay(y, m, d);
      if (astro.isNotEmpty) {
        return _UpcomingEventInfo(
            astroEvent: astro.first, hDay: d, hMonth: m, hYear: y);
      }
      d++;
    }
    return null;
  }"""

new_get_next_event = """  _UpcomingEventInfo? _getNextEvent() {
    int y = _displayedHijri.hYear;
    int m = _displayedHijri.hMonth;
    int d = (_selectedDay ?? _realTodayHDay ?? 1) + 1;

    for (int i = 0; i < 60; i++) {
      final monthData = CalendarRepository.getMonthData(y, m);
      final int totalDays = monthData.totalDays;

      if (d > totalDays) {
        d = 1;
        m++;
        if (m > 12) {
          m = 1;
          y++;
        }
        continue;
      }

      HijriDayData? dayData;
      for (var dayObj in monthData.days) {
        if (dayObj.day == d) {
          dayData = dayObj;
          break;
        }
      }

      if (dayData != null) {
        if (dayData.events.isNotEmpty) {
          return _UpcomingEventInfo(
              event: dayData.events.first, hDay: d, hMonth: m, hYear: y);
        }
        if (dayData.astronomicalEvents.isNotEmpty) {
          return _UpcomingEventInfo(
              astroEvent: dayData.astronomicalEvents.first, hDay: d, hMonth: m, hYear: y);
        }
      }
      d++;
    }
    return null;
  }"""

content = content.replace(old_get_next_event, new_get_next_event)

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
