import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/providers/settings_provider.dart';
import 'package:aldhakereen/ui/home/home_section.dart';
import 'package:aldhakereen/ui/home/widgets/prophets_tree_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async => initializeDateFormatting('ar_SA'));

  testWidgets('the card is a compact, two-tile wide door with a drawn backdrop',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            // The width of two grid tiles and the gap between them.
            child: SizedBox(
              width: 328,
              child: ProphetsTreeCard(
                title: 'شجرة الأنبياء والأئمة',
                uiOpacity: 1,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('شجرة الأنبياء والأئمة'), findsOneWidget);
    expect(find.text(ProphetsTreeCard.subtitle), findsOneWidget);
    expect(find.byIcon(Icons.account_tree), findsOneWidget);

    // Full row width, and shorter than a grid tile.
    final card = tester.getSize(find.byType(ProphetsTreeCard));
    expect(card.width, 328);
    expect(card.height, lessThan(120));

    // The backdrop is painted, not an asset, and it never repaints itself.
    final backdrop = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
    expect(backdrop, isNotEmpty);
    expect(backdrop.first.painter, isNotNull);
    expect(
      backdrop.first.painter!.shouldRepaint(backdrop.first.painter!),
      isFalse,
    );

    await tester.tap(find.byType(ProphetsTreeCard));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'home places the card under the daily dhikr and opens the section',
      (tester) async {
    // Tall enough for the whole home list to be laid out, so the card exists
    // even though it sits below the prayer card.
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    DataManager.setDB({
      'sections': {
        'prophets_stories': {'title': 'قصص الانبياء'},
        'prophets_tree': {
          'title': 'شجرة الأنبياء والأئمة',
          'icon': 'account_tree',
          'color': '0xFFD4AF37',
          'visible_home': true,
          'home_card': true,
        },
      },
      'content': {
        'duas_days': [],
        'prophets_tree': [
          {'id': 1, 'title': 'شجرة النسب', 'content': 'html <p>آدم</p>'},
        ],
      },
      'settings': {},
    });
    final settings = SettingsProvider();
    await settings.loadSettings();
    addTearDown(settings.dispose);

    String? navigated;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [Locale('ar', 'SA')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: HomeSection(onNavigate: (section) => navigated = section),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('شجرة الأنبياء والأئمة'), findsOneWidget);
    // Below ذكر اليوم, and never as a grid tile of its own.
    expect(
      tester.getTopLeft(find.byType(ProphetsTreeCard)).dy,
      greaterThan(tester.getTopLeft(find.text('ذكر اليوم')).dy),
    );

    await tester.tap(find.byType(ProphetsTreeCard));
    await tester.pump();
    expect(navigated, 'prophets_tree');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a document without the section gets no card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    DataManager.setDB({
      'sections': {'quran': {'title': 'القرآن الكريم'}},
      'content': {'quran': []},
      'settings': {},
    });
    final settings = SettingsProvider();
    await settings.loadSettings();
    addTearDown(settings.dispose);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [Locale('ar', 'SA')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: HomeSection(),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ProphetsTreeCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
