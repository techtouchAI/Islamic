import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../utils/string_extensions.dart';

class DataManager {
  static Map<String, dynamic>? _db;
  static final ValueNotifier<int> dbNotifier = ValueNotifier(0);
  static const String _repoUrl =
      "https://raw.githubusercontent.com/techtouchAI/Islamic/main/assets/data/content.json";

  // Allows dependency injection for testing
  static http.Client? httpClient;
  static Future<File> Function()? getLocalFileOverride;

  static Map<String, dynamic>? getDB() => _db;

  @visibleForTesting
  static void setDB(Map<String, dynamic>? newDb) {
    _db = newDb;
    _normalizeDB(_db);
  }

  static Future<void> loadContent() async {
    try {
      final localFile = await _getLocalFile();

      // 1. Try to load from local storage first
      if (await localFile.exists()) {
        final content = await localFile.readAsString();
        _db = json.decode(content);
        _normalizeDB(_db);
        debugPrint("DataManager: Loaded from local storage.");
      } else {
        // 2. Fallback to bundled assets
        final String response = await rootBundle.loadString(
          'assets/data/content.json',
        );
        _db = json.decode(response);
        _normalizeDB(_db);
        debugPrint("DataManager: Loaded from bundled assets.");
      }
    } catch (e) {
      debugPrint("DataManager Error: $e");
      _db = {};
    }
  }

  static Future<bool> syncCloudData({http.Client? client}) async {
    try {
      client = client ?? httpClient ?? http.Client();
      final response = await client.get(Uri.parse(_repoUrl));
      if (response.statusCode == 200) {
        final content = response.body;

        // التحقق من وجود تغييرات فعلية لتجنب إعادة التحميل غير الضرورية
        final localFile = await _getLocalFile();
        if (await localFile.exists()) {
          final oldContent = await localFile.readAsString();
          if (oldContent == content) return false;
        }

        final newDb = json.decode(content);
        if (newDb is Map && newDb.containsKey('sections')) {
          await localFile.writeAsString(content);
          _db = Map<String, dynamic>.from(newDb);
          _normalizeDB(_db);
          dbNotifier.value++;
          debugPrint("DataManager: Cloud sync successful.");
          return true;
        }
      }
    } catch (e) {
      debugPrint("DataManager Sync Error: $e");
    }
    return false;
  }

  static Future<File> _getLocalFile() async {
    if (getLocalFileOverride != null) {
      return await getLocalFileOverride!();
    }
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/content.json');
  }

  static List<dynamic> getItems(String section) {
    if (_db == null || _db!['content'] == null) return [];
    if (section == 'adhkar') {
      List all = [];
      all.addAll(_db!['content']['adhkar_munajat'] ?? []);
      all.addAll(_db!['content']['adhkar_tasbihs'] ?? []);
      return all;
    }
    if (section == 'duas') {
      List all = [];
      all.addAll(_db!['content']['duas_days'] ?? []);
      all.addAll(_db!['content']['duas_taqeebat'] ?? []);
      all.addAll(_db!['content']['duas_general'] ?? []);
      all.addAll(_db!['content']['duas_salawat'] ?? []);
      return all;
    }
    if (section == 'visits') {
      List all = [];
      all.addAll(_db!['content']['visits_days'] ?? []);
      all.addAll(_db!['content']['visits_general'] ?? []);
      return all;
    }
    if (section == 'imam_ali') {
      return _db!['content']['imam_ali'] ?? [];
    }
    if (section.startsWith('fatawa_cat_')) {
      final idString = section.replaceAll('fatawa_cat_', '');
      final id = int.tryParse(idString);
      final cats = _db!['fatawa_categories'] as List<dynamic>? ?? [];
      final cat = cats.firstWhere((c) => c['id'] == id, orElse: () => null);
      if (cat != null) {
        return cat['items'] as List<dynamic>? ?? [];
      }
      return [];
    }

    if (section.startsWith('dreams_cat_')) {
      try {
        final idString = section.replaceAll('dreams_cat_', '');
        final cats = _db!['dreams_categories'] as List<dynamic>? ?? [];
        final cat = cats.firstWhere(
          (c) => c['id'].toString() == idString,
          orElse: () => null,
        );
        if (cat != null) {
          if (cat is Map && cat.containsKey('items')) {
            return cat['items'] as List<dynamic>? ?? [];
          }
          return _db!['content']['dreams_cat_$idString'] as List<dynamic>? ??
              [];
        }
      } catch (e) {
        debugPrint('Error getting dreams categories: $e');
      }
      return [];
    }

    if (section.startsWith('imam_ali_cat_')) {
      try {
        final idString = section.replaceAll('imam_ali_cat_', '');
        final cats = _db!['content']['imam_ali'] as List<dynamic>? ?? [];
        final cat = cats.firstWhere(
          (c) => c['id'].toString() == idString,
          orElse: () => null,
        );
        if (cat != null) {
          if (cat is Map && cat.containsKey('items')) {
            return cat['items'] as List<dynamic>? ?? [];
          }
          return _db!['content']['imam_ali_cat_$idString'] as List<dynamic>? ??
              [];
        }
      } catch (e) {
        debugPrint('Error getting imam ali categories: $e');
      }
      return [];
    }
    if (section == 'fatawa') {
      return _db!['fatawa_categories'] ?? [];
    }
    if (section == 'dreams') {
      return _db!['dreams_categories'] ?? [];
    }
    if (section == 'prophets_stories') {
      return _db!['prophets_stories'] as List<dynamic>? ?? [];
    }
    return _db!['content'][section] as List<dynamic>? ?? [];
  }

  static Map<String, dynamic> getAbout() {
    return (_db?['about'] as Map<String, dynamic>?) ?? {};
  }

  static Map<String, dynamic> getSettings() {
    return (_db?['settings'] as Map<String, dynamic>?) ?? {};
  }

  static Map<String, dynamic> getSections() {
    return (_db?['sections'] as Map<String, dynamic>?) ?? {};
  }

  static void _normalizeDB(Map<String, dynamic>? db) {
    if (db == null || db['content'] == null) return;
    final content = db['content'];
    if (content is Map) {
      for (var section in content.values) {
        if (section is List) {
          for (var item in section) {
            if (item is Map) {
              if (item['title'] != null) {
                item['_normalized_title'] =
                    item['title'].toString().normalizeArabic();
              }
              if (item['content'] != null) {
                item['_normalized_content'] =
                    item['content'].toString().normalizeArabic();
              }
            }
          }
        }
      }
    }
  }
}
