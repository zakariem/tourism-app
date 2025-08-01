// lib/services/web_database_helper.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class WebDatabaseHelper {
  static const String _chatMessagesKey = 'chat_messages';
  static const String _placesKey = 'places';
  static const String _favoritesKey = 'favorites';
  
  static WebDatabaseHelper? _instance;
  static WebDatabaseHelper get instance {
    _instance ??= WebDatabaseHelper._internal();
    return _instance!;
  }
  
  WebDatabaseHelper._internal();
  
  // Chat Messages Methods
  Future<int> insertChatMessage(Map<String, dynamic> message) async {
    final prefs = await SharedPreferences.getInstance();
    final existingMessages = await getChatMessages(null);
    
    final newId = existingMessages.isEmpty ? 1 : 
        existingMessages.map((m) => m['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    
    message['id'] = newId;
    existingMessages.add(message);
    
    await prefs.setString(_chatMessagesKey, jsonEncode(existingMessages));
    
    return newId;
  }
  
  Future<List<Map<String, dynamic>>> getChatMessages(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString(_chatMessagesKey);
    
    if (messagesJson == null) return [];
    
    try {
      final List<dynamic> messagesList = jsonDecode(messagesJson);
      final messages = messagesList.cast<Map<String, dynamic>>();
      
      if (userId != null) {
        return messages.where((message) => message['user_id'] == userId).toList();
      }
      
      return messages;
    } catch (e) {
      print('Error parsing chat messages: $e');
      return [];
    }
  }
  
  Future<void> clearChatMessages(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (userId != null) {
      // Clear messages for specific user
      final messages = await getChatMessages(null);
      final filteredMessages = messages.where((message) => message['user_id'] != userId).toList();
      await prefs.setString(_chatMessagesKey, jsonEncode(filteredMessages));
    } else {
      // Clear all messages
      await prefs.remove(_chatMessagesKey);
    }
  }
  
  // Places Methods (simplified for web)
  Future<List<Map<String, dynamic>>> getPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final placesJson = prefs.getString(_placesKey);
    
    if (placesJson == null) return [];
    
    try {
      final List<dynamic> placesList = jsonDecode(placesJson);
      return placesList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error parsing places: $e');
      return [];
    }
  }
  
  Future<void> insertPlace(Map<String, dynamic> place) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await getPlaces();
    
    // Generate a simple ID
    place['id'] = DateTime.now().millisecondsSinceEpoch;
    places.add(place);
    
    await prefs.setString(_placesKey, jsonEncode(places));
  }
  
  // Favorites Methods
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    
    if (favoritesJson == null) return [];
    
    try {
      final List<dynamic> favoritesList = jsonDecode(favoritesJson);
      return favoritesList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error parsing favorites: $e');
      return [];
    }
  }
  
  Future<void> insertFavorite(Map<String, dynamic> favorite) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    // Check if already exists
    final exists = favorites.any((f) => f['place_id'] == favorite['place_id']);
    if (!exists) {
      favorite['id'] = DateTime.now().millisecondsSinceEpoch;
      favorites.add(favorite);
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
    }
  }
  
  Future<void> deleteFavorite(int placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    favorites.removeWhere((f) => f['place_id'] == placeId);
    await prefs.setString(_favoritesKey, jsonEncode(favorites));
  }
  
  Future<bool> isFavorite(int placeId) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f['place_id'] == placeId);
  }
  
  // Utility methods to match DatabaseHelper interface
  Future<bool> isPlacesTableEmpty() async {
    final places = await getPlaces();
    return places.isEmpty;
  }
  
  Future<Map<String, dynamic>?> getPlaceByName(String name) async {
    final places = await getPlaces();
    try {
      return places.firstWhere((place) => place['name'] == name);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> updatePlace(Map<String, dynamic> place) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await getPlaces();
    
    final index = places.indexWhere((p) => p['id'] == place['id']);
    if (index != -1) {
      places[index] = place;
      await prefs.setString(_placesKey, jsonEncode(places));
    }
  }
}