import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/data_manager.dart';

class QuranService {
  static Database? _db;
  static final Map<int, List<Map<String, dynamic>>> _ayahsCache = {};

  static Future<void> initDB() async {
    if (kIsWeb) return;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, "quran_db.db");

      if (!await File(path).exists()) {
        ByteData data = await rootBundle.load("assets/data/quran_db.db");
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes);
      }
      _db = await openDatabase(path);
    } catch (e) {
      debugPrint("QuranService Init Error: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getSurahs() async {
    if (kIsWeb || _db == null) {
      // Use DataManager as fallback (CMS support)
      final items = DataManager.getItems('quran');
      if (items.isNotEmpty) {
        return items
            .map((e) => {
                  'id': e['id'],
                  'name': e['title'].toString().replaceFirst('سورة ', ''),
                  'total_ayahs': 'غير محدد'
                })
            .toList();
      }
      return [
        {'id': 2, 'name': 'الفاتحة', 'total_ayahs': 7},
        {'id': 3, 'name': 'البقرة', 'total_ayahs': 286},
      ];
    }
    return await _db!.query('surah', orderBy: 'id ASC');
  }

  static Future<List<Map<String, dynamic>>> getAyahs(int surahId) async {
    if (_ayahsCache.containsKey(surahId)) {
      return _ayahsCache[surahId]!;
    }

    if (kIsWeb || _db == null) {
      final items = DataManager.getItems('quran');
      final found =
          items.firstWhere((e) => e['id'] == surahId, orElse: () => null);
      if (found != null) {
        final result = [
          {'ar_text': found['content'].toString(), 'ayah_surah_index': ''}
        ];
        _ayahsCache[surahId] = result;
        return result;
      }
      return [];
    }
    // Using 'text' column for full Tashkeel
    final result = await _db!.query('ayah',
        where: 'sid = ?',
        columns: ['text as ar_text', 'anum', 'ayah_surah_index'],
        whereArgs: [surahId],
        orderBy: 'anum ASC');
    _ayahsCache[surahId] = result;
    return result;
  }
}
