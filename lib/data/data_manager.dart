import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/string_extensions.dart';

class DataManager {
  static Map<String, dynamic>? _db;
  static final ValueNotifier<int> dbNotifier = ValueNotifier(0);
  static const String _repoUrl =
      "https://raw.githubusercontent.com/techtouchAI/Islamic/main/assets/data/content.json";
  static const String _contentAsset = 'assets/data/content.json';

  /// The calendar table is the calendar of record of the app (the announced
  /// months of the office of Grand Ayatollah al-Sistani). It is versioned by
  /// `calendar_version` in the document, so a device can tell which table is
  /// newer: the bundled asset of the installed build, the cached document, or
  /// the cloud document. A table with a lower version never replaces a higher
  /// one, which is what keeps a corrected month from being rolled back.
  static const String calendarVersionKey = 'calendar_version';

  /// Document the device copy can be older than: the CMS ships ~25 MB, which
  /// needs more than a token timeout on a mobile link. A sync that times out
  /// leaves the device on stale content, so the limit is deliberately roomy.
  static const Duration cloudTimeout = Duration(seconds: 60);

  // Allows dependency injection for testing
  static http.Client? httpClient;
  static Future<File> Function()? getLocalFileOverride;

  /// Build stamp of the app currently running, used to notice an app update.
  static Future<String?> Function()? appBuildOverride;

  /// The refresh of an installed build, while it runs. The app does not wait
  /// for it (it must not delay the splash screen), but tests await it.
  @visibleForTesting
  static Future<void>? bundleRefresh;

  static Future<String?> _appBuild() async {
    if (appBuildOverride != null) return appBuildOverride!();
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  static Map<String, dynamic>? getDB() => _db;

  @visibleForTesting
  static void setDB(Map<String, dynamic>? newDb) {
    _db = newDb;
    _normalizeDB(_db);
  }

  /// Generation of the calendar table a document carries. A document without
  /// the marker predates versioning and counts as generation zero.
  static int calendarVersionOf(Map<String, dynamic>? document) {
    final value = document?[calendarVersionKey];
    return value is int && value > 0 ? value : 0;
  }

  /// Whether the table of [candidate] may replace the table of [current].
  ///
  /// The device always keeps the newest table it has seen: a correction in the
  /// bundle or in the cloud wins, while an older document can never put an
  /// outdated month back.
  static bool calendarIsNewer(
    Map<String, dynamic> candidate,
    Map<String, dynamic>? current,
  ) {
    final incoming = candidate['hijri_calendar'];
    if (incoming is! List || incoming.isEmpty) return false;
    return calendarVersionOf(candidate) > calendarVersionOf(current);
  }

  /// Copies the calendar of [source] onto [target].
  static void _copyCalendar(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    target['hijri_calendar'] = source['hijri_calendar'];
    target[calendarVersionKey] = source[calendarVersionKey];
    target['calendar_source'] = source['calendar_source'];
  }

  static Map<String, dynamic> _decodeAndNormalizeJson(String source) {
    final dynamic decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Content document must be a JSON object');
    }
    final Map<String, dynamic> db = decoded;
    _validateSchema(db);
    _normalizeDBLocal(db);
    return db;
  }

  /// Schema policy — every document (bundled asset, local cache, cloud sync)
  /// is validated here BEFORE it is adopted. Rejecting a document keeps the
  /// previously loaded copy in place. Rules:
  ///
  /// 1. Root is a JSON object.
  /// 2. `sections`: object of string -> object (UI section descriptors).
  /// 3. `content`: object of string -> array of objects; every item exposes a
  ///    string `title` or `name`, or nests further `items` (recursively) —
  ///    search, indexing and rendering all depend on a displayable title.
  /// 4. Legacy collections (`fatawa_categories`, `dreams_categories`,
  ///    `prophets_stories`, `imam_ali`), when present, are arrays of objects
  ///    following the same item rules.
  /// 5. `about` / `settings`, when present, are objects.
  static void _validateSchema(Map<String, dynamic> db) {
    final sections = db['sections'];
    if (sections is! Map) {
      throw const FormatException('Schema: "sections" must be an object');
    }
    if (sections.keys.any((key) => key is! String) ||
        sections.values.any((value) => value is! Map)) {
      throw const FormatException(
        'Schema: "sections" entries must be string -> object',
      );
    }

    final content = db['content'];
    if (content is! Map) {
      throw const FormatException('Schema: "content" must be an object');
    }
    for (final entry in content.entries) {
      if (entry.key is! String) {
        throw const FormatException('Schema: "content" keys must be strings');
      }
      final value = entry.value;
      if (value is! List) {
        throw FormatException('Schema: content.${entry.key} must be an array');
      }
      _validateItems(value, 'content.${entry.key}');
    }

    for (final key in const [
      'fatawa_categories',
      'dreams_categories',
      'prophets_stories',
      'imam_ali',
    ]) {
      final value = db[key];
      if (value == null) continue;
      if (value is! List) {
        throw FormatException('Schema: "$key" must be an array when present');
      }
      _validateItems(value, key);
    }

    for (final key in const ['about', 'settings']) {
      final value = db[key];
      if (value != null && value is! Map) {
        throw FormatException('Schema: "$key" must be an object when present');
      }
    }
  }

