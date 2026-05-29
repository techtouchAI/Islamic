import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aldhakereen/main.dart';
import 'package:aldhakereen/providers/settings_provider.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const AlDhakereenApp(),
      ),
    );
    // Initially shows loading or splash
    // Just expect finding the app
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
