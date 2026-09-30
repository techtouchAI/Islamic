import 'dart:convert';
import 'dart:io';

import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/data/repositories/calendar_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled table is the calendar of record of this app: the month starts of
/// the office of Grand Ayatollah al-Sistani, which differ from the calculated
/// Umm al-Qura calendar by a day in several months. The expected values below
/// are transcribed from the office itself:
///
/// * months 1-4 were announced after the sighting of the crescent
///   (`sistani_office_announcement`), e.g. the statement that Sunday 13 Sep
///   2026 is the first of Rabi' al-thani 1448;
/// * months 5-12 are the predictions of the office's crescent booklet for
///   1448 (`sistani_office_booklet`), published at
///   sistani.org/downloads/ahelleh1448hj.pdf. Each start is traced to the
///   line stating the evening the crescent is sought on: the Jumada al-ula
///   page looks for it on 30 Rabi' al-thani 1448 = 12 Oct 2026, so its day 1
///   is 13 Oct 2026.
///
/// A month length here is the distance to the next month start, which the
/// booklet fixes for months 1-11 through that same crescent line.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// month -> (day 1 as a civil date, number of days).
  final officeMonths = <int, (String, int)>{
    1: ('2026-06-17', 29), // Muharram, announced (crescent 16 Jun 2026).
    2: ('2026-07-16', 30), // Safar, announced (crescent 15 Jul 2026).
    3: ('2026-08-15', 29), // Rabi' al-awwal, announced (crescent 14 Aug).
    4: ('2026-09-13', 30), // Rabi' al-thani, announced (crescent 12 Sep).
    5: ('2026-10-13', 30), // Jumada al-ula (crescent 12 Oct 2026).
    6: ('2026-11-12', 29), // Jumada al-akhirah (crescent 11 Nov 2026).
    7: ('2026-12-11', 30), // Rajab (crescent 10 Dec 2026).
    8: ('2027-01-10', 30), // Sha'ban (crescent 9 Jan 2027).
    9: ('2027-02-09', 29), // Ramadan (crescent 8 Feb 2027).
    10: ('2027-03-10', 30), // Shawwal (crescent 9 Mar 2027).
    11: ('2027-04-09', 29), // Dhu al-qa'dah (crescent 8 Apr 2027).
    12: ('2027-05-08', 29), // Dhu al-hijjah (crescent 7 May 2027).
  };
  final announcedStarts = <int, String>{
    for (final entry in officeMonths.entries) entry.key: entry.value.$1,
  };

  group('bundled calendar data', () {
    late List<dynamic> table;

    late Map<String, dynamic> document;

    setUpAll(() async {
      final raw = await File('assets/data/content.json').readAsString();
      document = jsonDecode(raw) as Map<String, dynamic>;
      table = document['hijri_calendar'] as List<dynamic>;
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{},
        'content': <String, dynamic>{},
        'hijri_calendar': table,
        'calendar_version': document['calendar_version'],
      });
    });

    test('the document versions its calendar and names the authority', () {
      expect(document['calendar_version'], isA<int>());
      expect(document['calendar_version'], greaterThan(0));
      expect(
        document['calendar_source'].toString(),
        contains('السيستاني'),
        reason: 'the table must state which authority it follows',
      );
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
        expect(
          totalDays,
          officeMonths[month]!.$2,
          reason: 'month $month length as fixed by the office table',
        );
        expect(totalDays, inInclusiveRange(29, 30));
        expect(
          entry['source'],
          month <= 4 ? 'sistani_office_announcement' : 'sistani_office_booklet',
          reason: 'month $month must record where its start comes from',
        );
        if (previousEnd != null) {
          expect(
            start,
            previousEnd.add(const Duration(days: 1)),
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

    test('maps the reported days of Rabi\' al-thani 1448', () {
      // Asked for explicitly: 28, 29 and 30 September and 1 October 2026, as
      // the office's announcement of 12 Sep 2026 (day 1 = 13 Sep) fixes them.
      const expected = <String, int>{
        '2026-09-28': 16,
        '2026-09-29': 17,
        '2026-09-30': 18,
        '2026-10-01': 19,
      };
      expected.forEach((iso, day) {
        final hijri = CalendarRepository.getTodayHijri(DateTime.parse(iso), 0);
        expect((hijri.year, hijri.month, hijri.day), (1448, 4, day),
            reason: iso);
        expect(hijri.monthName, 'ربيع الآخر');
      });

      // The regression: the app used to answer 17 for 30 Sep 2026 because the
      // table started the month on 14 Sep instead of the announced 13 Sep.
      final reported = CalendarRepository.getTodayHijri(
        DateTime(2026, 9, 30),
        0,
      );
      expect(reported.day, isNot(17));
      expect(reported.day, 18);
    });

    test('a month that the office ends early is not padded to 30 days', () {
      // Dhu al-qa'dah 1448: the booklet looks for the Dhu al-hijjah crescent
      // on 29 Dhu al-qa'dah (7 May 2027), so the month has 29 days and the
      // martyrdom of Imam Muhammad al-Jawad, its last day, is day 29.
      final lastDay = CalendarRepository.getTodayHijri(DateTime(2027, 5, 7), 0);
      expect((lastDay.month, lastDay.day), (11, 29));
      final firstDay =
          CalendarRepository.getTodayHijri(DateTime(2027, 5, 8), 0);
      expect((firstDay.month, firstDay.day), (12, 1));
      expect(firstDay.monthName, 'ذو الحجة');
    });

    test('a local day keeps one Hijri date from midnight to midnight', () {
      // The civil date is read from the local fields, so no conversion may
      // move the answer across a day: 30 Sep 2026 is 18 Rabi' al-thani at the
      // first second and at the last second of the day.
      for (final time in [
        DateTime(2026, 9, 30, 0, 0, 1),
        DateTime(2026, 9, 30, 12),
        DateTime(2026, 9, 30, 23, 59, 59),
      ]) {
        final hijri = CalendarRepository.getTodayHijri(time, 0);
        expect((hijri.month, hijri.day), (4, 18), reason: time.toString());
      }
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
