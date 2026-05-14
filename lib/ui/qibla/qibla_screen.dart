import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double _qiblaDirection = 0.0;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _initQibla();
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
    return Scaffold(
      appBar: AppBar(title: Text('اتجاه القبلة')),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error reading heading: ${snapshot.error}');
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          double? heading = snapshot.data?.heading;
          if (heading == null) return Center(child: Text("جهازك لا يدعم مستشعر البوصلة"));
          double kaabaNeedleAngle = _qiblaDirection - heading;
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(angle: (heading * (math.pi / 180) * -1), child: Icon(Icons.explore_outlined, size: 300, color: Colors.grey)),
                Transform.rotate(angle: (kaabaNeedleAngle * (math.pi / 180)), child: Icon(Icons.navigation, size: 100, color: Colors.red)),
              ],
            ),
          );
        },
      ),
    );
  }
}
