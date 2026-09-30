import 'package:flutter/foundation.dart';

import '../data_manager.dart';

import 'package:hijri/hijri_calendar.dart';

class CalendarEvent {
  final String title;
  final String? description;
  final bool isImportant;

  CalendarEvent({
    required this.title,
    this.description,
    this.isImportant = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CalendarEvent(title: 'غير معروف');
    }
    return CalendarEvent(
      title: json['title']?.toString() ?? 'بدون عنوان',
      description: json['description']?.toString().isNotEmpty == true
          ? json['description'].toString()
          : null,
      isImportant: json['isImportant'] == true,
    );
  }
}

class AstronomicalEvent {
  final String title;
  final String? description;

  AstronomicalEvent({required this.title, this.description});

  factory AstronomicalEvent.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AstronomicalEvent(title: 'غير معروف');
    }
    return AstronomicalEvent(
      title: json['title']?.toString() ?? 'بدون عنوان',
      description: json['description']?.toString().isNotEmpty == true
          ? json['description'].toString()
          : null,
    );
  }
}

class HijriDayData {
  final int day;
  final List<CalendarEvent> events;
  final List<AstronomicalEvent> astronomicalEvents;

  HijriDayData({
    required this.day,
    required this.events,
    required this.astronomicalEvents,
  });

  factory HijriDayData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return HijriDayData(day: 1, events: [], astronomicalEvents: []);
    }

    List<CalendarEvent> parsedEvents = [];
    if (json['events'] is List) {
      for (var e in json['events']) {
        try {
          if (e is Map<String, dynamic>) {
            parsedEvents.add(CalendarEvent.fromJson(e));
          }
        } catch (err) {
          debugPrint('Error parsing event: $err');
        }
      }
    }

    List<AstronomicalEvent> parsedAstroEvents = [];
    if (json['astronomical_events'] is List) {
      for (var e in json['astronomical_events']) {
        try {
          if (e is Map<String, dynamic>) {
            parsedAstroEvents.add(AstronomicalEvent.fromJson(e));
          }
        } catch (err) {
          debugPrint('Error parsing astronomical event: $err');
        }
      }
    }

    return HijriDayData(
      day: json['day'] is int
          ? json['day']
          : int.tryParse(json['day']?.toString() ?? '1') ?? 1,
      events: parsedEvents,
      astronomicalEvents: parsedAstroEvents,
    );
  }
}

class HijriMonthData {
  final int year;
  final int month;
  final int totalDays;
  final String expectedGregorianStart;
  final List<HijriDayData> days;

  HijriMonthData({
    required this.year,
    required this.month,
    required this.totalDays,
    required this.expectedGregorianStart,
    required this.days,
  });

  factory HijriMonthData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return HijriMonthData(
        year: 1446,
        month: 1,
        totalDays: 30,
        expectedGregorianStart:
            DateTime.now().toIso8601String().split('T').first,
        days: [],
      );
    }

    List<HijriDayData> parsedDays = [];
    if (json['days'] is List) {
      for (var dayObj in json['days']) {
        try {
          if (dayObj is Map<String, dynamic>) {
            parsedDays.add(HijriDayData.fromJson(dayObj));
          }
        } catch (e) {
          debugPrint('Error parsing day: $e');
        }
      }
    }

    return HijriMonthData(
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year']?.toString() ?? '1446') ?? 1446,
      month: json['month'] is int
          ? json['month']
          : int.tryParse(json['month']?.toString() ?? '1') ?? 1,
      totalDays: json['total_days'] is int
          ? json['total_days']
          : int.tryParse(json['total_days']?.toString() ?? '30') ?? 30,
      expectedGregorianStart: json['expected_gregorian_start']?.toString() ??
          DateTime.now().toIso8601String().split('T').first,
      days: parsedDays,
    );
  }
}

/// One month row of the bundled Hijri table: the civil date of Hijri day 1 and
/// the number of days the reference authority declared for that month.
///
/// The table is the calendar of record (see `scripts/verify_hijri_calendar.py`)
/// because the announced month starts differ from the calculated Umm al-Qura
/// calendar by a day.
class HijriMonthSummary {
  const HijriMonthSummary({
    required this.year,
    required this.month,
    required this.totalDays,
    required this.start,
  });

  final int year;
  final int month;
  final int totalDays;

  /// Civil date of Hijri day 1 of this month, time of day removed.
  final DateTime start;

  /// Civil date of the last day of this month.
  DateTime get end => start.add(Duration(days: totalDays - 1));

  bool contains(DateTime civilDate) =>
      !civilDate.isBefore(start) && !civilDate.isAfter(end);
}

class AppHijriDate {
  final int day;
  final int month;
  final int year;
  final String monthName;

  AppHijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
  });

  @override
  String toString() {
    return '$day $monthName $year هـ';
  }
}

class CalendarRepository {
  static String getHijriMonthName(int month) {
    if (month < 1 || month > 12) return '';
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
    return months[month - 1];
  }

