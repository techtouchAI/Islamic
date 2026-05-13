import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../data/data_manager.dart';

class SearchDocument {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final String type; // 'content' or 'quran'
  final int? surahNumber;
  final int? ayahNumber;

  // Normalized fields for searching
  final String normalizedTitle;
  final String normalizedContent;
  final String normalizedCategory;
  final List<String> normalizedTags;

  SearchDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.type,
    this.surahNumber,
    this.ayahNumber,
    required this.normalizedTitle,
    required this.normalizedContent,
    required this.normalizedCategory,
    required this.normalizedTags,
  });
}

class SearchResult {
  final SearchDocument document;
  final int score;

  SearchResult({required this.document, required this.score});
}

class SearchEngine {
  static final SearchEngine _instance = SearchEngine._internal();
  factory SearchEngine() => _instance;
  SearchEngine._internal();

  static SearchEngine get instance => _instance;

  List<SearchDocument> _index = [];
  bool _isIndexed = false;

  @visibleForTesting
  void setMockIndex(List<SearchDocument> mockIndex) {
    _index = mockIndex;
    _isIndexed = true;
  }

  bool get isIndexed => _isIndexed;

  // Arabic Normalization
  static final _diacriticsRegExp = RegExp(r'[\u064B-\u065F\u0670]');

