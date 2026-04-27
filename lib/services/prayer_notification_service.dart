import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. تهيئة الإشعارات
  static Future<void> initNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // 2. حساب أوقات الصلاة (المذهب الجعفري - جامعة طهران)
  static void scheduleDailyPrayers() {
    // إحداثيات الموقع (الحلة)
    final coordinates = Coordinates(32.4682, 44.4361);

    // ضبط المعايير
    final params = CalculationMethod.tehran.getParameters();
    params.madhab = Madhab.shafi;

    final date = DateComponents.from(DateTime.now());
    final prayerTimes = PrayerTimes(coordinates, date, params);

    // جدولة الصلوات
    if (prayerTimes.fajr.isAfter(DateTime.now())) {
      _schedulePrayerNotification(prayerTimes.fajr, 'الفجر');
    }
    if (prayerTimes.dhuhr.isAfter(DateTime.now())) {
      _schedulePrayerNotification(prayerTimes.dhuhr, 'الظهر');
    }
    if (prayerTimes.maghrib.isAfter(DateTime.now())) {
      _schedulePrayerNotification(prayerTimes.maghrib, 'المغرب');
    }
  }

  // 3. جدولة الإشعار الصوتي الاحترافي
  static Future<void> _schedulePrayerNotification(DateTime prayerTime, String prayerName) async {
    const String channelId = 'adhan_channel_v2';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      'أوقات الصلاة',
      channelDescription: 'تنبيهات الأذان لأوقات الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_sound'),
      enableVibration: true,
      fullScreenIntent: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.zonedSchedule(
      prayerName.hashCode,
      'حان الآن موعد أذان $prayerName',
      'تقبل الله أعمالكم',
      tz.TZDateTime.from(prayerTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
