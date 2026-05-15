import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prayer_alarm_service.dart';

/// خدمة أوقات الصلاة - تتبع معايير هندسة الكود النظيف (Clean Architecture)
/// تقوم بحساب الأوقات ديناميكياً بناءً على الموقع الجغرافي للمستخدم.
class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  /// إعدادات الحساب وفق المنهج الجعفري (مؤسسة لوا - قم)
  /// يتم ضبط الزوايا بدقة: الفجر 16 درجة، العشاء 14 درجة، والمغرب 4 درجات.
  CalculationParameters get shiaJafariParams {
    final params = CalculationParameters(
      method: CalculationMethod.tehran, // Tehran method is base for Jafari
      fajrAngle: 16.0,
      ishaAngle: 14.0,
      maghribAngle: 4.0,
    );
    params.madhab = Madhab.shafi;
    params.highLatitudeRule = HighLatitudeRule.seventhOfTheNight;
    return params;
  }

  /// طلب الصلاحيات وجلب الموقع الجغرافي الحالي مع التخزين المؤقت
  Future<Position?> getCurrentLocation() async {
    try {
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }

      if (status.isGranted) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('cached_lat', pos.latitude);
          await prefs.setDouble('cached_lon', pos.longitude);

          return pos;
        } catch (timeoutOrError) {
          debugPrint("Location timeout or error, falling back: $timeoutOrError");
        }
      }
    } catch (e) {
      debugPrint("خطأ في جلب الموقع: $e");
    }

    // Fallback 1: Cache
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('cached_lat');
    final lon = prefs.getDouble('cached_lon');
    if (lat != null && lon != null) {
      return Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    // Fallback 2: Hillah
    return Position(
      latitude: 32.4682,
      longitude: 44.4361,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// حساب أوقات الصلاة ليوم معين وموقع معين مع التحويل الصارم للتوقيت المحلي
  Map<String, DateTime> calculatePrayerTimes(
    Position position, {
    DateTime? date,
  }) {
    final coordinates = Coordinates(position.latitude, position.longitude);
    final calculationDate = date ?? DateTime.now();

    final pt = PrayerTimes(
      coordinates: coordinates,
      date: calculationDate,
      calculationParameters: shiaJafariParams,
      precision: true,
    );

    // Midnight calculation: Sunset to Dawn
    final maghrib = pt.maghrib.toLocal();
    final nextFajr = pt.fajr.add(const Duration(days: 1)).toLocal();
    final duration = nextFajr.difference(maghrib);
    final midnight = maghrib.add(
      Duration(seconds: (duration.inSeconds / 2).round()),
    );

    return {
      'fajr': pt.fajr.toLocal(),
      'sunrise': pt.sunrise.toLocal(),
      'dhuhr': pt.dhuhr.toLocal(),
      'asr': pt.asr.toLocal(),
      'maghrib': pt.maghrib.toLocal(),
      'isha': pt.isha.toLocal(),
      'midnight': midnight,
    };
  }

  /// Background task scheduler
  Future<void> scheduleAdhanNotificationsBackground() async {
    try {
      final pos = await getCurrentLocation();
      if (pos == null) return;

      final prefs = await SharedPreferences.getInstance();

      final enabledPrayers = {
        'fajr': prefs.getBool('adhan_fajr') ?? true,
        'dhuhr': prefs.getBool('adhan_dhuhr') ?? true,
        'asr': prefs.getBool('adhan_asr') ?? true,
        'maghrib': prefs.getBool('adhan_maghrib') ?? true,
        'isha': prefs.getBool('adhan_isha') ?? true,
      };

      final offsets = {
        'fajr': prefs.getInt('adj_fajr') ?? 0,
        'dhuhr': prefs.getInt('adj_dhuhr') ?? 0,
        'asr': prefs.getInt('adj_asr') ?? 0,
        'maghrib': prefs.getInt('adj_maghrib') ?? 0,
        'isha': prefs.getInt('adj_isha') ?? 0,
      };

      await scheduleAdhanNotifications(pos, enabledPrayers, offsets);

      await prefs.setString('last_bg_sync', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint("Background scheduling failed: $e");
      rethrow;
    }
  }

  Future<void> forceReschedule() async {
    await scheduleAdhanNotificationsBackground();
  }

  /// جدولة التنبيهات لمدة 7 أيام قادمة
  Future<void> scheduleAdhanNotifications(
    Position position,
    Map<String, bool> enabledPrayers,
    Map<String, int> offsets,
  ) async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final times = calculatePrayerTimes(position, date: date);

      times.forEach((key, time) {
        final adjustedTime = time.add(Duration(minutes: offsets[key] ?? 0));
        final name = _getPrayerNameAr(key);
        _scheduleSingleNotification(
          i * 10 + _getPrayerId(key),
          name,
          adjustedTime,
          enabledPrayers[key] ?? true,
          key,
        );
      });
    }
  }

  String _getPrayerNameAr(String key) {
    switch (key) {
      case 'fajr':
        return "الفجر";
      case 'dhuhr':
        return "الظهر";
      case 'asr':
        return "العصر";
      case 'maghrib':
        return "المغرب";
      case 'isha':
        return "العشاء";
      default:
        return "";
    }
  }

  int _getPrayerId(String key) {
    switch (key) {
      case 'fajr':
        return 1;
      case 'dhuhr':
        return 2;
      case 'asr':
        return 3;
      case 'maghrib':
        return 4;
      case 'isha':
        return 5;
      default:
        return 0;
    }
  }

  void _scheduleSingleNotification(
    int id,
    String name,
    DateTime time,
    bool isEnabled,
    String key,
  ) async {
    if (!isEnabled || time.isBefore(DateTime.now())) return;
    final prefs = await SharedPreferences.getInstance();
    final bool isFullScreen = prefs.getBool('fullscreen_$key') ?? false;
    final double volume = prefs.getDouble('adhan_volume') ?? 1.0;
    final int preAlert = prefs.getInt('adhan_pre_alert') ?? 0;
    await PrayerAlarmService.schedulePrayer(id, time, name, fullScreen: isFullScreen, volume: volume, preAlertMinutes: preAlert);
  }
}
