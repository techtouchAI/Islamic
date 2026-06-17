import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

# Fix DST calculateHDayForDate
old_calc_hday = """  int _calculateHDayForDate(
      DateTime targetDate, HijriMonthData monthData, int offset) {
    DateTime firstDayGregorian;
    try {
      firstDayGregorian = DateTime.parse(monthData.expectedGregorianStart);
    } catch (e) {
      firstDayGregorian = DateTime.now();
    }

    final DateTime adjustedGregorianStart =
        firstDayGregorian.add(Duration(days: offset));

    // We only care about the date part (year, month, day) to calculate difference correctly
    final targetDateOnly =
        DateTime(targetDate.year, targetDate.month, targetDate.day);
    final startDateOnly = DateTime(
        adjustedGregorianStart.year,
        adjustedGregorianStart.month,
        adjustedGregorianStart.day);

    return targetDateOnly.difference(startDateOnly).inDays + 1;
  }"""

new_calc_hday = """  int _calculateHDayForDate(
      DateTime targetDate, HijriMonthData monthData, int offset) {
    DateTime firstDayGregorian;
    try {
      firstDayGregorian = DateTime.parse(monthData.expectedGregorianStart);
    } catch (e) {
      firstDayGregorian = DateTime.now();
    }

    final DateTime adjustedGregorianStart =
        firstDayGregorian.add(Duration(days: offset));

    // We only care about the date part (year, month, day) to calculate difference correctly
    final targetDateOnly =
        DateTime.utc(targetDate.year, targetDate.month, targetDate.day);
    final startDateOnly = DateTime.utc(
        adjustedGregorianStart.year,
        adjustedGregorianStart.month,
        adjustedGregorianStart.day);

    return targetDateOnly.difference(startDateOnly).inDays + 1;
  }"""

content = content.replace(old_calc_hday, new_calc_hday)

# Fix _getNextEvent
old_next_event = """  _UpcomingEventInfo? _getNextEvent() {
    int y = _displayedHijri.hYear;
    int m = _displayedHijri.hMonth;
    int d = 1;

    // If we are on the current month, start from the selected day or today
    if (_todayHijri != null &&
        y == _todayHijri!.hYear &&
        m == _todayHijri!.hMonth) {
      d = (_selectedDay ?? _realTodayHDay ?? 1) + 1;
    }"""

new_next_event = """  _UpcomingEventInfo? _getNextEvent() {
    int y = _displayedHijri.hYear;
    int m = _displayedHijri.hMonth;
    int d = 1;

    if (_selectedDay != null) {
      d = _selectedDay! + 1;
    } else if (_todayHijri != null &&
        y == _todayHijri!.hYear &&
        m == _todayHijri!.hMonth) {
      d = (_realTodayHDay ?? 1) + 1;
    }"""

content = content.replace(old_next_event, new_next_event)

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
