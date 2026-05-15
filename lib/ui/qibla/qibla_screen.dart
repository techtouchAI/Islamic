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

  @override
  Widget build(BuildContext context) {
    if (!_hasLocation) return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_hasSensors) return Scaffold(body: Center(child: Text("جهازك لا يدعم مستشعر البوصلة")));

    return Scaffold(
      appBar: AppBar(title: Text('اتجاه القبلة')),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: (_currentHeading * (math.pi / 180) * -1),
              child: Image.asset('assets/images/qibla_compass.png', width: 300),
            ),
            Transform.rotate(
              angle: ((_qiblaDirection - _currentHeading) * (math.pi / 180)),
              child: Image.asset('assets/images/qibla_needle.png', width: 300),
            ),
          ],
        ),
      ),
    );
  }
}
