import 'package:flutter/material.dart';

import '../../ui/reader/reader_page.dart';
import '../controllers/search_controller.dart' as app_search;
import '../controllers/search_notifier.dart';
import '../models/search_models.dart';
import '../repositories/search_repository.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/lazy_load_footer.dart';
import '../widgets/search_result_tile.dart';
import '../widgets/section_header.dart';
import '../../services/search_engine.dart';
import '../../services/quran_service.dart';

class SearchScreen extends StatefulWidget {
  final double fontSizeFactor;

  /// Optional override so tests can drive the exact [SearchState] sequences
  /// the UI must render (loading / success / empty / error / partial).
  final SearchRepository? repository;

  const SearchScreen({
    super.key,
    required this.fontSizeFactor,
    this.repository,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final app_search.SearchController _controller;
  late final SearchNotifier _notifier;
  final TextEditingController _searchFieldController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// Distance from the bottom that triggers fetching the next batch.
  static const double _lazyLoadThreshold = 300;

  String _lastResultsKey = '';

  @override
  void initState() {
    super.initState();

    _controller = app_search.SearchController(
      allItems: _loadContentItems(),
      repository: widget.repository,
      availableSections: const [
        'quran',
        'mafatih',
        'dua',
        'ziyarat',
        'amal',
        'fatawa',
        'imam_ali',
        'dreams',
        'prophets_stories',
      ],
    );

    _lastResultsKey = '${_controller.query}|${_controller.selectedCategory}';
    _notifier = SearchNotifier(_controller);
    _controller.addListener(_onControllerChanged);
    SearchEngine.instance.isIndexingNotifier.addListener(_onIndexChanged);
    _scrollController.addListener(_onScroll);
    _searchFocusNode.requestFocus();
  }

  List<ContentItem> _loadContentItems() {
    if (!SearchEngine.instance.isIndexed) {
      return [];
    }

    final docs = SearchEngine.instance.allDocuments;
    return docs.map((doc) {
      final String mappedSectionId = _mapCategoryToSectionId(
        doc.category,
        doc.type,
      );
      return ContentItem(
        id: doc.id,
        title: doc.title,
        subtitle: doc.type == 'quran' ? 'القرآن الكريم' : doc.category,
        content: doc.content,
        sectionId: mappedSectionId,
        sectionName: _getSectionName(mappedSectionId),
        category: doc.category,
        normalizedTitle: doc.normalizedTitle,
        normalizedContent: doc.normalizedContent,
        normalizedCategory: doc.normalizedCategory,
        surahNumber: doc.surahNumber,
        ayahNumber: doc.ayahNumber,
        type: doc.type,
      );
    }).toList();
  }

  String _getSectionName(String sectionId) {
    const displayNames = {
      'all': 'الكل',
      'quran': 'القرآن الكريم',
      'dua': 'الأدعية',
      'ziyarat': 'الزيارات',
      'amal': 'الأعمال',
      'fatawa': 'الاستفتاءات',
      'imam_ali': 'الإمام علي (ع)',
      'dreams': 'تفسير الأحلام',
      'prophets_stories': 'قصص الأنبياء',
    };
    return displayNames[sectionId] ?? sectionId;
  }

  String _mapCategoryToSectionId(String category, String type) {
    if (type == 'quran') return 'quran';
    // Strict mapping based on actual internal IDs from the Content JSON structure
    if (category.startsWith('dua')) return 'dua';
    if (category.startsWith('ziyarat')) return 'ziyarat';
    if (category.startsWith('amal')) return 'amal';
    if (category.startsWith('fatawa')) return 'fatawa';
    if (category.startsWith('imam_ali')) return 'imam_ali';
    if (category.startsWith('dreams')) return 'dreams';
    if (category.startsWith('prophets')) return 'prophets_stories';

    // Fallback to Arabic string matching if category comes as raw Arabic
    if (category.contains('دعاء') ||
        category.contains('أدعية') ||
        category.contains('مناجاة')) return 'dua';
    if (category.contains('زيارة') || category.contains('زيارات')) {
      return 'ziyarat';
    }
    if (category.contains('أعمال') || category.contains('عمل')) return 'amal';
    if (category.contains('استفتاء') || category.contains('فتاوى')) {
      return 'fatawa';
    }
    if (category.contains('علي') || category.contains('امام')) {
      return 'imam_ali';
    }
    if (category.contains('حلم') ||
        category.contains('أحلام') ||
        category.contains('تفسير')) return 'dreams';
    if (category.contains('أنبياء') || category.contains('نبي')) {
      return 'prophets_stories';
    }

    return 'amal';
  }

  void _onIndexChanged() {
    if (!mounted) return;
    if (!SearchEngine.instance.isIndexingNotifier.value &&
        SearchEngine.instance.isIndexed) {
      _controller.replaceItems(_loadContentItems());
    }
    setState(() {});
  }

  void _onControllerChanged() {
    if (!mounted) return;
    // Auto-scroll to top only when the query/category actually changes —
    // lazy load-more notifications must not jump the user back up.
    final key = '${_controller.query}|${_controller.selectedCategory}';
    if (key != _lastResultsKey) {
      _lastResultsKey = key;
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  /// Lazy pagination: fetch the next batch when reaching the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _lazyLoadThreshold) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    SearchEngine.instance.isIndexingNotifier.removeListener(_onIndexChanged);
    _controller.removeListener(_onControllerChanged);
    _scrollController.removeListener(_onScroll);
    _notifier.dispose();
    _searchFieldController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SearchEngine.instance.isIndexed) {
      return Scaffold(
        body: Center(
          child: SearchEngine.instance.isIndexingNotifier.value
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('تعذر إعداد البحث'),
                    TextButton(
                      onPressed: () => SearchEngine.instance.init(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
        ),
      );
    }

    // The whole scaffold is built once.
    // The AppBar has its own isolated rebuild for the category filter.
    // The body has its own isolated rebuild for results.
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: _SearchTextField(
          controller: _searchFieldController,
          focusNode: _searchFocusNode,
          onChanged: _controller.updateQuery,
          onClear: () {
            _searchFieldController.clear();
            _controller.updateQuery('');
            _searchFocusNode.requestFocus();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: ValueListenableBuilder<SearchSnapshot>(
            valueListenable: _notifier,
            builder: (context, snapshot, child) {
              return CategoryFilterBar(
                categories: _controller.availableSections,
                selectedCategory: snapshot.category,
                onCategorySelected: _controller.selectCategory,
              );
            },
          ),
        ),
      ),
      body: ValueListenableBuilder<SearchSnapshot>(
        valueListenable: _notifier,
        builder: (context, snapshot, child) {
          return Column(
            children: [
              // Results Count Indicator
              _buildResultsHeader(snapshot),
              // Partial-coverage warning with a consistent Retry action.
              if (snapshot.state is SearchSuccess && snapshot.warning != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.warning!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _controller.retry,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Main Results List
              Expanded(child: _buildResultsList(snapshot)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader(SearchSnapshot snapshot) {
    final query = snapshot.query;
    final total = snapshot.loadedCount;

    if (query.isEmpty && total == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Text(
        query.isEmpty
            ? 'إجمالي المحتوى: $total'
            : 'تم العثور على $total${snapshot.hasMore ? '+' : ''} نتيجة لـ "$query"',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildResultsList(SearchSnapshot snapshot) {
    if (snapshot.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = snapshot.items;
    final groups = snapshot.groups;
    final isAll = snapshot.category == 'all';

    if (snapshot.query.isEmpty && items.isEmpty && groups.isEmpty) {
      return const Center(child: Text('ابدأ البحث الآن...'));
    }

    // Strict state contract: Error -> message + consistent Retry button.
    if (snapshot.state is SearchError) {
      return _ErrorState(
        message: snapshot.warning ?? (snapshot.state as SearchError).message,
        onRetry: _controller.retry,
      );
    }

    if (items.isEmpty && groups.isEmpty) {
      return const _EmptyState();
    }

    final bool showFooter = snapshot.isLoadingMore ||
        snapshot.hasMore ||
        items.length >= HybridSearchRepository.defaultBatchSize;
    final Widget? footer = showFooter
        ? LazyLoadFooter(
            isLoadingMore: snapshot.isLoadingMore,
            hasMore: snapshot.hasMore,
            loadedCount: snapshot.loadedCount,
            onLoadMore: _controller.loadMore,
          )
        : null;

    // Grouped View (الكل)
    if (isAll) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount:
            _computeGroupedListItemCount(groups) + (footer != null ? 1 : 0),
        itemBuilder: (context, index) {
          final groupCount = _computeGroupedListItemCount(groups);
          if (index >= groupCount) return footer!;
          return _buildGroupedItem(context, index, groups, snapshot.query);
        },
      );
    }

    // Flat View (Specific Category)
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: items.length + (footer != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) return footer!;
        return SearchResultTile(
          item: items[index],
          highlightQuery: snapshot.query,
          onTap: () => _navigateToItem(items[index]),
        );
      },
    );
  }

  // ─── Grouped List Helpers ───

  int _computeGroupedListItemCount(List<SectionGroup> groups) {
    int count = 0;
    for (final group in groups) {
      count += 1; // Header
      count += group.items.length; // Items
    }
    return count;
  }

  Widget _buildGroupedItem(
    BuildContext context,
    int index,
    List<SectionGroup> groups,
    String query,
  ) {
    int currentIndex = 0;
    for (final group in groups) {
      // Header index
      if (currentIndex == index) {
        return SectionHeader(title: group.sectionName);
      }
      currentIndex++;

      // Item indices
      for (final item in group.items) {
        if (currentIndex == index) {
          return SearchResultTile(
            item: item,
            highlightQuery: query,
            onTap: () => _navigateToItem(item),
          );
        }
        currentIndex++;
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _navigateToItem(ContentItem item) async {
    if (item.type == 'quran') {
      if (item.surahNumber != null) {
        final ayahs = await QuranService.getAyahs(item.surahNumber!);
        if (mounted) {
          final surahName =
              item.title.split(' - آية').first.replaceFirst('سورة ', '');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReaderPage(
                title: surahName,
                content: '',
                isQuran: true,
                surahName: surahName,
                surahId: item.surahNumber,
                targetAyahNumber: item.ayahNumber,
                ayahs: ayahs,
                fontSizeFactor: widget.fontSizeFactor,
              ),
            ),
          );
        }
      }
    } else {
      final isImamAli =
          (item.category != null && item.category!.contains('علي')) ||
              item.id.startsWith('imam_ali');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReaderPage(
            title: item.title,
            content: item.content,
            isImamAli: isImamAli,
            fontSizeFactor: widget.fontSizeFactor,
          ),
        ),
      );
    }
  }
}

// ─── Supporting Widgets ───

class _SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchTextField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'ابحث في المحتوى...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: onClear,
            );
          },
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

/// Error view for the SearchError state: always offers a Retry action so
/// any failed source can be retried consistently.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب البحث بكلمات مختلفة',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
