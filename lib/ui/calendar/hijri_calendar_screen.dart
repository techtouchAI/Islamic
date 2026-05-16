import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lottie/lottie.dart';

class HijriCalendarScreen extends StatefulWidget {
  @override
  _HijriCalendarScreenState createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  HijriCalendar? _todayHijri;
  DateTime _todayGregorian = DateTime.now();
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

  @override
  void initState() {
    super.initState();
    _fetchHijriData();
  }

  static const MethodChannel _hijriChannel = MethodChannel('com.techtouchai.islamic/hijri');

  Future<void> _fetchHijriData() async {
    HijriCalendar.setLocal('ar');
    try {
      final date = await _hijriChannel.invokeMethod('getHijriDate', {'manualOffset': _manualOffset});
      final events = await _hijriChannel.invokeMethod('getEvents');
      setState(() {
        if (date != null && date is Map) {
           _todayHijri = HijriCalendar()
             ..hYear = date['year']
             ..hMonth = date['month']
             ..hDay = date['day'];
        } else {
           _todayHijri = HijriCalendar.now();
        }
        if (events != null) {
           _events = events as List<dynamic>;
        }
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get Hijri Date: '${e.message}'.");
      setState(() {
         _todayHijri = HijriCalendar.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_todayHijri == null) {
      return Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text('التقويم الهجري', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: Color(0xFF2A2A2A),
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
                          '${_todayHijri!.hDay} ${_todayHijri!.longMonthName} ${_todayHijri!.hYear}',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '${_todayGregorian.day} ${_getGregorianMonthName(_todayGregorian.month)} ${_todayGregorian.year}',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      child: Lottie.asset('assets/lottie/calendar.json'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            Expanded(
              child: _buildCalendarGrid(),
            ),

            SizedBox(height: 20),

            Align(
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
            SizedBox(height: 10),
            Container(
              height: 100,
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Card(
                    color: Color(0xFF2A2A2A),
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(event['title'], style: TextStyle(color: Colors.white, fontSize: 16)),
                      trailing: Text("${event['day']} ${event['month']}", style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
                    )
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    int daysInMonth = _todayHijri!.lengthOfMonth;

    DateTime gFirstDay = _todayGregorian.subtract(Duration(days: _todayHijri!.hDay - 1));
    int startingWeekday = gFirstDay.weekday;
    if (startingWeekday == 7) startingWeekday = 0;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: daysInMonth + startingWeekday,
      itemBuilder: (context, index) {
        if (index < startingWeekday) {
          return Container();
        }

        int hDay = index - startingWeekday + 1;
        bool isToday = hDay == _todayHijri!.hDay;

        DateTime gDate = _todayGregorian.add(Duration(days: hDay - _todayHijri!.hDay));

        return Container(
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday ? Colors.red : Colors.transparent,
            shape: isToday ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isToday ? null : BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$hDay',
                style: TextStyle(
                  color: isToday ? Colors.white : Colors.white70,
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
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return months[month - 1];
  }
}
