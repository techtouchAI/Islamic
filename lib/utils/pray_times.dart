import 'dart:math' as math;

/// Implementation of PrayTimes astronomical algorithms.
/// Based on PrayTimes.org JS library (v2.5) by Hamid Zarrabi-Zadeh.
/// Adapted for clean architecture in Dart with Jafari parameters.
class PrayTimes {
  // Constants for calculation
  final double _numIterations = 1;

  // Calculation parameters for Shia Jafari
  final double _fajrAngle = 18.0;
  final double _maghribAngle = 4.0;
  final double _ishaAngle = 14.0;
  final double _refraction = 0.833;

  // Coordinate and timezone info
  late double _lat;
  late double _lng;
  late double _elv;
  late double _timeZone;
  late double _jDate;

  PrayTimes();

  /// Calculate prayer times for a given date, coordinates, and timezone.
  /// returns a Map of string to DateTime
  Map<String, DateTime> getTimes(
      DateTime date, double lat, double lng, double timeZone, {double elevation = 0}) {
    _lat = lat;
    _lng = lng;
    _elv = elevation;
    _timeZone = timeZone;

    int year = date.year;
    int month = date.month;
    int day = date.day;

    _jDate = _julian(year, month, day) - lng / 360;

    Map<String, double> times = _computeTimes();

    // Convert double times to DateTimes
    Map<String, DateTime> dateTimes = {};
    times.forEach((key, value) {
      dateTimes[key] = _timeToDateTime(date, value);
    });

    return dateTimes;
  }

  //---------------------- Calculation Functions -----------------------

  // compute mid-day time
  double _midDay(double time) {
    double eqt = _sunPosition(_jDate + time).equation;
    return _DMath.fixHour(12 - eqt);
  }

  // compute the time at which sun reaches a specific angle below horizon
  double _sunAngleTime(double angle, double time, String direction) {
    double decl = _sunPosition(_jDate + time).declination;
    double noon = _midDay(time);

    double t = 1 / 15 * _DMath.arccos(
        (-_DMath.sin(angle) - _DMath.sin(decl) * _DMath.sin(_lat)) /
        (_DMath.cos(decl) * _DMath.cos(_lat)));

    return noon + (direction == 'ccw' ? -t : t);
  }

  // compute asr time
  double _asrTime(double factor, double time) {
    double decl = _sunPosition(_jDate + time).declination;
    double angle = -_DMath.arccot(factor + _DMath.tan((_lat - decl).abs()));
    return _sunAngleTime(angle, time, 'cw');
  }

  // compute declination angle of sun and equation of time
  // Ref: http://aa.usno.navy.mil/faq/docs/SunApprox.php
  _SunPosition _sunPosition(double jd) {
    double D = jd - 2451545.0;
    double g = _DMath.fixAngle(357.529 + 0.98560028 * D);
    double q = _DMath.fixAngle(280.459 + 0.98564736 * D);
    double L = _DMath.fixAngle(q + 1.915 * _DMath.sin(g) + 0.020 * _DMath.sin(2 * g));

    // double R = 1.00014 - 0.01671 * _DMath.cos(g) - 0.00014 * _DMath.cos(2 * g);
    double e = 23.439 - 0.00000036 * D;

    double RA = _DMath.arctan2(_DMath.cos(e) * _DMath.sin(L), _DMath.cos(L)) / 15;
    double eqt = q / 15 - _DMath.fixHour(RA);
    double decl = _DMath.arcsin(_DMath.sin(e) * _DMath.sin(L));

    return _SunPosition(declination: decl, equation: eqt);
  }

  // convert Gregorian date to Julian day
  // Ref: Astronomical Algorithms by Jean Meeus
  double _julian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    int A = (year / 100).floor();
    int B = 2 - A + (A / 4).floor();

    double JD = (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() + day + B - 1524.5;
    return JD;
  }

  //---------------------- Compute Prayer Times -----------------------

