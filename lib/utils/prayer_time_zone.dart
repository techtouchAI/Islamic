class PrayerTimeZonePolicy {
  static const double iraqOffsetHours = 3.0;

  const PrayerTimeZonePolicy._();

  /// Fixed Iraqi civil time is used for the selected Iraqi city coordinates.
  static double forSelectedIraqiCity() => iraqOffsetHours;

  /// GPS uses the device's current timezone by policy. This avoids adding a
  /// timezone-database dependency while keeping display and alarms consistent.
  static double forGpsDevice(DateTime now) =>
      now.timeZoneOffset.inMinutes / 60.0;

  /// Creates a civil-time value with UTC kind so Dart does not apply the host
  /// machine timezone a second time. The fields represent the target local
  /// clock in [offsetHours].
  static DateTime localCivilTime(
    int year,
    int month,
    int day,
    int hour,
    int minute,
  ) {
    return DateTime.utc(year, month, day, hour, minute);
  }

  static DateTime localCivilToUtc(DateTime localCivil, double offsetHours) {
    return DateTime.utc(
      localCivil.year,
      localCivil.month,
      localCivil.day,
      localCivil.hour,
      localCivil.minute,
      localCivil.second,
    ).subtract(Duration(minutes: (offsetHours * 60).round()));
  }

  static DateTime utcToLocalCivil(DateTime utc, double offsetHours) {
    final value = utc.toUtc();
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    ).add(Duration(minutes: (offsetHours * 60).round()));
  }
}
