import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/search_models.dart';
import '../repositories/search_repository.dart';
import '../../services/search_engine.dart';

/// Search facade for the UI.
///
/// All queries flow through the strict [SearchRepository] contract
/// ([SearchLoading] / [SearchSuccess] / [SearchEmpty] / [SearchError]) and
/// results are lazily extended in batches of 20 through [loadMore].
class SearchController extends ChangeNotifier {
  // ─── Dependencies ───
  final SearchRepository _repository;
  List<ContentItem> _allItems;
  final List<String> _availableSections;

  // ─── State ───
  String _query = '';
  String _selectedCategory = 'all'; // 'all' = الكل
  SearchState _state = const SearchEmpty();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _indexing = false;

  Timer? _debounceTimer;
  int _requestGeneration = 0;
  bool _disposed = false;

  // ─── Cached Results (all batches loaded so far) ───
  List<ContentItem> _filteredItems = [];
  List<SectionGroup> _groupedItems = [];

  SearchController({
    required List<ContentItem> allItems,
    required List<String> availableSections,
    SearchRepository? repository,
  }) : _allItems = allItems,
       _availableSections = availableSections,
       _repository = repository ?? HybridSearchRepository() {
    SearchEngine.instance.isIndexingNotifier.addListener(
      _onIndexingStateChanged,
    );
    _indexing = SearchEngine.instance.isIndexingNotifier.value;
  }

  void _onIndexingStateChanged() {
    _indexing = SearchEngine.instance.isIndexingNotifier.value;
    notifyListeners();
  }

  @override
  void dispose() {
    SearchEngine.instance.isIndexingNotifier.removeListener(
      _onIndexingStateChanged,
    );
    _debounceTimer?.cancel();
    _disposed = true;
    _requestGeneration++;
    super.dispose();
  }

  // ─── Public Getters ───
  String get query => _query;
  String get selectedCategory => _selectedCategory;
  SearchState get state => _state;
  bool get isLoading => _isLoading || _indexing;
  bool get isLoadingMore => _isLoadingMore;
  bool get indexing => _indexing;
  List<ContentItem> get filteredItems => List.unmodifiable(_filteredItems);
  List<SectionGroup> get groupedItems => List.unmodifiable(_groupedItems);
  List<String> get availableSections => ['all', ..._availableSections];
  bool get isAllCategory => _selectedCategory == 'all';

  /// Number of results loaded so far (batches accumulate lazily).
  int get totalLoaded => _filteredItems.length;

  /// Whether another batch may still be fetched for the current query.
  bool get hasMore =>
      _state is SearchSuccess && (_state as SearchSuccess).hasMore;

  /// Consistent warning contract:
  /// * [SearchError]      -> its message (full failure, Retry required)
  /// * partial [SearchSuccess] -> names of failed sources (Retry required)
  /// * otherwise          -> null
  String? get warning {
    final current = _state;
    if (current is SearchError) return current.message;
    if (current is SearchSuccess && current.failedSources.isNotEmpty) {
      final names = current.failedSources.map(sourceDisplayName).join('، ');
      return 'تعذر البحث في: $names. النتائج جزئية.';
    }
    return null;
  }

  // ─── Actions ───

  void updateQuery(String value) {
    final normalized = value.trim();
    if (_query == normalized) return;
    _query = normalized;
    _requestGeneration++;
    _isLoading = true;
    _isLoadingMore = false;
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _computeResults();
    });
  }

  void replaceItems(List<ContentItem> items) {
    _allItems = items;
    _debounceTimer?.cancel();
    _computeResults();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _requestGeneration++;
    _isLoading = true;
    _isLoadingMore = false;
    notifyListeners();

    _computeResults();
  }

  void retry() {
    _debounceTimer?.cancel();
    _computeResults();
  }

  /// Lazily fetches the next batch (20 results) when the UI list reaches
  /// its bottom. Stale responses from previous queries are discarded.
  Future<void> loadMore() async {
    if (_disposed || _query.isEmpty) return;
    if (_isLoading || _isLoadingMore || _indexing) return;
    if (!hasMore) return;

    final generation = _requestGeneration;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final state = await _repository.loadMore(
        contentItems: _categoryFilteredItems(),
      );
      if (_disposed) return;
      if (generation != _requestGeneration) return;
      _applyState(state);
    } finally {
      // Only the still-current request may release the flag; a superseding
      // query already owns _isLoadingMore/_isLoading at this point.
      if (!_disposed && generation == _requestGeneration) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  // ─── Core Logic ───

  Future<void> _computeResults() async {
    final generation = ++_requestGeneration;
    _isLoading = true;
    _isLoadingMore = false;
    notifyListeners();

    if (_query.trim().isEmpty) {
      _repository.reset();
      _state = const SearchEmpty();
      _filteredItems = [];
      _groupedItems = [];
      _isLoading = false;
      if (!_disposed && generation == _requestGeneration) notifyListeners();
      return;
    }

    // Strict contract: the UI observes SearchLoading while the repository
    // resolves the new session.
    _state = const SearchLoading();
    final state = await _repository.search(
      query: _query,
      category: _selectedCategory,
      contentItems: _categoryFilteredItems(),
    );

    if (_disposed || generation != _requestGeneration) return;
    _applyState(state);
    _isLoading = false;
    notifyListeners();
  }

  void _applyState(SearchState state) {
    _state = state;
    if (state is SearchSuccess) {
      _filteredItems = List<ContentItem>.of(state.items);
    } else if (state is SearchError) {
      _filteredItems = [];
    }
    // SearchEmpty keeps any already-loaded list empty as well.
    if (state is SearchEmpty) _filteredItems = [];

    if (isAllCategory && _filteredItems.isNotEmpty) {
      _groupedItems = _buildSectionGroups(_filteredItems);
    } else {
      _groupedItems = [];
    }
  }

  List<ContentItem> _categoryFilteredItems() {
    if (_selectedCategory == 'all') return _allItems;
    return _allItems.where((i) => i.sectionId == _selectedCategory).toList();
  }

  List<SectionGroup> _buildSectionGroups(List<ContentItem> items) {
    final Map<String, List<ContentItem>> map = {};
    for (final item in items) {
      map.putIfAbsent(item.sectionId, () => []).add(item);
    }
    return map.entries
        .map(
          (e) => SectionGroup(
            sectionId: e.key,
            sectionName: e.value.first.sectionName,
            items: e.value,
          ),
        )
        .toList();
  }
}
