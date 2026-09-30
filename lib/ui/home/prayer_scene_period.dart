import '../../models/prayer_schedule.dart';

enum PrayerScenePeriod { day, night }

/// The artwork follows the selected location's civil day, not theme brightness
/// or the device timezone. Sunset (not the later Jafari Maghrib) ends daylight.
/// While solar events are unavailable, 06:00–18:00 is a visual-only fallback;
/// this policy never supplies prayer times or affects alarms.
PrayerScenePeriod prayerScenePeriod({
  required DateTime localNow,
  PrayerSchedule? schedule,
}) {
  final sunrise = schedule?['sunrise']?.localCivilTime;
  final sunset = schedule?['sunset']?.localCivilTime;
  bool sameDate(DateTime value) => value.year == localNow.year &&
      value.month == localNow.month && value.day == localNow.day;
  // Civil values are represented with UTC kind by PrayerTimesService. Compare
  // fields consistently even when a fallback caller supplies a local DateTime.
  DateTime civil(DateTime value) => DateTime.utc(value.year, value.month,
      value.day, value.hour, value.minute, value.second);
  if (sunrise != null && sunset != null &&
      sameDate(sunrise) && sameDate(sunset) && sunset.isAfter(sunrise)) {
    final now = civil(localNow);
    return !now.isBefore(civil(sunrise)) && now.isBefore(civil(sunset))
        ? PrayerScenePeriod.day : PrayerScenePeriod.night;
  }
  return localNow.hour >= 6 && localNow.hour < 18
      ? PrayerScenePeriod.day : PrayerScenePeriod.night;
}