  static void _validateItems(List<dynamic> items, String path) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) {
        throw FormatException('Schema: $path[$i] must be an object');
      }
      final title = item['title'];
      final name = item['name'];
      final nested = item['items'];
      if (title != null && title is! String) {
        throw FormatException('Schema: $path[$i].title must be a string');
      }
      if (name != null && name is! String) {
        throw FormatException('Schema: $path[$i].name must be a string');
      }
      if (nested != null) {
        if (nested is! List) {
          throw FormatException('Schema: $path[$i].items must be an array');
        }
        if (title == null && name == null && nested.isEmpty) {
          throw FormatException(
            'Schema: $path[$i] has no "title", "name" or nested "items"',
          );
        }
        _validateItems(nested, '$path[$i].items');
        continue;
      }
      if (title == null && name == null) {
        throw FormatException(
          'Schema: $path[$i] has no "title", "name" or nested "items"',
        );
      }
    }
  }

  /// Deletes [file] if it exists, swallowing IO errors — cleanup must never
  /// break the loading path.
  static Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (e) {
      debugPrint('DataManager: unable to remove ${file.path}: $e');
    }
  }

  /// Removes `.pending` leftovers from a previously interrupted write.
  static Future<void> _cleanupOrphanedPending(File localFile) =>
      _deleteIfExists(File('${localFile.path}.pending'));

  static void _normalizeDBLocal(Map<String, dynamic>? db) {
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
        item['_normalized_content'] =
            item['content'].toString().normalizeArabic();
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
      'imam_ali',
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

  /// Brings what a freshly installed build ships onto the device.
  ///
  /// The device copy in the documents directory survives app updates and is
  /// loaded before the bundle, so without this step anything a new build adds
  /// could never take effect: a corrected calendar table would keep answering
  /// with the old day of the month, and a section the build ships (such as
  /// `prophets_tree`) would stay hidden behind the older copy — including on
  /// a device whose cache lost the section to an older cloud document. Runs
  /// once per build; the calendar is accepted only with a higher generation,
  /// while sections are additive and can therefore never remove content.
  static Future<void> _adoptBundledDocumentOnUpdate(File localFile) async {
    try {
      final build = await _appBuild();
      if (build == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_calendarBuildKey) == build) return;

      final bundled = await compute(
        _decodeAndNormalizeJson,
        await rootBundle.loadString(_contentAsset),
      );
      rootBundle.evict(_contentAsset);
      // Only a bundle that was read completely marks this build as handled.
      await prefs.setString(_calendarBuildKey, build);

      final current = _db;
      if (current == null) return;
      final tookCalendar = calendarIsNewer(bundled, current);

      // The live document is replaced, never edited in place, so a frame that
      // is building right now reads either the old or the new document. The
      // nested maps are copied as well because restoring sections adds keys.
      final merged = Map<String, dynamic>.from(current);
      final sections = merged['sections'];
      if (sections is Map) {
        merged['sections'] = Map<String, dynamic>.from(sections);
      }
      final content = merged['content'];
      if (content is Map) {
        merged['content'] = Map<String, dynamic>.from(content);
      }
      if (tookCalendar) _copyCalendar(merged, bundled);
      final tookSections = _keepNewestSections(merged, bundled);
      if (!tookCalendar && !tookSections) return;

      _db = merged;
      final temporary = File('${localFile.path}.pending');
      try {
        await temporary.writeAsString(jsonEncode(merged), encoding: utf8);
        await temporary.rename(localFile.path);
      } finally {
        await _deleteIfExists(temporary);
      }
      debugPrint(
        'DataManager: Installed build $build refreshed the device document '
        '(calendar generation ${calendarVersionOf(merged)}'
        '${tookSections ? ', missing sections restored' : ''}).',
      );
      dbNotifier.value++;
    } catch (e) {
      // The bundled refresh is a bonus on app updates: a platform service
      // that is unavailable (or a damaged asset) must not stop the app from
      // booting with the document that was already loaded.
      debugPrint("DataManager: Bundled refresh skipped: $e");
    }
  }

  static const String _calendarBuildKey = 'data.calendar.build';

  static Future<void> loadContent() async {
    try {
      // Browser storage has no dart:io file; load the same bundled content.
      final localFile = kIsWeb ? null : await _getLocalFile();

      if (localFile != null) {
        // Sweep `.pending` leftovers from a previously interrupted write so
        // they can never accumulate across launches.
        await _cleanupOrphanedPending(localFile);

        // 1. Try to load from local storage first
        if (await localFile.exists()) {
          try {
            final content = await localFile.readAsString(encoding: utf8);
            _db = await compute(_decodeAndNormalizeJson, content);
            debugPrint("DataManager: Loaded from local storage.");
            // Deliberately not awaited here: the refresh reads and decodes the
            // bundled document, which must not delay the splash screen. It
            // reports completion through dbNotifier and through
            // [bundleRefresh], which tests await.
            bundleRefresh = _adoptBundledDocumentOnUpdate(localFile);
            return;
          } catch (e) {
            debugPrint(
              "DataManager: Invalid local content, using bundled asset: $e",
            );
            // Policy: a local copy that fails parsing/validation is corrupt.
            // Remove it so it is not re-read on every launch — the bundled
            // asset (and the next successful cloud sync) replaces it.
            await _deleteIfExists(localFile);
          }
        }
      }
      final response = await rootBundle.loadString(_contentAsset);
      _db = await compute(_decodeAndNormalizeJson, response);
      rootBundle.evict(_contentAsset);
      debugPrint("DataManager: Loaded from bundled assets.");
    } catch (e) {
      debugPrint("DataManager Error: $e");
      _db = {
        'content': {},
        'sections': {},
        'fatawa_categories': [],
        'dreams_categories': [],
      };
    }
  }

  static Future<bool> syncCloudData({http.Client? client}) async {
    final ownsClient = client == null && httpClient == null;
    final requestClient = client ?? httpClient ?? http.Client();
    try {
      // Add random component to fully bypass strict CDN caches
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          DateTime.now().microsecondsSinceEpoch.toString();
      final url = Uri.parse("$_repoUrl?t=$timestamp");

      final response = await requestClient.get(url).timeout(cloudTimeout);
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);

        if (kIsWeb) {
          final newDb = await compute(_decodeAndNormalizeJson, content);
          _keepNewestCalendar(newDb);
          _keepNewestSections(newDb, _db);
          _db = newDb;
          dbNotifier.value++;
          return true;
        }

        // التحقق من وجود تغييرات فعلية
        final localFile = await _getLocalFile();
        final oldContent = await localFile.exists()
            ? await localFile.readAsString(encoding: utf8)
            : null;
        if (oldContent == content) return false;

        // Schema policy: decode + validate BEFORE the document is adopted or
        // written. A rejected document keeps the previous copy untouched.
        final Map<String, dynamic> newDb;
        try {
          newDb = await compute(_decodeAndNormalizeJson, content);
        } catch (parseError) {
          debugPrint(
            "DataManager: Rejected cloud content (schema/validation): $parseError",
          );
          return false;
        }

        // A newer calendar table already on the device (for example the one
        // the installed build ships) outranks the incoming document, so the
        // document is adopted without its older table.
        final keepDeviceCalendar = _keepNewestCalendar(newDb);
        // A cloud copy that predates a section the device already carries —
        // an older CMS export, or a cached copy of one — must not hide it:
        // this is how the prophets tree vanished from the home and drawer
        // seconds after launch. The restored sections make the persisted
        // document differ from the received bytes, so it is re-encoded.
        final keptSections = _keepNewestSections(newDb, _db);
        final persisted =
            keepDeviceCalendar || keptSections ? jsonEncode(newDb) : content;
        if (oldContent == persisted) return false;

        // Persist atomically: write `<file>.pending`, then rename it over the
        // live file so a failed/interrupted write can never corrupt the last
        // good copy. Any failure cleans the temp file up and keeps the old data.
        final temporary = File('${localFile.path}.pending');
        try {
          await _cleanupOrphanedPending(localFile);
          await temporary.writeAsString(persisted, encoding: utf8, flush: true);
          await temporary.rename(localFile.path);
        } catch (writeError) {
          debugPrint(
            "DataManager: Failed to persist cloud content, keeping "
            "previous copy: $writeError",
          );
          return false;
        } finally {
          await _deleteIfExists(temporary);
        }

        _db = Map<String, dynamic>.from(newDb);
        dbNotifier.value++;
        debugPrint("DataManager: Cloud sync successful.");
        return true;
      } else {
        debugPrint(
          "DataManager Sync Error: HTTP Status ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("DataManager Sync Error (Network/Timeout): $e");
    } finally {
      if (ownsClient) requestClient.close();
    }
    return false;
  }

  /// Keeps the newest calendar table when a document is adopted.
  ///
  /// Returns true when the device table was copied onto [incoming], which
  /// requires persisting the merged document instead of the received bytes.
  static bool _keepNewestCalendar(Map<String, dynamic> incoming) {
    final current = _db;
    if (current == null || !calendarIsNewer(current, incoming)) return false;
    _copyCalendar(incoming, current);
    debugPrint(
      'DataManager: Kept calendar generation ${calendarVersionOf(incoming)} '
      'instead of the older one in the sync document.',
    );
    return true;
  }

  /// Restores onto [target] every section that [source] carries and [target]
  /// lacks, so an older document can never hide what a newer one shipped.
  ///
  /// A document is adopted as a whole, which is how a section such as
  /// `prophets_tree` disappeared from the home doorway and the drawer: a
  /// cloud copy fetched before the section shipped (or a cached copy of that
  /// older document) replaced the device copy and took the section with it.
  /// The device therefore keeps every section it has seen, mirroring the
  /// keep-newest policy of the calendar table:
  ///
  /// * a `sections` descriptor is copied when [target] has none;
  /// * the section entries are looked up the way [getItems] does — under
  ///   `content` first, then at the top level (`prophets_stories` and the
  ///   other legacy collections) — and copied when the target side is
  ///   missing or empty and the source side is not.
  ///
  /// Entries a section already carries on [target] are never replaced, so a
  /// newer document still updates them normally. Returns true when anything
  /// was copied.
  static bool _keepNewestSections(
    Map<String, dynamic> target,
    Map<String, dynamic>? source,
  ) {
    if (source == null) return false;
    final sourceSections = source['sections'];
    final targetSections = target['sections'];
    if (sourceSections is! Map || targetSections is! Map) return false;
    final sourceContent = source['content'];
    final targetContent = target['content'];

    var changed = false;
    for (final entry in sourceSections.entries) {
      final key = entry.key;

      if (!targetSections.containsKey(key) && entry.value is Map) {
        targetSections[key] = entry.value;
        changed = true;
      }

      if (targetContent is Map) {
        final targetItems = targetContent[key];
        final sourceItems = sourceContent is Map ? sourceContent[key] : null;
        final empty = targetItems is! List || targetItems.isEmpty;
        if (empty && sourceItems is List && sourceItems.isNotEmpty) {
          targetContent[key] = sourceItems;
          changed = true;
        }
      }

      final targetTop = target[key];
      final sourceTop = source[key];
      final topEmpty = targetTop is! List || targetTop.isEmpty;
      if (topEmpty && sourceTop is List && sourceTop.isNotEmpty) {
        target[key] = sourceTop;
        changed = true;
      }
    }
    return changed;
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
      try {
        final idString = section.replaceAll('fatawa_cat_', '');
        final cats = _db!['fatawa_categories'] as List<dynamic>? ?? [];
        final cat = cats.firstWhere(
          (c) => c['id'].toString() == idString,
          orElse: () => null,
        );
        if (cat != null) {
          if (cat is Map) {
            if (cat.containsKey('items'))
              return cat['items'] as List<dynamic>? ?? [];
            return cat['items'] ?? [];
          }
        }
      } catch (e) {
        debugPrint('Error getting fatawa categories: $e');
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
          if (cat is Map) {
            if (cat.containsKey('items'))
              return cat['items'] as List<dynamic>? ?? [];
            return cat['items'] ?? [];
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
          if (cat is Map) {
            if (cat.containsKey('items'))
              return cat['items'] as List<dynamic>? ?? [];
            return cat['items'] ?? [];
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

  static String getIstikharaDua() {
    return getSettings()['istikhara_dua'] as String? ??
        "«اللَّهُمَّ إِنِّي تَفَأَّلْتُ بِكِتَابِكَ، وَتَوَكَّلْتُ عَلَيْكَ، فَأَرِنِي مِنْ كِتَابِكَ مَا هُوَ مَكْتُومٌ مِنْ سِرِّكَ الْمَكْنُونِ فِي غَيْبِكَ»";
  }

  static String getMainScreenDua() {
    return getSettings()['main_screen_dua'] as String? ??
        "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ";
  }

  static List<dynamic> getDailyDuas() {
    return _db?['content']?['daily_duas'] as List<dynamic>? ?? [];
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
        item['_normalized_content'] =
            item['content'].toString().normalizeArabic();
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
      'imam_ali',
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
