import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/favorite_item.dart';
import 'package:flutter/foundation.dart';

class FavoritesService {
  FavoritesService._privateConstructor();
  static final FavoritesService _instance = FavoritesService._privateConstructor();
  static FavoritesService get instance => _instance;

  static const String _boxName = 'favoritesBox';
  Box<FavoriteItem>? _favoritesBox;

  // State notifier to update the UI
  final ValueNotifier<List<FavoriteItem>> favoritesNotifier = ValueNotifier<List<FavoriteItem>>([]);

  /// Initializes the Hive database, registers the adapter,
  /// opens the necessary box, and updates the notifier.
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FavoriteItemAdapter());
    }
    _favoritesBox = await Hive.openBox<FavoriteItem>(_boxName);
    _updateNotifier();
  }

  void _updateNotifier() {
    if (_favoritesBox != null) {
      final list = _favoritesBox!.values.toList();
      // Sort by timestamp descending
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      favoritesNotifier.value = list;
    }
  }

  /// Toggles the favorite status of a [FavoriteItem].
  /// If the item is already a favorite, it removes it.
  /// Otherwise, it adds the item.
  Future<void> toggleFavorite(FavoriteItem item) async {
    try {
      if (_favoritesBox == null) return;

      if (_favoritesBox!.containsKey(item.id)) {
        await _favoritesBox!.delete(item.id);
        if (kDebugMode) {
          print('Removed favorite: ${item.id}');
        }
      } else {
        await _favoritesBox!.put(item.id, item);
        if (kDebugMode) {
          print('Added favorite: ${item.id}');
        }
      }
      _updateNotifier();
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite: $e');
      }
    }
  }

  /// Adds a custom user-generated note to the favorites list.
  /// A unique UUID is generated automatically for the item.
  Future<void> addCustomNote(String title, String content) async {
    try {
      if (_favoritesBox == null) return;

      final String id = const Uuid().v4();
      final note = FavoriteItem(
        id: id,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        isCustom: true,
      );

      await _favoritesBox!.put(id, note);
      if (kDebugMode) {
        print('Added custom note: $id');
      }
      _updateNotifier();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding custom note: $e');
      }
    }
  }

  /// Updates an existing custom note.
  Future<void> updateCustomNote(String id, String title, String content) async {
    try {
      if (_favoritesBox == null) return;

      final existingNote = _favoritesBox!.get(id);
      if (existingNote != null && existingNote.isCustom) {
        final note = FavoriteItem(
          id: id,
          title: title,
          content: content,
          timestamp: DateTime.now(),
          isCustom: true,
        );

        await _favoritesBox!.put(id, note);
        if (kDebugMode) {
          print('Updated custom note: $id');
        }
        _updateNotifier();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating custom note: $e');
      }
    }
  }

  /// Removes an item from the favorites using its [id].
  Future<void> removeFavorite(String id) async {
    try {
      if (_favoritesBox == null) return;

      await _favoritesBox!.delete(id);
      if (kDebugMode) {
        print('Removed favorite: $id');
      }
      _updateNotifier();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing favorite: $e');
      }
    }
  }

  /// Returns the current list of favorite items.
  List<FavoriteItem> getFavorites() {
    return favoritesNotifier.value;
  }

  /// Quickly checks if an item is favorited based on its [id].
  bool isFavorite(String id) {
    if (_favoritesBox == null) return false;
    return _favoritesBox!.containsKey(id);
  }

  /// Exports all favorite items as a formatted JSON string.
  /// Suitable for backup capabilities.
  String exportFavorites() {
    try {
      if (_favoritesBox == null) return '';

      final list = _favoritesBox!.values.map((item) => item.toJson()).toList();
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(list);
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting favorites: $e');
      }
      return '';
    }
  }

  /// Validates and imports external JSON backups into the local Hive box.
  /// Handles conflict resolution by avoiding duplicate IDs.
  Future<bool> importFavorites(String jsonString) async {
    try {
      if (_favoritesBox == null) return false;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      bool changesMade = false;

      for (final jsonItem in jsonList) {
        if (jsonItem is Map<String, dynamic>) {
          final item = FavoriteItem.fromJson(jsonItem);
          // Conflict resolution: only add if it doesn't already exist
          if (!_favoritesBox!.containsKey(item.id)) {
            await _favoritesBox!.put(item.id, item);
            changesMade = true;
          }
        }
      }

      if (changesMade) {
        _updateNotifier();
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error importing favorites: $e');
      }
      return false;
    }
  }
}
