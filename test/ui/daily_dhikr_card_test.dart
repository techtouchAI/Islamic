import 'package:aldhakereen/ui/home/widgets/daily_dhikr_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('rapid taps persist and restore without changing tasbih state',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tasbih_zahra_count': 17});
    Widget app() => const MaterialApp(home: Scaffold(body: DailyDhikrCard()));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('daily-dhikr-increment')));
    }
    await tester.pumpAndSettle();
    expect(find.text('تسبيح · ٤ / ١٠٠'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('home_daily_dhikr'), endsWith('|4'));
    expect(prefs.getInt('tasbih_zahra_count'), 17);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('تسبيح · ٤ / ١٠٠'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('old day resets and malformed count is bounded', (tester) async {
    SharedPreferences.setMockInitialValues({'home_daily_dhikr': '2000-1-1|99'});
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: DailyDhikrCard())));
    await tester.pumpAndSettle();
    expect(find.text('تسبيح · ٠ / ١٠٠'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
