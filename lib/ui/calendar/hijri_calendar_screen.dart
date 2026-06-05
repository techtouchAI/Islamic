import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../utils/string_extensions.dart';
import '../../providers/settings_provider.dart';
import '../../data/repositories/calendar_repository.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({Key? key}) : super(key: key);

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  static const int _initialPage = 1000;
  static const List<String> _weekDays = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];

  HijriCalendar? _todayHijri;
  HijriCalendar _displayedHijri = HijriCalendar.fromDate(DateTime.now());
  PageController? _pageController;

  int? _selectedDay;
  List<CalendarEvent> _selectedDayEvents = [];

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
      setState(() {
        _displayedHijri = _todayHijri!;
        _selectedDay = null;
        _selectedDayEvents = [];
      });
      _pageController!.animateToPage(
        _initialPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  HijriCalendar _getHijriMonthForPage(int pageIndex) {
    if (_todayHijri == null) return HijriCalendar.fromDate(DateTime.now());
    int monthOffset = pageIndex - _initialPage;

    int newMonth = _todayHijri!.hMonth + monthOffset;
    int newYear = _todayHijri!.hYear;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear -= 1;
    }

    final temp = HijriCalendar()
      ..hYear = newYear
      ..hMonth = newMonth
      ..hDay = 1;
    return temp;
  }

  bool _hasEvent(int day, int month) {
    return CalendarRepository.getEventsForDay(_displayedHijri.hYear, month, day).isNotEmpty;
  }

  List<CalendarEvent> _getEventsForDay(int day, int month) {
    return CalendarRepository.getEventsForDay(_displayedHijri.hYear, month, day);
  }

  CalendarEvent? _getNextEvent() {
    if (_todayHijri == null) return null;

    for (int m = _todayHijri!.hMonth; m <= 12; m++) {
      int startDay = (m == _todayHijri!.hMonth) ? _todayHijri!.hDay + 1 : 1;
      for (int d = startDay; d <= 30; d++) {
        var events = CalendarRepository.getEventsForDay(_todayHijri!.hYear, m, d);
        if (events.isNotEmpty) return events.first;
      }
    }

    for (int m = 1; m <= 12; m++) {
      for (int d = 1; d <= 30; d++) {
        var events = CalendarRepository.getEventsForDay(_todayHijri!.hYear + 1, m, d);
        if (events.isNotEmpty) return events.first;
      }
    }

    return null;
  }

  Widget _buildCalendarGridForPage(BuildContext context, int pageIndex) {
    final HijriCalendar monthHijri = _getHijriMonthForPage(pageIndex);
    final int daysInMonth = monthHijri.getDaysInMonth(monthHijri.hYear, monthHijri.hMonth);

    DateTime firstDayGregorian;
    try {
      final firstDayTemp = HijriCalendar()
        ..hYear = monthHijri.hYear
        ..hMonth = monthHijri.hMonth
        ..hDay = 1;
      firstDayGregorian = firstDayTemp.hijriToGregorian(
        firstDayTemp.hYear,
        firstDayTemp.hMonth,
        firstDayTemp.hDay,
      );
    } catch (e) {
      firstDayGregorian = DateTime.now();
    }

    int startWeekday = firstDayGregorian.weekday;
    int leadingEmptyCells = (startWeekday + 1) % 7;

    final screenWidth = MediaQuery.of(context).size.width;
    final cellWidth = (screenWidth - 32) / 7;
    final cellHeight = cellWidth * 1.1;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rowsCount = (totalCells / 7).ceil();
    final gridHeight = rowsCount * cellHeight;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${monthHijri.longMonthName} ${monthHijri.hYear}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getGregorianMonthName(firstDayGregorian.month),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDays.map((day) => Expanded(
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
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: gridHeight,
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(leadingEmptyCells + daysInMonth, (index) {
                if (index < leadingEmptyCells) {
                  return const SizedBox.shrink();
                }

                final int hDay = index - leadingEmptyCells + 1;
                final bool isToday = _todayHijri != null &&
                    hDay == _todayHijri!.hDay &&
                    monthHijri.hMonth == _todayHijri!.hMonth &&
                    monthHijri.hYear == _todayHijri!.hYear;

                final bool hasEvent = _hasEvent(hDay, monthHijri.hMonth);
                final bool isSelected = _selectedDay == hDay &&
                    _displayedHijri.hMonth == monthHijri.hMonth &&
                    _displayedHijri.hYear == monthHijri.hYear;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDay = hDay;
                      _selectedDayEvents = _getEventsForDay(hDay, monthHijri.hMonth);
                      _displayedHijri = monthHijri;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? (hasEvent ? Colors.teal.shade700 : Colors.teal)
                          : null,
                      shape: isToday ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: isToday ? null : BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday && hasEvent
                            ? Colors.amber
                            : (isSelected
                                ? Colors.green
                                : (hasEvent ? Colors.amber : Colors.transparent)),
                        width: isToday && hasEvent
                            ? 2.0
                            : (isSelected ? 2.0 : (hasEvent ? 1.5 : 0.0)),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$hDay',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? (hasEvent ? Colors.amber.shade200 : Colors.white)
                                : (hasEvent ? Colors.amber.shade300 : Colors.white70),
                          ),
                        ),
                        if (isToday && hasEvent)
                          Positioned(
                            bottom: 2,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEventsCard(String title, List<CalendarEvent> events) {
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'me_quran',
                color: Colors.tealAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...events.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, color: Colors.tealAccent, size: 8),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'me_quran',
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  String _getGregorianMonthName(int month) {
    if (month < 1 || month > 12) return '';
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return months[month - 1];
  }

  Widget _buildTodayEventCard(List<CalendarEvent> events) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.amber,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مناسبة اليوم',
            style: TextStyle(
              fontFamily: 'me_quran',
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...events.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🕌', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontFamily: 'me_quran',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_todayHijri!.hDay} ${_todayHijri!.longMonthName} ${_todayHijri!.hYear} هـ',
                      style: const TextStyle(
                        fontFamily: 'me_quran',
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final DateTime trueNow = DateTime.now().add(Duration(days: settingsProvider.hijriAdjustment));
    final newTodayHijri = HijriCalendar.fromDate(trueNow);

    if (_todayHijri == null ||
        _todayHijri!.hDay != newTodayHijri.hDay ||
        _todayHijri!.hMonth != newTodayHijri.hMonth ||
        _todayHijri!.hYear != newTodayHijri.hYear) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _todayHijri = newTodayHijri;
          _displayedHijri = newTodayHijri;
          _selectedDay = null;
          _selectedDayEvents = [];
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

    final CalendarEvent? nextEvent = _getNextEvent();
    final List<CalendarEvent> todayEvents = _getEventsForDay(_todayHijri!.hDay, _todayHijri!.hMonth);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'التقويم الهجري',
          style: TextStyle(
            fontFamily: 'me_quran',
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            tooltip: 'اليوم',
            onPressed: _goToToday,
          ),
        ],
      ),
      body: Column(
        children: [
          if (todayEvents.isNotEmpty)
            _buildTodayEventCard(todayEvents),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _displayedHijri = _getHijriMonthForPage(page);
                  _selectedDay = null;
                  _selectedDayEvents = [];
                });
              },
              itemBuilder: (context, index) => _buildCalendarGridForPage(context, index),
            ),
          ),
          if (_selectedDay != null && _selectedDayEvents.isNotEmpty)
            _buildEventsCard('أحداث هذا اليوم', _selectedDayEvents)
          else if (nextEvent != null && !(todayEvents.isNotEmpty && nextEvent.title == todayEvents.first.title))
            _buildEventsCard('الأحداث القادمة', [nextEvent])
          else if (nextEvent == null)
             _buildEventsCard('الأحداث القادمة', [CalendarEvent(title: 'لا توجد مناسبات قادمة')]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
