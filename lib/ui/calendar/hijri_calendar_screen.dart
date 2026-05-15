import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HijriCalendarScreen extends StatefulWidget {
  @override
  _HijriCalendarScreenState createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  static const MethodChannel _hijriChannel = MethodChannel('com.techtouchai.islamic/hijri');
  Map<dynamic, dynamic>? _today;
  int _manualOffset = 0;
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchHijriData();
  }

  Future<void> _fetchHijriData() async {
    try {
      final date = await _hijriChannel.invokeMethod('getHijriDate', {'manualOffset': _manualOffset});
      final events = await _hijriChannel.invokeMethod('getEvents');
      setState(() {
        _today = date as Map<dynamic, dynamic>;
        _events = events as List<dynamic>;
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get Hijri Date: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('التقويم الهجري')),
      body: _today == null
        ? Center(child: CircularProgressIndicator())
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2)
                  ),
                  child: Column(
                    children: [
                      Text('${_today!["day"]}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                      Text('${_today!["monthName"]} ${_today!["year"]}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(shape: CircleBorder(), padding: EdgeInsets.all(15)),
                      onPressed: () { setState(() { _manualOffset--; _fetchHijriData(); }); },
                      child: Icon(Icons.remove)
                    ),
                    SizedBox(width: 20),
                    Text("ضبط التاريخ", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(shape: CircleBorder(), padding: EdgeInsets.all(15)),
                      onPressed: () { setState(() { _manualOffset++; _fetchHijriData(); }); },
                      child: Icon(Icons.add)
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text("المناسبات القادمة", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: Icon(Icons.event, color: Theme.of(context).primaryColor),
                          title: Text(event['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Text("${event['day']} من ${event['month']}", style: TextStyle(fontSize: 14)),
                        )
                      );
                    },
                  )
                )
              ],
            ),
          ),
    );
  }
}
