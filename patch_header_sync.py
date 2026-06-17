import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

# Let's replace the top header part
# Header Dates
old_header_start = """          // Header Dates
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Text(
                  '${_todayHijri!.hDay} ${_getHijriMonthName(_todayHijri!.hMonth)} ${_todayHijri!.hYear} هـ',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.amber,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${realNow.day} ${_getGregorianMonthName(realNow.month)} ${realNow.year} م',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white70, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),"""

new_header = """          // Header Dates
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Text(
                  _selectedDay != null
                      ? '$_selectedDay ${_getHijriMonthName(_displayedHijri.hMonth)} ${_displayedHijri.hYear} هـ'
                      : '${_getHijriMonthName(_displayedHijri.hMonth)} ${_displayedHijri.hYear} هـ',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.amber,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold),
                ),
                Builder(builder: (context) {
                  if (_selectedDay == null) {
                    return const SizedBox(height: 14); // Keep spacing even if not shown
                  }
                  final currentMonthData = CalendarRepository.getMonthData(_displayedHijri.hYear, _displayedHijri.hMonth);
                  DateTime firstDayGregorian;
                  try {
                    firstDayGregorian = DateTime.parse(currentMonthData.expectedGregorianStart);
                  } catch (e) {
                    firstDayGregorian = DateTime.now();
                  }

                  final settingsProvider = context.watch<SettingsProvider>();
                  final DateTime adjustedGregorianStart = firstDayGregorian.add(Duration(days: settingsProvider.hijriAdjustment));
                  final selectedGregorian = adjustedGregorianStart.add(Duration(days: _selectedDay! - 1));

                  return Text(
                    '${selectedGregorian.day} ${_getGregorianMonthName(selectedGregorian.month)} ${selectedGregorian.year} م',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70, fontFamily: 'Cairo'),
                  );
                }),
              ],
            ),
          ),"""

content = content.replace(old_header_start, new_header)

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
