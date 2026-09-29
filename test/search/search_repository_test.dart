import 'package:aldhakereen/search/models/search_models.dart';
import 'package:aldhakereen/search/repositories/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dua = ContentItem(
    id: 'dua-1',
    title: 'دعاء',
    subtitle: '',
    content: 'محتوى',
    sectionId: 'dua',
    sectionName: 'الأدعية',
  );

  Map<String, dynamic> ayah(int sid, int anum) => {
    'surah_number': sid,
    'ayah_number': anum,
    'surah_name': 'الفاتحة',
    'ayah_text': 'بسم الله الرحمن الرحيم',
  };

  test('no matches resolves to SearchEmpty', () async {
    final repo = HybridSearchRepository(
      searchQuran: (query, limit, offset) async => [],
      searchMafatih: (query, limit, offset) async => [],
      searchContent: (items, query, limit, offset) async =>
          const ContentSearchPage(items: [], totalMatches: 0),
    );
    final state = await repo.search(
      query: 'غير موجود',
      category: 'all',
      contentItems: [dua],
    );
    expect(state, isA<SearchEmpty>());
  });

  test(
    'all sources failing resolves to SearchError with failed sources',
    () async {
      final repo = HybridSearchRepository(
        searchQuran: (query, limit, offset) async => throw StateError('db'),
        searchMafatih: (query, limit, offset) async => throw StateError('db'),
        searchContent: (items, query, limit, offset) async =>
            throw StateError('boom'),
      );
      final state = await repo.search(
        query: 'دعاء',
        category: 'all',
        contentItems: [dua],
      );
      expect(state, isA<SearchError>());
      final error = state as SearchError;
      expect(
        error.failedSources,
        containsAll([
          SearchSource.quran,
          SearchSource.mafatih,
          SearchSource.content,
        ]),
      );
    },
  );

  test(
    'partial failure keeps successful results and reports the source',
    () async {
      final repo = HybridSearchRepository(
        searchQuran: (query, limit, offset) async => throw StateError('db'),
        searchMafatih: (query, limit, offset) async => [],
        searchContent: (items, query, limit, offset) async =>
            const ContentSearchPage(items: [dua], totalMatches: 1),
      );
      final state = await repo.search(
        query: 'دعاء',
        category: 'all',
        contentItems: [dua],
      );
      expect(state, isA<SearchSuccess>());
      final success = state as SearchSuccess;
      expect(success.items.single.id, 'dua-1');
      expect(success.failedSources, contains(SearchSource.quran));
    },
  );

  test('loadMore fetches the next SQL batch through LIMIT/OFFSET', () async {
    final requestedCursors = <String>[];
    final repo = HybridSearchRepository(
      batchSize: 2,
      searchQuran: (query, limit, offset) async {
        requestedCursors.add('limit=$limit offset=$offset');
        final all = [ayah(1, 1), ayah(1, 2), ayah(1, 3)];
        final window = (offset >= all.length)
            ? <Map<String, dynamic>>[]
            : all.sublist(
                offset,
                offset + limit > all.length ? all.length : offset + limit,
              );
        return window;
      },
      searchMafatih: (query, limit, offset) async => [],
      searchContent: (items, query, limit, offset) async =>
          const ContentSearchPage(items: [], totalMatches: 0),
    );

    final first = await repo.search(
      query: 'بسم',
      category: 'quran',
      contentItems: const [],
    );
    expect(first, isA<SearchSuccess>());
    final firstSuccess = first as SearchSuccess;
    expect(firstSuccess.hasMore, isTrue);
    expect(firstSuccess.items.length, 2);
    expect(requestedCursors, ['limit=2 offset=0']);

    final second = await repo.loadMore(contentItems: const []);
    expect(second, isA<SearchSuccess>());
    final success = second as SearchSuccess;
    expect(success.items.length, 3);
    expect(success.hasMore, isFalse);
    expect(requestedCursors, ['limit=2 offset=0', 'limit=2 offset=2']);

    final third = await repo.loadMore(contentItems: const []);
    expect(third, isA<SearchSuccess>()); // no further fetch once exhausted
    expect(requestedCursors.length, 2);
  });

  test(
    'web-style SQLite absence (empty sources) falls back gracefully',
    () async {
      // Mirrors the kIsWeb behavior of QuranService/MafatihService: sources
      // return empty batches instead of throwing native SQL errors.
      final repo = HybridSearchRepository(
        searchQuran: (query, limit, offset) async => [],
        searchMafatih: (query, limit, offset) async => [],
        searchContent: (items, query, limit, offset) async =>
            const ContentSearchPage(items: [dua], totalMatches: 1),
      );
      final state = await repo.search(
        query: 'دعاء',
        category: 'all',
        contentItems: [dua],
      );
      expect(state, isA<SearchSuccess>());
      expect((state as SearchSuccess).failedSources, isEmpty);
    },
  );

  test('reset discards the active session', () async {
    final repo = HybridSearchRepository(
      searchQuran: (query, limit, offset) async => [],
      searchMafatih: (query, limit, offset) async => [],
      searchContent: (items, query, limit, offset) async =>
          const ContentSearchPage(items: [dua], totalMatches: 1),
    );
    await repo.search(query: 'دعاء', category: 'all', contentItems: [dua]);
    expect(repo.hasMore, isFalse);
    repo.reset();
    expect(repo.hasMore, isFalse);
    final state = await repo.loadMore(contentItems: const []);
    expect(state, isA<SearchEmpty>());
  });
}
