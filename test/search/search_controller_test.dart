import 'dart:async';

import 'package:aldhakereen/search/controllers/search_controller.dart' as app;
import 'package:aldhakereen/search/models/search_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dua = ContentItem(
    id: 'dua-1', title: 'دعاء', subtitle: '', content: 'دعاء',
    sectionId: 'dua', sectionName: 'الأدعية',
  );
  const amal = ContentItem(
    id: 'amal-1', title: 'عمل', subtitle: '', content: 'عمل',
    sectionId: 'amal', sectionName: 'الأعمال',
  );

  test('late results from another category cannot replace current results', () async {
    final oldRequest = Completer<List<ContentItem>>();
    final newRequest = Completer<List<ContentItem>>();
    final started = Completer<void>();
    final controller = app.SearchController(
      allItems: [dua, amal],
      availableSections: ['dua', 'amal'],
      searchQuran: (_) async => [],
      searchMafatih: (_) async => [],
      searchMemory: (items, query) {
        if (items.length == 2) {
          if (!started.isCompleted) started.complete();
          return oldRequest.future;
        }
        return newRequest.future;
      },
    );
    addTearDown(controller.dispose);

    controller.updateQuery('دعاء');
    await started.future.timeout(const Duration(seconds: 2));
    controller.selectCategory('dua');
    newRequest.complete([dua]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controller.filteredItems.map((e) => e.id), ['dua-1']);

    oldRequest.complete([amal]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controller.filteredItems.map((e) => e.id), ['dua-1']);
    expect(controller.selectedCategory, 'dua');
  });

  test('a failed source retains other results and reports partial coverage', () async {
    final controller = app.SearchController(
      allItems: [dua],
      availableSections: ['dua'],
      searchQuran: (_) async => throw StateError('database unavailable'),
      searchMafatih: (_) async => [],
      searchMemory: (items, query) async => [dua],
    );
    addTearDown(controller.dispose);
    controller.updateQuery('دعاء');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(controller.filteredItems.map((item) => item.id), ['dua-1']);
    expect(controller.warning, contains('القرآن'));
  });
}
