import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/sections/html_content_renderer.dart';

void main() {
  testWidgets('Test HtmlContentRenderer paragraph tap', (WidgetTester tester) async {
    int tappedIndex = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HtmlContentRenderer(
          content: 'Paragraph 1\n\nParagraph 2',
          baseStyle: const TextStyle(fontSize: 16),
          onParagraphTapped: (index) {
            tappedIndex = index;
          },
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // The text is probably in a RichText. Let's find it.
    final richText = find.byType(RichText).first;

    // Tap Paragraph 1
    await tester.tap(richText);
    await tester.pumpAndSettle();

    print('tappedIndex: $tappedIndex');
  });
}
