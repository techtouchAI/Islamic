import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:aldhakereen/services/prayer_notification_service.dart';

import 'prayer_notification_service_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    PrayerNotificationService.notificationsPlugin = mockPlugin;

    when(mockPlugin.cancelAll()).thenAnswer((_) async {});

    when(
      mockPlugin.zonedSchedule(
        any,
        any,
        any,
        any,
        any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        uiLocalNotificationDateInterpretation: anyNamed(
          'uiLocalNotificationDateInterpretation',
        ),
      ),
    ).thenAnswer((_) async {});
  });

  group('PrayerNotificationService.scheduleDailyPrayers', () {
    test('schedules all three prayers when current time is before Fajr', () async {
      // Create a specific date/time before Fajr
      // For coordinates 32.4682, 44.4361 on Jan 1: Fajr 02:38, Dhuhr 09:06, Maghrib 14:27 (UTC)
      final testTime = DateTime.utc(2023, 1, 1, 1, 0, 0); // 1:00 AM UTC

      await PrayerNotificationService.scheduleDailyPrayers(now: testTime);

      // Should clear existing alarms first
      verify(mockPlugin.cancelAll()).called(1);

      // Should schedule Fajr, Dhuhr, and Maghrib for 7 days
      verify(
        mockPlugin.zonedSchedule(
          any,
          argThat(contains('الفجر')),
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation: anyNamed(
            'uiLocalNotificationDateInterpretation',
          ),
        ),
      ).called(7);

      verify(
        mockPlugin.zonedSchedule(
          any,
          argThat(contains('الظهر')),
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation: anyNamed(
            'uiLocalNotificationDateInterpretation',
          ),
        ),
      ).called(7);

      verify(
        mockPlugin.zonedSchedule(
          any,
          argThat(contains('المغرب')),
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation: anyNamed(
            'uiLocalNotificationDateInterpretation',
          ),
        ),
      ).called(7);
    });

    test(
      'schedules Dhuhr and Maghrib when current time is after Fajr but before Dhuhr',
      () async {
        // 5:00 AM UTC (After Fajr 02:38, before Dhuhr 09:06)
        final testTime = DateTime.utc(2023, 1, 1, 5, 0, 0);

        await PrayerNotificationService.scheduleDailyPrayers(now: testTime);

        // Should schedule Fajr only for the next 6 days
        verify(
          mockPlugin.zonedSchedule(
            any,
            argThat(contains('الفجر')),
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            uiLocalNotificationDateInterpretation: anyNamed(
              'uiLocalNotificationDateInterpretation',
            ),
          ),
        ).called(6);

        // Should schedule Dhuhr and Maghrib for 7 days
        verify(
          mockPlugin.zonedSchedule(
            any,
            argThat(contains('الظهر')),
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            uiLocalNotificationDateInterpretation: anyNamed(
              'uiLocalNotificationDateInterpretation',
            ),
          ),
        ).called(7);

        verify(
          mockPlugin.zonedSchedule(
            any,
            argThat(contains('المغرب')),
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            uiLocalNotificationDateInterpretation: anyNamed(
              'uiLocalNotificationDateInterpretation',
            ),
          ),
        ).called(7);
      },
    );

    test(
      'schedules only Maghrib when current time is after Dhuhr but before Maghrib',
      () async {
        // 10:00 AM UTC (After Dhuhr 09:06, before Maghrib 14:27)
        final testTime = DateTime.utc(2023, 1, 1, 10, 0, 0);

        await PrayerNotificationService.scheduleDailyPrayers(now: testTime);

        // Should schedule Fajr and Dhuhr only for the next 6 days
        verify(
          mockPlugin.zonedSchedule(
            any,
            argThat(contains('الفجر')),
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            uiLocalNotificationDateInterpretation: anyNamed(
              'uiLocalNotificationDateInterpretation',
            ),
          ),
        ).called(6);

        verify(
          mockPlugin.zonedSchedule(
            any,
            argThat(contains('الظهر')),
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            uiLocalNotificationDateInterpretation: anyNamed(
              'uiLocalNotificationDateInterpretation',
            ),
          ),
        ).called(6);

        // Should schedule Maghrib for 7 days
        verify(
          mockPlugin.zonedSchedule(
            any,
            argThat(contains('المغرب')),
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            uiLocalNotificationDateInterpretation: anyNamed(
              'uiLocalNotificationDateInterpretation',
            ),
          ),
        ).called(7);
      },
    );

    test('schedules next 6 days when current time is after Maghrib', () async {
      // 15:00 UTC (3:00 PM, After Maghrib 14:27)
      final testTime = DateTime.utc(2023, 1, 1, 15, 0, 0);

      await PrayerNotificationService.scheduleDailyPrayers(now: testTime);

      // Should schedule all three prayers for 6 days (excluding today)
      verify(
        mockPlugin.zonedSchedule(
          any,
          argThat(contains('الفجر')),
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation: anyNamed(
            'uiLocalNotificationDateInterpretation',
          ),
        ),
      ).called(6);

      verify(
        mockPlugin.zonedSchedule(
          any,
          argThat(contains('الظهر')),
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation: anyNamed(
            'uiLocalNotificationDateInterpretation',
          ),
        ),
      ).called(6);

      verify(
        mockPlugin.zonedSchedule(
          any,
          argThat(contains('المغرب')),
          any,
          any,
          any,
          androidScheduleMode: anyNamed('androidScheduleMode'),
          uiLocalNotificationDateInterpretation: anyNamed(
            'uiLocalNotificationDateInterpretation',
          ),
        ),
      ).called(6);
    });
  });
}
