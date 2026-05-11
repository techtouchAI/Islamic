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
      final safeClient = client ?? httpClient ?? http.Client();
      final response = await safeClient.get(Uri.parse(_repoUrl));
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
    if (_db == null) return [];

    // --- 1. الأقسام الجديدة (في الجذر الرئيسي لملف الـ JSON) ---
    if (section == 'fatawa') {
      return _db!['fatawa_categories'] ?? [];
    }
    if (section == 'dreams') {
      return _db!['dreams_categories'] ?? [];
    }
    if (section == 'prophets_stories') {
      return _db!['prophets_stories'] ?? [];
    }
    if (section == 'imam_ali' && _db!.containsKey('imam_ali')) {
      return _db!['imam_ali'] ?? [];
    }

    // --- 2. الأقسام الفرعية المتداخلة (الفتاوى، الأحلام، الإمام علي) ---
    if (section.startsWith('fatawa_cat_')) {
      return _extractNestedItems('fatawa_categories', section.replaceAll('fatawa_cat_', ''));
    }
    if (section.startsWith('dreams_cat_')) {
      return _extractNestedItems('dreams_categories', section.replaceAll('dreams_cat_', ''));
    }
    if (section.startsWith('imam_ali_cat_')) {
      return _extractNestedItems('imam_ali', section.replaceAll('imam_ali_cat_', ''));
    }

    // --- 3. الأقسام القديمة المستقرة (الموجودة داخل كائن 'content') ---
    // حماية إضافية: نتحقق من وجود content حتى لا ينهار التطبيق
    final contentObj = _db!['content'] as Map<String, dynamic>?;
    if (contentObj == null) return [];

    if (section == 'adhkar') {
      List all = [];
      all.addAll(contentObj['adhkar_munajat'] ?? []);
      all.addAll(contentObj['adhkar_tasbihs'] ?? []);
      return all;
    }
    if (section == 'duas') {
      List all = [];
      all.addAll(contentObj['duas_days'] ?? []);
      all.addAll(contentObj['duas_taqeebat'] ?? []);
      all.addAll(contentObj['duas_general'] ?? []);
      all.addAll(contentObj['duas_salawat'] ?? []);
      return all;
    }
    if (section == 'visits') {
      List all = [];
      all.addAll(contentObj['visits_days'] ?? []);
      all.addAll(contentObj['visits_general'] ?? []);
      return all;
    }
    if (section == 'imam_ali') { 
      return contentObj['imam_ali'] ?? [];
    }

    // الإرجاع الافتراضي لأي قسم قديم آخر
    return contentObj[section] as List<dynamic>? ?? [];
  }

  // دالة مساعدة (Helper) نظيفة لاستخراج البيانات المتداخلة بأمان وبدون تكرار الكود
  static List<dynamic> _extractNestedItems(String rootKey, String idString) {
    try {
      final cats = _db![rootKey] as List<dynamic>? ?? [];
      final cat = cats.firstWhere(
        (c) => c is Map && c['id'].toString() == idString,
        orElse: () => null,
      );
      if (cat != null && cat is Map) {
        if (cat.containsKey('items')) return cat['items'] as List<dynamic>? ?? [];
      }
      
      // التوافق مع البيانات القديمة إن وجدت داخل 'content'
      final contentObj = _db!['content'] as Map<String, dynamic>?;
      if (contentObj != null) {
        if (rootKey == 'dreams_categories') return contentObj['dreams_cat_$idString'] ?? [];
        if (rootKey == 'imam_ali') return contentObj['imam_ali_cat_$idString'] ?? [];
      }
    } catch (e) {
      debugPrint('Error getting nested categories for $rootKey: $e');
    }
    return [];
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
    if (db == null) return;

    void normalizeItem(Map item) {
      if (item.containsKey('name') && !item.containsKey('title')) {
        item['title'] = item['name'];
        item['content'] = item['name'];
      }
      if (item['title'] != null) {
        item['_normalized_title'] = item['title'].toString().normalizeArabic();
      }
      if (item['content'] != null) {
        item['_normalized_content'] = item['content'].toString().normalizeArabic();
      }
      if (item.containsKey('items') && item['items'] is List) {
        for (var nestedItem in item['items']) {
          if (nestedItem is Map) {
            normalizeItem(nestedItem);
          }
        }
      }
    }

    final content = db['content'];
    if (content is Map) {
      for (var section in content.values) {
        if (section is List) {
          for (var item in section) {
            if (item is Map) normalizeItem(item);
          }
        }
      }
    }

    final topLevelSections = [
      'fatawa_categories',
      'dreams_categories',
      'prophets_stories',
      'imam_ali'
    ];
    for (var sectionName in topLevelSections) {
      final sectionList = db[sectionName];
      if (sectionList is List) {
        for (var item in sectionList) {
          if (item is Map) normalizeItem(item);
        }
      }
    }
  }
}
