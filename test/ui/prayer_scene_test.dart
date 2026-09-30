import 'dart:io';
import 'dart:ui' as ui;

import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/models/prayer_schedule.dart';
import 'package:aldhakereen/providers/settings_provider.dart';
import 'package:aldhakereen/theme/app_theme.dart';
import 'package:aldhakereen/ui/home/home_section.dart';
import 'package:aldhakereen/ui/home/home_prayer_controller.dart';
import 'package:aldhakereen/ui/home/prayer_scene_period.dart';
import 'package:aldhakereen/ui/home/widgets/home_prayer_card.dart';
import 'package:aldhakereen/ui/home/widgets/prayer_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/prayer_schedules.dart';

void main() {
  final day = DateTime.utc(2026, 9, 30);
  final schedule = scheduleFor(day, hours: {
    'fajr': 5,
    'sunrise': 6,
    'dhuhr': 12,
    'asr': 15,
    'sunset': 18,
    'maghrib': 19,
    'isha': 20,
  });

  test('artwork uses sunrise inclusive, sunset exclusive; not Maghrib', () {
    PrayerScenePeriod at(int hour, [int minute = 0]) => prayerScenePeriod(
          localNow: DateTime.utc(2026, 9, 30, hour, minute),
          schedule: schedule,
        );
    expect(at(5, 59), PrayerScenePeriod.night);
    expect(at(6), PrayerScenePeriod.day);
    expect(at(17, 59), PrayerScenePeriod.day);
    expect(at(18), PrayerScenePeriod.night);
    expect(at(18, 30), PrayerScenePeriod.night);
    expect(at(23), PrayerScenePeriod.night);
    expect(at(0), PrayerScenePeriod.night);
  });

  test('absent, incomplete, stale and invalid events use visual fallback', () {
    final missing = scheduleFor(day, hours: {'sunrise': 7});
    final invalid = scheduleFor(day, hours: {'sunrise': 20, 'sunset': 6});
    final stale = scheduleFor(day.subtract(const Duration(days: 1)),
        hours: {'sunrise': 8, 'sunset': 20});
    for (final s in <PrayerSchedule?>[null, missing, invalid, stale]) {
      expect(
          prayerScenePeriod(
              localNow: DateTime.utc(2026, 9, 30, 7), schedule: s),
          PrayerScenePeriod.day);
      expect(
          prayerScenePeriod(
              localNow: DateTime.utc(2026, 9, 30, 19), schedule: s),
          PrayerScenePeriod.night);
    }
  });

  test('scene repaints only when the day/night period changes', () {
    const dayPainter = PrayerScenePainter(period: PrayerScenePeriod.day);
    const nightPainter = PrayerScenePainter(period: PrayerScenePeriod.night);
    expect(dayPainter.shouldRepaint(dayPainter), isFalse);
    expect(dayPainter.shouldRepaint(nightPainter), isTrue);
  });

  testWidgets('home starts with prayer card, no greeting, new inspiration icon',
      (tester) async {
    await initializeDateFormatting('ar_SA');
    SharedPreferences.setMockInitialValues({
      'vis_day_dua': false,
      'vis_adhkar': false,
      'vis_inspiration': true,
    });
    DataManager.setDB(
        {'sections': <String, dynamic>{}, 'content': <String, dynamic>{}});
    final settings = SettingsProvider();
    await settings.loadSettings();
    addTearDown(settings.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: const MaterialApp(
          home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: HomeSection()),
      )),
    ));
    await tester.pump();
    expect(find.text('السلام عليكم'), findsNothing);
    expect(find.text('نسأل الله أن يجعل يومكم عامراً بالذكر'), findsNothing);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
    expect(tester.getTopLeft(find.byKey(const ValueKey('home-prayer-card'))).dy,
        20);
    await tester.scrollUntilVisible(find.text('إلهام اليوم'), 200);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('clock changes artwork without changing app theme; local fonts',
      (tester) async {
    await initializeDateFormatting('ar_SA');
    // Loading real fonts makes exported images faithful to the actual app,
    // instead of Flutter test's Ahem placeholder glyphs.
    for (final pair in [
      ('Cairo', 'assets/font/Cairo-VariableFont.ttf'),
      ('OmarNaskh', 'assets/font/OmarNaskh-Medium.ttf'),
    ]) {
      final loader = FontLoader(pair.$1)..addFont(rootBundle.load(pair.$2));
      await loader.load();
    }
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var now = DateTime.utc(2026, 9, 30, 8);
    final controller = HomePrayerController(
      loadToday: () async => schedule,
      loadTomorrow: (_) async => scheduleFor(day.add(const Duration(days: 1))),
      clock: () => now,
    );
    addTearDown(controller.dispose);
    var taps = 0;
    const boundaryKey = ValueKey('scene-capture');
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.build(
          brightness: Brightness.light,
          primary: AppPalette.forest,
          card: Colors.white),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: RepaintBoundary(
              key: boundaryKey,
              child: HomePrayerCard(
                  controller: controller,
                  hijriAdjustment: 0,
                  onTap: () => taps++)),
        )),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<PrayerScene>(find.byType(PrayerScene)).period,
        PrayerScenePeriod.day);
    final title =
        tester.widget<Text>(find.byKey(const ValueKey('prayer-title')));
    final countdown =
        tester.widget<Text>(find.byKey(const ValueKey('prayer-countdown')));
    expect(title.style?.fontFamily, 'Cairo');
    expect(title.style?.fontWeight, FontWeight.w500);
    expect(countdown.style?.fontFamily, 'OmarNaskh');
    expect(find.byIcon(Icons.mosque_outlined), findsNothing);
    await _capture(tester, boundaryKey, 'prayer-day');
    now = DateTime.utc(2026, 9, 30, 15); // 18:00 in selected Iraqi location
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<PrayerScene>(find.byType(PrayerScene)).period,
        PrayerScenePeriod.night);
    await _capture(tester, boundaryKey, 'prayer-night');
    await tester
        .tapAt(tester.getCenter(find.byKey(const ValueKey('prayer-title'))));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _capture(WidgetTester tester, Key key, String name) async {
  // Opt-in CI evidence, never a golden baseline auto-approved by this test.
  if (Platform.environment['CAPTURE_UI'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('build/ui-previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
