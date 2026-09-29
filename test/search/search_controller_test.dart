import 'dart:async';

import 'package:aldhakereen/search/controllers/search_controller.dart' as app;
import 'package:aldhakereen/search/models/search_models.dart';
import 'package:aldhakereen/search/repositories/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dua = ContentItem(
    id: 'dua-1',
    title: 'دعاء',
    subtitle: '',
    content: 'دعاء',
    sectionId: 'dua',
    sectionName: 'الأدعية',
  );
  const amal = ContentItem(
    id: 'amal-1',
    title: 'عمل',
    subtitle: '',
    content: 'عمل',
    sectionId: 'amal',
    sectionName: 'الأعمال',
  );

  test(
    'late results from another category cannot replace current results',
    () async {
      final oldRequest = Completer<ContentSearchPage>();
      final newRequest = Completer<ContentSearchPage>();
      final started = Completer<void>();
      final repository = HybridSearchRepository(
        searchQuran: (query, limit, offset) async => [],
        searchMafatih: (query, limit, offset) async => [],
        searchContent: (items, query, limit, offset) {
          if (items.length == 2) {
            if (!started.isCompleted) started.complete();
            return oldRequest.future;
          }
          return newRequest.future;
        },
      );
      final controller = app.SearchController(
        allItems: [dua, amal],
        availableSections: ['dua', 'amal'],
        repository: repository,
      );
      addTearDown(controller.dispose);

      controller.updateQuery('دعاء');
      await started.future.timeout(const Duration(seconds: 2));
      controller.selectCategory('dua');
      newRequest.complete(
        const ContentSearchPage(items: [dua], totalMatches: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.filteredItems.map((e) => e.id), ['dua-1']);

      oldRequest.complete(
        const ContentSearchPage(items: [amal], totalMatches: 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.filteredItems.map((e) => e.id), ['dua-1']);
      expect(controller.selectedCategory, 'dua');
    },
  );

  test(
    'a failed source retains other results and reports partial coverage',
    () async {
      final repository = HybridSearchRepository(
        searchQuran: (query, limit, offset) async =>
            throw StateError('database unavailable'),
        searchMafatih: (query, limit, offset) async => [],
        searchContent: (items, query, limit, offset) async =>
            const ContentSearchPage(items: [dua], totalMatches: 1),
      );
      final controller = app.SearchController(
        allItems: [dua],
        availableSections: ['dua'],
        repository: repository,
      );
      addTearDown(controller.dispose);
      controller.updateQuery('دعاء');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(controller.filteredItems.map((item) => item.id), ['dua-1']);
      expect(controller.warning, contains('القرآن'));
      expect(controller.state, isA<SearchSuccess>());
      expect(
        (controller.state as SearchSuccess).failedSources,
        contains(SearchSource.quran),
      );
    },
  );

  test('every source failing yields SearchError and retry recovers', () async {
    var shouldFail = true;
    final repository = HybridSearchRepository(
      searchQuran: (query, limit, offset) async => [],
      searchMafatih: (query, limit, offset) async => [],
      searchContent: (items, query, limit, offset) async {
        if (shouldFail) throw StateError('index unavailable');
        return const ContentSearchPage(items: [dua], totalMatches: 1);
      },
    );
    final controller = app.SearchController(
      allItems: [dua],
      availableSections: ['dua'],
      repository: repository,
    );
    addTearDown(controller.dispose);

    controller.updateQuery('دعاء');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(controller.state, isA<SearchError>());
    expect(controller.warning, isNotNull);
    expect(controller.filteredItems, isEmpty);

    shouldFail = false;
    controller.retry();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.state, isA<SearchSuccess>());
    expect(controller.filteredItems.map((e) => e.id), ['dua-1']);
    expect(controller.warning, isNull);
  });

  test('loadMore appends the next batch and keeps unified ordering', () async {
    const batch1 = [
      ContentItem(
        id: 'a-1',
        title: 'دعاء',
        subtitle: '',
        content: 'محتوى أول',
        sectionId: 'dua',
        sectionName: 'الأدعية',
      ),
      ContentItem(
        id: 'a-2',
        title: 'دعاء',
        subtitle: '',
        content: 'محتوى ثانٍ',
        sectionId: 'dua',
        sectionName: 'الأدعية',
      ),
    ];
    const batch2 = [
      ContentItem(
        id: 'a-3',
        title: 'دعاء',
        subtitle: '',
        content: 'محتوى ثالث',
        sectionId: 'dua',
        sectionName: 'الأدعية',
      ),
    ];
    var offsetSeen = 0;
    final repository = HybridSearchRepository(
      batchSize: 2,
      searchQuran: (query, limit, offset) async => [],
      searchMafatih: (query, limit, offset) async => [],
      searchContent: (items, query, limit, offset) async {
        offsetSeen = offset;
        if (offset == 0) {
          return const ContentSearchPage(items: batch1, totalMatches: 3);
        }
        return const ContentSearchPage(items: batch2, totalMatches: 3);
      },
    );
    final controller = app.SearchController(
      allItems: const [...batch1, ...batch2],
      availableSections: ['dua'],
      repository: repository,
    );
    addTearDown(controller.dispose);

    controller.updateQuery('دعاء');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(controller.filteredItems.length, 2);
    expect(controller.hasMore, isTrue);

    await controller.loadMore();
    expect(offsetSeen, 2); // OFFSET advanced by exactly one batch
    expect(controller.filteredItems.length, 3);
    expect(controller.hasMore, isFalse);
    expect(
      controller.filteredItems.map((e) => e.id),
      containsAllInOrder(['a-1', 'a-2', 'a-3']),
    );
  });
}