  /// Calendar day of [value] with the time of day removed.
  ///
  /// Day arithmetic uses UTC fields so a daylight-saving change on the device
  /// can never truncate a difference and shift a Hijri date by one day.
  static DateTime civilDate(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  /// Header fields of every row in the bundled table.
  ///
  /// Day records (with their event lists) are deliberately not parsed here:
  /// locating a month must stay cheap even when the calendar document is large.
  static List<HijriMonthSummary> monthSummaries() {
    final months = DataManager.getDB()?['hijri_calendar'];
    if (months is! List) return const <HijriMonthSummary>[];

    final summaries = <HijriMonthSummary>[];
    for (final entry in months) {
      if (entry is! Map) continue;
      final year = _asInt(entry['year']);
      final month = _asInt(entry['month']);
      final totalDays = _asInt(entry['total_days']);
      final start = DateTime.tryParse(
        entry['expected_gregorian_start']?.toString() ?? '',
      );
      if (year == null || month == null || start == null) continue;
      if (month < 1 || month > 12) continue;
      if (totalDays == null || totalDays < 29 || totalDays > 30) continue;
      summaries.add(
        HijriMonthSummary(
          year: year,
          month: month,
          totalDays: totalDays,
          start: civilDate(start),
        ),
      );
    }
    return summaries;
  }

  /// The table row containing [date], or null when the bundled table does not
  /// cover that day (another Hijri year, or a document without a calendar).
  static HijriMonthSummary? monthSummaryForDate(DateTime date) {
    final day = civilDate(date);
    for (final summary in monthSummaries()) {
      if (summary.contains(day)) return summary;
    }
    return null;
  }

  /// Civil date on which day 1 of [monthData] is displayed.
  ///
  /// A positive correction reads the table [offset] days ahead, so the same
  /// Hijri day is shown [offset] days *earlier* on the Gregorian grid. The grid
  /// and [getTodayHijri] therefore always agree.
  static DateTime adjustedMonthStart(HijriMonthData monthData, int offset) {
    final parsed = DateTime.tryParse(monthData.expectedGregorianStart);
    final start = parsed ??
        getGregorianStartFallback(monthData.year, monthData.month);
    return civilDate(start).subtract(Duration(days: offset));
  }

  /// Hijri date of the civil date [targetDate], after the user's [offset].
  ///
  /// The bundled table decides: the month that really contains the date wins,
  /// so the last day of a month is never reported as day one of the next month
  /// even when the calculated calendar is a day ahead on that boundary. Dates
  /// outside the table fall back to the Umm al-Qura calculation bundled with
  /// the `hijri` package, which remains the best available approximation.
  static AppHijriDate getTodayHijri(DateTime targetDate, int offset) {
    final civil = civilDate(targetDate).add(Duration(days: offset));

    final summary = monthSummaryForDate(civil);
    if (summary != null) {
      return AppHijriDate(
        day: civil.difference(summary.start).inDays + 1,
        month: summary.month,
        year: summary.year,
        monthName: getHijriMonthName(summary.month),
      );
    }

    final fallback = HijriCalendar.fromDate(
      DateTime(civil.year, civil.month, civil.day),
    );
    return AppHijriDate(
      day: fallback.hDay,
      month: fallback.hMonth,
      year: fallback.hYear,
      monthName: getHijriMonthName(fallback.hMonth),
    );
  }

  static int? _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  static DateTime getGregorianStartFallback(int year, int month) {
    try {
      final firstDayTemp = HijriCalendar()
        ..hYear = year
        ..hMonth = month
        ..hDay = 1;
      return firstDayTemp.hijriToGregorian(year, month, 1);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Full record of one Hijri month: header fields plus the days that carry
  /// events. Months the bundled table does not know are derived from the
  /// calculation library so navigation never breaks outside the table.
  static HijriMonthData getMonthData(int year, int month) {
    final months = DataManager.getDB()?['hijri_calendar'];
    if (months is List) {
      for (final entry in months) {
        if (entry is! Map) continue;
        if (_asInt(entry['year']) != year) continue;
        if (_asInt(entry['month']) != month) continue;
        try {
          return HijriMonthData.fromJson(Map<String, dynamic>.from(entry));
        } catch (e) {
          debugPrint('Error parsing Hijri month $year-$month: $e');
        }
      }
    }

    try {
      final fallbackHijri = HijriCalendar()
        ..hYear = year
        ..hMonth = month
        ..hDay = 1;

      final gregorianStart = fallbackHijri.hijriToGregorian(year, month, 1);
      final totalDays = fallbackHijri.getDaysInMonth(year, month);

      return HijriMonthData(
        year: year,
        month: month,
        totalDays: totalDays,
        expectedGregorianStart:
            gregorianStart.toIso8601String().split('T').first,
        days: [],
      );
    } catch (e) {
      return HijriMonthData(
        year: year,
        month: month,
        totalDays: 30,
        expectedGregorianStart:
            DateTime.now().toIso8601String().split('T').first,
        days: [],
      );
    }
  }

  static HijriDayData? getDayData(int year, int month, int day) {
    final monthData = getMonthData(year, month);
    for (final d in monthData.days) {
      if (d.day == day) return d;
    }
    return null;
  }

  static List<CalendarEvent> getEventsForDay(int year, int month, int day) {
    final dayData = getDayData(year, month, day);
    if (dayData != null) {
      return dayData.events;
    }
    return [];
  }

  static List<AstronomicalEvent> getAstronomicalEventsForDay(
    int year,
    int month,
    int day,
  ) {
    final dayData = getDayData(year, month, day);
    if (dayData != null) {
      return dayData.astronomicalEvents;
    }
    return [];
  }
}
