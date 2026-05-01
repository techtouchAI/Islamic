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
    test('schedules all three prayers when current time is before Fajr', () {
      // Create a specific date/time before Fajr
      // For coordinates 32.4682, 44.4361 on Jan 1: Fajr 02:38, Dhuhr 09:06, Maghrib 14:27 (UTC)
      final testTime = DateTime.utc(2023, 1, 1, 1, 0, 0); // 1:00 AM UTC

      PrayerNotificationService.scheduleDailyPrayers(now: testTime);

      // Should schedule Fajr, Dhuhr, and Maghrib
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
      ).called(1);

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
      ).called(1);

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
      ).called(1);
    });

    test(
      'schedules Dhuhr and Maghrib when current time is after Fajr but before Dhuhr',
      () {
        // 5:00 AM UTC (After Fajr 02:38, before Dhuhr 09:06)
        final testTime = DateTime.utc(2023, 1, 1, 5, 0, 0);

        PrayerNotificationService.scheduleDailyPrayers(now: testTime);

        // Should not schedule Fajr
        verifyNever(
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
        );

        // Should schedule Dhuhr and Maghrib
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
        ).called(1);

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
        ).called(1);
      },
    );

    test(
      'schedules only Maghrib when current time is after Dhuhr but before Maghrib',
      () {
        // 10:00 AM UTC (After Dhuhr 09:06, before Maghrib 14:27)
        final testTime = DateTime.utc(2023, 1, 1, 10, 0, 0);

        PrayerNotificationService.scheduleDailyPrayers(now: testTime);

        // Should not schedule Fajr or Dhuhr
        verifyNever(
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
        );

        verifyNever(
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
        );

        // Should schedule Maghrib
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
        ).called(1);
      },
    );

    test('schedules no prayers when current time is after Maghrib', () {
      // 15:00 UTC (3:00 PM, After Maghrib 14:27)
      final testTime = DateTime.utc(2023, 1, 1, 15, 0, 0);

      PrayerNotificationService.scheduleDailyPrayers(now: testTime);

      // Should not schedule any prayers
      verifyNever(
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
      );
    });
  });
}
