import 'package:aldhakereen/models/prayer_location.dart';
import 'package:aldhakereen/models/prayer_schedule.dart';

PrayerSchedule scheduleFor(DateTime date, {Map<String, int>? hours}) {
  const location = PrayerLocation(
    latitude: 32.48,
    longitude: 44.43,
    source: PrayerLocationSource.selectedCity,
    displayName: 'الحلة',
    timeZoneOffsetHours: 3,
  );
  final times = hours ??
      {
        'imsak': 4,
        'fajr': 5,
        'dhuhr': 12,
        'asr': 15,
        'maghrib': 18,
        'isha': 20
      };
  return PrayerSchedule(
    date: DateTime.utc(date.year, date.month, date.day),
    location: location,
    prayers: times.map((key, hour) {
      final civil = DateTime.utc(date.year, date.month, date.day, hour);
      return MapEntry(
          key,
          PrayerTimeValue(
            key: key,
            localCivilTime: civil,
            utcTime: civil.subtract(const Duration(hours: 3)),
          ));
    }),
  );
}
