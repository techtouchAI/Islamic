import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/providers/settings_provider.dart';
import 'package:aldhakereen/theme/app_theme.dart';
import 'package:aldhakereen/ui/widgets/theme_mode_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the shared app-bar action toggles and persists the theme',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DataManager.setDB(<String, dynamic>{
      'sections': <String, dynamic>{},
      'content': <String, dynamic>{},
      'settings': <String, dynamic>{},
    });
    final settings = SettingsProvider();
    await settings.loadSettings();
    addTearDown(() {
      settings.dispose();
      DataManager.setDB(null);
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: Consumer<SettingsProvider>(
          builder: (context, currentSettings, _) => MaterialApp(
            theme: AppTheme.build(
              brightness: Brightness.light,
              primary: currentSettings.primaryColor,
              card: currentSettings.cardColor,
            ),
            darkTheme: AppTheme.build(
              brightness: Brightness.dark,
              primary: currentSettings.primaryColor,
              card: currentSettings.cardColor,
            ),
            themeMode: currentSettings.themeMode,
            home: const Scaffold(
              appBar: AppBar(actions: [ThemeModeActionButton()]),
              body: Center(child: Text('الصفحة')),
            ),
          ),
        ),
      ),
    );

    expect(settings.themeMode, ThemeMode.dark);
    expect(find.byTooltip('التبديل إلى الوضع النهاري'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byKey(const ValueKey('theme-mode-toggle')));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.light);
    expect(find.byTooltip('التبديل إلى الوضع الليلي'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme'), 'light');
    expect(tester.takeException(), isNull);
  });
}
