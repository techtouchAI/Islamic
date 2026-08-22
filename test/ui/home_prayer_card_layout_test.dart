import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/providers/settings_provider.dart';
import 'package:aldhakereen/ui/home/home_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initializeDateFormatting('ar_SA');
    SharedPreferences.setMockInitialValues(<String, Object>{
      'vis_inspiration': false,
      'vis_day_dua': false,
    });
    DataManager.setDB(<String, dynamic>{'content': <String, dynamic>{}});
  });

  testWidgets('prayer card remains within a narrow phone viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settingsProvider,
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: HomeSection()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsWidgets);
  });
}
