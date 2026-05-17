import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HijriCalendarScreen extends StatefulWidget {
  @override
  _HijriCalendarScreenState createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late PageController _pageController;
  HijriCalendar? _todayHijri;
  int _manualOffset = 0;
  List<dynamic> _events = [
    {"title": "رأس السنة الهجرية", "day": 1, "month": 1},
    {"title": "عاشوراء", "day": 10, "month": 1},
    {"title": "المولد النبوي الشريف", "day": 12, "month": 3},
    {"title": "الإسراء والمعراج", "day": 27, "month": 7},
    {"title": "النصف من شعبان", "day": 15, "month": 8},
    {"title": "بداية شهر رمضان", "day": 1, "month": 9},
    {"title": "عيد الفطر المبارك", "day": 1, "month": 10},
    {"title": "يوم عرفة", "day": 9, "month": 12},
    {"title": "عيد الأضحى المبارك", "day": 10, "month": 12},
  ];

  static const MethodChannel _hijriChannel = MethodChannel('com.techtouchai.islamic/hijri');

  @override
  void initState() {
    super.initState();
    // استخدام رقم كبير لتفعيل التمرير اللانهائي (Infinite Scroll)
    _pageController = PageController(initialPage: 1200);
    _fetchHijriData();
  }

  Future<void> _fetchHijriData() async {
    HijriCalendar.setLocal('ar');
    final prefs = await SharedPreferences.getInstance();
    _manualOffset = prefs.getInt('hijri.date.correction.value') ?? 0;
    
    try {
      final date = await _hijriChannel.invokeMethod('getHijriDate', {'manualOffset': _manualOffset});
      final events = await _hijriChannel.invokeMethod('getEvents');
      
      setState(() {
        if (date != null && date is Map) {
           // We ignore the map from Native because manually setting properties breaks HijriCalendar internals.
           // Instead we initialize properly by letting the library process the date via `fromDate` using the manual offset.
           _todayHijri = HijriCalendar.fromDate(DateTime.now().add(Duration(days: _manualOffset)));
        } else {
           _todayHijri = HijriCalendar.fromDate(DateTime.now().add(Duration(days: _manualOffset)));
        }
        
        if (events != null && events is List) {
           _events = events;
        }
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get Hijri Date: '${e.message}'.");
      setState(() {
         _todayHijri = HijriCalendar.now();
      });
    } catch (e) {
      // التقاط أي استثناءات أخرى (مثل أخطاء التحويل) لضمان عدم ظهور الشاشة الرمادية
      debugPrint("Unknown error fetching Hijri Date: $e");
      setState(() {
         _todayHijri = HijriCalendar.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // شاشة التحميل الآمنة
    if (_todayHijri == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('التقويم الهجري', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        reverse: true, // الاتجاه من اليمين لليسار RTL
        itemBuilder: (context, index) {
          try {
            int monthOffset = index - 1200;
            int targetMonth = _todayHijri!.hMonth + monthOffset;
            int targetYear = _todayHijri!.hYear;
            while (targetMonth > 12) { targetMonth -= 12; targetYear++; }
            while (targetMonth < 1) { targetMonth += 12; targetYear--; }

            // Let HijriCalendar handle the math safely.
            // The method `hijriToGregorian` works as long as we use an initialized object.
            DateTime gFirstDay = _todayHijri!.hijriToGregorian(targetYear, targetMonth, 1);
            var pageHijri = HijriCalendar.fromDate(gFirstDay);
            // Force hDay=1 to align grid since fromDate uses the exact day it resolved to.
            pageHijri.hDay = 1;

            return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Card(
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pageHijri.longMonthName} ${pageHijri.hYear}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${gFirstDay.year} ${_getGregorianMonthName(gFirstDay.month)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Lottie.asset('assets/lottie/calendar.json', errorBuilder: (context, error, stackTrace) => Icon(Icons.calendar_today, color: Colors.white, size: 40)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: _buildCalendarGridForPage(pageHijri, gFirstDay),
                ),

                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        "الحدث القادم",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      // التعامل الآمن مع القيم الفارغة (Null handling)
                      final title = event['title']?.toString() ?? 'حدث غير محدد';
                      final day = event['day']?.toString() ?? '';
                      final month = event['month']?.toString() ?? '';
                      
                      return Card(
                        color: const Color(0xFF2A2A2A),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          trailing: Text("$day $month", style: const TextStyle(color: Colors.blueAccent, fontSize: 14)),
                        )
                      );
                    },
                  ),
                )
              ],
            ),
          );
          } catch (e) {
            return Center(child: Text("Error: ${e.toString()}", style: TextStyle(color: Colors.white)));
          }
        },
      ),
    );
  }

  Widget _buildCalendarGridForPage(HijriCalendar pageHijri, DateTime gFirstDay) {
    int daysInMonth = 30; // قيمة افتراضية للسلامة
    try {
      daysInMonth = pageHijri.lengthOfMonth;
    } catch (e) {
      debugPrint("Error getting length of month: $e");
    }

    int startingWeekday = gFirstDay.weekday;
    if (startingWeekday == 7) startingWeekday = 0; // الأحد = 0 في بعض التقويمات

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Safe constraint inside Expanded Column
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: daysInMonth + startingWeekday,
      itemBuilder: (context, index) {
        if (index < startingWeekday) {
          return const SizedBox.shrink(); // استخدام SizedBox.shrink للأداء الأفضل بدلاً من Container فارغ
        }

        int hDay = index - startingWeekday + 1;
        bool isToday = (hDay == _todayHijri!.hDay) && (pageHijri.hMonth == _todayHijri!.hMonth) && (pageHijri.hYear == _todayHijri!.hYear);

        DateTime gDate = gFirstDay.add(Duration(days: hDay - 1));

        // معالجة التوافق بين أنواع البيانات بأمان
        bool hasEvent = _events.any((e) {
           final eDay = int.tryParse(e['day']?.toString() ?? '-1');
           final eMonth = int.tryParse(e['month']?.toString() ?? '-1');
           return eDay == hDay && eMonth == pageHijri.hMonth;
        });

        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday ? Colors.red : (hasEvent ? Colors.blue.withAlpha(51) : Colors.transparent),
            shape: isToday ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isToday ? null : BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withAlpha(51)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$hDay',
                style: TextStyle(
                  color: isToday ? Colors.white : (hasEvent ? Colors.blueAccent : Colors.white70),
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              Text(
                '${gDate.day}',
                style: TextStyle(
                  color: isToday ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGregorianMonthName(int month) {
    if (month < 1 || month > 12) return ''; // حماية من خطأ RangeError
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return months[month - 1];
  }
}
