import 'package:flutter_test/flutter_test.dart';
import 'package:aldhakereen/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AlDhakereenApp());
    expect(find.text('الذاكرين'), findsOneWidget);
  });
}
