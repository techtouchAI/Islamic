import 'dart:convert';
import 'dart:io';

import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/data/repositories/calendar_repository.dart';
import 'package:aldhakereen/theme/app_theme.dart';
import 'package:aldhakereen/ui/home/home_prayer_controller.dart';
import 'package:aldhakereen/ui/home/widgets/home_prayer_card.dart';
import 'package:aldhakereen/ui/home/widgets/daily_worship_actions.dart';
import 'package:aldhakereen/ui/widgets/keep_alive_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../fixtures/prayer_schedules.dart';

void main() {
  late Map<String, dynamic> bundledDocument;

  setUp(() async => initializeDateFormatting('ar_SA'));

  // Reading the shipped document is real I/O, which never completes inside the
  // fake async zone of a widget test, so it is read once, outside it.
  setUpAll(() async {
    final raw = await File('assets/data/content.json').readAsString();
    bundledDocument = jsonDecode(raw) as Map<String, dynamic>;
  });

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('prayer card RTL $width scale $scale $brightness',
            (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final date = DateTime.utc(2026, 9, 30);
          final controller = HomePrayerController(
            loadToday: () async => scheduleFor(date),
            loadTomorrow: (_) async =>
                scheduleFor(date.add(const Duration(days: 1))),
            clock: () => DateTime.utc(2026, 9, 30, 8),
          );
          addTearDown(controller.dispose);
          var tapped = false;
          var dateTapped = false;
          await tester.pumpWidget(MaterialApp(
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [Locale('ar', 'SA')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.build(
                brightness: brightness,
                primary: AppPalette.forest,
                card: Colors.white),
            home: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 1800),
                  textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: HomePrayerCard(
                    controller: controller,
                    hijriAdjustment: 0,
                    onTap: () => tapped = true,
                    onDateTap: () => dateTapped = true),
              )),
            ),
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);
          expect(find.text('صلاة الظهر'), findsOneWidget);
          expect(find.text('٠١:٠٠:٠٠'), findsOneWidget);
          for (final key in PrayerTimesStrip.keys) {
            expect(find.byKey(ValueKey('prayer-time-$key')), findsOneWidget);
          }
          if (scale == 1) {
            final fajr = tester
                .getCenter(find.byKey(const ValueKey('prayer-time-fajr')));
            final isha = tester
                .getCenter(find.byKey(const ValueKey('prayer-time-isha')));
            expect(fajr.dx, greaterThan(isha.dx));
            expect(fajr.dy, isha.dy);
          }
          await tester.tapAt(tester.getCenter(find.text('صلاة الظهر')));
          expect(tapped, isTrue);
          expect(dateTapped, isFalse);

          // The Hijri date line is its own target: tapping it must open the
          // calendar and never the prayer-times settings behind it.
          final dateFinder = find.byKey(const ValueKey('prayer-date-button'));
          expect(dateFinder, findsOneWidget);
          final dateCenter = tester.getCenter(dateFinder);
          await tester.tapAt(tester.getCenter(find.text('صلاة الظهر')));
          await tester.tapAt(dateCenter);
          expect(dateTapped, isTrue);
          expect(tapped, isTrue);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  testWidgets(
      'missing times and failure have no fabricated countdown, retry works',
      (tester) async {
    var fail = true;
    final date = DateTime.utc(2026, 9, 30);
    final controller = HomePrayerController(
      loadToday: () async {
        if (fail) throw StateError('unavailable');
        return scheduleFor(date);
      },
      loadTomorrow: (_) async => scheduleFor(date.add(const Duration(days: 1))),
      clock: () => DateTime.utc(2026, 9, 30, 8),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
      child: HomePrayerCard(controller: controller, hijriAdjustment: 0),
    ))));
    await tester.pump();
    expect(find.byKey(const ValueKey('prayer-countdown')), findsNothing);
    expect(find.text('—'), findsNWidgets(5));
    fail = false;
    await tester.tap(find.text('تعذّر تحديث المواقيت · إعادة المحاولة'));
    await tester.pump();
    expect(find.byKey(const ValueKey('prayer-countdown')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('quick actions respect visibility and all route keys',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DailyWorshipActions(
      onNavigate: (key) => selected = key,
      visibility: const {'adhkar': false},
    ))));
    expect(find.byKey(const ValueKey('quick-adhkar')), findsNothing);
    for (final key in ['quran', 'tasbih', 'qibla']) {
      await tester.tap(find.byKey(ValueKey('quick-$key')));
      expect(selected, key);
    }
  });

  testWidgets('the date line sits on the sky and stays readable in dark mode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final date = DateTime.utc(2026, 9, 30);
    final controller = HomePrayerController(
      loadToday: () async => scheduleFor(date),
      loadTomorrow: (_) async => scheduleFor(date.add(const Duration(days: 1))),
      clock: () => DateTime.utc(2026, 9, 30, 8),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: HomePrayerCard(
          controller: controller,
          hijriAdjustment: 0,
          onDateTap: () {},
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final card = tester.getRect(find.byKey(const ValueKey('home-prayer-card')));
    final dateRect = tester.getRect(find.byKey(const ValueKey('prayer-date')));
    final titleRect =
        tester.getRect(find.byKey(const ValueKey('prayer-title')));
    expect(dateRect.top, greaterThan(card.top));
    expect(dateRect.bottom, lessThan(titleRect.top));
    // The line is inset from the physical left edge, where the artwork draws
    // its sky, and stays inside the card.
    expect(dateRect.left - card.left, greaterThan(60));
    expect(dateRect.right, lessThanOrEqualTo(card.right));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('prayer-date-button')),
        matching: find.byIcon(Icons.calendar_today_outlined),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the card prints the shared repository date', (tester) async {
    // The acceptance case: the real bundled table must reach the screen. The
    // card may not work out a Hijri date of its own, and the day it prints for
    // 30 September 2026 has to be 18 Rabi' al-thani 1448, never 17.
    DataManager.setDB(<String, dynamic>{
      'sections': <String, dynamic>{},
      'content': <String, dynamic>{},
      'hijri_calendar': bundledDocument['hijri_calendar'],
      'calendar_version': bundledDocument['calendar_version'],
    });
    addTearDown(() => DataManager.setDB(null));

    // Noon in the app's own zone (the fixture location is UTC+3) as a fixed
    // instant, so the answer does not depend on the runner's time zone.
    final noon = DateTime.utc(2026, 9, 30, 12);
    final expected = CalendarRepository.getTodayHijri(noon, 0);
    expect((expected.month, expected.day), (4, 18));

    final controller = HomePrayerController(
      loadToday: () async => scheduleFor(DateTime.utc(2026, 9, 30)),
      loadTomorrow: (_) async => scheduleFor(DateTime.utc(2026, 10, 1)),
      clock: () => noon.subtract(const Duration(hours: 3)),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: HomePrayerCard(controller: controller, hijriAdjustment: 0),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final text = tester
        .widget<Text>(find.byKey(const ValueKey('prayer-date')))
        .data
        .toString();
    expect(text, contains('١٨ ربيع الآخر ١٤٤٨ هـ'));
    expect(text, contains('الأربعاء'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('scrolling the home list never reloads the schedule',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final date = DateTime.utc(2026, 9, 30);
    var loads = 0;
    final controller = HomePrayerController(
      loadToday: () async {
        loads++;
        return scheduleFor(date);
      },
      loadTomorrow: (_) async => scheduleFor(date.add(const Duration(days: 1))),
      clock: () => DateTime.utc(2026, 9, 30, 8),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            // The card keeps its natural height; the rows below are what push
            // it out of the viewport.
            KeepAliveHost(
              child: HomePrayerCard(controller: controller, hijriAdjustment: 0),
            ),
            for (var i = 0; i < 20; i++)
              SizedBox(height: 120, child: Text('عنصر $i')),
          ],
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(loads, 1);

    // The element that renders the card right now.
    final cardElement =
        tester.element(find.byKey(const ValueKey('home-prayer-card')));

    // Scroll to the middle and then to the very end of the list, the two
    // places where the card used to be rebuilt.
    final position = tester.state<ScrollableState>(find.byType(Scrollable));
    final maxScroll = position.position.maxScrollExtent;
    expect(maxScroll, greaterThan(1000));
    position.position.jumpTo(maxScroll / 2);
    await tester.pump();
    expect(loads, 1, reason: 'scrolling to the middle must not reload');
    position.position.jumpTo(maxScroll);
    await tester.pump();
    expect(loads, 1, reason: 'scrolling to the end must not reload');

    position.position.jumpTo(0);
    await tester.pump();
    expect(loads, 1, reason: 'returning to the card must not reload it');
    expect(
      identical(
        tester.element(find.byKey(const ValueKey('home-prayer-card'))),
        cardElement,
      ),
      isTrue,
      reason: 'a disposed card would come back as a new element and reload',
    );
    expect(find.byKey(const ValueKey('prayer-countdown')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
