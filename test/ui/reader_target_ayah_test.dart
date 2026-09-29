import 'package:aldhakereen/ui/reader/reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  List<Map<String, dynamic>> ayahs(int count) => [
    for (var i = 1; i <= count; i++)
      {'ar_text': 'الآية رقم $i', 'anum': i, 'ayah_surah_index': '$i'},
  ];

  Widget buildPage({int? targetAyahNumber}) => MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: ReaderPage(
        title: 'البقرة',
        content: '',
        fontSizeFactor: 1.0,
        isQuran: true,
        surahName: 'البقرة',
        surahId: 3,
        ayahs: ayahs(60),
        targetAyahNumber: targetAyahNumber,
      ),
    ),
  );

  testWidgets('scrolls to the searched ayah and highlights it', (tester) async {
    await tester.pumpWidget(buildPage(targetAyahNumber: 40));

    // Frame 1: the target is highlighted but still far below the viewport —
    // scrolling has not run yet (it waits for the surah frame to decode).
    expect(find.byKey(ReaderPage.targetAyahHighlightKey), findsOneWidget);
    final before = tester.getRect(find.text('﴿٤٠﴾'));
    expect(
      before.top,
      greaterThan(600),
      reason: 'target must start off-screen',
    );

    // Let the precache gate expire, settle the final layout, then run the
    // ensureVisible animation to completion.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final after = tester.getRect(find.text('﴿٤٠﴾'));
    expect(after.top, greaterThanOrEqualTo(0));
    expect(after.bottom, lessThan(600));
    expect(find.byKey(ReaderPage.targetAyahHighlightKey), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no highlight when opened without a target ayah', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(ReaderPage.targetAyahHighlightKey), findsNothing);
    // Reader still renders the ayah list normally.
    expect(find.text('﴿١﴾'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
