import 'dart:convert';
import 'dart:io';

import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/data/repositories/calendar_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards how a corrected calendar reaches the screen.
///
/// The bug that hid a corrected table from users was not the calculation: the
/// device copy of the content document outlives app updates and is loaded
/// before the bundle, and a cloud document with the same table was never
/// reconsidered. These tests drive the real [DataManager] entry points with a
/// cached document that carries the previous table and require the corrected
/// day to be reported afterwards.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The month start the bundled table shipped before it was corrected: the
  /// office announced 13 Sep 2026 as day 1 of Rabi' al-thani 1448, so a table
  /// starting on the 14th answers 17 for 30 Sep 2026.
  const String staleStart = '2026-09-14';
  const String announcedStart = '2026-09-13';

  String document({
    required String month4Start,
    required int calendarVersion,
    String? extraSection,
  }) {
    return jsonEncode(<String, dynamic>{
      'sections': <String, dynamic>{},
      'content': <String, dynamic>{
        if (extraSection != null)
          'sync_marker': <dynamic>[
            <String, dynamic>{'title': extraSection},
          ],
      },
      'calendar_version': calendarVersion,
      'calendar_source': 'test',
      'hijri_calendar': <dynamic>[
        <String, dynamic>{
          'year': 1448,
          'month': 4,
          'total_days': 30,
          'expected_gregorian_start': month4Start,
          'source': 'test',
          'days': <dynamic>[],
        },
      ],
    });
  }

  int dayOfSeptember30() =>
      CalendarRepository.getTodayHijri(DateTime(2026, 9, 30), 0).day;

  late Directory directory;
  late File cache;

  /// Start of month 4 in the document the device kept, whichever position the
  /// row has in the array.
  Future<String> persistedStartOfMonth4() async {
    final document = jsonDecode(await cache.readAsString()) as Map;
    final months = (document['hijri_calendar'] as List)
        .cast<Map>()
        .where((row) => row['month'] == 4)
        .toList();
    return months.single['expected_gregorian_start'] as String;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('calendar_sync_test');
    cache = File('${directory.path}/content.json');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DataManager.appBuildOverride = () async => '1.0.60+900';
    DataManager.getLocalFileOverride = () async => cache;
    DataManager.httpClient = null;
    DataManager.bundleCalendarRefresh = null;
    addTearDown(() async {
      DataManager.bundleCalendarRefresh = null;
      DataManager.appBuildOverride = null;
      DataManager.getLocalFileOverride = null;
      DataManager.httpClient = null;
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
  });

  group('calendar of an installed build', () {
    test('the bundled table supersedes a cached document', () async {
      // The cached document predates the versioned table, exactly like the
      // copies written by builds released before the correction.
      await cache.writeAsString(document(
        month4Start: staleStart,
        calendarVersion: 0,
        extraSection: 'cached',
      ));

      await DataManager.loadContent();
      await DataManager.bundleCalendarRefresh;

      // The cached document is still the source for everything else ...
      expect(
        DataManager.getDB()!['content']['sync_marker'][0]['title'],
        'cached',
      );
      // ... but its outdated table no longer decides the date.
      expect(
        DataManager.calendarVersionOf(DataManager.getDB()),
        greaterThan(0),
      );
      expect(dayOfSeptember30(), 18);
      expect(await persistedStartOfMonth4(), announcedStart);
    });

    test('the refresh is bound to the build that performed it', () async {
      // A previous launch of this very build already adopted its table, so the
      // device copy is authoritative until a newer build arrives.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'data.calendar.build': '1.0.60+900',
      });
      await cache.writeAsString(document(
        month4Start: staleStart,
        calendarVersion: 0,
      ));

      await DataManager.loadContent();
      await DataManager.bundleCalendarRefresh;

      expect(dayOfSeptember30(), 17);
      expect(await persistedStartOfMonth4(), staleStart);
    });

    test('a newer device table is not overwritten by the bundle', () async {
      await cache.writeAsString(document(
        month4Start: announcedStart,
        calendarVersion: 99,
        extraSection: 'cached',
      ));

      await DataManager.loadContent();
      await DataManager.bundleCalendarRefresh;

      expect(DataManager.calendarVersionOf(DataManager.getDB()), 99);
      expect(dayOfSeptember30(), 18);
      expect(await persistedStartOfMonth4(), announcedStart);
    });
  });

  group('calendar from the cloud', () {
    test('a newer cloud table replaces the device table', () async {
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{},
        'content': <String, dynamic>{},
        'calendar_version': 1,
        'hijri_calendar': <dynamic>[
          <String, dynamic>{
            'year': 1448,
            'month': 4,
            'total_days': 30,
            'expected_gregorian_start': staleStart,
          },
        ],
      });
      expect(dayOfSeptember30(), 17);

      final client = MockClient((request) async => http.Response(
            document(
              month4Start: announcedStart,
              calendarVersion: 2,
              extraSection: 'cloud',
            ),
            200,
          ));

      expect(await DataManager.syncCloudData(client: client), isTrue);
      expect(DataManager.calendarVersionOf(DataManager.getDB()), 2);
      expect(
          DataManager.getDB()!['content']['sync_marker'][0]['title'], 'cloud');
      expect(dayOfSeptember30(), 18);
    });

    test('an older cloud document cannot roll the device table back', () async {
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{},
        'content': <String, dynamic>{},
        'calendar_version': 5,
        'hijri_calendar': <dynamic>[
          <String, dynamic>{
            'year': 1448,
            'month': 4,
            'total_days': 30,
            'expected_gregorian_start': announcedStart,
          },
        ],
      });

      final client = MockClient((request) async => http.Response(
            document(
              month4Start: staleStart,
              calendarVersion: 1,
              extraSection: 'cloud',
            ),
            200,
          ));

      expect(await DataManager.syncCloudData(client: client), isTrue);
      // The rest of the document is adopted, the table is not regressed.
      expect(
          DataManager.getDB()!['content']['sync_marker'][0]['title'], 'cloud');
      expect(DataManager.calendarVersionOf(DataManager.getDB()), 5);
      expect(dayOfSeptember30(), 18);
      expect(await persistedStartOfMonth4(), announcedStart);
    });

    test('a document without a table keeps the device table', () async {
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{},
        'content': <String, dynamic>{},
        'calendar_version': 5,
        'hijri_calendar': <dynamic>[
          <String, dynamic>{
            'year': 1448,
            'month': 4,
            'total_days': 30,
            'expected_gregorian_start': announcedStart,
          },
        ],
      });

      final client = MockClient((request) async => http.Response(
            jsonEncode(<String, dynamic>{
              'sections': <String, dynamic>{},
              'content': <String, dynamic>{
                'sync_marker': <dynamic>[
                  <String, dynamic>{'title': 'cloud'},
                ],
              },
            }),
            200,
          ));

      expect(await DataManager.syncCloudData(client: client), isTrue);
      expect(dayOfSeptember30(), 18);
    });

    test('an unchanged document is not written again', () async {
      final body = document(
        month4Start: announcedStart,
        calendarVersion: 2,
      );
      await cache.writeAsString(body);
      DataManager.setDB(<String, dynamic>{
        'sections': <String, dynamic>{},
        'content': <String, dynamic>{},
        'calendar_version': 2,
        'hijri_calendar': <dynamic>[
          <String, dynamic>{
            'year': 1448,
            'month': 4,
            'total_days': 30,
            'expected_gregorian_start': announcedStart,
          },
        ],
      });

      final client = MockClient(
        (request) async => http.Response(body, 200),
      );

      expect(await DataManager.syncCloudData(client: client), isFalse);
      expect(await cache.readAsString(), body);
    });
  });
}
