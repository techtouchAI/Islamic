import 'dart:convert';
import 'package:flutter/services.dart';

class DataManager {
  static Map<String, dynamic>? _db;

  static Future<void> loadContent() async {
    try {
      final String response = await rootBundle.loadString('assets/data/content.json');
      _db = json.decode(response);
    } catch (e) {
      _db = {};
    }
  }

  static List<dynamic> getItems(String section) {
    if (_db == null || _db!['content'] == null || _db!['content'][section] == null) return [];
    return _db!['content'][section] as List<dynamic>;
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
}
