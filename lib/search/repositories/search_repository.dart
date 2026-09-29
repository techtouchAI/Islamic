import 'package:flutter/foundation.dart';

import '../../models/mafatih_article.dart';
import '../../services/mafatih_service.dart';
import '../../services/quran_service.dart';
import '../../services/search_engine.dart';
import '../../utils/arabic_normalizer.dart';
import '../models/search_models.dart';
import '../search_ranking.dart';

/// Sources that feed the unified search.
enum SearchSource { quran, mafatih, content }

/// Human-readable name used in warnings/retry messages.
String sourceDisplayName(SearchSource source) => switch (source) {
  SearchSource.quran => 'القرآن',
  SearchSource.mafatih => 'مفاتيح الجنان',
  SearchSource.content => 'المحتوى المحلي',
};

/// Strict search state contract. Every repository call resolves to exactly
/// one of these states — consumers must render them consistently:
///
/// * [SearchLoading] -> progress indicator
/// * [SearchSuccess] -> results (check `failedSources` for partial coverage)
/// * [SearchEmpty]   -> "no results" view
/// * [SearchError]   -> error view with a Retry action
sealed class SearchState {
  const SearchState();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchEmpty extends SearchState {
  const SearchEmpty();
}

final class SearchSuccess extends SearchState {
  /// The full merged list loaded so far, sorted by unified relevance.
  final List<ContentItem> items;

  /// True while at least one source may still have un-fetched batches.
  final bool hasMore;

  /// Sources that failed for this batch (partial results -> Retry).
  final Set<SearchSource> failedSources;

  const SearchSuccess({
    required this.items,
    required this.hasMore,
    this.failedSources = const {},
  });
}

final class SearchError extends SearchState {
  final String message;
  final Set<SearchSource> failedSources;

  const SearchError({required this.message, this.failedSources = const {}});
}

/// One `LIMIT`/`OFFSET` window of JSON (in-memory) search results.
class ContentSearchPage {
  final List<ContentItem> items;
  final int totalMatches;

  const ContentSearchPage({required this.items, required this.totalMatches});
}

typedef QuranPageLoader = Future<List<Map<String, dynamic>>> Function(
  String query,
  int limit,
  int offset,
);
typedef MafatihPageLoader = Future<List<MafatihArticle>> Function(
  String query,
  int limit,
  int offset,
);
typedef ContentPageLoader = Future<ContentSearchPage> Function(
  List<ContentItem> items,
  String query,
  int limit,
  int offset,
);

/// Strict interface every search consumer depends on.
abstract class SearchRepository {
  const SearchRepository();

  /// Whether more batches can still be fetched for the active session.
  bool get hasMore;

  /// Starts a fresh search session for [query]/[category].
  Future<SearchState> search({
    required String query,
    required String category,
    required List<ContentItem> contentItems,
  });

  /// Fetches the next batch (20 items by default) from every source that
  /// still has pending results and returns the merged state.
  Future<SearchState> loadMore({required List<ContentItem> contentItems});

  /// Discards the active session.
  void reset();
}

/// Default implementation merging Quran (SQLite), Mafatih (SQLite) and
/// JSON content with unified relevance sorting and lazy batch loading.
///
/// Web handling: SQLite sources are skipped entirely on web (`kIsWeb`), so
/// the build gracefully falls back to whatever the JSON source provides
/// instead of surfacing native SQL errors.
class HybridSearchRepository extends SearchRepository {
  static const int defaultBatchSize = 20;

  final QuranPageLoader _searchQuran;
  final MafatihPageLoader _searchMafatih;
  final ContentPageLoader _searchContent;
  final int batchSize;

  HybridSearchRepository({
    QuranPageLoader? searchQuran,
    MafatihPageLoader? searchMafatih,
    ContentPageLoader? searchContent,
    this.batchSize = defaultBatchSize,
  }) : _searchQuran =
           searchQuran ??
           ((q, l, o) =>
               QuranService.searchVersesPaged(q, limit: l, offset: o)),
       _searchMafatih =
           searchMafatih ??
           ((q, l, o) =>
               MafatihService.searchArticlesPaged(q, limit: l, offset: o)),
       _searchContent = searchContent ?? searchContentInIsolate;

  // ─── Session state ───
  String _query = '';
  List<ContentItem> _sessionContentItems = const [];
  bool _sessionActive = false;

  /// Invalidates in-flight batches when a new session starts.
  int _sessionToken = 0;

  final List<ContentItem> _quranItems = [];
  final List<ContentItem> _mafatihItems = [];
  final List<ContentItem> _contentResults = [];
  int _quranOffset = 0;
  int _mafatihOffset = 0;
  int _contentOffset = 0;
  bool _quranDone = true;
  bool _mafatihDone = true;
  bool _contentDone = true;

  @override
  bool get hasMore =>
      _sessionActive && (!_quranDone || !_mafatihDone || !_contentDone);

