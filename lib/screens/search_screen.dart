import 'package:flutter/material.dart';
import 'dart:async';
import '../services/search_engine.dart';
import '../services/quran_service.dart';
import '../main.dart'; // To access ReaderPage

class SearchScreen extends StatefulWidget {
  final double fontSizeFactor;

  const SearchScreen({super.key, required this.fontSizeFactor});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  List<SearchResult> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    Future.microtask(() {
      final results = SearchEngine.instance.search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    });
  }

  // Highlights normalized query matches in the original text
  Widget _buildHighlightedText(String originalText, String normalizedQuery, BuildContext context, {TextStyle? baseStyle}) {
    if (normalizedQuery.isEmpty) return Text(originalText, style: baseStyle);

    final theme = Theme.of(context);
    final highlightStyle = (baseStyle ?? const TextStyle()).copyWith(
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
    );

    final queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();
    if (queryWords.isEmpty) return Text(originalText, style: baseStyle);

    // This is a simplistic highlighter for demonstration, since words might be scattered.
    // In a real robust highlighter, we map normalized index to original index.
    // Here we'll do a basic word-by-word highlight.

    List<TextSpan> spans = [];
    final originalWords = originalText.split(' ');

    for (int i = 0; i < originalWords.length; i++) {
      final word = originalWords[i];
      final normWord = SearchEngine.normalizeArabic(word);

      bool isHighlighted = false;
      for (var qWord in queryWords) {
        if (normWord.contains(qWord) || SearchEngine.fuzzyMatch(qWord, normWord, isFuzzy: qWord.length >= 4)) {
          isHighlighted = true;
          break;
        }
      }

      spans.add(TextSpan(
        text: word + (i < originalWords.length - 1 ? ' ' : ''),
        style: isHighlighted ? highlightStyle : baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.merge(baseStyle),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQueryEmpty = _searchController.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ابحث...',
            border: InputBorder.none,
          ),
          style: theme.textTheme.titleLarge,
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (!isQueryEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: _buildBody(theme, isQueryEmpty),
    );
  }

  Widget _buildBody(ThemeData theme, bool isQueryEmpty) {
    if (!SearchEngine.instance.isIndexed) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isQueryEmpty) {
      return const Center(child: Text('ابدأ الكتابة للبحث...'));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    final normalizedQuery = SearchEngine.normalizeArabic(_searchController.text.trim());

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final doc = result.document;

        return ListTile(
          title: _buildHighlightedText(doc.title, normalizedQuery, context, baseStyle: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(doc.type == 'quran' ? 'القرآن الكريم' : doc.category),
          onTap: () async {
            if (doc.type == 'quran') {
              if (doc.surahNumber != null) {
                final ayahs = await QuranService.getAyahs(doc.surahNumber!);
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReaderPage(
                        title: doc.title,
                        content: '',
                        isQuran: true,
                        surahName: doc.title,
                        ayahs: ayahs,
                        fontSizeFactor: widget.fontSizeFactor,
                      ),
                    ),
                  );
                }
              }
            } else {
              final isImamAli = doc.category.contains('علي') || doc.id.startsWith('imam_ali');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderPage(
                    title: doc.title,
                    content: doc.content,
                    isImamAli: isImamAli,
                    fontSizeFactor: widget.fontSizeFactor,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
