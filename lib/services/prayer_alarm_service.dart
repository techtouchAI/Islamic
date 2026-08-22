import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PrayerAlarmService {
  static const MethodChannel _channel =
      MethodChannel('com.techtouchai.islamic/adhan');

  /// Native alarms are initialized lazily by the MethodChannel manager.
  /// Kept as an async compatibility entry point for the application bootstrap.
  static Future<void> init() async {}

  static Future<bool> checkExactAlarmPermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkExactAlarmPermission') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      debugPrint('Exact alarm permission check failed: $error');
      return false;
    }
  }

  static Future<bool> checkFullScreenPermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkFullScreenPermission') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      debugPrint('Full-screen permission check failed: $error');
      return false;
    }
  }

  static Future<void> openExactAlarmSettings() async {
    try {
      await _channel.invokeMethod<void>('openExactAlarmSettings');
    } on MissingPluginException {
      debugPrint('Exact alarm settings are not available on this platform.');
    } on PlatformException catch (error) {
      debugPrint('Opening exact alarm settings failed: $error');
    }
  }

  static Future<void> schedulePrayer(
    int id,
    DateTime prayerTime,
    String prayerName, {
    DateTime? localCivilTime,
    int timezoneOffsetMinutes = 0,
    bool timezoneUsesDevice = false,
    bool fullScreen = false,
    double volume = 1.0,
    int preAlertMinutes = 0,
  }) async {
    try {
      await _channel.invokeMethod('scheduleAdhan', {
        'id': id,
        'timeInMillis': prayerTime.toUtc().millisecondsSinceEpoch,
        'localTimeInMillis':
            (localCivilTime ?? prayerTime.toUtc()).millisecondsSinceEpoch,
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
        'timezoneUsesDevice': timezoneUsesDevice,
        'prayerName': prayerName,
        'fullScreen': fullScreen,
        'volume': volume,
        'preAlertMinutes': preAlertMinutes,
      });
    } on MissingPluginException {
      debugPrint('Adhan native channel is unavailable on this platform.');
    } on PlatformException catch (error) {
      debugPrint("Failed to schedule Adhan: '${error.message}'.");
    }
  }

  static Future<void> cancelPrayer(int id) async {
    try {
      await _channel.invokeMethod('cancelAdhan', {'id': id});
    } on MissingPluginException {
      debugPrint('Adhan native channel is unavailable on this platform.');
    } on PlatformException catch (error) {
      debugPrint("Failed to cancel Adhan: '${error.message}'.");
    }
  }
}
