import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tourism_app/services/enhanced_recommendation_service.dart';

class EnhancedUserBehaviorProvider extends ChangeNotifier {
  final EnhancedRecommendationService _recommendationService = EnhancedRecommendationService();
  
  // Current session tracking
  DateTime? _sessionStartTime;
  String? _currentCategory;
  String? _currentPlaceId;
  DateTime? _currentPlaceViewStartTime;
  
  // Real-time recommendations cache
  List<Map<String, dynamic>> _cachedRecommendations = [];
  List<Map<String, dynamic>> _cachedTrendingPlaces = [];
  DateTime? _lastRecommendationUpdate;
  DateTime? _lastTrendingUpdate;
  
  // Interaction statistics
  Map<String, dynamic> _userStats = {};
  
  bool _isInitialized = false;

  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _recommendationService.initialize();
      await _updateUserStats();
      
      // Load cached recommendations first for faster UI
      await _loadCachedRecommendations();
      
      // Notify listeners immediately if we have cached data
      if (_cachedRecommendations.isNotEmpty || _cachedTrendingPlaces.isNotEmpty) {
        notifyListeners();
        print('[EnhancedUserBehavior] Cached data loaded and UI updated');
      }
      
      // Then refresh with latest data
      await _refreshRecommendations();
      await _refreshTrendingPlaces();
      _isInitialized = true;
      
