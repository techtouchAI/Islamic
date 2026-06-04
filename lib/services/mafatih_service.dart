import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/mafatih_category.dart';
import '../models/mafatih_article.dart';

class MafatihService {
  static Database? _db;

  static Future<void> initDB() async {
    if (kIsWeb) return;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, "maftiha.ar2.db");

      // Ensure directory exists
      await Directory(dirname(path)).create(recursive: true);

      if (!await File(path).exists()) {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load("assets/data/maftiha.ar2.db");
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes);
        rootBundle.evict("assets/data/maftiha.ar2.db");
      }
      _db = await openDatabase(path, readOnly: true);
    } catch (e) {
      debugPrint("MafatihService Init Error: $e");
    }
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
      return [];
    }
  }
}
