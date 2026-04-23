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
      method: CalculationMethod.other,
      fajrAngle: 16.0,
      ishaAngle: 14.0,
      maghribAngle: 4.0, // زوال الحمرة المشرقية
    );
    params.madhab = Madhab.shafi; // الحساب الجعفري يتبع قواعد مشابهة للشافعي في طول الظل
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
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("خطأ في جلب الموقع: $e");
      return null;
    }
  }

  /// حساب أوقات الصلاة ليوم معين وموقع معين
  PrayerTimes calculatePrayerTimes(Position position, {DateTime? date}) {
    final coordinates = Coordinates(position.latitude, position.longitude);
    final calculationDate = date ?? DateTime.now();

    return PrayerTimes(
      coordinates: coordinates,
      date: calculationDate,
      calculationParameters: shiaJafariParams,
      precision: true,
    );
  }

  /// جدولة التنبيهات لمدة 7 أيام قادمة
  Future<void> scheduleAdhanNotifications(Position position, Map<String, bool> enabledPrayers) async {
    // التحقق من صلاحية الإشعارات (أندرويد 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final prayerTimes = calculatePrayerTimes(position, date: date);

      _scheduleSingleNotification(100 + i, "الفجر", prayerTimes.fajr, enabledPrayers['fajr'] ?? true);
      _scheduleSingleNotification(200 + i, "الظهر", prayerTimes.dhuhr, enabledPrayers['dhuhr'] ?? true);
      _scheduleSingleNotification(300 + i, "العصر", prayerTimes.asr, enabledPrayers['asr'] ?? true);
      _scheduleSingleNotification(400 + i, "المغرب", prayerTimes.maghrib, enabledPrayers['maghrib'] ?? true);
      _scheduleSingleNotification(500 + i, "العشاء", prayerTimes.isha, enabledPrayers['isha'] ?? true);
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
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: 'حان وقت صلاة $name',
      body: 'حي على الصلاة، حي على الفلاح',
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
