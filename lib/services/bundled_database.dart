import 'dart:io';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Bundled databases are read-only. A new build gets its own copy, so a failed
/// installation never overwrites a previously usable database.
class BundledDatabase {
  static Future<Database> open(String assetName) async {
    final info = await PackageInfo.fromPlatform();
    final directory = await getDatabasesPath();
    await Directory(directory).create(recursive: true);
    final name = p.basename(assetName);
    final path = p.join(directory, '${name}_${info.buildNumber}.db');
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
    // Verify that the new copy can be opened before discarding older copies.
    final db = await openDatabase(path, readOnly: true);
    try {
      await for (final entry in Directory(directory).list()) {
        if (entry is File && entry.path != path &&
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
}
