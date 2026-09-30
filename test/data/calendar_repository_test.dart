import 'dart:convert';
import 'dart:io';

import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/data/repositories/calendar_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled table is the calendar of record: announced month starts differ
/// from the calculated Umm al-Qura calendar, so the shipped data — not the
/// calculation package — has to decide what day it is.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Day 1 of each month of 1448. Months 1-4 are the announced starts of the
  /// Sistani office; the rest are the Umm al-Qura start plus the same one-day
  /// difference until the office publishes them, keeping the table contiguous.
  final announcedStarts = <int, String>{
    1: '2026-06-17', // Muharram — announced.
    2: '2026-07-16', // Safar — announced.
    3: '2026-08-15', // Rabi' al-awwal — announced.
    4: '2026-09-13', // Rabi' al-thani — announced.
    5: '2026-10-13', // Jumada al-ula.
    6: '2026-11-12',
    7: '2026-12-11',
    8: '2027-01-10',
    9: '2027-02-09',
    10: '2027-03-10',
    11: '2027-04-09',
    12: '2027-05-09',
  };

  group('bundled calendar data', () {
    late List<dynamic> table;

    setUpAll(() async {
      final raw = await File('assets/data/content.json').readAsString();
      final document = jsonDecode(raw) as Map<String, dynamic>;
      table = document['hijri_calendar'] as List<dynamic>;
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{},
        'content': <String, dynamic>{},
        'hijri_calendar': table,
      });
    });

    test('publishes every month of 1448 with a contiguous day range', () {
      final months = {
        for (final entry in table.cast<Map<String, dynamic>>())
          entry['month'] as int: entry,
      };
      expect(months.keys.toList()..sort(), List.generate(12, (i) => i + 1));

      DateTime? previousEnd;
      for (var month = 1; month <= 12; month++) {
        final entry = months[month]!;
        final start = DateTime.parse(
          entry['expected_gregorian_start'] as String,
        );
        expect(
          entry['expected_gregorian_start'],
          announcedStarts[month],
          reason: 'month $month start',
        );
        final totalDays = entry['total_days'] as int;
        expect(totalDays, inInclusiveRange(29, 30));
        if (previousEnd != null) {
          expect(
            start,
            previousEnd!.add(const Duration(days: 1)),
            reason: 'month $month must start the day after month ${month - 1}',
          );
        }
        previousEnd = start.add(Duration(days: totalDays - 1));
      }
    });

    test('a month is never shorter than the events it holds', () {
      for (final entry in table.cast<Map<String, dynamic>>()) {
        final totalDays = entry['total_days'] as int;
        final days = (entry['days'] as List<dynamic>? ?? const []);
        for (final day in days.cast<Map<String, dynamic>>()) {
          expect(
            day['day'] as int,
            inInclusiveRange(1, totalDays),
            reason: 'month ${entry['month']} holds events on day ${day['day']}',
          );
        }
      }
    });

    test('every day of 1448 maps to its own month and day', () {
      final summaries = CalendarRepository.monthSummaries();
      for (final summary in summaries) {
        for (var day = 1; day <= summary.totalDays; day++) {
          final civil = summary.start.add(Duration(days: day - 1));
          final hijri = CalendarRepository.getTodayHijri(civil, 0);
          expect(
            (hijri.year, hijri.month, hijri.day, hijri.monthName),
            (
              1448,
              summary.month,
              day,
              CalendarRepository.getHijriMonthName(
                summary.month,
              )
            ),
            reason: 'civil $civil',
          );
        }
      }
    });

    test('reports the announced day of Rabi\' al-thani, not the calculated one',
        () {
      // 30 Sep 2026 is 18 Rabi' al-thani 1448 in Iraq. The calculated Umm
      // al-Qura date is 19, which is exactly the off-by-one that was reported.
      final hijri = CalendarRepository.getTodayHijri(DateTime(2026, 9, 30), 0);
      expect(hijri.day, 18);
      expect(hijri.month, 4);
      expect(hijri.year, 1448);
      expect(hijri.monthName, 'ربيع الآخر');
      expect(hijri.toString(), '18 ربيع الآخر 1448 هـ');

      expect(
        CalendarRepository.getTodayHijri(DateTime(2026, 9, 30), 1).day,
        19,
      );
      expect(
        CalendarRepository.getTodayHijri(DateTime(2026, 9, 30), -1).day,
        17,
      );
    });

    test('the table decides month boundaries the calculation gets wrong', () {
      // Calculated Umm al-Qura starts Jumada al-ula on 12 Oct 2026; the table
      // keeps 12 Oct as the 30th of Rabi' al-thani.
      final lastDay =
          CalendarRepository.getTodayHijri(DateTime(2026, 10, 12), 0);
      expect((lastDay.month, lastDay.day), (4, 30));

      final firstDay =
          CalendarRepository.getTodayHijri(DateTime(2026, 10, 13), 0);
      expect((firstDay.month, firstDay.day), (5, 1));
      expect(firstDay.monthName, 'جمادى الأولى');
    });
  });

  group('month data', () {
    setUp(() {
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{},
        'content': <String, dynamic>{},
        'hijri_calendar': <dynamic>[
          <String, dynamic>{
            'year': 1446,
            'month': 2,
            'total_days': 29,
            'expected_gregorian_start': '2024-08-05',
            'days': <dynamic>[
              <String, dynamic>{
                'day': 3,
                'events': <dynamic>[
                  <String, dynamic>{
                    'title': 'حدث',
                    'description': 'وصف',
                    'isImportant': true,
                  },
                ],
                'astronomical_events': <dynamic>[],
              },
            ],
          },
        ],
      });
    });

    test('schema drift is rejected instead of shifting the calendar', () {
      final summaries = CalendarRepository.monthSummaries();
      expect(summaries, hasLength(1));
      expect(summaries.single.totalDays, 29);
      expect(summaries.single.start, DateTime.utc(2024, 8, 5));
      expect(summaries.single.end, DateTime.utc(2024, 9, 2));

      // A corrupted row (impossible month length, unparsable start) is skipped
      // so the calculation fallback is used for that month.
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{},
        'content': <String, dynamic>{},
        'hijri_calendar': <dynamic>[
          <String, dynamic>{
            'year': 1446,
            'month': 2,
            'total_days': 31,
            'expected_gregorian_start': 'not-a-date',
          },
        ],
      });
      expect(CalendarRepository.monthSummaries(), isEmpty);
      expect(
          CalendarRepository.monthSummaryForDate(DateTime(2024, 8, 5)), isNull);
    });

    test('month start follows the same correction as the reported date', () {
      final month = CalendarRepository.getMonthData(1446, 2);
      expect(month.totalDays, 29);
      expect(
        CalendarRepository.adjustedMonthStart(month, 0),
        DateTime.utc(2024, 8, 5),
      );
      // A positive correction reads the table ahead, so day 1 is displayed one
      // day earlier on the Gregorian grid.
      expect(
        CalendarRepository.adjustedMonthStart(month, 1),
        DateTime.utc(2024, 8, 4),
      );
      expect(CalendarRepository.getTodayHijri(DateTime(2024, 8, 5), 1).day, 2);
    });

    test('distinguishes the day of departure from the day of return', () {
      final civil = CalendarRepository.civilDate(DateTime(2026, 9, 30, 23, 59));
      expect(civil, DateTime.utc(2026, 9, 30));
      expect(civil.isUtc, isTrue);
    });
  });
}