  @override
  void reset() {
    _sessionToken++;
    _sessionActive = false;
    _query = '';
    _sessionContentItems = const [];
    _quranItems.clear();
    _mafatihItems.clear();
    _contentResults.clear();
    _quranOffset = _mafatihOffset = _contentOffset = 0;
    _quranDone = _mafatihDone = _contentDone = true;
  }

  @override
  Future<SearchState> search({
    required String query,
    required String category,
    required List<ContentItem> contentItems,
  }) async {
    reset();
    _query = query.trim();
    _sessionContentItems = contentItems;
    if (_query.isEmpty) return const SearchEmpty();

    _sessionActive = true;

    // Phase 6: SQLite sources are disabled on web — graceful empty fallback,
    // never a native SQL error.
    final bool wantQuran =
        !kIsWeb && (category == 'all' || category == 'quran');
    final bool wantMafatih =
        !kIsWeb && (category == 'all' || category == 'mafatih');
    _quranDone = !wantQuran;
    _mafatihDone = !wantMafatih;
    _contentDone = contentItems.isEmpty;
    _quranOffset = _mafatihOffset = _contentOffset = 0;
    _quranItems.clear();
    _mafatihItems.clear();
    _contentResults.clear();

    final token = _sessionToken;
    final failed = <SearchSource>{};
    await Future.wait<void>([
      if (!_quranDone) _loadQuranBatch(failed, token),
      if (!_mafatihDone) _loadMafatihBatch(failed, token),
      if (!_contentDone) _loadContentBatch(failed, token),
    ]);
    if (token != _sessionToken) return const SearchLoading();
    return _buildState(failed);
  }

  @override
  Future<SearchState> loadMore({
    required List<ContentItem> contentItems,
  }) async {
    if (!_sessionActive) return const SearchEmpty();
    if (!hasMore) return _buildState(const <SearchSource>{});
    _sessionContentItems = contentItems;

    final token = _sessionToken;
    final failed = <SearchSource>{};
    await Future.wait<void>([
      if (!_quranDone) _loadQuranBatch(failed, token),
      if (!_mafatihDone) _loadMafatihBatch(failed, token),
      if (!_contentDone) _loadContentBatch(failed, token),
    ]);
    if (token != _sessionToken) return const SearchLoading();
    return _buildState(failed);
  }

  // ─── Per-source batch loaders (LIMIT/OFFSET cursors) ───

  Future<void> _loadQuranBatch(Set<SearchSource> failed, int token) async {
    try {
      final rows = await _searchQuran(_query, batchSize, _quranOffset);
      if (token != _sessionToken) return;
      _quranOffset += rows.length;
      if (rows.length < batchSize) _quranDone = true;
      _quranItems.addAll(rows.map(_mapQuranRow));
    } catch (e) {
      if (token != _sessionToken) return;
      debugPrint('Quran paged search failed: $e');
      failed.add(SearchSource.quran);
    }
  }

  Future<void> _loadMafatihBatch(Set<SearchSource> failed, int token) async {
    try {
      final articles = await _searchMafatih(_query, batchSize, _mafatihOffset);
      if (token != _sessionToken) return;
      _mafatihOffset += articles.length;
      if (articles.length < batchSize) _mafatihDone = true;
      _mafatihItems.addAll(articles.map(_mapMafatihArticle));
    } catch (e) {
      if (token != _sessionToken) return;
      debugPrint('Mafatih paged search failed: $e');
      failed.add(SearchSource.mafatih);
    }
  }

  Future<void> _loadContentBatch(Set<SearchSource> failed, int token) async {
    try {
      final page = await _searchContent(
        _sessionContentItems,
        _query,
        batchSize,
        _contentOffset,
      );
      if (token != _sessionToken) return;
      _contentOffset += page.items.length;
      if (_contentOffset >= page.totalMatches) _contentDone = true;
      _contentResults.addAll(page.items);
    } catch (e) {
      if (token != _sessionToken) return;
      debugPrint('Content paged search failed: $e');
      failed.add(SearchSource.content);
    }
  }

  // ─── Unified merged state ───

  SearchState _buildState(Set<SearchSource> failed) {
    final normalizedQuery = ArabicNormalizer.normalize(_query);
    final merged = <ContentItem>[
      ..._quranItems,
      ..._mafatihItems,
      ..._contentResults,
    ]..sort((a, b) => SearchRanking.compareNormalized(a, b, normalizedQuery));

    if (failed.isEmpty) {
      return merged.isEmpty
          ? const SearchEmpty()
          : SearchSuccess(items: merged, hasMore: hasMore);
    }
    if (merged.isEmpty) {
      return SearchError(
        message: 'تعذر إكمال البحث. يرجى المحاولة مجددًا.',
        failedSources: failed,
      );
    }
    // Partial coverage: keep results, expose failures so the UI can show
    // a consistent Retry action.
    return SearchSuccess(
      items: merged,
      hasMore: hasMore,
      failedSources: failed,
    );
  }

  // ─── Row mapping ───

