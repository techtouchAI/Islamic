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
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  HijriCalendar? _todayHijri;
  HijriCalendar _displayedHijri = HijriCalendar.fromDate(DateTime.now());
  PageController? _pageController;

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
      setState(() {
        _displayedHijri = _todayHijri!;
        _selectedDay = null;
        _selectedDayData = null;
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

  Widget _buildCalendarGridForPage(BuildContext context, int pageIndex) {
    final HijriCalendar monthHijri = _getHijriMonthForPage(pageIndex);

    return FutureBuilder<HijriMonthData?>(
      future: CalendarRepository.getMonthDataAsync(monthHijri.hYear, monthHijri.hMonth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.amber, size: 50),
                const SizedBox(height: 16),
                Text(
                  'لا توجد بيانات متاحة لشهر ${_getHijriMonthName(monthHijri.hMonth)}',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                )
              ],
            ),
          );
        }

        final monthData = snapshot.data!;
        final int daysInMonth = monthData.totalDays;

        DateTime firstDayGregorian;
        try {
          firstDayGregorian = DateTime.parse(monthData.expectedGregorianStart);
        } catch (e) {
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
          } catch (e2) {
            firstDayGregorian = DateTime.now();
          }
        }

        // Adjust for week starting on Monday (1 = Monday, 7 = Sunday)
        int startWeekday = firstDayGregorian.weekday;
        int leadingEmptyCells = startWeekday - 1;

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
                      '${_getHijriMonthName(monthHijri.hMonth)} ${monthHijri.hYear}',
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

                    HijriDayData? dayData;
                    for (var d in monthData.days) {
                      if (d.day == hDay) {
                        dayData = d;
                        break;
                      }
                    }

                    final bool hasEvent = dayData != null && (dayData.events.isNotEmpty || dayData.astronomicalEvents.isNotEmpty);
                    final bool isSelected = _selectedDay == hDay &&
                        _displayedHijri.hMonth == monthHijri.hMonth &&
                        _displayedHijri.hYear == monthHijri.hYear;

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
                            if (hasEvent)
                              Positioned(
                                bottom: 2,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isToday ? Colors.amber : Colors.amber.shade400,
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
    );
  }

  Widget _buildCombinedEventsCard() {
    if (_selectedDayData == null || (_selectedDayData!.events.isEmpty && _selectedDayData!.astronomicalEvents.isEmpty)) {
      return Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'لا توجد مناسبات لهذا اليوم',
              style: TextStyle(
                fontFamily: 'me_quran',
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أحداث هذا اليوم',
              style: TextStyle(
                fontFamily: 'me_quran',
                color: Colors.tealAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedDayData!.events.isNotEmpty) ...[
              const Text(
                'المناسبات الإسلامية:',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._selectedDayData!.events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(event.isImportant ? Icons.star : Icons.circle,
                         color: event.isImportant ? Colors.amber : Colors.tealAccent,
                         size: event.isImportant ? 16 : 10),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontFamily: 'me_quran',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: event.isImportant ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (event.description != null && event.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                event.description!,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],

            if (_selectedDayData!.astronomicalEvents.isNotEmpty) ...[
              if (_selectedDayData!.events.isNotEmpty) const Divider(color: Colors.white24, height: 24),
              const Text(
                'الأحداث الفلكية:',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._selectedDayData!.astronomicalEvents.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.nightlight_round, color: Colors.blueAccent, size: 14),
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
                              fontSize: 15,
                            ),
                          ),
                          if (event.description != null && event.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                event.description!,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
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
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return months[month - 1];
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
          _selectedDayData = null;
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
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _displayedHijri = _getHijriMonthForPage(page);
                  _selectedDay = null;
                  _selectedDayData = null;
                });
              },
              itemBuilder: (context, index) => _buildCalendarGridForPage(context, index),
            ),
          ),
          if (_selectedDay != null)
            _buildCombinedEventsCard()
          else
            const SizedBox(height: 8),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
