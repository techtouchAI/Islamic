import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aldhakereen/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AlDhakereenApp());
    // Initially shows loading or splash
    expect(find.text("اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ"), findsOneWidget);
  });
}
