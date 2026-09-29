import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

import 'bundled_database.dart';
import '../data/data_manager.dart';
import '../utils/arabic_normalizer.dart';

class QuranService {
  static Database? _db;
  static final Map<int, List<Map<String, dynamic>>> _ayahsCache = {};
  static final Map<int, String> _formattedContentCache = {};

  static Future<void> initDB() async {
    if (kIsWeb) return;
    try {
      _db = await BundledDatabase.open('assets/data/quran_db.db');
    } catch (e) {
      debugPrint("QuranService Init Error: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getSurahs() async {
    try {
      if (kIsWeb || _db == null) {
        // Use DataManager as fallback (CMS support)
        final items = DataManager.getItems('quran');
        if (items.isNotEmpty) {
          return items
              .map(
                (e) => {
                  'id': e['id'],
                  'name': e['title'].toString().replaceFirst('سورة ', ''),
                  'total_ayahs': 'غير محدد',
                },
              )
              .toList();
        }
        return [
          {'id': 2, 'name': 'الفاتحة', 'total_ayahs': 7},
          {'id': 3, 'name': 'البقرة', 'total_ayahs': 286},
        ];
      }
      return await _db!.query('surah', orderBy: 'id ASC');
    } catch (e) {
      debugPrint("QuranService getSurahs Error: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAyahs(int surahId) async {
    try {
      if (_ayahsCache.containsKey(surahId)) {
        return _ayahsCache[surahId]!;
      }

      if (kIsWeb || _db == null) {
        final items = DataManager.getItems('quran');
        final found = items.firstWhere(
          (e) => e['id'] == surahId,
          orElse: () => null,
        );
        if (found != null) {
          final result = [
            {'ar_text': found['content'].toString(), 'ayah_surah_index': ''},
          ];
          _ayahsCache[surahId] = result;
          return result;
        }
        return [];
      }
      // Using 'text' column for full Tashkeel
      final result = await _db!.query(
        'ayah',
        where: 'sid = ?',
        columns: ['text as ar_text', 'anum', 'ayah_surah_index'],
        whereArgs: [surahId],
        orderBy: 'anum ASC',
      );
      _ayahsCache[surahId] = result;
      return result;
    } catch (e) {
      debugPrint("QuranService getAyahs Error: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getVersesByPage(
    int pageNumber,
  ) async {
    if (_db == null) return [];
    try {
      final result = await _db!.rawQuery(
        '''
        SELECT a.ar_text, a.anum, s.name AS surah_name
        FROM ayah a
        INNER JOIN surah s ON a.sid = s.id
        WHERE a.ayah_page_number = ?
        ORDER BY a.id ASC
      ''',
        [pageNumber],
      );
      return result;
    } catch (e) {
      debugPrint("QuranService getVersesByPage Error: $e");
      return [];
    }
  }

  /// Paged Quran search: applies SQL `LIMIT`/`OFFSET` so callers lazily
  /// fetch batches instead of materializing every match.
  ///
  /// On the web build SQLite is unavailable: returns an empty (fallback)
  /// result instead of throwing a native SQL error.
  static Future<List<Map<String, dynamic>>> searchVersesPaged(
    String query, {
    required int limit,
    required int offset,
  }) async {
    if (kIsWeb || query.isEmpty) return [];
    if (_db == null) throw StateError('قاعدة القرآن غير متاحة');

    try {
      // Search the unvowelled database column; keep the original text for display.
      final rawPattern = '%${ArabicNormalizer.escapeLike(query.trim())}%';
      final normalizedPattern =
          '%${ArabicNormalizer.escapeLike(ArabicNormalizer.normalize(query))}%';
      final result = await _db!.rawQuery(
        '''
        SELECT a.anum, a.text, a.sid, s.name as surah_name
        FROM ayah a
        JOIN surah s ON a.sid = s.id
        WHERE a.ar_text LIKE ? ESCAPE '\' OR s.name LIKE ? ESCAPE '\'
           OR a.ar_text LIKE ? ESCAPE '\' OR s.name LIKE ? ESCAPE '\'
        ORDER BY a.sid ASC, a.anum ASC
        LIMIT ? OFFSET ?
      ''',
        [
          rawPattern,
          rawPattern,
          normalizedPattern,
          normalizedPattern,
          limit,
          offset,
        ],
      );

      return result
          .map(
            (row) => {
              'ayah_text': row['text']?.toString() ?? '',
              'surah_name': row['surah_name']?.toString() ?? '',
              'ayah_number': row['anum'],
              'surah_number': row['sid'],
            },
          )
          .toList();
    } catch (e) {
      debugPrint("QuranService searchVersesPaged Error: $e");
      rethrow;
    }
  }

  /// Convenience wrapper returning a single large batch.
  static Future<List<Map<String, dynamic>>> searchVerses(String query) =>
      searchVersesPaged(query, limit: 7000, offset: 0);

  static String getFormattedContent(
    int surahId,
    List<Map<String, dynamic>> ayahs,
  ) {
    if (_formattedContentCache.containsKey(surahId)) {
      return _formattedContentCache[surahId]!;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < ayahs.length; i++) {
      final a = ayahs[i];
      final text = a['ar_text'].toString().trim();
      final index = a['anum']?.toString() ?? a['ayah_surah_index'].toString();
      if (index.isEmpty) {
        buffer.write(text);
      } else {
        buffer.write(text);
        buffer.write(" \uFD3F");
        buffer.write(index);
        buffer.write("\uFD3E");
      }
      if (i < ayahs.length - 1) {
        buffer.write(" ");
      }
    }

    final content = buffer.toString();
    _formattedContentCache[surahId] = content;
    return content;
  }
}
