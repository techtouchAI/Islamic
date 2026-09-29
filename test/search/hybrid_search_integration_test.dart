import 'package:aldhakereen/search/models/search_models.dart';
import 'package:aldhakereen/search/repositories/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration coverage for the hybrid search engine: SQL-shaped sources
/// (Quran/Mafatih loaders mirroring the SQLite paged queries) merged with
/// the REAL isolate-based JSON scorer, unified ranking and lazy batching.
void main() {
  ContentItem contentItem(String id, String title) => ContentItem(
        id: id,
        title: title,
        subtitle: '',
        content: 'محتوى $title',
        sectionId: 'dua',
        sectionName: 'الأدعية',
        category: 'dua',
      );

  Map<String, dynamic> ayah(int sid, int anum, String text, String surah) => {
        'surah_number': sid,
        'ayah_number': anum,
        'surah_name': surah,
        'ayah_text': text,
      };

  test('merges SQL rows and JSON hits under a single relevance order', () async {
    final repo = HybridSearchRepository(
      // Mirrors QuranService.searchVersesPaged returning one ayah.
      searchQuran: (query, limit, offset) async =>
          [ayah(1, 1, 'بسم الله الرحمن الرحيم', 'الفاتحة')],
      searchMafatih: (query, limit, offset) async => [],
      // Content source stays the REAL isolate scorer (default).
    );

    final state = await repo.search(
      query: 'رحمن',
      category: 'all',
      contentItems: [contentItem('json-1', 'رحمن')],
    );

    expect(state, isA<SearchSuccess>());
    final success = state as SearchSuccess;
    final items = success.items;
    expect(items, hasLength(2));
    // Exact title match (JSON) outranks the ayah that merely contains the
    // word in its text — one ranking rule for every source.
    expect(items.first.id, 'json-1');
    expect(items.last.id, '1_1');
    expect(success.hasMore, isFalse);
  });

  test('lazy-loads 20-item batches from SQL and JSON until both are exhausted',
      () async {
    const totalQuran = 25;
    const totalContent = 45;
    final sqlCursors = <String>[];

    final repo = HybridSearchRepository(
      batchSize: 20,
      searchQuran: (query, limit, offset) async {
        sqlCursors.add('limit=$limit offset=$offset');
        final remaining = totalQuran - offset;
        if (remaining <= 0) return [];
        final take = remaining < limit ? remaining : limit;
        return [
          for (var i = 0; i < take; i++)
            ayah(2, offset + i + 1, 'ذكر في الآية ${offset + i + 1}',
                'البقرة'),
        ];
      },
      searchMafatih: (query, limit, offset) async => [],
    );

    final contentItems = [
      for (var i = 1; i <= totalContent; i++) contentItem('c-$i', 'ذكر رقم $i'),
    ];

    var state = await repo.search(
      query: 'ذكر',
      category: 'all',
      contentItems: contentItems,
    );
    expect(state, isA<SearchSuccess>());
    var success = state as SearchSuccess;
    // First batch: 20 ayahs + 20 JSON hits, merged.
    expect(success.items, hasLength(40));
    expect(success.items.where((e) => e.id.startsWith('c-')), hasLength(20));
    expect(success.hasMore, isTrue);

    state = await repo.loadMore(contentItems: contentItems);
    success = state as SearchSuccess;
    // Second batch: remaining 5 ayahs + 20 JSON hits.
    expect(success.items, hasLength(65));
    expect(success.hasMore, isTrue);

    state = await repo.loadMore(contentItems: contentItems);
    success = state as SearchSuccess;
    // Final batch: last 5 JSON hits — everything exhausted.
    expect(success.items, hasLength(70));
    expect(success.hasMore, isFalse);

    // SQL cursors advanced by exactly one batch each call.
    expect(sqlCursors, ['limit=20 offset=0', 'limit=20 offset=20']);
  });

  test('a failing SQL source keeps JSON results and stays retryable',
      () async {
    var sqlFails = true;
    final repo = HybridSearchRepository(
      searchQuran: (query, limit, offset) async {
        if (sqlFails) throw StateError('database unavailable');
        return [ayah(1, 1, 'بسم الله الرحمن الرحيم', 'الفاتحة')];
      },
      searchMafatih: (query, limit, offset) async => [],
    );

    var state = await repo.search(
      query: 'رحمن',
      category: 'all',
      contentItems: [contentItem('json-1', 'رحمن')],
    );
    expect(state, isA<SearchSuccess>());
    var success = state as SearchSuccess;
    expect(success.failedSources, contains(SearchSource.quran));
    expect(success.items.single.id, 'json-1');

    // Retry (a fresh search) succeeds once the source recovers.
    sqlFails = false;
    state = await repo.search(
      query: 'رحمن',
      category: 'all',
      contentItems: [contentItem('json-1', 'رحمن')],
    );
    success = state as SearchSuccess;
    expect(success.failedSources, isEmpty);
    expect(success.items, hasLength(2));
  });
}
