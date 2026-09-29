import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/main.dart';
import 'package:aldhakereen/providers/settings_provider.dart';
import 'package:aldhakereen/services/search_engine.dart';
import 'package:aldhakereen/ui/navigation/app_navigation_controller.dart';
import 'package:aldhakereen/ui/dynamic_list/dynamic_list_section.dart';
import 'package:aldhakereen/ui/tabs/tabbed_section.dart';
import 'package:aldhakereen/ui/home/home_section.dart';
import 'package:aldhakereen/sections/favorites_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('tabs are roots; details return to their origin; Android back goes home',
      () {
    final nav = AppNavigationController();
    addTearDown(nav.dispose);
    expect(nav.canGoBack, isFalse);
    nav.selectTab(1);
    expect(nav.currentSection, 'quran');
    expect(nav.isDetail, isFalse);
    nav.navigateTo('settings');
    expect(nav.isDetail, isTrue);
    nav.goBack();
    expect(nav.currentSection, 'quran');
    nav.goBack();
    expect(nav.currentSection, 'home');
    nav.navigateTo('adhkar');
    expect(nav.selectedIndex, 2);
    nav.navigateTo('duas');
    nav.navigateTo('favorites');
    expect(nav.isDetail, isFalse);
    expect(nav.selectedIndex, 3);
    nav.goBack();
    expect(nav.canGoBack, isFalse);
  });

  testWidgets(
      'real shell switches Quran, adhkar, favorites, home and drawer roots',
      (tester) async {
    await initializeDateFormatting('ar_SA');
    SharedPreferences.setMockInitialValues({});
    DataManager.setDB({
      'sections': {
        'quran': {'title': 'القرآن الكريم'},
        'adhkar': {'title': 'الأذكار'},
      },
      'content': {
        'quran': [
          {'id': 112, 'title': 'سورة الإخلاص', 'content': 'قل هو الله أحد'}
        ],
        'adhkar_munajat': [
          {'id': 1, 'title': 'مناجاة للاختبار', 'content': 'ذكر'}
        ],
      },
    });
    DataManager.httpClient = MockClient((_) async => http.Response('', 304));
    addTearDown(() {
      DataManager.httpClient?.close();
      DataManager.httpClient = null;
    });
    // Pre-initialize the actual index outside fake-async; no network/SQLite is
    // required for this shell integration test (CMS fallback is exercised).
    await tester.runAsync(() => SearchEngine.instance.init(force: true));
    final settings = SettingsProvider();
    await settings.loadSettings();
    addTearDown(settings.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: const MaterialApp(
        locale: Locale('ar', 'SA'),
        supportedLocales: [Locale('ar', 'SA')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MainScaffold(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeSection), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-quran')));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);
    expect(
        tester
            .widget<DynamicListSection>(find.byType(DynamicListSection))
            .sectionKey,
        'quran');
    expect(find.bySemanticsLabel('الإخلاص'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('nav-adhkar')));
    await tester.pumpAndSettle();
    expect(tester.widget<TabbedSection>(find.byType(TabbedSection)).sectionKeys,
        ['adhkar_munajat', 'adhkar_tasbihs']);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2);
    await tester.tap(find.byKey(const ValueKey('nav-favorites')));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesSection), findsOneWidget);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeSection), findsOneWidget);
    // Opening a bottom-tab destination through the drawer keeps the bar and
    // selects the same tab, rather than incorrectly creating a detail page.
    await tester.tap(find.byTooltip('القائمة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('drawer-quran')).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('drawer-quran')));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);
    await tester.tap(find.byTooltip('القائمة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);
    expect(
        tester.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen,
        isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