  static String normalizeArabic(String text) {
    return text
        .replaceAll(_diacriticsRegExp, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Levenshtein distance calculation
  static int levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i <= t.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v0[t.length];
  }

  static bool fuzzyMatch(String queryWord, String targetText, {required bool isFuzzy}) {
      if (queryWord.isEmpty) return false;
      if (!isFuzzy) {
          return targetText.contains(queryWord);
      }

      List<String> targetWords = targetText.split(' ');
      for (String targetWord in targetWords) {
          if ((targetWord.length - queryWord.length).abs() > 1) continue;

          if (levenshteinDistance(queryWord, targetWord) <= 1) {
              return true;
          }
      }
      return targetText.contains(queryWord);
  }

  Future<void> init() async {
    if (_isIndexed) return;
    try {
      // 1. Prepare data for isolate
      final db = DataManager.getDB();
      final contentItems = <Map<String, dynamic>>[];

      if (db != null) {
        final sections = DataManager.getSections();
        sections.forEach((key, sec) {
          if (key == 'fatawa' || key == 'imam_ali' || key == 'dreams') {
            final cats = DataManager.getItems(key);
            for (var cat in cats) {
              final catItems = DataManager.getItems('${key}_cat_${cat["id"]}');
              for (var item in catItems) {
                contentItems.add({
                  ...item,
                  '_search_section_key': '${key}_cat_${cat["id"]}',
                  '_category_title': cat['title'] ?? sec['title'],
                });
              }
            }
          } else {
            final items = DataManager.getItems(key);
            for (var item in items) {
              contentItems.add({
                ...item,
                '_search_section_key': key,
                '_category_title': sec['title'],
              });
            }
          }
        });
      }

      // 2. Prepare Quran data
      final quranAyahs = <Map<String, dynamic>>[];
      if (!kIsWeb) {
        try {
          final dbPath = await getDatabasesPath();
          final path = join(dbPath, "quran_db.db");
          if (await File(path).exists()) {
             final quranDb = await openDatabase(path);
             final List<Map<String, dynamic>> ayahs = await quranDb.rawQuery('''
               SELECT a.anum, a.text, a.sid, s.name as surah_name
               FROM ayah a
               JOIN surah s ON a.sid = s.id
             ''');
             for (var ayah in ayahs) {
                quranAyahs.add({
                   'ayah_text': ayah['text']?.toString() ?? '',
                   'surah_name': ayah['surah_name']?.toString() ?? '',
                   'ayah_number': ayah['anum'],
                   'surah_number': ayah['sid'],
                });
             }
             await quranDb.close();
          }
        } catch (e) {
          debugPrint("SearchEngine Quran Error: $e");
        }
      }

      // 3. Build index via isolate
      try {
        _index = await compute(_buildIndex, {
          'contentItems': contentItems,
          'quranAyahs': quranAyahs,
        });
      } catch (computeError) {
        debugPrint("SearchEngine Isolate Error: $computeError. Fallback to synchronous indexing.");
        _index = _buildIndex({
          'contentItems': contentItems,
          'quranAyahs': quranAyahs,
        });
      }

      _isIndexed = true;
      debugPrint("SearchEngine: Indexed ${_index.length} items.");

    } catch (e) {
      debugPrint("SearchEngine Init Error: $e");
      // Fallback in case Data prep failed
      _index = [];
      _isIndexed = true;
    }
  }

  static List<SearchDocument> _buildIndex(Map<String, dynamic> data) {
    final List<SearchDocument> index = [];
    final contentItems = data['contentItems'] as List<Map<String, dynamic>>;
    final quranAyahs = data['quranAyahs'] as List<Map<String, dynamic>>;

    for (var item in contentItems) {
      final id = item['id']?.toString() ?? '';
      final title = item['title']?.toString() ?? '';
      final content = item['content']?.toString() ?? '';
      final category = item['_search_section_key']?.toString() ?? '';
      List<String> tags = [];
      if (item['tags'] is List) {
        tags = (item['tags'] as List).map((e) => e.toString()).toList();
      }

      index.add(SearchDocument(
        id: id,
        title: title,
        content: content,
        category: category,
        tags: tags,
        type: 'content',
        normalizedTitle: normalizeArabic(title),
        normalizedContent: normalizeArabic(content),
        normalizedCategory: normalizeArabic(category),
        normalizedTags: tags.map((e) => normalizeArabic(e)).toList(),
      ));
    }

    for (var ayah in quranAyahs) {
      final surahName = ayah['surah_name'] as String;
      final ayahText = ayah['ayah_text'] as String;
      final ayahNum = ayah['ayah_number'] as int;
      final surahNum = ayah['surah_number'] as int;

      index.add(SearchDocument(
        id: '${surahNum}_$ayahNum',
        title: surahName, // Surah name acts as title
        content: ayahText, // Ayah text acts as content
        category: 'quran',
        tags: [],
        type: 'quran',
        surahNumber: surahNum,
        ayahNumber: ayahNum,
        normalizedTitle: normalizeArabic(surahName),
        normalizedContent: normalizeArabic(ayahText),
        normalizedCategory: normalizeArabic('quran'),
        normalizedTags: [],
      ));
    }

    return index;
  }

  List<SearchResult> search(String query) {
    if (query.isEmpty || !_isIndexed) return [];

    final normalizedQuery = normalizeArabic(query);
    final queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();
    if (queryWords.isEmpty) return [];

    final List<SearchResult> results = [];

    for (var doc in _index) {
      bool allWordsMatched = true;
      int docScore = 0;

      for (var word in queryWords) {
        bool isWordFuzzy = word.length >= 4;
        bool wordMatched = false;
        int wordScore = 0;

        // 1. Title / Surah Name
        if (doc.normalizedTitle == word || doc.normalizedTitle.contains(word)) {
           wordMatched = true;
           wordScore += 10;
        } else if (fuzzyMatch(word, doc.normalizedTitle, isFuzzy: isWordFuzzy)) {
           wordMatched = true;
           wordScore += 6;
        }

        // 2. Category / Tag exact match
        if (doc.normalizedCategory == word || doc.normalizedCategory.contains(word)) {
           wordMatched = true;
           wordScore += 4;
        } else {
           for (var tag in doc.normalizedTags) {
             if (tag == word || tag.contains(word)) {
                wordMatched = true;
                wordScore += 4;
                break;
             }
           }
        }

        // 3. Content / Ayah Text
        if (doc.normalizedContent == word || doc.normalizedContent.contains(word)) {
           wordMatched = true;
           wordScore += 2;
        } else if (fuzzyMatch(word, doc.normalizedContent, isFuzzy: isWordFuzzy)) {
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
        results.add(SearchResult(document: doc, score: docScore));
      }
    }

    // Sort results descending by score, then alphabetically by title
    results.sort((a, b) {
      int scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.document.title.compareTo(b.document.title);
    });

    return results.take(50).toList();
  }
}
