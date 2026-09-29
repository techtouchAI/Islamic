import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

import 'bundled_database.dart';
import '../models/mafatih_category.dart';
import '../models/mafatih_article.dart';
import '../utils/arabic_normalizer.dart';

class MafatihService {
  static Database? _db;

  static Future<void> initDB() async {
    if (kIsWeb) return;
    try {
      _db = await BundledDatabase.open('assets/data/maftiha.ar2.db');
    } catch (e) {
      debugPrint("MafatihService Init Error: $e");
      rethrow;
    }
  }

  static Future<List<MafatihCategory>> getCategories() async {
    // Web has no SQLite: gracefully fall back to an empty list.
    if (kIsWeb) return [];
    try {
      if (_db == null) {
        throw StateError('مفاتيح الجنان غير متاح على هذا الجهاز');
      }
      final maps = await _db!.query('categories', where: 'parent_id = 0');
      return maps.map((m) => MafatihCategory.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService getCategories Error: $e");
      rethrow;
    }
  }

  static Future<List<MafatihCategory>> getSubCategories(int parentId) async {
    // Web has no SQLite: gracefully fall back to an empty list.
    if (kIsWeb) return [];
    try {
      if (_db == null) {
        throw StateError('مفاتيح الجنان غير متاح على هذا الجهاز');
      }
      final maps = await _db!.query(
        'categories',
        where: 'parent_id = ?',
        whereArgs: [parentId],
      );
      return maps.map((m) => MafatihCategory.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService getSubCategories Error: $e");
      rethrow;
    }
  }

  static Future<int> getTotalArticlesCount() async {
    try {
      if (kIsWeb || _db == null) {
        return 0;
      }
      final count = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM articles'),
      );
      return count ?? 0;
    } catch (e) {
      debugPrint("MafatihService getTotalArticlesCount Error: $e");
      return 0;
    }
  }

  static Future<int> getCategoryArticlesCount(int categoryId) async {
    try {
      if (kIsWeb || _db == null) {
        return 0;
      }
      final String idStr = categoryId.toString();
      final count = Sqflite.firstIntValue(
        await _db!.rawQuery(
          'SELECT COUNT(*) FROM articles WHERE group_id = ? OR group_id LIKE ? OR group_id LIKE ? OR group_id LIKE ?',
          [idStr, '$idStr@@%', '%@@$idStr', '%@@$idStr@@%'],
        ),
      );
      return count ?? 0;
    } catch (e) {
      debugPrint("MafatihService getCategoryArticlesCount Error: $e");
      return 0;
    }
  }

  /// Paged Mafatih search: applies SQL `LIMIT`/`OFFSET` so callers lazily
  /// fetch batches instead of materializing every match.
  ///
  /// On the web build SQLite is unavailable: returns an empty (fallback)
  /// result instead of throwing a native SQL error.
  static Future<List<MafatihArticle>> searchArticlesPaged(
    String query, {
    required int limit,
    required int offset,
  }) async {
    try {
      if (kIsWeb || query.isEmpty) return [];
      if (_db == null) {
        throw StateError('قاعدة مفاتيح الجنان غير متاحة');
      }
      final rawPattern = '%${ArabicNormalizer.escapeLike(query.trim())}%';
      final normalizedPattern =
          '%${ArabicNormalizer.escapeLike(ArabicNormalizer.normalize(query))}%';
      final maps = await _db!.query(
        'articles',
        where:
            r"title LIKE ? ESCAPE '\' OR text LIKE ? ESCAPE '\' "
            r"OR title LIKE ? ESCAPE '\' OR text LIKE ? ESCAPE '\'",
        whereArgs: [
          rawPattern,
          rawPattern,
          normalizedPattern,
          normalizedPattern,
        ],
        orderBy: 'id ASC',
        limit: limit,
        offset: offset,
      );
      return maps.map((m) => MafatihArticle.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService searchArticlesPaged Error: $e");
      rethrow;
    }
  }

  /// Convenience wrapper returning a single large batch.
  static Future<List<MafatihArticle>> searchArticles(String query) =>
      searchArticlesPaged(query, limit: 100000, offset: 0);

  static Future<List<MafatihArticle>> getArticles(int categoryId) async {
    // Web has no SQLite: gracefully fall back to an empty list.
    if (kIsWeb) return [];
    try {
      if (_db == null) {
        throw StateError('مفاتيح الجنان غير متاح على هذا الجهاز');
      }
      final String idStr = categoryId.toString();
      // group_id can be exact '10', start with '10@@', end with '@@10', or contain '@@10@@'
      final maps = await _db!.query(
        'articles',
        where: 'group_id = ? OR group_id LIKE ? OR group_id LIKE ? OR group_id LIKE ?',
        whereArgs: [idStr, '$idStr@@%', '%@@$idStr', '%@@$idStr@@%'],
      );
      return maps.map((m) => MafatihArticle.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService getArticles Error: $e");
      rethrow;
    }
  }
}
