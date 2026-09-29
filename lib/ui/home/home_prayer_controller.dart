import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/calendar_repository.dart';
import '../../models/prayer_schedule.dart';
import '../../services/prayer_times_service.dart';
import '../../utils/next_prayer.dart';

class UpcomingPrayer {
  const UpcomingPrayer(this.key, this.utcTime);
  final String key;
  final DateTime utcTime;
}

/// Select an actual occurrence, never yesterday's Fajr plus 24 hours. Both
/// schedules already include saved offsets and date-specific manual changes.
UpcomingPrayer? findUpcomingPrayer(
  Iterable<PrayerSchedule> schedules,
  DateTime nowUtc, {
  required int hijriAdjustment,
}) {
  final upcoming = <UpcomingPrayer>[];
  for (final schedule in schedules) {
    final ramadan = CalendarRepository.getTodayHijri(
          schedule.date,
          hijriAdjustment,
        ).month ==
        9;
    for (final key in prayerDisplayNamesAr.keys) {
      if (key == 'imsak' && !ramadan) continue;
      final value = schedule[key];
      if (value == null || !value.isAvailable) continue;
      if (value.utcTime!.isAfter(nowUtc)) {
        upcoming.add(UpcomingPrayer(key, value.utcTime!));
      }
    }
  }
  upcoming.sort((a, b) => a.utcTime.compareTo(b.utcTime));
  return upcoming.isEmpty ? null : upcoming.first;
}

/// Presentation state only: time calculation and persistence stay in the
/// existing prayer service. The one-second ticker rebuilds the card, not home.
class HomePrayerController extends ChangeNotifier {
  HomePrayerController({
    Future<PrayerSchedule?> Function()? loadToday,
    Future<PrayerSchedule> Function(PrayerSchedule)? loadTomorrow,
    DateTime Function()? clock,
  })  : _loadToday = loadToday ?? PrayerTimesService().loadTodaySchedule,
        _loadTomorrow = loadTomorrow ?? _defaultTomorrow,
        _clock = clock ?? DateTime.now;

  final Future<PrayerSchedule?> Function() _loadToday;
  final Future<PrayerSchedule> Function(PrayerSchedule) _loadTomorrow;
  final DateTime Function() _clock;
  PrayerSchedule? today;
  PrayerSchedule? tomorrow;
  bool loading = true;
  bool failed = false;
  bool _disposed = false;
  bool _refreshing = false;
  bool _refreshAgain = false;
  Timer? _timer;
  DateTime? _lastAttempt;

  DateTime get nowUtc => _clock().toUtc();
  DateTime get localNow => today == null
      ? _clock()
      : nowUtc.add(Duration(
          minutes: (today!.location.timeZoneOffsetHours * 60).round(),
        ));

  static Future<PrayerSchedule> _defaultTomorrow(PrayerSchedule today) =>
      PrayerTimesService().loadScheduleForDate(
        today.location,
        today.date.add(const Duration(days: 1)),
      );

  UpcomingPrayer? upcoming(int adjustment) => findUpcomingPrayer(
        [if (today != null) today!, if (tomorrow != null) tomorrow!],
        nowUtc,
        hijriAdjustment: adjustment,
      );

  Future<void> refresh() async {
    if (_disposed) return;
    _discardStaleSchedules();
    if (_refreshing) {
      _refreshAgain = true;
      notifyListeners();
      return;
    }
    _refreshing = true;
    _lastAttempt = nowUtc;
    loading = today == null;
    failed = false;
    notifyListeners();
    try {
      final result = await _loadToday();
      if (_disposed) return;
      if (result != null && !_sameDate(result.date, _civilNow(result))) {
        failed = true;
        return;
      }
      today = result;
      tomorrow = null;
      failed = result == null;
      if (result != null) {
        final next = await _loadTomorrow(result);
        if (_disposed) return;
        tomorrow = next;
        _discardStaleSchedules();
      }
    } catch (_) {
      // Keep any valid current-day times; a missing next day must never be
      // represented by a fabricated countdown.
      failed = true;
    } finally {
      _refreshing = false;
      if (!_disposed) {
        loading = false;
        notifyListeners();
        if (_refreshAgain) {
          _refreshAgain = false;
          unawaited(refresh());
        }
      }
    }
  }

  DateTime _civilNow(PrayerSchedule schedule) => nowUtc.add(Duration(
        minutes: (schedule.location.timeZoneOffsetHours * 60).round(),
      ));

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _discardStaleSchedules() {
    final current = today;
    if (current == null || _sameDate(current.date, _civilNow(current)))
      return false;
    final next = tomorrow;
    today =
        next != null && _sameDate(next.date, _civilNow(current)) ? next : null;
    tomorrow = null;
    return true;
  }

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final newDate = _discardStaleSchedules();
      final retryDue = failed &&
          (_lastAttempt == null ||
              nowUtc.difference(_lastAttempt!) >= const Duration(minutes: 1));
      if (newDate || retryDue) {
        unawaited(refresh());
      }
      if (!_disposed) notifyListeners();
    });
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    pause();
    super.dispose();
  }
}
