import re

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'r') as f:
    content = f.read()

# Add `int? _realTodayHDay;` to the state
content = content.replace('  int? _selectedDay;', '  int? _realTodayHDay;\n  int? _selectedDay;')

build_replacement = """
  int _calculateHDayForDate(DateTime targetDate, HijriMonthData monthData, int offset) {
    DateTime firstDayGregorian;
    try {
      firstDayGregorian = DateTime.parse(monthData.expectedGregorianStart);
    } catch (e) {
      firstDayGregorian = DateTime.now();
    }

    final DateTime adjustedGregorianStart = firstDayGregorian.add(Duration(days: offset));

    // We only care about the date part (year, month, day) to calculate difference correctly
    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final startDateOnly = DateTime(adjustedGregorianStart.year, adjustedGregorianStart.month, adjustedGregorianStart.day);

    return targetDateOnly.difference(startDateOnly).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final DateTime realNow = DateTime.now();
    final DateTime adjustedTodayForHijri = realNow.add(Duration(days: settingsProvider.hijriAdjustment));
    final newTodayHijri = HijriCalendar.fromDate(adjustedTodayForHijri);

    final int offset = settingsProvider.hijriAdjustment;
    final currentMonthData = CalendarRepository.getMonthData(newTodayHijri.hYear, newTodayHijri.hMonth);
    int calculatedTodayHDay = _calculateHDayForDate(realNow, currentMonthData, offset);

    if (_todayHijri == null ||
        _todayHijri!.hMonth != newTodayHijri.hMonth ||
        _todayHijri!.hYear != newTodayHijri.hYear ||
        _realTodayHDay != calculatedTodayHDay) {

      HijriDayData? initialDayData;
      for (var d in currentMonthData.days) {
        if (d.day == calculatedTodayHDay) {
          initialDayData = d;
          break;
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _todayHijri = newTodayHijri;
          _realTodayHDay = calculatedTodayHDay;
          _displayedHijri = newTodayHijri;
          _selectedDay = calculatedTodayHDay;
          _selectedDayData = initialDayData;
          if (_pageController?.hasClients ?? false) {
            _pageController?.jumpToPage(_initialPage);
          }
        });
      });
    }

    if (_todayHijri == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }
"""

old_build_start = """  @override
  Widget build(BuildContext context) {"""
old_build_end = """    if (_todayHijri == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }"""

content = content.replace(content[content.find(old_build_start):content.find(old_build_end)+len(old_build_end)], build_replacement.strip())

# Update _goToToday
goto_replacement = """  void _goToToday() {
    if (_todayHijri != null && _pageController != null) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final currentMonthData = CalendarRepository.getMonthData(_todayHijri!.hYear, _todayHijri!.hMonth);
      int calculatedTodayHDay = _calculateHDayForDate(DateTime.now(), currentMonthData, settingsProvider.hijriAdjustment);

      HijriDayData? initialDayData;
      for (var d in currentMonthData.days) {
        if (d.day == calculatedTodayHDay) {
          initialDayData = d;
          break;
        }
      }

      setState(() {
        _displayedHijri = _todayHijri!;
        _selectedDay = calculatedTodayHDay;
        _selectedDayData = initialDayData;
      });
      _pageController!.animateToPage(
        _initialPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }"""

old_goto_start = """  void _goToToday() {"""
old_goto_end = """    }
  }"""

content = content.replace(content[content.find(old_goto_start):content.find(old_goto_end)+len(old_goto_end)], goto_replacement.strip())

with open('lib/ui/calendar/hijri_calendar_screen.dart', 'w') as f:
    f.write(content)