  // compute prayer times at given julian date
  Map<String, double> _computePrayerTimes(Map<String, double> times) {
    times = _dayPortion(times);

    double fajr = _sunAngleTime(_fajrAngle, times['fajr']!, 'ccw');
    double sunrise = _sunAngleTime(_riseSetAngle(), times['sunrise']!, 'ccw');
    double dhuhr = _midDay(times['dhuhr']!);
    double asr = _asrTime(1, times['asr']!); // Standard factor = 1
    double sunset = _sunAngleTime(_riseSetAngle(), times['sunset']!, 'cw');
    double maghrib = _sunAngleTime(_maghribAngle, times['maghrib']!, 'cw');
    double isha = _sunAngleTime(_ishaAngle, times['isha']!, 'cw');

    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'sunset': sunset,
      'maghrib': maghrib,
      'isha': isha
    };
  }

  // compute prayer times
  Map<String, double> _computeTimes() {
    // default times
    Map<String, double> times = {
      'fajr': 5,
      'sunrise': 6,
      'dhuhr': 12,
      'asr': 13,
      'sunset': 18,
      'maghrib': 18,
      'isha': 18
    };

    // main iterations
    for (int i = 1; i <= _numIterations; i++) {
      times = _computePrayerTimes(times);
    }

    times = _adjustTimes(times);

    // add midnight time (Jafari method)
    // In Jafari method, Midnight is between Sunset and Fajr of next day
    // We calculate next day's fajr

    // Create a temporary clone for tomorrow's jDate
    double originalJDate = _jDate;
    _jDate += 1.0;

    Map<String, double> tomorrowTimes = {
      'fajr': 5,
      'sunrise': 6,
      'dhuhr': 12,
      'asr': 13,
      'sunset': 18,
      'maghrib': 18,
      'isha': 18
    };
    for (int i = 1; i <= _numIterations; i++) {
      tomorrowTimes = _computePrayerTimes(tomorrowTimes);
    }
    tomorrowTimes = _adjustTimes(tomorrowTimes);
    double tomorrowFajr = tomorrowTimes['fajr']!;

    // Restore jDate
    _jDate = originalJDate;

    times['midnight'] = times['sunset']! + _timeDiff(times['sunset']!, tomorrowFajr + 24) / 2;

    return times;
  }

  // adjust times
  Map<String, double> _adjustTimes(Map<String, double> times) {
    Map<String, double> newTimes = {};
    times.forEach((key, value) {
      newTimes[key] = value + _timeZone - _lng / 15;
    });

    return newTimes;
  }

  // return sun angle for sunset/sunrise
  double _riseSetAngle() {
    double angle = 0.0347 * math.sqrt(_elv); // an approximation
    return _refraction + angle;
  }

  // convert hours to day portions
  Map<String, double> _dayPortion(Map<String, double> times) {
    Map<String, double> newTimes = {};
    times.forEach((key, value) {
      newTimes[key] = value / 24;
    });
    return newTimes;
  }

  //---------------------- Misc Functions -----------------------

  // compute the difference between two times
  double _timeDiff(double time1, double time2) {
    return _DMath.fixHour(time2 - time1);
  }

  // Convert double hours to DateTime
  DateTime _timeToDateTime(DateTime date, double time) {
    if (time.isNaN) {
      return date; // or handle invalid time
    }

    // The time could be > 24 if it's the next day (e.g. midnight or tomorrow fajr calculation)
    double timeInHours = _DMath.fixHour(time + 0.5 / 60); // add 0.5 minutes to round

    int hours = timeInHours.floor();
    int minutes = ((timeInHours - hours) * 60).floor();

    // Add days if time crossed past midnight
    int daysToAdd = ((time + 0.5 / 60) / 24).floor();

    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).add(Duration(days: daysToAdd, hours: hours, minutes: minutes)).subtract(Duration(minutes: (_timeZone * 60).round())); // convert back to UTC
  }
}

class _SunPosition {
  final double declination;
  final double equation;

  _SunPosition({required this.declination, required this.equation});
}

//---------------------- Degree-Based Math Class -----------------------
class _DMath {
  static double dtr(double d) => (d * math.pi) / 180.0;
  static double rtd(double r) => (r * 180.0) / math.pi;

  static double sin(double d) => math.sin(dtr(d));
  static double cos(double d) => math.cos(dtr(d));
  static double tan(double d) => math.tan(dtr(d));

  static double arcsin(double d) => rtd(math.asin(d));
  static double arccos(double d) => rtd(math.acos(d));
  static double arctan(double d) => rtd(math.atan(d));

  static double arccot(double x) => rtd(math.atan(1 / x));
  static double arctan2(double y, double x) => rtd(math.atan2(y, x));

  static double fixAngle(double a) => fix(a, 360);
  static double fixHour(double a) => fix(a, 24);

  static double fix(double a, double b) {
    if (a.isNaN) return a;
    double aFix = a - b * (a / b).floor();
    return (aFix < 0) ? aFix + b : aFix;
  }
}
