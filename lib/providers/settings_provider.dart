import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/data_manager.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  ThemeMode themeMode = ThemeMode.light;
  double fontSizeFactor = 1.0;
  Color primaryColor = Colors.brown;
  double uiOpacity = 0.9;
  String? backgroundImagePath;
  String? selectedBase64Bg;
  Color cardColor = Colors.white;
  int hijriAdjustment = 0;
  Map<String, bool> homeVisibility = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load Settings
    final settings = DataManager.getSettings();
    themeMode = (settings['theme_mode'] ?? 'light') == 'dark' ? ThemeMode.dark : ThemeMode.light;
    fontSizeFactor = (settings['font_size_factor'] ?? 1.0).toDouble();
    primaryColor = _parseColor(settings['primary_color']) ?? Colors.brown;
    uiOpacity = (settings['ui_opacity'] ?? 0.9).toDouble();
    backgroundImagePath = settings['custom_bg_path'];
    selectedBase64Bg = settings['custom_bg_base64'];
    cardColor = _parseColor(settings['card_color']) ?? Colors.white;
    hijriAdjustment = settings['hijri_adjustment'] ?? 0;

    if (settings['home_visibility'] != null) {
      final Map<dynamic, dynamic> vis = settings['home_visibility'];
      homeVisibility = vis.map((k, v) => MapEntry(k.toString(), v as bool));
    }

    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveSetting('theme_mode', themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void setFontSizeFactor(double factor) {
    fontSizeFactor = factor;
    _saveSetting('font_size_factor', factor);
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    primaryColor = color;
    _saveSetting('primary_color', '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}');
    notifyListeners();
  }

  void setUiOpacity(double opacity) {
    uiOpacity = opacity;
    _saveSetting('ui_opacity', opacity);
    notifyListeners();
  }

  void setBackgroundImagePath(String? path) {
    backgroundImagePath = path;
    if (path == null) {
      _saveSetting('custom_bg_path', null);
    } else {
      _saveSetting('custom_bg_path', path);
    }
    notifyListeners();
  }

  void setSelectedBase64Bg(String? base64) {
    selectedBase64Bg = base64;
    if (base64 == null) {
      _saveSetting('custom_bg_base64', null);
    } else {
      _saveSetting('custom_bg_base64', base64);
    }
    notifyListeners();
  }

  void setCardColor(Color color) {
    cardColor = color;
    _saveSetting('card_color', '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}');
    notifyListeners();
  }

  void setHijriAdjustment(int adjustment) {
    hijriAdjustment = adjustment;
    _saveSetting('hijri_adjustment', adjustment);
    notifyListeners();
  }

  void setHomeSectionVisibility(String key, bool isVisible) {
    homeVisibility[key] = isVisible;
    _saveSetting('home_visibility', homeVisibility);
    notifyListeners();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return null;
    }
  }
}
