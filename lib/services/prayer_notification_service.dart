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
    try {
      // We will fallback to UTC but convert local time properly if timezone library fails
      // Using UTC +3 for Iraq explicitly as fallback without adding native plugins that break gradle
      tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
    } catch (e) {
      debugPrint('Error setting timezone: $e');
    }

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

  static Future<void> testImmediateAzan() async {
    try {
      debugPrint('--- FIRING NUCLEAR TEST IN 10 SECONDS ---');
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledDate = now.add(const Duration(seconds: 10));

      await _notificationsPlugin.zonedSchedule(
        9999, // Unique test ID
        'اختبار نووي',
        'إذا ظهر هذا، فالنظام يعمل',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'adhan_channel_v3',
            'أوقات الصلاة',
            channelDescription: 'تنبيهات الأذان لأوقات الصلاة',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('adhan'),
            fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Nuclear test scheduled successfully.');
    } catch (e) {
      debugPrint('NUCLEAR TEST FAILED TO SCHEDULE: $e');
    }
  }

  // 2. حساب أوقات الصلاة (المذهب الجعفري - جامعة طهران) لعدة أيام
  static Future<void> scheduleDailyPrayers({DateTime? now}) async {
    await _notificationsPlugin.cancelAll();

    final DateTime baseTime = now ?? DateTime.now();
    final coordinates = Coordinates(32.4682, 44.4361);
    final params = CalculationMethod.tehran.getParameters();
    params.madhab = Madhab.shafi;

    // جدولة لـ 7 أيام قادمة لضمان بقاء الطابور ممتلئاً
    for (int i = 0; i < 7; i++) {
      final DateTime currentTime = baseTime.add(Duration(days: i));
      final date = DateComponents.from(currentTime);
      final prayerTimes = PrayerTimes(coordinates, date, params);

      if (prayerTimes.fajr.isAfter(baseTime)) {
        final id = 'الفجر'.hashCode +
            prayerTimes.fajr.year +
            prayerTimes.fajr.month +
            prayerTimes.fajr.day;
        _schedulePrayerNotification(prayerTimes.fajr, 'الفجر', id);
      }
      if (prayerTimes.dhuhr.isAfter(baseTime)) {
        final id = 'الظهر'.hashCode +
            prayerTimes.dhuhr.year +
            prayerTimes.dhuhr.month +
            prayerTimes.dhuhr.day;
        _schedulePrayerNotification(prayerTimes.dhuhr, 'الظهر', id);
      }
      if (prayerTimes.maghrib.isAfter(baseTime)) {
        final id = 'المغرب'.hashCode +
            prayerTimes.maghrib.year +
            prayerTimes.maghrib.month +
            prayerTimes.maghrib.day;
        _schedulePrayerNotification(prayerTimes.maghrib, 'المغرب', id);
      }
    }
  }

  // 3. جدولة الإشعار الصوتي الاحترافي
  static Future<void> _schedulePrayerNotification(
    DateTime prayerTime,
    String prayerName,
    int notificationId,
  ) async {
    const String channelId = 'adhan_channel_v3';

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

    final String notificationBody = (prayerName == 'الفجر')
        ? 'الصلاة خير من النوم'
        : 'حي على الصلاة، حي على الفلاح';

    try {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'حان الآن موعد أذان $prayerName',
        notificationBody,
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
