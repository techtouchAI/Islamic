import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationService {
  static FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @visibleForTesting
  static set notificationsPlugin(FlutterLocalNotificationsPlugin plugin) {
    _notificationsPlugin = plugin;
  }

  // 1. تهيئة الإشعارات
  static Future<void> initNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request Android 13+ permissions
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  // 2. حساب أوقات الصلاة (المذهب الجعفري - جامعة طهران)
  static void scheduleDailyPrayers({DateTime? now}) {
    final DateTime currentTime = now ?? DateTime.now();

    // إحداثيات الموقع (الحلة)
    final coordinates = Coordinates(32.4682, 44.4361);

    // ضبط المعايير
    final params = CalculationMethod.tehran.getParameters();
    params.madhab = Madhab.shafi;

    final date = DateComponents.from(currentTime);
    final prayerTimes = PrayerTimes(coordinates, date, params);

    // جدولة الصلوات
    if (prayerTimes.fajr.isAfter(currentTime)) {
      _schedulePrayerNotification(prayerTimes.fajr, 'الفجر');
    }
    if (prayerTimes.dhuhr.isAfter(currentTime)) {
      _schedulePrayerNotification(prayerTimes.dhuhr, 'الظهر');
    }
    if (prayerTimes.maghrib.isAfter(currentTime)) {
      _schedulePrayerNotification(prayerTimes.maghrib, 'المغرب');
    }
  }

  // 3. جدولة الإشعار الصوتي الاحترافي
  static Future<void> _schedulePrayerNotification(
    DateTime prayerTime,
    String prayerName,
  ) async {
    const String channelId = 'adhan_channel_v2';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      'أوقات الصلاة',
      channelDescription: 'تنبيهات الأذان لأوقات الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan'),
      enableVibration: true,
      fullScreenIntent: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        prayerName.hashCode,
        'حان الآن موعد أذان $prayerName',
        'تقبل الله أعمالكم',
        tz.TZDateTime.from(prayerTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }
}
