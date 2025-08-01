import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'web_database_helper.dart';

class DatabaseAdapter {
  static final DatabaseAdapter _instance = DatabaseAdapter._internal();
  factory DatabaseAdapter() => _instance;
  DatabaseAdapter._internal();
  
  static DatabaseAdapter get instance => _instance;

  DatabaseHelper? _databaseHelper;
  WebDatabaseHelper? _webDatabaseHelper;

  DatabaseHelper get _dbHelper {
    _databaseHelper ??= DatabaseHelper();
    return _databaseHelper!;
  }

  WebDatabaseHelper get _webHelper {
    _webDatabaseHelper ??= WebDatabaseHelper.instance;
    return _webDatabaseHelper!;
  }

  // Chat Messages operations
  Future<int> insertChatMessage(Map<String, dynamic> message) async {
    if (kIsWeb) {
      return await _webHelper.insertChatMessage(message);
    } else {
      return await _dbHelper.insertChatMessage(message);
    }
  }

  Future<List<Map<String, dynamic>>> getChatMessages([int? userId]) async {
    if (kIsWeb) {
      return await _webHelper.getChatMessages(userId);
    } else {
      return await _dbHelper.getChatMessages(userId);
    }
  }

  Future<void> clearChatMessages([int? userId]) async {
    if (kIsWeb) {
      return await _webHelper.clearChatMessages(userId);
    } else {
      return await _dbHelper.clearChatMessages(userId);
    }
  }

  // Places operations
  Future<int> insertPlace(Map<String, dynamic> place) async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      throw UnsupportedError('Places operations not supported on web platform');
    } else {
      return await _dbHelper.insertPlace(place);
    }
  }

  Future<List<Map<String, dynamic>>> getPlaces() async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      throw UnsupportedError('Places operations not supported on web platform');
    } else {
      return await _dbHelper.getPlaces();
    }
  }

  Future<List<Map<String, dynamic>>> getAllPlaces() async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      throw UnsupportedError('Places operations not supported on web platform');
    } else {
      return await _dbHelper.getAllPlaces();
    }
  }

  Future<int> getPlacesCount() async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      return 0;
    } else {
      return await _dbHelper.getPlacesCount();
    }
  }

  Future<List<Map<String, dynamic>>> getPlacesByCategory(String category) async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      throw UnsupportedError('Places operations not supported on web platform');
    } else {
      return await _dbHelper.getPlacesByCategory(category);
    }
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query, String language) async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      throw UnsupportedError('Places operations not supported on web platform');
    } else {
      return await _dbHelper.searchPlaces(query, language);
    }
  }

  Future<bool> placeExists(String nameEng) async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      return false;
    } else {
      return await _dbHelper.placeExists(nameEng);
    }
  }

  Future<Map<String, dynamic>?> getPlaceByName(String nameEng) async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      return null;
    } else {
      return await _dbHelper.getPlaceByName(nameEng);
    }
  }

  Future<int> updatePlaceByName(String nameEng, Map<String, dynamic> place) async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      throw UnsupportedError('Places operations not supported on web platform');
    } else {
      return await _dbHelper.updatePlaceByName(nameEng, place);
    }
  }

  Future<bool> isPlacesTableEmpty() async {
    if (kIsWeb) {
      // Web doesn't support places operations yet
      return true;
    } else {
      return await _dbHelper.isPlacesTableEmpty();
    }
  }

  // Favorites operations
  Future<int> addToFavorites(dynamic userId, dynamic placeId) async {
    if (kIsWeb) {
      // Web doesn't support favorites operations yet
      throw UnsupportedError('Favorites operations not supported on web platform');
    } else {
      return await _dbHelper.addToFavorites(userId, placeId);
    }
  }

  Future<void> insertFavorite(Map<String, dynamic> favorite) async {
    if (kIsWeb) {
      // Web doesn't support favorites operations yet
      throw UnsupportedError('Favorites operations not supported on web platform');
    } else {
      await _dbHelper.insertFavorite(favorite);
    }
  }

  Future<int> removeFromFavorites(dynamic userId, dynamic placeId) async {
    if (kIsWeb) {
      // Web doesn't support favorites operations yet
      throw UnsupportedError('Favorites operations not supported on web platform');
    } else {
      return await _dbHelper.removeFromFavorites(userId, placeId);
    }
  }

  Future<void> deleteFavorite(int placeId) async {
    if (kIsWeb) {
      // Web doesn't support favorites operations yet
      throw UnsupportedError('Favorites operations not supported on web platform');
    } else {
      // Note: This method has limitations - see DatabaseHelper implementation
      await _dbHelper.deleteFavorite(placeId);
    }
  }

  Future<List<Map<String, dynamic>>> getFavoritePlaces(dynamic userId) async {
    if (kIsWeb) {
      // Web doesn't support favorites operations yet
      throw UnsupportedError('Favorites operations not supported on web platform');
    } else {
      return await _dbHelper.getFavoritePlaces(userId);
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    if (kIsWeb) {
      // Web doesn't support favorites operations yet
      throw UnsupportedError('Favorites operations not supported on web platform');
    } else {
      return await _dbHelper.getFavorites();
    }
  }

  Future<bool> isPlaceFavorite(dynamic userId, dynamic placeId) async {
    if (kIsWeb) {
      // Web doesn't support favorites operations yet
      return false;
    } else {
      return await _dbHelper.isPlaceFavorite(userId, placeId);
    }
  }

  Future<bool> isFavorite(int placeId, place) async {
    if (kIsWeb) {
      // Web doesn't support favorites operations yet
      return false;
    } else {
      // Note: This method has limitations - see DatabaseHelper implementation
      try {
        return await _dbHelper.isFavorite(placeId);
      } catch (e) {
        // If the method is not implemented properly, return false
        return false;
      }
    }
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    if (kIsWeb) {
      // Web doesn't support user operations yet
      throw UnsupportedError('User operations not supported on web platform');
    } else {
      return await _dbHelper.insertUser(user);
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    if (kIsWeb) {
      // Web doesn't support user operations yet
      return null;
    } else {
      return await _dbHelper.getUserByUsername(username);
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    if (kIsWeb) {
      // Web doesn't support user operations yet
      return null;
    } else {
      return await _dbHelper.getUserById(id);
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    if (kIsWeb) {
      // Web doesn't support user operations yet
      return false;
    } else {
      return await _dbHelper.updateUser(id, data);
    }
  }

  // Utility methods
  Future<void> close() async {
    // Close database connections if needed
    // For now, this is a no-op as we use singleton pattern
  }

  // Method to check platform capabilities
  bool get supportsPlaces => !kIsWeb;
  bool get supportsFavorites => !kIsWeb;
  bool get supportsUsers => !kIsWeb;
  bool get supportsChatMessages => true; // Both platforms support chat messages
}