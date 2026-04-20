import 'dart:convert';
import 'package:flutter/services.dart';

class DataManager {
  static Map<String, dynamic>? _content;

  static Future<void> loadContent() async {
    try {
      final String response = await rootBundle.loadString('assets/data/content.json');
      _content = json.decode(response);
    } catch (e) {
      _content = {};
    }
  }

  static List<dynamic> getItems(String section) {
    if (_content == null || _content![section] == null) return [];
    return _content![section] as List<dynamic>;
  }

  static Map<String, dynamic> getAbout() {
    return (_content?['about'] as Map<String, dynamic>?) ?? {};
  }

  static Map<String, dynamic> getSettings() {
    return (_content?['settings'] as Map<String, dynamic>?) ?? {};
  }
}
