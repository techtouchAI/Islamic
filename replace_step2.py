import re

with open("lib/ui/calendar/hijri_calendar_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Add state variables
state_vars_insertion = """  late PageController _pageController;
  HijriCalendar? _todayHijri;
  int _manualOffset = 0;
  int? _selectedDay;
  List<dynamic> _selectedDayEvents = [];
"""
content = re.sub(
    r'  late PageController _pageController;\n  HijriCalendar\? _todayHijri;\n  int _manualOffset = 0;',
    state_vars_insertion,
    content,
    count=1
)

# Update GridView builder to include InkWell and onTap
grid_search = """        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday ? Colors.red : (hasEvent ? Colors.blue.withAlpha(51) : Colors.transparent),
            shape: isToday ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isToday ? null : BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withAlpha(51)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,"""

grid_replace = """        bool isSelected = _selectedDay == hDay;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDay = hDay;
              _selectedDayEvents = _events.where((e) {
                final eDay = int.tryParse(e['day']?.toString() ?? '-1');
                final eMonth = int.tryParse(e['month']?.toString() ?? '-1');
                return eDay == hDay && eMonth == pageHijri.hMonth;
              }).toList();
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday ? Colors.red : (isSelected ? Colors.green.withAlpha(51) : (hasEvent ? Colors.blue.withAlpha(51) : Colors.transparent)),
              shape: isToday ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isToday ? null : BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Colors.green : Colors.grey.withAlpha(51)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,"""

content = content.replace(grid_search, grid_replace)

with open("lib/ui/calendar/hijri_calendar_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)
