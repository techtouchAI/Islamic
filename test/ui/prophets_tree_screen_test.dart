import 'package:aldhakereen/data/data_manager.dart';
import 'package:aldhakereen/ui/prophets_tree/prophets_tree_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The tree page: one trunk, one branch, one chain — and filters that
/// collapse the page onto the nodes of a single tag.
void main() {
  Map<String, dynamic> node(
    String id,
    String title,
    String type, {
    String badge = '',
    String group = 'trunk',
    String desc = '',
    List<String> tags = const [],
    int? step,
    bool strong = false,
  }) {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'type': type,
      'badge': badge,
      'group': group,
      if (desc.isNotEmpty) 'desc': desc,
      if (step != null) 'step': step,
      if (strong) 'strong': true,
      'tags': tags,
    };
  }

  void seedTree() {
    DataManager.setDB(<String, dynamic>{
      'sections': <String, dynamic>{
        'prophets_tree': <String, dynamic>{'title': 'شجرة الأنبياء والأئمة'},
      },
      'content': <String, dynamic>{
        'prophets_tree': <dynamic>[
          node('adam', 'آدم', 'prophet',
              badge: 'نبي', desc: 'أبو البشر.', tags: ['prophets']),
          node('anush', 'أنوش', 'ancestor',
              badge: 'الخط الأبوي', tags: ['ancestors']),
          node('gap', 'سلسلة عدنان (بين إسماعيل وعدنان اختلاف)', 'gap'),
          node('adnan', 'عدنان', 'quraish',
              badge: 'نسب قريش', tags: ['quraish']),
          node('abdulmuttalib', 'عبد المطلب', 'ancestor',
              badge: 'الجد', tags: ['ancestors']),
          node('abdullah', 'عبد الله', 'ancestor',
              badge: 'والد النبي', group: 'branch_a', tags: ['ancestors']),
          node('muhammad', 'محمد ﷺ', 'prophet',
              badge: 'خاتم الأنبياء',
              group: 'branch_a',
              desc: 'ابن عبد الله.',
              tags: ['prophets', 'ahl_albayt'],
              strong: true),
          node('fatima', 'فاطمة الزهراء عليها السلام', 'lady',
              badge: 'الابنة',
              group: 'branch_a',
              desc: 'ابنة النبي.',
              tags: ['ahl_albayt'],
              strong: true),
          node('abotalib', 'أبو طالب', 'ancestor',
              badge: 'والد الإمام', group: 'branch_b', tags: ['ancestors']),
          node('ali', 'علي بن أبي طالب عليه السلام', 'imam',
              badge: 'الإمام الأول',
              group: 'branch_b',
              desc: 'أول الأئمة.',
              tags: ['imams', 'ahl_albayt'],
              strong: true),
          node('marriage', 'تزوج علي من فاطمة بنت النبي', 'marriage',
              group: 'marriage'),
          node('hasan', 'الحسن بن علي', 'imam',
              badge: 'الإمام الثاني',
              group: 'grid',
              desc: 'الإمام الثاني.',
              tags: ['imams', 'ahl_albayt']),
          node('husayn', 'الحسين بن علي', 'husayn',
              badge: 'الإمام الثالث',
              group: 'grid',
              desc: 'الإمام الثالث.',
              tags: ['imams', 'ahl_albayt']),
          node('zaynalabidin', 'علي بن الحسين زين العابدين', 'imam',
              badge: 'الإمام الرابع',
              group: 'chain',
              desc: 'الإمام الرابع.',
              tags: ['imams'],
              step: 4),
          node('mahdi', 'محمد بن الحسن المهدي', 'mahdi',
              badge: 'الإمام الثاني عشر',
              group: 'chain',
              desc: 'الإمام الثاني عشر.',
              tags: ['imams'],
              step: 12),
          node('sup0', 'نوح', 'supplement',
              group: 'supplement', desc: 'من السابقين قبل إبراهيم.'),
        ],
      },
      'settings': <String, dynamic>{},
    });
  }

  Widget host() {
    return MaterialApp(
      locale: const Locale('ar', 'SA'),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: ProphetsTreeScreen(
          title: 'شجرة الأنبياء والأئمة',
          fontSizeFactor: 1.0,
        ),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    seedTree();
  });

  testWidgets('renders the whole tree on one page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host());
    await tester.pump();

    // Hero, note, trunk, branch, marriage, grid, chain and supplement.
    expect(find.text('شجرة الأنبياء والأئمة'), findsOneWidget);
    expect(find.textContaining('ملاحظة منهجية'), findsOneWidget);
    expect(find.text('آدم'), findsOneWidget);
    expect(find.text('أنوش'), findsOneWidget);
    expect(find.textContaining('سلسلة عدنان'), findsOneWidget);
    expect(find.text('محمد ﷺ'), findsOneWidget);
    expect(find.text('فاطمة الزهراء عليها السلام'), findsOneWidget);
    expect(find.text('علي بن أبي طالب عليه السلام'), findsOneWidget);
    expect(find.text('تزوج علي من فاطمة بنت النبي'), findsOneWidget);
    expect(find.text('الحسن بن علي'), findsOneWidget);
    expect(find.text('الحسين بن علي'), findsOneWidget);

    // The chain carries Eastern Arabic medallions.
    expect(find.text('٤'), findsOneWidget);
    expect(find.text('١٢'), findsOneWidget);

    // The supplement lists the prophetic branches.
    expect(
      find.text(ProphetsTreeScreen.supplementTitle),
      findsOneWidget,
    );
    expect(find.textContaining('من السابقين قبل إبراهيم'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('a filter collapses the page onto its nodes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host());
    await tester.pump();

    // All six filters are offered.
    for (final label in const [
      'الكل',
      'الأنبياء والرسل',
      'الخط الأبوي',
      'نسب قريش',
      'الأئمة الاثنا عشر',
      'أهل البيت',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('الأنبياء والرسل'));
    await tester.pumpAndSettle();

    // Only prophets remain: the ancestors, the branch drawing, the marriage
    // label, the medallions and the supplement all step aside.
    expect(find.text('آدم'), findsOneWidget);
    expect(find.text('محمد ﷺ'), findsOneWidget);
    expect(find.text('أنوش'), findsNothing);
    expect(find.text('عدنان'), findsNothing);
    expect(find.text('تزوج علي من فاطمة بنت النبي'), findsNothing);
    expect(find.text('٤'), findsNothing);
    expect(find.text(ProphetsTreeScreen.supplementTitle), findsNothing);

    // The imams filter reaches the chain, including the Mahdi.
    await tester.tap(find.text('الأئمة الاثنا عشر'));
    await tester.pumpAndSettle();
    expect(find.text('علي بن أبي طالب عليه السلام'), findsOneWidget);
    expect(find.text('محمد بن الحسن المهدي'), findsOneWidget);
    expect(find.text('آدم'), findsNothing);

    // The show-everything chip restores the full tree.
    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    expect(find.text('أنوش'), findsOneWidget);
    expect(find.text('تزوج علي من فاطمة بنت النبي'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the people of the house filter gathers the five of the cloak',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host());
    await tester.pump();

    await tester.tap(find.text('أهل البيت'));
    await tester.pumpAndSettle();

    for (final name in const [
      'محمد ﷺ',
      'فاطمة الزهراء عليها السلام',
      'علي بن أبي طالب عليه السلام',
      'الحسن بن علي',
      'الحسين بن علي',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    // Lineage outside the cloak steps aside.
    expect(find.text('آدم'), findsNothing);
    expect(find.text('أنوش'), findsNothing);
    expect(find.text('محمد بن الحسن المهدي'), findsNothing);
  });

  testWidgets('an empty section leaves the page calm, not broken',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    DataManager.setDB(<String, dynamic>{
      'sections': <String, dynamic>{},
      'content': <String, dynamic>{'prophets_tree': <dynamic>[]},
      'settings': <String, dynamic>{},
    });

    await tester.pumpWidget(host());
    await tester.pump();

    // The chips and the hero are still there; the tree is simply absent.
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('آدم'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
