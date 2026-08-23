import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/qibla_calculator.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const EventChannel _qiblaChannel =
      EventChannel('com.techtouchai.islamic/qibla');
  double _qiblaDirection = 0.0;
  bool _hasLocation = false;
  double _currentHeading = 0.0;
  bool _hasSensors = true;
  StreamSubscription<dynamic>? _headingSubscription;

  @override
  void initState() {
    super.initState();
    _initQibla();
    _headingSubscription = _qiblaChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (!mounted || event is! num) return;
        setState(() => _currentHeading = event.toDouble());
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _hasSensors = false);
      },
    );
  }

  Future<void> _initQibla() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _showLocationServiceDisabledDialog();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          _showPermissionDeniedDialog();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _qiblaDirection = calculateQiblaDirection(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _hasLocation = true;
      });
    } catch (error) {
      debugPrint('Unable to initialize qibla direction: $error');
      if (!mounted) return;
      setState(() => _hasLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد موقعك لاتجاه القبلة')),
      );
    }
  }

  @override
  void dispose() {
    _headingSubscription?.cancel();
    super.dispose();
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("خدمة الموقع معطلة"),
          content: Text("يرجى تفعيل خدمة الموقع لتحديد اتجاه القبلة."),
          actions: <Widget>[
            TextButton(
              child: Text("حسناً"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("صلاحية الموقع مطلوبة"),
          content: Text(
              "تطبيق الذاكرين يحتاج إلى صلاحية الوصول إلى الموقع لتحديد اتجاه القبلة. يرجى تفعيل الصلاحية من إعدادات التطبيق."),
          actions: <Widget>[
            TextButton(
              child: Text("إلغاء"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to the previous screen
              },
            ),
            TextButton(
              child: Text("فتح الإعدادات"),
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
    if (!_hasLocation)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_hasSensors)
      return Scaffold(
          body: Center(child: Text("جهازك لا يدعم مستشعر البوصلة")));

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
        child: Column(
          children: [
            SizedBox(height: 100.0),
            Image.asset('assets/images/kaaba.png', width: 80),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: (_currentHeading * (math.pi / 180) * -1),
                        child: Image.asset('assets/images/qibla_compass.png',
                            width: 340),
                      ),
                      Transform.rotate(
                        angle: ((_qiblaDirection - _currentHeading) *
                            (math.pi / 180)),
                        child: Image.asset('assets/images/qibla_needle.png',
                            width: 340),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Text(
                    "${_currentHeading.toStringAsFixed(1)}°",
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    _getDirectionText(_currentHeading),
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'اتجاه القبلة التقريبي: ${_qiblaDirection.round()}°',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
