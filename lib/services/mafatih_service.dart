import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'bundled_database.dart';
import '../models/mafatih_category.dart';
import '../models/mafatih_article.dart';

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
    try {
      if (kIsWeb || _db == null) {
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
    try {
      if (kIsWeb || _db == null) {
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
      final count = Sqflite.firstIntValue(await _db!.rawQuery(
        'SELECT COUNT(*) FROM articles WHERE group_id = ? OR group_id LIKE ? OR group_id LIKE ? OR group_id LIKE ?',
        [
          idStr,
          '$idStr@@%',
          '%@@$idStr',
          '%@@$idStr@@%',
        ],
      ));
      return count ?? 0;
    } catch (e) {
      debugPrint("MafatihService getCategoryArticlesCount Error: $e");
      return 0;
    }
  }

  static Future<List<MafatihArticle>> searchArticles(String query) async {
    try {
      if (query.isEmpty) return [];
      if (kIsWeb || _db == null) {
        throw StateError('قاعدة مفاتيح الجنان غير متاحة');
      }
      final escaped = query.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
      final String safeQuery = '%$escaped%';
      final maps = await _db!.query(
        'articles',
        where: r"title LIKE ? ESCAPE '\' OR text LIKE ? ESCAPE '\'",
        whereArgs: [safeQuery, safeQuery],
        orderBy: 'id ASC',
      );
      return maps.map((m) => MafatihArticle.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService searchArticles Error: $e");
      rethrow;
    }
  }

  static Future<List<MafatihArticle>> getArticles(int categoryId) async {
    try {
      if (kIsWeb || _db == null) {
        throw StateError('مفاتيح الجنان غير متاح على هذا الجهاز');
      }
      final String idStr = categoryId.toString();
      // group_id can be exact '10', start with '10@@', end with '@@10', or contain '@@10@@'
      final maps = await _db!.query(
        'articles',
        where: 'group_id = ? OR group_id LIKE ? OR group_id LIKE ? OR group_id LIKE ?',
        whereArgs: [
          idStr,
          '$idStr@@%',
          '%@@$idStr',
          '%@@$idStr@@%',
        ],
      );
      return maps.map((m) => MafatihArticle.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService getArticles Error: $e");
      rethrow;
    }
  }
}
