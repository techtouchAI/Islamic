import 'package:aldhakereen/ui/reader/reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A payload in the CMS dialect: the `html` marker, paragraphs, bold and a
/// colour span — exactly what the prophets stories are stored as.
const String _payload = 'html <p><c=#ff0000><b> ملخص قصة اليسع</b></c></p>'
    '<p><b>من العبدة الأخيار، كيف يحيي الموتى!!</b></p>';

void main() {
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('the reader renders the payload as prose, never as markup',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_reader(_payload));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final rendered = _renderedText(tester);
    expect(rendered, contains('ملخص قصة اليسع'));
    expect(rendered, contains('من العبدة الأخيار، كيف يحيي الموتى!!'));
    expect(rendered, isNot(contains('<')));
    expect(rendered, isNot(contains('>')));
    // The legacy rewrite of `!` into `(عليه السلام)` is gone with it.
    expect(rendered, isNot(contains('(عليه السلام)')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('copying puts tag-free text on the clipboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_reader(_payload));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.content_copy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final clipboard = calls
        .where((call) => call.method == 'Clipboard.setData')
        .toList(growable: false);
    expect(clipboard, hasLength(1));
    final text = (clipboard.single.arguments as Map)['text'] as String;
    expect(text, contains('ملخص قصة اليسع'));
    expect(text, contains('كيف يحيي الموتى!!'));
    expect(text, isNot(contains('<')));
    expect(text, isNot(contains('>')));
  });
}

Widget _reader(String content) => MaterialApp(
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ReaderPage(
          title: 'اليسع عليه السلام',
          content: content,
          fontSizeFactor: 1,
        ),
      ),
    );

String _renderedText(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((widget) => widget.text.toPlainText())
    .join('\n');
