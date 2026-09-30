import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/data/repositories/calendar_repository.dart';
import 'package:aldhakereen/providers/settings_provider.dart';
import 'package:aldhakereen/ui/calendar/hijri_calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screen resolves "today" through the bundled table, so the fixture is a
/// table whose month contains the real current date: the assertions stay true
/// on any day the suite runs. Day 12 of the fixture month is always today.
void main() {
  const int todayDay = 12;
  const int monthDays = 30;
  const int fixtureMonth = 7;
  const int fixtureYear = 1446;

  /// First civil day of the fixture month: `todayDay` days before today.
  DateTime monthStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(const Duration(days: todayDay - 1));
  }

  String isoDate(DateTime value) => '${value.year.toString().padLeft(4, '0')}'
      '-${value.month.toString().padLeft(2, '0')}'
      '-${value.day.toString().padLeft(2, '0')}';

  void installFixture() {
    DataManager.setDB(<String, dynamic>{
      'sections': <String, dynamic>{},
      'content': <String, dynamic>{},
      'hijri_calendar': <dynamic>[
        <String, dynamic>{
          'year': fixtureYear,
          'month': fixtureMonth,
          'total_days': monthDays,
          'expected_gregorian_start': isoDate(monthStart()),
          'days': <dynamic>[
            <String, dynamic>{
              'day': todayDay,
              'events': <dynamic>[
                <String, dynamic>{
                  'title': 'حدث الاختبار',
                  'description': 'وصف الاختبار',
                  'isImportant': true,
                },
              ],
              'astronomical_events': <dynamic>[],
            },
          ],
        },
      ],
    });
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
        child: MaterialApp(
          locale: const Locale('ar', 'SA'),
          supportedLocales: const [Locale('ar', 'SA')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const HijriCalendarScreen(),
        ),
      ),
    );
    // The screen fills its state from a post-frame callback.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  Finder inGrid(Finder matching) =>
      find.descendant(of: find.byType(GridView), matching: matching);

  setUp(() async {
    await initializeDateFormatting('ar_SA');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    installFixture();
  });

  test('the fixture month is the month the repository reports for today', () {
    final hijri = CalendarRepository.getTodayHijri(DateTime.now(), 0);
    expect((hijri.year, hijri.month, hijri.day), (
      fixtureYear,
      fixtureMonth,
      todayDay,
    ));
  });

  testWidgets('the grid draws every day of the month and nothing beyond it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(GridView), findsWidgets);
    expect(
      find.textContaining(CalendarRepository.getHijriMonthName(fixtureMonth)),
      findsWidgets,
    );

    for (var day = 1; day <= monthDays; day++) {
      expect(inGrid(find.text('$day')), findsOneWidget, reason: 'day $day');
    }
    // One day past the end of the month must stay empty.
    expect(inGrid(find.text('${monthDays + 1}')), findsNothing);

    // Today is the day the repository reports, never a calculated neighbour.
    final hijri = CalendarRepository.getTodayHijri(DateTime.now(), 0);
    expect(inGrid(find.text('${hijri.day}')), findsOneWidget);
  });

  testWidgets('the month grid starts on the weekday of the month start',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester);

    final start = monthStart();

    // One tappable cell per day of the month, no more and no less.
    expect(inGrid(find.byType(InkWell)), findsNWidgets(monthDays));

    // Day 1 sits in the column of its weekday. The header row starts with
    // Monday at the right edge, so a cell's column is counted from the right.
    final firstCell = tester.getRect(inGrid(find.text('1')));
    final gridRect = tester.getRect(find.byType(GridView).first);
    final columnWidth = gridRect.width / 7;
    final actualColumn = ((gridRect.right - firstCell.center.dx) / columnWidth)
        .floor();
    expect(actualColumn, start.weekday - 1);
    expect(firstCell.center.dy, lessThan(gridRect.bottom));
  });

  testWidgets('tapping a day selects it and shows its events', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('حدث الاختبار'));

    // The screen opens on today, whose event comes from the table.
    expect(find.text('حدث الاختبار'), findsOneWidget);
    expect(find.textContaining('أحداث يوم $todayDay'), findsOneWidget);

    const otherDay = 20;
    await tester.ensureVisible(inGrid(find.text('$otherDay')));
    await tester.pump();
    await tester.tap(inGrid(find.text('$otherDay')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('أحداث يوم $otherDay'), findsOneWidget);
    expect(find.text('لا توجد أحداث في هذا اليوم'), findsOneWidget);
    expect(find.text('حدث الاختبار'), findsNothing);

    // Going back to today restores the event.
    await tester.ensureVisible(inGrid(find.text('$todayDay')));
    await tester.pump();
    await tester.tap(inGrid(find.text('$todayDay')));
    await tester.pump();
    expect(find.text('حدث الاختبار'), findsOneWidget);
  });
}
