import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Bundled databases are read-only extracts of the assets shipped with the
/// app. A failed extraction never overwrites a previously usable database.
///
/// ## Versioning (db_version)
/// * `assets/data/db_version.json` maps every database asset to an integer
///   version. **Bump the number whenever a corrected database ships.**
/// * The extracted copy on the device is named
///   `<name>_v<dbVersion>_b<buildNumber>.db`.
/// * On every launch the version of the device copy is compared with the
///   asset's (db_version, app build): any mismatch — a newer db_version *or*
///   a newer app build — extracts the asset again and deletes the outdated
///   copy. The build number acts as a safety net so even a forgotten
///   db_version bump can never leave a user stuck on a stale database.
class BundledDatabase {
  /// Sidecar manifest holding the integer version of each database asset.
  static const String dbVersionManifest = 'assets/data/db_version.json';

  static Future<Database> open(String assetName) async {
    final info = await PackageInfo.fromPlatform();
    final buildNumber = int.tryParse(info.buildNumber) ?? 0;
    final name = p.basename(assetName);
    final assetVersion = await _resolveAssetVersion(
      assetName,
      fallback: buildNumber,
    );

    final directory = await getDatabasesPath();
    await Directory(directory).create(recursive: true);

    // The file name encodes the version of this copy: a newer db_version or
    // a newer app build produces a different name -> extracted again below.
    final path =
        p.join(directory, '${name}_v${assetVersion}_b$buildNumber.db');
    final file = File(path);

    if (!await file.exists()) {
      final pending = File('$path.pending');
      try {
        final data = await rootBundle.load(assetName);
        await pending.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        await pending.rename(path);
      } finally {
        rootBundle.evict(assetName);
        if (await pending.exists()) await pending.delete();
      }
    }

    // Verify that the copy can be opened. A copy that fails to open is
    // deleted so the next launch re-extracts it from the asset (self-heal).
    final Database db;
    try {
      db = await openDatabase(path, readOnly: true);
    } catch (_) {
      try {
        await file.delete();
      } on FileSystemException {
        // Leaving the bad copy in place only affects this launch.
      }
      rethrow;
    }

    // Drop outdated copies: older db_versions, older app builds and files
    // from the legacy naming scheme.
    try {
      await for (final entry in Directory(directory).list()) {
        if (entry is File &&
            entry.path != path &&
            (entry.path == p.join(directory, name) ||
                (p.basename(entry.path).startsWith('${name}_') &&
                    entry.path.endsWith('.db')))) {
          try {
            await entry.delete();
          } on FileSystemException {
            // Cleanup must not prevent opening a valid database.
          }
        }
      }
    } on FileSystemException {
      // An installed database remains usable even if directory cleanup fails.
    }
    return db;
  }

  /// Reads the asset's integer version from [dbVersionManifest].
  ///
  /// Falls back to the app build number when the manifest is missing or
  /// malformed, which preserves the legacy "one copy per build" behavior.
  static Future<int> _resolveAssetVersion(
    String assetName, {
    required int fallback,
  }) async {
    try {
      final raw = await rootBundle.loadString(dbVersionManifest);
      final decoded = json.decode(raw);
      if (decoded is Map) {
        final value = decoded[assetName];
        if (value is int && value > 0) return value;
      }
      debugPrint(
          'BundledDatabase: no version entry for $assetName, using build number.');
    } catch (e) {
      debugPrint(
          'BundledDatabase: db_version manifest unavailable ($e), using build number.');
    }
    return fallback;
  }
}
