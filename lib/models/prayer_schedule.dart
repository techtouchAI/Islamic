import 'prayer_location.dart';

class PrayerTimeValue {
  final String key;
  final DateTime? utcTime;
  final DateTime? localCivilTime;

  const PrayerTimeValue({
    required this.key,
    required this.utcTime,
    required this.localCivilTime,
  });

  bool get isAvailable => utcTime != null && localCivilTime != null;
}

/// The final, validated result used by both the UI and alarm scheduling.
class PrayerSchedule {
  final DateTime date;
  final PrayerLocation location;
  final Map<String, PrayerTimeValue> prayers;

  const PrayerSchedule({
    required this.date,
    required this.location,
    required this.prayers,
  });

  PrayerTimeValue? operator [](String key) => prayers[key];

  Map<String, DateTime> get availableUtcTimes {
    final result = <String, DateTime>{};
    for (final entry in prayers.entries) {
      final time = entry.value.utcTime;
      if (time != null) result[entry.key] = time;
    }
    return result;
  }

  Map<String, DateTime> get availableLocalCivilTimes {
    final result = <String, DateTime>{};
    for (final entry in prayers.entries) {
      final time = entry.value.localCivilTime;
      if (time != null) result[entry.key] = time;
    }
    return result;
  }

  DateTime nowAsLocalCivil() {
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.add(
      Duration(minutes: (location.timeZoneOffsetHours * 60).round()),
    );
  }
}
