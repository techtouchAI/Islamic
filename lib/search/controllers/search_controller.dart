import 'package:flutter/foundation.dart';
import '../models/search_models.dart';
import '../../services/search_engine.dart'; // To use fuzzyMatch if needed

class SearchController extends ChangeNotifier {
  // ─── Dependencies ───
  final List<ContentItem> _allItems;
  final List<String> _availableSections;

  // ─── State ───
  String _query = '';
  String _selectedCategory = 'all'; // 'all' = الكل
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  // ─── Cached Results ───
  List<ContentItem> _filteredItems = [];
  List<SectionGroup> _groupedItems = [];
  PaginationMetadata _pagination = const PaginationMetadata(
    currentPage: 1,
    totalPages: 0,
    totalItems: 0,
    itemsPerPage: _itemsPerPage,
  );

  // ─── Public Getters ───
  String get query => _query;
  String get selectedCategory => _selectedCategory;
  int get currentPage => _currentPage;
  List<ContentItem> get filteredItems => List.unmodifiable(_filteredItems);
  List<SectionGroup> get groupedItems => List.unmodifiable(_groupedItems);
  PaginationMetadata get pagination => _pagination;
  List<String> get availableSections => ['all', ..._availableSections];

  bool get isAllCategory => _selectedCategory == 'all';

  SearchController({
    required List<ContentItem> allItems,
    required List<String> availableSections,
  })  : _allItems = allItems,
        _availableSections = availableSections {
    _computeResults();
  }

  // ─── Actions ───

  void updateQuery(String value) {
    final normalized = value.trim();
    if (_query == normalized) return;
    _query = normalized;
    _currentPage = 1; // Reset pagination on query change
    _computeResults();
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _currentPage = 1; // Reset pagination on category change
    _computeResults();
    notifyListeners();
  }

  void goToPage(int page) {
    if (page < 1 || page > _pagination.totalPages || page == _currentPage) return;
    _currentPage = page;
    _computePagination(); // Only re-slice, no need to re-filter
    notifyListeners();
  }

  void nextPage() => goToPage(_currentPage + 1);
  void previousPage() => goToPage(_currentPage - 1);

  // ─── Core Logic ───

  void _computeResults() {
    // 1. Filter by category
    List<ContentItem> categoryFiltered;
    if (_selectedCategory == 'all') {
      categoryFiltered = _allItems;
    } else {
      categoryFiltered = _allItems.where((i) => i.sectionId == _selectedCategory).toList();
    }

    // 2. Filter by search query
    if (_query.isEmpty) {
      _filteredItems = categoryFiltered;
    } else {
      final normalizedQuery = SearchEngine.normalizeArabic(_query);
      final queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();

      if (queryWords.isEmpty) {
        _filteredItems = categoryFiltered;
      } else {
        // We do a scoring based approach similar to SearchEngine to keep the quality of results
        List<Map<String, dynamic>> scoredItems = [];
        for (var item in categoryFiltered) {
          bool allWordsMatched = true;
          int docScore = 0;

          final normalizedTitle = SearchEngine.normalizeArabic(item.title);
          final normalizedContent = SearchEngine.normalizeArabic(item.content);
          final normalizedCategory = SearchEngine.normalizeArabic(item.category ?? '');

          for (var word in queryWords) {
            bool isWordFuzzy = word.length >= 4;
            bool wordMatched = false;
            int wordScore = 0;

            if (normalizedTitle == word || normalizedTitle.contains(word)) {
              wordMatched = true;
              wordScore += 10;
            } else if (SearchEngine.fuzzyMatch(word, normalizedTitle, isFuzzy: isWordFuzzy)) {
              wordMatched = true;
              wordScore += 6;
            }

            if (normalizedCategory == word || normalizedCategory.contains(word)) {
              wordMatched = true;
              wordScore += 4;
            }

            if (normalizedContent == word || normalizedContent.contains(word)) {
              wordMatched = true;
              wordScore += 2;
            } else if (SearchEngine.fuzzyMatch(word, normalizedContent, isFuzzy: isWordFuzzy)) {
              wordMatched = true;
              wordScore += 1;
            }

            if (!wordMatched) {
              allWordsMatched = false;
              break;
            }

            docScore += wordScore;
          }

          if (allWordsMatched && docScore > 0) {
            scoredItems.add({'item': item, 'score': docScore});
          }
        }

        scoredItems.sort((a, b) {
          int scoreCompare = (b['score'] as int).compareTo(a['score'] as int);
          if (scoreCompare != 0) return scoreCompare;
          return (a['item'] as ContentItem).title.compareTo((b['item'] as ContentItem).title);
        });

        _filteredItems = scoredItems.map((e) => e['item'] as ContentItem).toList();
      }
    }

    // 3. Group if "All" category
    if (isAllCategory) {
      _groupedItems = _buildSectionGroups(_filteredItems);
    } else {
      _groupedItems = [];
    }

    // 4. Compute pagination
    _computePagination();
  }

  List<SectionGroup> _buildSectionGroups(List<ContentItem> items) {
    final Map<String, List<ContentItem>> map = {};
    for (final item in items) {
      map.putIfAbsent(item.sectionId, () => []).add(item);
    }
    return map.entries.map((e) {
      final sectionName = _allItems
          .firstWhere((i) => i.sectionId == e.key, orElse: () => items.first)
          .sectionName;
      return SectionGroup(
        sectionId: e.key,
        sectionName: sectionName,
        items: e.value,
      );
    }).toList();
  }

  void _computePagination() {
    final totalItems = _filteredItems.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;

    // Clamp current page
    if (_currentPage > safeTotalPages) {
      _currentPage = safeTotalPages;
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);

    // Slice the flattened list for current page
    final paginatedItems = _filteredItems.sublist(startIndex, endIndex);

    // Rebuild groups from paginated items if in "All" mode
    if (isAllCategory) {
      _groupedItems = _buildSectionGroups(paginatedItems);
    } else {
      // Actually, if not 'all', filteredItems for view should be the paginated ones?
      // Wait, the prompt says "if (isAllCategory) { _groupedItems = ... } else { _filteredItems = paginatedItems; }"
      // But _filteredItems is used for slicing... if we re-assign it, next time we paginate we lose the full list!
      // The prompt actually re-assigns `_filteredItems` in the original prompt logic, which is a bug in the prompt.
      // Let's keep `_filteredItems` intact, and just use `_paginatedItems` or re-assign a temporary list for view.
      // Wait, the prompt provided:
      // if (isAllCategory) { _groupedItems = _buildSectionGroups(paginatedItems); } else { _filteredItems = paginatedItems; }
      // This breaks pagination on next page because _filteredItems size drops. Let's fix this by keeping a separate list or only returning paginatedItems.
    }

    // Let's safely handle this by updating the pagination logic
    _pagination = PaginationMetadata(
      currentPage: _currentPage,
      totalPages: safeTotalPages,
      totalItems: totalItems,
      itemsPerPage: _itemsPerPage,
    );
  }

  // Expose paginated items safely without destroying the filtered cache
  List<ContentItem> get paginatedFilteredItems {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredItems.length);
    return _filteredItems.sublist(startIndex, endIndex);
  }
}
