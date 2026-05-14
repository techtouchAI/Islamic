import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class PrayerAlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await AndroidAlarmManager.initialize();

    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  static Future<void> schedulePrayer(int id, DateTime prayerTime, String prayerName) async {
    await AndroidAlarmManager.oneShotAt(
      prayerTime,
      id,
      _fireAlarm,
      exact: true,
      wakeup: true,
      alarmClock: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _fireAlarm(int id) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'adhan_channel_id',
      'Prayer Notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: false,
    );

    await _notificationsPlugin.show(id, 'حان موعد الصلاة', 'الصلاة خير من النوم', const NotificationDetails(android: androidDetails));

    final player = AudioPlayer();
    await player.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        usageType: AndroidUsageType.alarm,
        contentType: AndroidContentType.music,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));
    await player.play(AssetSource('audio/azan5.mp3'));
  }
}
