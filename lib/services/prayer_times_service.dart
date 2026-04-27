import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// خدمة أوقات الصلاة - تتبع معايير هندسة الكود النظيف (Clean Architecture)
/// تقوم بحساب الأوقات ديناميكياً بناءً على الموقع الجغرافي للمستخدم.
class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

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

  /// طلب الصلاحيات وجلب الموقع الجغرافي الحالي
  Future<Position?> getCurrentLocation() async {
    try {
      // التحقق من صلاحيات الموقع عبر permission_handler
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
        if (status.isDenied) return null;
      }

      if (status.isPermanentlyDenied) {
        openAppSettings();
        return null;
      }

      // جلب الإحداثيات بدقة عالية
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint("خطأ في جلب الموقع: $e");
      return null;
    }
  }

  /// حساب أوقات الصلاة ليوم معين وموقع معين مع التحويل الصارم للتوقيت المحلي
  Map<String, DateTime> calculatePrayerTimes(Position position, {DateTime? date}) {
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
    final midnight = maghrib.add(Duration(seconds: (duration.inSeconds / 2).round()));

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

  /// جدولة التنبيهات لمدة 7 أيام قادمة
  Future<void> scheduleAdhanNotifications(Position position, Map<String, bool> enabledPrayers, Map<String, int> offsets) async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final times = calculatePrayerTimes(position, date: date);

      times.forEach((key, time) {
        final adjustedTime = time.add(Duration(minutes: offsets[key] ?? 0));
        final name = _getPrayerNameAr(key);
        _scheduleSingleNotification(i * 10 + _getPrayerId(key), name, adjustedTime, enabledPrayers[key] ?? true);
      });
    }
  }

  String _getPrayerNameAr(String key) {
    switch (key) {
      case 'fajr': return "الفجر";
      case 'dhuhr': return "الظهر";
      case 'asr': return "العصر";
      case 'maghrib': return "المغرب";
      case 'isha': return "العشاء";
      default: return "";
    }
  }

  int _getPrayerId(String key) {
    switch (key) {
      case 'fajr': return 1;
      case 'dhuhr': return 2;
      case 'asr': return 3;
      case 'maghrib': return 4;
      case 'isha': return 5;
      default: return 0;
    }
  }

  void _scheduleSingleNotification(int id, String name, DateTime time, bool isEnabled) async {
    if (!isEnabled || time.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'adhan_channel_v2',
      'تنبيهات الأذان الاحترافية',
      channelDescription: 'قناة مخصصة لبث صوت الأذان في مواقيته الدقيقة',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('adhan'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      'حان وقت صلاة $name',
      'حي على الصلاة، حي على الفلاح',
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
