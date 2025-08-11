import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoritesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _favoriteIds = {};

  List<Map<String, dynamic>> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get favoritesCount => _favorites.length;
  Set<String> get favoriteIds => _favoriteIds;

  // Check if a place is in favorites
  bool isFavorite(String placeId) {
    return _favoriteIds.contains(placeId);
  }

  // Load favorites from backend
  Future<void> loadFavorites() async {
    if (!await FavoritesService.isAuthenticated()) {
      _error = 'Authentication required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _favorites = await FavoritesService.getFavorites();
      _favoriteIds = _favorites.map((place) => (place['_id']?.toString() ?? place['id']?.toString() ?? '')).toSet();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a place to favorites
  Future<bool> addToFavorites(
      String placeId, Map<String, dynamic>? placeData) async {
    if (!await FavoritesService.isAuthenticated()) {
      _error = 'Authentication required';
      notifyListeners();
      return false;
    }

    try {
      final success = await FavoritesService.addToFavorites(placeId);
      if (success) {
        _favoriteIds.add(placeId);

        // Add place data to favorites list if provided
        if (placeData != null &&
            !_favorites.any((place) => (place['_id']?.toString() ?? place['id']?.toString() ?? '') == placeId)) {
          _favorites.add(placeData);
        }

        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('❌ Error adding to favorites: $e');
      notifyListeners();
      return false;
    }
  }

  // Remove a place from favorites
  Future<bool> removeFromFavorites(String placeId) async {
    if (!await FavoritesService.isAuthenticated()) {
      _error = 'Authentication required';
      notifyListeners();
      return false;
    }

    try {
      final success = await FavoritesService.removeFromFavorites(placeId);
      if (success) {
        _favoriteIds.remove(placeId);
        _favorites.removeWhere((place) => (place['_id']?.toString() ?? place['id']?.toString() ?? '') == placeId);
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('❌ Error removing from favorites: $e');
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(
      String placeId, Map<String, dynamic>? placeData) async {
    if (!await FavoritesService.isAuthenticated()) {
      _error = 'Authentication required';
      notifyListeners();
      return false;
    }

    try {
      final newIsFavorite = await FavoritesService.toggleFavorite(placeId);

      if (newIsFavorite) {
        _favoriteIds.add(placeId);
        if (placeData != null &&
            !_favorites.any((place) => (place['_id']?.toString() ?? place['id']?.toString() ?? '') == placeId)) {
          _favorites.add(placeData);
        }
      } else {
        _favoriteIds.remove(placeId);
        _favorites.removeWhere((place) => (place['_id']?.toString() ?? place['id']?.toString() ?? '') == placeId);
      }

      _error = null;
      notifyListeners();
      return newIsFavorite;
    } catch (e) {
      _error = e.toString();
      print('❌ Error toggling favorite: $e');
      notifyListeners();
      return isFavorite(placeId); // Return current state on error
    }
  }

  // Check favorite status from backend
  Future<bool> checkFavoriteStatus(String placeId) async {
    if (!await FavoritesService.isAuthenticated()) {
      return false;
    }

    try {
      final isFav = await FavoritesService.isFavorite(placeId);

      // Update local state
      if (isFav) {
        _favoriteIds.add(placeId);
      } else {
        _favoriteIds.remove(placeId);
      }

      notifyListeners();
      return isFav;
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }

  // Clear all favorites (for logout)
  void clearFavorites() {
    _favorites.clear();
    _favoriteIds.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Refresh favorites
  Future<void> refreshFavorites() async {
    await loadFavorites();
  }

  // Get a specific favorite place by ID
  Map<String, dynamic>? getFavoriteById(String placeId) {
    try {
      return _favorites.firstWhere((place) => (place['_id']?.toString() ?? place['id']?.toString() ?? '') == placeId);
    } catch (e) {
      return null;
    }
  }

  // Search favorites by name
  List<Map<String, dynamic>> searchFavorites(String query) {
    if (query.isEmpty) return _favorites;

    return _favorites.where((place) {
      final name = place['name']?.toString().toLowerCase() ?? '';
      final description = place['description']?.toString().toLowerCase() ?? '';
      final location = place['location']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return name.contains(searchQuery) ||
          description.contains(searchQuery) ||
          location.contains(searchQuery);
    }).toList();
  }
}
