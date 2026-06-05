import 'package:hijri/hijri_calendar.dart';
import '../data_manager.dart';

class CalendarEvent {
  final String title;
  final String? description;
  final bool isImportant;

  CalendarEvent({
    required this.title,
    this.description,
    this.isImportant = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      title: json['title'] ?? '',
      description: json['description'],
      isImportant: json['isImportant'] ?? false,
    );
  }
}

class HijriDayData {
  final int day;
  final List<CalendarEvent> events;
  final List<CalendarEvent> astronomicalEvents;

  HijriDayData({
    required this.day,
    required this.events,
    required this.astronomicalEvents,
  });

  factory HijriDayData.fromJson(Map<String, dynamic> json) {
    return HijriDayData(
      day: json['day'] ?? 1,
      events: (json['events'] as List?)
              ?.map((e) => CalendarEvent.fromJson(e))
              .toList() ??
          [],
      astronomicalEvents: (json['astronomical_events'] as List?)
              ?.map((e) => CalendarEvent.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class HijriMonthData {
  final int year;
  final int month;
  final int totalDays;
  final DateTime expectedGregorianStart;
  final Map<int, HijriDayData> days;

  HijriMonthData({
    required this.year,
    required this.month,
    required this.totalDays,
    required this.expectedGregorianStart,
    required this.days,
  });

  factory HijriMonthData.fromJson(Map<String, dynamic> json) {
    var daysMap = <int, HijriDayData>{};
    if (json['days'] != null) {
      for (var dayObj in json['days']) {
        final d = HijriDayData.fromJson(dayObj);
        daysMap[d.day] = d;
      }
    }
    return HijriMonthData(
      year: json['year'] ?? 1440,
      month: json['month'] ?? 1,
      totalDays: json['total_days'] ?? 30,
      expectedGregorianStart: DateTime.tryParse(json['expected_gregorian_start'] ?? '') ?? DateTime.now(),
      days: daysMap,
    );
  }
}

class CalendarRepository {
  static HijriMonthData? getMonthData(int year, int month) {
    final db = DataManager.getDB();
    if (db == null || db['hijri_calendar'] == null) return null;

    final months = db['hijri_calendar'] as List;
    for (var m in months) {
      if (m['year'] == year && m['month'] == month) {
        try {
          return HijriMonthData.fromJson(m);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  static List<CalendarEvent> getEventsForDay(int year, int month, int day) {
    final monthData = getMonthData(year, month);
    if (monthData != null) {
      final dayData = monthData.days[day];
      if (dayData != null) {
        return dayData.events;
      }
      return [];
    }

    return _getFallbackEvents(year, month, day);
  }

  static List<CalendarEvent> _getFallbackEvents(int year, int month, int day) {
    // We will extract fallback events logic from original code.
    return [];
  }
}
