import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/repositories/calendar_repository.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class _UpcomingEventInfo {
  final CalendarEvent? event;
  final AstronomicalEvent? astroEvent;
  final int hDay;
  final int hMonth;
  final int hYear;

  _UpcomingEventInfo({
    this.event,
    this.astroEvent,
    required this.hDay,
    required this.hMonth,
    required this.hYear,
  });
}

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({Key? key}) : super(key: key);

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  static const int _initialPage = 1000;
  static const List<String> _weekDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  AppHijriDate? _todayHijri;
  AppHijriDate _displayedHijri = AppHijriDate(day: 1, month: 1, year: 1446, monthName: 'محرم');
  PageController? _pageController;

  int? _realTodayHDay;
  int? _selectedDay;
  HijriDayData? _selectedDayData;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _goToToday() {
    if (_todayHijri != null && _pageController != null) {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final currentMonthData = CalendarRepository.getMonthData(
        _todayHijri!.year,
        _todayHijri!.month,
      );
      int calculatedTodayHDay = _calculateHDayForDate(
        DateTime.now(),
        currentMonthData,
        settingsProvider.hijriAdjustment,
      );

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
  }

  AppHijriDate _getHijriMonthForPage(int pageIndex) {
    if (_todayHijri == null) return AppHijriDate(day: 1, month: 1, year: 1446, monthName: 'محرم');
    int monthOffset = pageIndex - _initialPage;

    int newMonth = _todayHijri!.month + monthOffset;
    int newYear = _todayHijri!.year;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear -= 1;
    }

    return AppHijriDate(
      day: 1,
      month: newMonth,
      year: newYear,
      monthName: CalendarRepository.getHijriMonthName(newMonth),
    );
  }

  String _getHijriMonthName(int month) {
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _getGregorianMonthName(int month) {
    if (month < 1 || month > 12) return '';
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }

  _UpcomingEventInfo? _getNextEvent() {
    int y = _displayedHijri.year;
    int m = _displayedHijri.month;
    int d = 1;

    if (_selectedDay != null) {
      d = _selectedDay! + 1;
    } else if (_todayHijri != null &&
        y == _todayHijri!.year &&
        m == _todayHijri!.month) {
      d = (_realTodayHDay ?? 1) + 1;
    }

    for (int i = 0; i < 90; i++) {
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
              astroEvent: dayData.astronomicalEvents.first,
              hDay: d,
              hMonth: m,
              hYear: y);
        }
      }
      d++;
    }
    return null;
  }

  Widget _buildIslamicCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF16201D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade700, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.15), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (children.isNotEmpty)
              const Divider(color: Colors.white24, height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(
    String title,
    String? description,
    bool isImportant,
    bool isAstro,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Icon(
              isAstro
                  ? Icons.nightlight_round
                  : (isImportant ? Icons.star : Icons.circle),
              color: isAstro
                  ? Colors.blueAccent
                  : (isImportant ? Colors.amber : Colors.tealAccent),
              size: isAstro ? 14 : (isImportant ? 16 : 10),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'me_quran',
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                    wordSpacing: 1.5,
                    fontWeight:
                        isImportant ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.3,
                        wordSpacing: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGridForPage(BuildContext context, int pageIndex) {
    final AppHijriDate monthHijri = _getHijriMonthForPage(pageIndex);
    final settingsProvider = context.watch<SettingsProvider>();
    final int offset = settingsProvider.hijriAdjustment;
    final DateTime realNow = DateTime.now();

    return FutureBuilder<HijriMonthData>(
      future: CalendarRepository.getMonthDataAsync(
        monthHijri.year,
        monthHijri.month,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('حدث خطأ', style: TextStyle(color: Colors.white)),
          );
        }

        final monthData = snapshot.data!;
        final int daysInMonth = monthData.totalDays;

        DateTime firstDayGregorian;
        try {
          firstDayGregorian = DateTime.parse(monthData.expectedGregorianStart);
        } catch (e) {
          firstDayGregorian = CalendarRepository.getGregorianStartFallback(
            monthHijri.year,
            monthHijri.month,
          );
        }

        final DateTime adjustedGregorianStart = firstDayGregorian.add(
          Duration(days: offset),
        );

        int startWeekday = adjustedGregorianStart.weekday;
        int leadingEmptyCells = startWeekday - 1;

        final screenWidth = MediaQuery.of(context).size.width;
        final cellWidth = (screenWidth - 32) / 7;
        final cellHeight = cellWidth * 0.9;

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  '${_getHijriMonthName(monthHijri.month)} - ${_getGregorianMonthName(adjustedGregorianStart.month)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekDays
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                childAspectRatio: cellWidth / cellHeight,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(leadingEmptyCells + daysInMonth, (
                  index,
                ) {
                  if (index < leadingEmptyCells) {
                    return const SizedBox.shrink();
                  }

                  final int hDay = index - leadingEmptyCells + 1;
                  final DateTime cellGregorianDate = adjustedGregorianStart.add(
                    Duration(days: hDay - 1),
                  );
                  final bool isToday = cellGregorianDate.year == realNow.year &&
                      cellGregorianDate.month == realNow.month &&
                      cellGregorianDate.day == realNow.day;

                  HijriDayData? dayData;
                  for (var d in monthData.days) {
                    if (d.day == hDay) {
                      dayData = d;
                      break;
                    }
                  }

                  final bool hasEvent = dayData != null &&
                      (dayData.events.isNotEmpty ||
                          dayData.astronomicalEvents.isNotEmpty);
                  final bool isSelected = _selectedDay == hDay &&
                      _displayedHijri.month == monthHijri.month &&
                      _displayedHijri.year == monthHijri.year;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDay = hDay;
                        _selectedDayData = dayData;
                        _displayedHijri = monthHijri;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isToday
                            ? (hasEvent
                                ? Colors.teal.shade700
                                : Colors.teal.withOpacity(0.6))
                            : null,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isToday
                              ? Colors.amber
                              : (isSelected
                                  ? Colors.green
                                  : (hasEvent
                                      ? Colors.amber.withOpacity(0.8)
                                      : Colors.white12)),
                          width: isToday || isSelected
                              ? 2.0
                              : (hasEvent ? 1.5 : 1.0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$hDay',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday
                              ? (hasEvent
                                  ? Colors.amber.shade200
                                  : Colors.white)
                              : (hasEvent
                                  ? Colors.amber.shade300
                                  : Colors.white70),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  int _calculateHDayForDate(
    DateTime targetDate,
    HijriMonthData monthData,
    int offset,
  ) {
    DateTime firstDayGregorian;
    try {
      firstDayGregorian = DateTime.parse(monthData.expectedGregorianStart);
    } catch (e) {
      firstDayGregorian = DateTime.now();
    }

    final DateTime adjustedGregorianStart = firstDayGregorian.add(
      Duration(days: offset),
    );

    // We only care about the date part (year, month, day) to calculate difference correctly
    final targetDateOnly = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final startDateOnly = DateTime(
      adjustedGregorianStart.year,
      adjustedGregorianStart.month,
      adjustedGregorianStart.day,
    );

    return targetDateOnly.difference(startDateOnly).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final DateTime realNow = DateTime.now();
    final int offset = settingsProvider.hijriAdjustment;
    final newTodayHijri = CalendarRepository.getTodayHijri(realNow, offset);

    final currentMonthData = CalendarRepository.getMonthData(
      newTodayHijri.year,
      newTodayHijri.month,
    );
    int calculatedTodayHDay = newTodayHijri.day;

    if (_todayHijri == null ||
        _todayHijri!.month != newTodayHijri.month ||
        _todayHijri!.year != newTodayHijri.year ||
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

    // Bottom Section logic
    final upcomingInfo = _getNextEvent();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'التقويم الهجري',
          style: TextStyle(
            fontFamily: 'me_quran',
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.amber),
            tooltip: 'اليوم',
            onPressed: _goToToday,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Dates
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                Text(
                  _selectedDay != null
                    ? '$_selectedDay ${_getHijriMonthName(_displayedHijri.month)} ${_displayedHijri.year} هـ'
                    : '${_getHijriMonthName(_displayedHijri.month)} ${_displayedHijri.year} هـ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.amber,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${realNow.day} ${_getGregorianMonthName(realNow.month)} ${realNow.year} م',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),

          // Calendar Grid
          Expanded(
            flex: 4,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _displayedHijri = _getHijriMonthForPage(page);
                  _selectedDay = null;
                  _selectedDayData = null;
                });
              },
              itemBuilder: (context, index) =>
                  _buildCalendarGridForPage(context, index),
            ),
          ),

          // Bottom Section (Selected or Upcoming)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_selectedDay == null)
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
                          _selectedDayData!.astronomicalEvents.isNotEmpty))
                    _buildIslamicCard(
                      title:
                          'أحداث يوم $_selectedDay ${_getHijriMonthName(_displayedHijri.month)}',
                      icon: Icons.event_available,
                      children: [
                        ..._selectedDayData!.events.map(
                          (e) => _buildEventItem(
                            e.title,
                            e.description,
                            e.isImportant,
                            false,
                          ),
                        ),
                        ..._selectedDayData!.astronomicalEvents.map(
                          (e) => _buildEventItem(
                            e.title,
                            e.description,
                            false,
                            true,
                          ),
                        ),
                      ],
                    )
                  else if (_selectedDayData != null)
                    _buildIslamicCard(
                      title:
                          'أحداث يوم $_selectedDay ${_getHijriMonthName(_displayedHijri.month)}',
                      icon: Icons.event_busy,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'لا توجد أحداث في هذا اليوم',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (upcomingInfo != null && _selectedDay != null)
                    const SizedBox(height: 12),
                  if (upcomingInfo != null && _selectedDay != null)
                    _buildIslamicCard(
                      title: 'الحدث القادم',
                      icon: Icons.update,
                      subtitle:
                          'يوم ${upcomingInfo.hDay} ${_getHijriMonthName(upcomingInfo.hMonth)}',
                      children: [
                        if (upcomingInfo.event != null)
                          _buildEventItem(
                            upcomingInfo.event!.title,
                            upcomingInfo.event!.description,
                            upcomingInfo.event!.isImportant,
                            false,
                          ),
                        if (upcomingInfo.astroEvent != null)
                          _buildEventItem(
                            upcomingInfo.astroEvent!.title,
                            upcomingInfo.astroEvent!.description,
                            false,
                            true,
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
