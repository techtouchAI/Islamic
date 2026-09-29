import 'package:flutter/foundation.dart';

import 'search_controller.dart';
import '../models/search_models.dart';
import '../repositories/search_repository.dart';

class SearchNotifier extends ValueNotifier<SearchSnapshot> {
  final SearchController controller;

  SearchNotifier(this.controller) : super(_snapshot(controller)) {
    controller.addListener(_onChange);
  }

  static SearchSnapshot _snapshot(SearchController c) {
    final state = c.state;
    return SearchSnapshot(
      query: c.query,
      warning: c.warning,
      category: c.selectedCategory,
      isLoading: c.isLoading,
      isLoadingMore: c.isLoadingMore,
      items: c.filteredItems,
      groups: c.groupedItems,
      state: state,
      hasMore: state is SearchSuccess && state.hasMore,
      loadedCount: c.totalLoaded,
    );
  }

  void _onChange() => value = _snapshot(controller);

  @override
  void dispose() {
    controller.removeListener(_onChange);
    controller.dispose();
    super.dispose();
  }
}

class SearchSnapshot {
  final String query;
  final String? warning;
  final String category;
  final bool isLoading;
  final bool isLoadingMore;
  final List<ContentItem> items;
  final List<SectionGroup> groups;
  final SearchState state;
  final bool hasMore;
  final int loadedCount;

  const SearchSnapshot({
    required this.query,
    required this.warning,
    required this.category,
    required this.isLoading,
    required this.isLoadingMore,
    required this.items,
    required this.groups,
    required this.state,
    required this.hasMore,
    required this.loadedCount,
  });
}
