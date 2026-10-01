import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/providers/settings_provider.dart';
import 'package:aldhakereen/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('new installs use dark mode and worship-card green by default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    DataManager.setDB(<String, dynamic>{
      'sections': <String, dynamic>{},
      'content': <String, dynamic>{},
      // White was the previous implicit card default and should migrate.
      'settings': <String, dynamic>{'card_color': '0xFFFFFFFF'},
    });

    final settings = SettingsProvider();
    addTearDown(() {
      settings.dispose();
      DataManager.setDB(null);
    });
    await settings.loadSettings();

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.cardColor, AppPalette.forest);
    expect(AppPalette.forest.toARGB32(), 0xFF123C32);
  });
}
