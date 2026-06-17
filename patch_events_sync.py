import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

# Remove 'Today's Events (Top)'
old_top_events_start = """          // Today's Events (Top)
          if (todayEvents.isNotEmpty || todayAstro.isNotEmpty)
            _buildIslamicCard(
              title: 'أحداث اليوم',
              icon: Icons.mosque,
              children: [
                ...todayEvents.map((e) => _buildEventItem(
                    e.title, e.description, e.isImportant, false)),
                ...todayAstro.map((e) =>
                    _buildEventItem(e.title, e.description, false, true)),
              ],
            ),"""

content = content.replace(old_top_events_start, "")

# Remove variables not needed anymore
old_today_events_vars = """    // Top Section logic
    final todayEvents = CalendarRepository.getEventsForDay(
        _todayHijri!.hYear, _todayHijri!.hMonth, _todayHijri!.hDay);
    final todayAstro = CalendarRepository.getAstronomicalEventsForDay(
        _todayHijri!.hYear, _todayHijri!.hMonth, _todayHijri!.hDay);"""

content = content.replace(old_today_events_vars, "")

# Update bottom events logic
old_bottom_events_start = """                  if (_selectedDayData != null &&
                      (_selectedDayData!.events.isNotEmpty ||
                          _selectedDayData!.astronomicalEvents.isNotEmpty))
                    _buildIslamicCard(
                      title:
                          'أحداث يوم $_selectedDay ${_getHijriMonthName(_displayedHijri.hMonth)}',
                      icon: Icons.event_available,
                      children: [
                        ..._selectedDayData!.events.map((e) => _buildEventItem(
                            e.title, e.description, e.isImportant, false)),
                        ..._selectedDayData!.astronomicalEvents.map((e) =>
                            _buildEventItem(
                                e.title, e.description, false, true)),
                      ],
                    )
                  else if (_selectedDayData != null)
                    _buildIslamicCard(
                      title:
                          'أحداث يوم $_selectedDay ${_getHijriMonthName(_displayedHijri.hMonth)}',
                      icon: Icons.event_busy,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'لا توجد أحداث في هذا اليوم',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white54,
                                fontSize: 13),
                          ),
                        )
                      ],
                    )"""

new_bottom_events = """                  if (_selectedDay == null)
                    _buildIslamicCard(
                      title: 'الأحداث',
                      icon: Icons.touch_app,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'اختر يوماً لعرض الأحداث',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white54,
                                fontSize: 13),
                          ),
                        )
                      ],
                    )
                  else if (_selectedDayData != null &&
                      (_selectedDayData!.events.isNotEmpty ||
                          _selectedDayData!.astronomicalEvents.isNotEmpty))
                    _buildIslamicCard(
                      title:
                          'أحداث يوم $_selectedDay ${_getHijriMonthName(_displayedHijri.hMonth)}',
                      icon: Icons.event_available,
                      children: [
                        ..._selectedDayData!.events.map((e) => _buildEventItem(
                            e.title, e.description, e.isImportant, false)),
                        ..._selectedDayData!.astronomicalEvents.map((e) =>
                            _buildEventItem(
                                e.title, e.description, false, true)),
                      ],
                    )
                  else
                    _buildIslamicCard(
                      title:
                          'أحداث يوم $_selectedDay ${_getHijriMonthName(_displayedHijri.hMonth)}',
                      icon: Icons.event_busy,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'لا توجد أحداث في هذا اليوم',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.white54,
                                fontSize: 13),
                          ),
                        )
                      ],
                    )"""

content = content.replace(old_bottom_events_start, new_bottom_events)

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