      print('[EnhancedUserBehavior] Provider initialized with fresh data');
      notifyListeners();
    } catch (e) {
      print('[EnhancedUserBehavior] Error initializing: $e');
    }
  }

  // Start a new session
  void startSession() {
    _sessionStartTime = DateTime.now();
    print('[EnhancedUserBehavior] Session started');
  }

  // Record category interaction
  Future<void> recordCategoryInteraction(String category) async {
    try {
      await _recommendationService.recordCategoryInteraction(category);
      await _updateUserStats();
      await _refreshRecommendationsIfNeeded();
      
      print('[EnhancedUserBehavior] Category interaction recorded: $category');
      notifyListeners();
    } catch (e) {
      print('[EnhancedUserBehavior] Error recording category interaction: $e');
    }
  }

  // Start viewing a place
  void startPlaceView(String placeId, String category) {
    _currentPlaceId = placeId;
    _currentCategory = category;
    _currentPlaceViewStartTime = DateTime.now();
    
    print('[EnhancedUserBehavior] Started viewing place: $placeId in $category');
  }

  // End viewing a place and record the interaction
  Future<void> endPlaceView() async {
    if (_currentPlaceId != null && 
        _currentCategory != null && 
        _currentPlaceViewStartTime != null) {
      
      final viewDuration = DateTime.now().difference(_currentPlaceViewStartTime!).inSeconds.toDouble();
      
      try {
        await _recommendationService.recordPlaceInteraction(
          _currentPlaceId!,
          _currentCategory!,
          viewTime: viewDuration,
        );
        
        await _updateUserStats();
        await _refreshRecommendationsIfNeeded();
        await _refreshTrendingPlacesIfNeeded();
        
        print('[EnhancedUserBehavior] Place view ended: $_currentPlaceId (${viewDuration}s)');
        notifyListeners();
      } catch (e) {
        print('[EnhancedUserBehavior] Error recording place interaction: $e');
      }
    }
    
    _currentPlaceId = null;
    _currentCategory = null;
    _currentPlaceViewStartTime = null;
  }

  // Record a quick interaction (like clicking on a place card)
  Future<void> recordQuickInteraction(String placeId, String category) async {
    try {
      await _recommendationService.recordPlaceInteraction(placeId, category, viewTime: 1.0);
      await _updateUserStats();
      await _refreshRecommendationsIfNeeded();
      
      print('[EnhancedUserBehavior] Quick interaction recorded: $placeId in $category');
      notifyListeners();
    } catch (e) {
      print('[EnhancedUserBehavior] Error recording quick interaction: $e');
    }
  }

  // Get real-time recommendations
  Future<List<Map<String, dynamic>>> getRecommendations({bool forceRefresh = false}) async {
    if (forceRefresh || _shouldRefreshRecommendations()) {
      await _refreshRecommendations();
    }
    return List.from(_cachedRecommendations);
  }

  // Get trending places
  Future<List<Map<String, dynamic>>> getTrendingPlaces({bool forceRefresh = false}) async {
    if (forceRefresh || _shouldRefreshTrending()) {
      await _refreshTrendingPlaces();
    }
    return List.from(_cachedTrendingPlaces);
  }

  // Get user statistics
  Map<String, dynamic> get userStats => Map.from(_userStats);

  // Get the most preferred category
  String get mostPreferredCategory {
    return _userStats['most_preferred_category'] ?? 'beach';
  }

  // Get total interactions count
  int get totalInteractions {
    return _userStats['total_interactions'] ?? 0;
  }

  // Get category interactions
  Map<String, int> get categoryInteractions {
    return Map<String, int>.from(_userStats['category_interactions'] ?? {});
  }

  // Get category priorities
  Map<String, double> get categoryPriorities {
    return Map<String, double>.from(_userStats['category_priorities'] ?? {});
  }

  // Check if user has enough data for personalized recommendations
  bool get hasEnoughDataForRecommendations {
    return totalInteractions >= 3; // Minimum 3 interactions for personalization
  }

  // Get recommendation explanation
  String getRecommendationExplanation() {
    if (!hasEnoughDataForRecommendations) {
      return 'Explore more places to get personalized recommendations!';
    }
    
    final mostPreferred = mostPreferredCategory;
    final interactions = categoryInteractions[mostPreferred] ?? 0;
    
    return 'Based on your $interactions interactions with $mostPreferred places';
  }

  // Reset user data
  Future<void> resetUserData() async {
    try {
      await _recommendationService.resetUserData();
      _cachedRecommendations.clear();
      _cachedTrendingPlaces.clear();
      _userStats.clear();
      _lastRecommendationUpdate = null;
      _lastTrendingUpdate = null;
      
      await _updateUserStats();
      await _refreshRecommendations();
      await _refreshTrendingPlaces();
      
      print('[EnhancedUserBehavior] User data reset');
      notifyListeners();
    } catch (e) {
      print('[EnhancedUserBehavior] Error resetting user data: $e');
    }
  }

  // Private methods
  
  Future<void> _updateUserStats() async {
    try {
      _userStats = _recommendationService.getUserStats();
    } catch (e) {
      print('[EnhancedUserBehavior] Error updating user stats: $e');
    }
  }

  Future<void> _refreshRecommendations() async {
    try {
      _cachedRecommendations = await _recommendationService.getDynamicRecommendations(limit: 10);
      _lastRecommendationUpdate = DateTime.now();
      
      // Save to persistent storage
      await _saveCachedRecommendations();
      
      print('[EnhancedUserBehavior] Recommendations refreshed: ${_cachedRecommendations.length} items');
    } catch (e) {
      print('[EnhancedUserBehavior] Error refreshing recommendations: $e');
    }
  }

  Future<void> _refreshTrendingPlaces() async {
    try {
      _cachedTrendingPlaces = await _recommendationService.getTrendingPlaces(limit: 10);
      _lastTrendingUpdate = DateTime.now();
      
      // Save to persistent storage
      await _saveCachedRecommendations();
      
      print('[EnhancedUserBehavior] Trending places refreshed: ${_cachedTrendingPlaces.length} items');
    } catch (e) {
      print('[EnhancedUserBehavior] Error refreshing trending places: $e');
    }
  }

  Future<void> _refreshRecommendationsIfNeeded() async {
    if (_shouldRefreshRecommendations()) {
      await _refreshRecommendations();
    }
  }

  Future<void> _refreshTrendingPlacesIfNeeded() async {
    if (_shouldRefreshTrending()) {
      await _refreshTrendingPlaces();
    }
  }

  bool _shouldRefreshRecommendations() {
    if (_lastRecommendationUpdate == null) return true;
    
    // Refresh recommendations every 2 minutes or after significant interactions
    final timeSinceLastUpdate = DateTime.now().difference(_lastRecommendationUpdate!);
    return timeSinceLastUpdate.inMinutes >= 2;
  }

  bool _shouldRefreshTrending() {
    if (_lastTrendingUpdate == null) return true;
    
    // Refresh trending every 5 minutes
    final timeSinceLastUpdate = DateTime.now().difference(_lastTrendingUpdate!);
    return timeSinceLastUpdate.inMinutes >= 5;
  }

  // Save cached recommendations to persistent storage
  Future<void> _saveCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save recommendations
      await prefs.setString('cached_recommendations', json.encode(_cachedRecommendations));
      
      // Save trending places
      await prefs.setString('cached_trending_places', json.encode(_cachedTrendingPlaces));
      
      // Save timestamps
      if (_lastRecommendationUpdate != null) {
        await prefs.setString('last_recommendation_update', _lastRecommendationUpdate!.toIso8601String());
      }
      if (_lastTrendingUpdate != null) {
        await prefs.setString('last_trending_update', _lastTrendingUpdate!.toIso8601String());
      }
      
      print('[EnhancedUserBehavior] Cached recommendations saved');
    } catch (e) {
      print('[EnhancedUserBehavior] Error saving cached recommendations: $e');
    }
  }
  
  // Load cached recommendations from persistent storage
  Future<void> _loadCachedRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load recommendations
      final recommendationsStr = prefs.getString('cached_recommendations');
      if (recommendationsStr != null) {
        final decoded = json.decode(recommendationsStr) as List<dynamic>;
        _cachedRecommendations = decoded.cast<Map<String, dynamic>>();
      }
      
      // Load trending places
      final trendingStr = prefs.getString('cached_trending_places');
      if (trendingStr != null) {
        final decoded = json.decode(trendingStr) as List<dynamic>;
        _cachedTrendingPlaces = decoded.cast<Map<String, dynamic>>();
      }
      
      // Load timestamps
      final lastRecommendationStr = prefs.getString('last_recommendation_update');
      if (lastRecommendationStr != null) {
        _lastRecommendationUpdate = DateTime.parse(lastRecommendationStr);
      }
      
      final lastTrendingStr = prefs.getString('last_trending_update');
      if (lastTrendingStr != null) {
        _lastTrendingUpdate = DateTime.parse(lastTrendingStr);
      }
      
      print('[EnhancedUserBehavior] Cached recommendations loaded: ${_cachedRecommendations.length} recommendations, ${_cachedTrendingPlaces.length} trending');
    } catch (e) {
      print('[EnhancedUserBehavior] Error loading cached recommendations: $e');
    }
  }

  @override
  void dispose() {
    // End any ongoing place view
    if (_currentPlaceId != null) {
      endPlaceView();
    }
    super.dispose();
  }
}