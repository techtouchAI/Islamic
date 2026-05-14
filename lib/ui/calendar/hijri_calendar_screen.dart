import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class HijriCalendarScreen extends StatefulWidget {
  @override
  _HijriCalendarScreenState createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late HijriCalendar _today;
  int _manualOffset = 0;

  @override
  void initState() {
    super.initState();
    _updateHijriDate();
  }

  void _updateHijriDate() {
    HijriCalendar.setLocal('ar');
    _today = HijriCalendar.now();
    if (_manualOffset != 0) {
      final gregorianNow = DateTime.now().add(Duration(days: _manualOffset));
      _today = HijriCalendar.fromDate(gregorianNow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('التقويم الهجري')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${_today.hDay} ${_today.longMonthName} ${_today.hYear}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: () { setState(() { _manualOffset--; _updateHijriDate(); }); }, child: Text("-1 يوم")),
              SizedBox(width: 10),
              ElevatedButton(onPressed: () { setState(() { _manualOffset++; _updateHijriDate(); }); }, child: Text("+1 يوم")),
            ],
          )
        ],
      ),
    );
  }
}
