import 'dart:async';

import 'package:aldhakereen/models/prayer_schedule.dart';
import 'package:aldhakereen/ui/home/home_prayer_controller.dart';
import 'package:aldhakereen/services/prayer_times_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/prayer_schedules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final date = DateTime.utc(2026, 9, 30);
  final today = scheduleFor(date);
  final tomorrow = scheduleFor(DateTime.utc(2026, 10, 1), hours: {'fajr': 6});

  test('selects actual UTC occurrence and skips exact elapsed boundary', () {
    expect(
        findUpcomingPrayer([today], DateTime.utc(2026, 9, 30, 8),
                hijriAdjustment: 0)
            ?.key,
        'dhuhr');
    expect(
        findUpcomingPrayer([today], DateTime.utc(2026, 9, 30, 9),
                hijriAdjustment: 0)
            ?.key,
        'asr');
  });

  test('after Isha uses tomorrow timetable, not today plus 24 hours', () {
    final next = findUpcomingPrayer(
        [today, tomorrow], DateTime.utc(2026, 9, 30, 18),
        hijriAdjustment: 0);
    expect(next?.key, 'fajr');
    expect(next?.utcTime, DateTime.utc(2026, 10, 1, 3));
    expect(findUpcomingPrayer([], date, hijriAdjustment: 0), isNull);
  });

  test('Ramadan imsak is available but outside Ramadan it is skipped', () {
    final ramadan = scheduleFor(DateTime.utc(2026, 3, 5));
    expect(
        findUpcomingPrayer([ramadan], DateTime.utc(2026, 3, 5),
                hijriAdjustment: 0)
            ?.key,
        'imsak');
    expect(findUpcomingPrayer([today], date, hijriAdjustment: 0)?.key, 'fajr');
  });

  test('explicit-date service keeps saved offsets and manual timetable',
      () async {
    SharedPreferences.setMockInitialValues({'adj_fajr': 7});
    final service = PrayerTimesService();
    await service.saveManualScheduleForDate(tomorrow.date, {'fajr': '06:20'});
    final result =
        await service.loadScheduleForDate(today.location, tomorrow.date);
    expect(result['fajr']?.localCivilTime, DateTime.utc(2026, 10, 1, 6, 27));
    expect(result['fajr']?.utcTime, DateTime.utc(2026, 10, 1, 3, 27));
  });

  test('failure is recoverable and missing tomorrow never fabricates a time',
      () async {
    var fail = true;
    final controller = HomePrayerController(
      loadToday: () async => today,
      loadTomorrow: (_) async {
        if (fail) throw StateError('offline');
        return tomorrow;
      },
      clock: () => DateTime.utc(2026, 9, 30, 18),
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.failed, isTrue);
    expect(controller.today, today);
    expect(controller.upcoming(0), isNull);
    fail = false;
    await controller.refresh();
    expect(controller.failed, isFalse);
    expect(controller.upcoming(0)?.key, 'fajr');
  });

  test('completion after disposal never notifies or starts tomorrow load',
      () async {
    final completer = Completer<PrayerSchedule?>();
    var nextLoads = 0;
    final controller = HomePrayerController(
      loadToday: () => completer.future,
      loadTomorrow: (_) async {
        nextLoads++;
        return tomorrow;
      },
      clock: () => date,
    );
    final pending = controller.refresh();
    controller.dispose();
    completer.complete(today);
    await pending;
    expect(nextLoads, 0);
  });

  testWidgets('midnight refresh bypasses recent attempt; pause disposes ticker',
      (tester) async {
    var now = DateTime.utc(2026, 9, 30, 20, 59, 40);
    var loads = 0;
    final controller = HomePrayerController(
      loadToday: () async {
        loads++;
        return scheduleFor(now.add(const Duration(hours: 3)));
      },
      loadTomorrow: (s) async =>
          scheduleFor(s.date.add(const Duration(days: 1))),
      clock: () => now,
    );
    controller.start();
    await controller.refresh();
    now = now.add(const Duration(seconds: 21));
    await tester.pump(const Duration(seconds: 1));
    expect(loads, 2);
    expect(controller.today?.date, DateTime.utc(2026, 10, 1));
    controller.pause();
    await tester.pump(const Duration(days: 1));
    expect(loads, 2);
    controller.dispose();
  });

  test('resume after several days drops stale times even when reload fails',
      () async {
    var now = date;
    var fail = false;
    final controller = HomePrayerController(
      loadToday: () async {
        if (fail) throw StateError('offline');
        return today;
      },
      loadTomorrow: (_) async => tomorrow,
      clock: () => now,
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    now = now.add(const Duration(days: 3));
    fail = true;
    await controller.refresh();
    expect(controller.today, isNull);
    expect(controller.tomorrow, isNull);
    expect(controller.failed, isTrue);
  });
}
