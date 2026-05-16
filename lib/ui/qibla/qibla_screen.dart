import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const EventChannel _qiblaChannel = EventChannel('com.techtouchai.islamic/qibla');
  double _qiblaDirection = 0.0;
  bool _hasLocation = false;
  double _currentHeading = 0.0;
  bool _hasSensors = true;

  @override
  void initState() {
    super.initState();
    _initQibla();
    _qiblaChannel.receiveBroadcastStream().listen((dynamic event) {
      setState(() {
        _currentHeading = event as double;
      });
    }, onError: (dynamic error) {
      setState(() {
        _hasSensors = false;
      });
    });
  }

  Future<void> _initQibla() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition();
    Coordinates coords = Coordinates(position.latitude, position.longitude);
    setState(() {
      _qiblaDirection = Qibla.qibla(coords);
      _hasLocation = true;
    });
  }

  String _getDirectionText(double degree) {
    if (degree >= 337.5 || degree < 22.5) return 'الشمال';
    if (degree >= 22.5 && degree < 67.5) return 'الشمال الشرقي';
    if (degree >= 67.5 && degree < 112.5) return 'الشرق';
    if (degree >= 112.5 && degree < 157.5) return 'الجنوب الشرقي';
    if (degree >= 157.5 && degree < 202.5) return 'الجنوب';
    if (degree >= 202.5 && degree < 247.5) return 'الجنوب الغربي';
    if (degree >= 247.5 && degree < 292.5) return 'الغرب';
    if (degree >= 292.5 && degree < 337.5) return 'الشمال الغربي';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLocation) return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_hasSensors) return Scaffold(body: Center(child: Text("جهازك لا يدعم مستشعر البوصلة")));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('اتجاه القبلة', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4DE1FF),
              Color(0xFF177AFB),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: (_currentHeading * (math.pi / 180) * -1),
                      child: Image.asset('assets/images/qibla_compass.png', width: 340),
                    ),
                    Transform.rotate(
                      angle: ((_qiblaDirection - _currentHeading) * (math.pi / 180)),
                      child: Image.asset('assets/images/qibla_needle.png', width: 340),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  "${_currentHeading.toStringAsFixed(1)}°",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  _getDirectionText(_qiblaDirection),
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/kaaba.png', width: 40),
                      SizedBox(height: 8),
                      Text(
                        "مكة المكرمة",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
