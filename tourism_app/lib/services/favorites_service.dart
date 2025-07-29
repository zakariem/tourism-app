import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String baseUrl = 'http://localhost:9000/api/favorites';

  // Get authorization headers with token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get user's favorite places
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> favorites = data['favorites'] ?? [];
        return favorites
            .map((place) => Map<String, dynamic>.from(place))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching favorites: $e');
      rethrow;
    }
  }

  // Add a place to favorites
  static Future<bool> addToFavorites(String placeId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode({'placeId': placeId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        if (data['message'] == 'Place already in favorites') {
          return true; // Already in favorites, consider it success
        }
        throw Exception(data['message']);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to add to favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove a place from favorites
  static Future<bool> removeFromFavorites(String placeId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$placeId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        if (data['message'] == 'Place not in favorites') {
          return true; // Not in favorites, consider it success
        }
        throw Exception(data['message']);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception(
            'Failed to remove from favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  // Check if a place is in favorites
  static Future<bool> isFavorite(String placeId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/check/$placeId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorite'] ?? false;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception(
            'Failed to check favorite status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false; // Default to false on error
    }
  }

  // Toggle favorite status (add if not favorite, remove if favorite)
  static Future<bool> toggleFavorite(String placeId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/toggle'),
        headers: headers,
        body: json.encode({'placeId': placeId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorite'] ?? false;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }

  // Get favorites count
  static Future<int> getFavoritesCount() async {
    try {
      final favorites = await getFavorites();
      return favorites.length;
    } catch (e) {
      print('❌ Error getting favorites count: $e');
      return 0;
    }
  }
}
