import 'package:aldhakereen/sections/tasbih_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('completion dialog requires an explicit action to close',
      (tester) async {
    final hapticCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') hapticCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TasbihSection()),
      ),
    );
    await tester.pumpAndSettle();

    final tapLabel = find.text('اضغط');
    expect(tapLabel, findsOneWidget);
    final tapTarget = find.ancestor(of: tapLabel, matching: find.byType(Ink));
    expect(tapTarget, findsOneWidget);
    expect(tester.getSize(tapTarget), const Size(218, 218));

    for (var index = 0; index < 100; index++) {
      await tester.tap(tapLabel);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.text('اكتمل التسبيح'), findsOneWidget);
    expect(find.text('الحمد لله'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    expect(hapticCalls, hasLength(3));
    expect(
      hapticCalls.map((call) => call.arguments),
      <String>[
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.heavyImpact',
      ],
    );
    expect(tester.getRect(find.byType(Dialog)).top, lessThan(180));
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('اكتمل التسبيح'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('اكتمل التسبيح'), findsOneWidget);

    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();
    expect(find.text('اكتمل التسبيح'), findsNothing);
  });
}
