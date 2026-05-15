import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class PrayerAlarmService {
  static const MethodChannel _channel = MethodChannel('com.techtouchai.islamic/adhan');

  static Future<void> init() async {
    // Initialization handled natively if needed
  }

  static Future<void> schedulePrayer(int id, DateTime prayerTime, String prayerName, {bool fullScreen = false, double volume = 1.0, int preAlertMinutes = 0}) async {
    try {
      await _channel.invokeMethod('scheduleAdhan', {
        'id': id,
        'timeInMillis': prayerTime.millisecondsSinceEpoch,
        'prayerName': prayerName,
        'fullScreen': fullScreen,
        'volume': volume,
        'preAlertMinutes': preAlertMinutes,
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to schedule Adhan: '${e.message}'.");
    }
  }
}
