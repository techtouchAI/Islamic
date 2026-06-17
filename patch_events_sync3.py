import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

# Fix bottom events logic to add the "Select a day" block when _selectedDay is null
old_bottom = """                  if (_selectedDayData != null &&
                      (_selectedDayData!.events.isNotEmpty ||
                          _selectedDayData!.astronomicalEvents.isNotEmpty))"""

new_bottom = """                  if (_selectedDay == null)
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
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_selectedDayData != null &&
                      (_selectedDayData!.events.isNotEmpty ||
                          _selectedDayData!.astronomicalEvents.isNotEmpty))"""

content = content.replace(old_bottom, new_bottom)

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
