import 'package:aldhakereen/theme/app_theme.dart';
import 'package:aldhakereen/ui/home/home_prayer_controller.dart';
import 'package:aldhakereen/ui/home/widgets/home_prayer_card.dart';
import 'package:aldhakereen/ui/home/widgets/daily_worship_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../fixtures/prayer_schedules.dart';

void main() {
  setUp(() async => initializeDateFormatting('ar_SA'));

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('prayer card RTL $width scale $scale $brightness', (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final date = DateTime.utc(2026, 9, 30);
          final controller = HomePrayerController(
            loadToday: () async => scheduleFor(date),
            loadTomorrow: (_) async => scheduleFor(date.add(const Duration(days: 1))),
            clock: () => DateTime.utc(2026, 9, 30, 8),
          );
          addTearDown(controller.dispose);
          var tapped = false;
          await tester.pumpWidget(MaterialApp(
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [Locale('ar', 'SA')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.build(brightness: brightness, primary: AppPalette.forest, card: Colors.white),
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 1800), textScaler: TextScaler.linear(scale)),
              child: Scaffold(body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: HomePrayerCard(controller: controller, hijriAdjustment: 0, onTap: () => tapped = true),
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
            final fajr = tester.getCenter(find.byKey(const ValueKey('prayer-time-fajr')));
            final isha = tester.getCenter(find.byKey(const ValueKey('prayer-time-isha')));
            expect(fajr.dx, greaterThan(isha.dx));
            expect(fajr.dy, isha.dy);
          }
          await tester.tap(find.text('صلاة الظهر'));
          expect(tapped, isTrue);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  testWidgets('missing times and failure have no fabricated countdown, retry works', (tester) async {
    var fail = true;
    final date = DateTime.utc(2026, 9, 30);
    final controller = HomePrayerController(
      loadToday: () async { if (fail) throw StateError('unavailable'); return scheduleFor(date); },
      loadTomorrow: (_) async => scheduleFor(date.add(const Duration(days: 1))),
      clock: () => DateTime.utc(2026, 9, 30, 8),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
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

  testWidgets('quick actions respect visibility and all route keys', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DailyWorshipActions(
      onNavigate: (key) => selected = key, visibility: const {'adhkar': false},
    ))));
    expect(find.byKey(const ValueKey('quick-adhkar')), findsNothing);
    for (final key in ['quran', 'tasbih', 'qibla']) {
      await tester.tap(find.byKey(ValueKey('quick-$key')));
      expect(selected, key);
    }
  });
}
