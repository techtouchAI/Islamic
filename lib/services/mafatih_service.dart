import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'bundled_database.dart';
import '../models/mafatih_category.dart';
import '../models/mafatih_article.dart';
import '../main.dart'; // To access navigatorKey

class MafatihService {
  static Database? _db;

  static Future<void> initDB() async {
    if (kIsWeb) return;
    try {
      _db = await BundledDatabase.open('assets/data/maftiha.ar2.db');
    } catch (e) {
      debugPrint("MafatihService Init Error: $e");
      _showError("حدث خطأ أثناء تهيئة مفاتيح الجنان: ${e.toString()}");
    }
  }

  static void _showError(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static Future<List<MafatihCategory>> getCategories() async {
    try {
      if (kIsWeb || _db == null) {
        return [];
      }
      final maps = await _db!.query('categories', where: 'parent_id = 0');
      return maps.map((m) => MafatihCategory.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService getCategories Error: $e");
      _showError("حدث خطأ أثناء جلب الفئات: ${e.toString()}");
      return [];
    }
  }

  static Future<List<MafatihCategory>> getSubCategories(int parentId) async {
    try {
      if (kIsWeb || _db == null) {
        return [];
      }
      final maps = await _db!.query(
        'categories',
        where: 'parent_id = ?',
        whereArgs: [parentId],
      );
      return maps.map((m) => MafatihCategory.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService getSubCategories Error: $e");
      _showError("حدث خطأ أثناء جلب الأقسام الفرعية: ${e.toString()}");
      return [];
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
      if (kIsWeb || _db == null || query.isEmpty) {
        return [];
      }
      final escaped = query.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
      final String safeQuery = '%$escaped%';
      final maps = await _db!.query(
        'articles',
        where: r"title LIKE ? ESCAPE '\' OR text LIKE ? ESCAPE '\'",
        whereArgs: [safeQuery, safeQuery],
        limit: 50,
      );
      return maps.map((m) => MafatihArticle.fromMap(m)).toList();
    } catch (e) {
      debugPrint("MafatihService searchArticles Error: \$e");
      return [];
    }
  }

  static Future<List<MafatihArticle>> getArticles(int categoryId) async {
    try {
      if (kIsWeb || _db == null) {
        return [];
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
      _showError("حدث خطأ أثناء جلب المقالات: ${e.toString()}");
      return [];
    }
  }
}