  static ContentItem _mapQuranRow(Map<String, dynamic> ayah) {
    final dynamic ayahNumber = ayah['ayah_number'];
    return ContentItem(
      id: '${ayah['surah_number']}_$ayahNumber',
      title: 'سورة ${ayah['surah_name']} - آية $ayahNumber',
      subtitle: 'القرآن الكريم',
      content: ayah['ayah_text'].toString(),
      sectionId: 'quran',
      sectionName: 'القرآن الكريم',
      category: 'quran',
      surahNumber: ayah['surah_number'] is int
          ? ayah['surah_number'] as int
          : int.tryParse('${ayah['surah_number']}'),
      ayahNumber: ayahNumber is int
          ? ayahNumber
          : int.tryParse(ayahNumber?.toString() ?? ''),
      type: 'quran',
    );
  }

  static ContentItem _mapMafatihArticle(MafatihArticle article) => ContentItem(
    id: 'mafatih_${article.id}',
    title: article.title,
    subtitle: 'مفاتيح الجنان',
    content: article.text,
    sectionId: 'mafatih',
    sectionName: 'مفاتيح الجنان',
    category: 'mafatih',
  );

  // ─── Default JSON source: isolate scoring with LIMIT/OFFSET ───

  static Future<ContentSearchPage> searchContentInIsolate(
    List<ContentItem> items,
    String query,
    int limit,
    int offset,
  ) => compute(_performContentSearch, {
    'items': items,
    'query': query,
    'limit': limit,
    'offset': offset,
  });

  /// Scores every candidate with the single [ArabicNormalizer], keeps items
  /// matching ALL query words (or the full phrase), sorts deterministically
  /// and then applies `LIMIT`/`OFFSET`.
  static ContentSearchPage _performContentSearch(Map<String, dynamic> params) {
    final List<ContentItem> items = params['items'];
    final String query = params['query'];
    final int limit = params['limit'];
    final int offset = params['offset'];

    final normalizedQuery = ArabicNormalizer.normalize(query);
    final queryWords = normalizedQuery
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    if (queryWords.isEmpty || items.isEmpty) {
      return const ContentSearchPage(items: [], totalMatches: 0);
    }

    final scored = <Map<String, dynamic>>[];

    for (final item in items) {
      bool allWordsMatched = true;
      int docScore = 0;

      final normalizedTitle =
          item.normalizedTitle ?? ArabicNormalizer.normalize(item.title);
      final normalizedContent =
          item.normalizedContent ?? ArabicNormalizer.normalize(item.content);
      final normalizedCategory =
          item.normalizedCategory ??
          ArabicNormalizer.normalize(item.category ?? '');

      // Tokenize strings once per document.
      final titleWords = normalizedTitle.split(' ').toSet();
      final contentWords = normalizedContent.split(' ').toSet();
      final categoryWords = normalizedCategory.split(' ').toSet();

      for (final word in queryWords) {
        bool wordMatched = false;
        int wordScore = 0;

        // Title matching.
        if (normalizedTitle == word) {
          wordMatched = true;
          wordScore += 20; // Exact match bonus
        } else if (titleWords.contains(word)) {
          wordMatched = true;
          wordScore += 10;
        }

        // Category matching.
        if (normalizedCategory == word || categoryWords.contains(word)) {
          wordMatched = true;
          wordScore += 4;
        }

        // Content matching.
        if (normalizedContent == word) {
          wordMatched = true;
          wordScore += 5;
        } else if (contentWords.contains(word)) {
          wordMatched = true;
          wordScore += 2;
        } else if (SearchEngine.fuzzyMatchWords(
          word,
          normalizedContent,
          contentWords,
        )) {
          wordMatched = true;
          wordScore += 1;
        }

        if (!wordMatched && word.length >= 4) {
          if (SearchEngine.fuzzyMatchWords(word, normalizedTitle, titleWords)) {
            wordMatched = true;
            wordScore += 6;
          }
        }

        if (!wordMatched) {
          allWordsMatched = false;
          break;
        }

        docScore += wordScore;
      }

      // Full exact phrase matches still qualify even when individual words
      // failed (e.g. phrases containing stop words).
      if (!allWordsMatched) {
        if (normalizedTitle.contains(normalizedQuery)) {
          allWordsMatched = true;
          docScore += 30;
        } else if (normalizedContent.contains(normalizedQuery)) {
          allWordsMatched = true;
          docScore += 5;
        }
      }

      if (allWordsMatched && docScore > 0) {
        scored.add({'item': item, 'score': docScore});
      }
    }

    scored.sort((a, b) {
      final scoreCompare = (b['score'] as int).compareTo(a['score'] as int);
      if (scoreCompare != 0) return scoreCompare;
      return (a['item'] as ContentItem).title.compareTo(
        (b['item'] as ContentItem).title,
      );
    });

    final total = scored.length;
    final start = offset <= 0 ? 0 : (offset > total ? total : offset);
    final requestedEnd = start + (limit <= 0 ? 0 : limit);
    final end = requestedEnd > total ? total : requestedEnd;
    final page = start < end
        ? scored
              .sublist(start, end)
              .map((e) => e['item'] as ContentItem)
              .toList()
        : <ContentItem>[];
    return ContentSearchPage(items: page, totalMatches: total);
  }
}
