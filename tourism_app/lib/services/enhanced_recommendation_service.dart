import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourism_app/services/places_service.dart';

class EnhancedRecommendationService {
  static final EnhancedRecommendationService _instance =
      EnhancedRecommendationService._internal();
  factory EnhancedRecommendationService() => _instance;
  EnhancedRecommendationService._internal();

  // User interaction tracking - Dynamic categories
  Map<String, int> _categoryInteractions = {};
  Map<String, double> _categoryViewTimes = {};

  Map<String, int> _placeInteractions = {};
  Map<String, DateTime> _lastInteractionTimes = {};

  // Trending calculation
  final Map<String, double> _trendingScores = {};
  DateTime? _lastTrendingUpdate;

  // Initialize the service
  Future<void> initialize() async {
    await _loadUserInteractions();
    await _calculateTrendingScores();
  }

  // Record user interaction with a category
  Future<void> recordCategoryInteraction(String category,
      {double viewTime = 0.0}) async {
    // Normalize category name to lowercase for consistency
    final normalizedCategory = category.toLowerCase().trim();

    if (!_categoryInteractions.containsKey(normalizedCategory)) {
      _categoryInteractions[normalizedCategory] = 0;
      _categoryViewTimes[normalizedCategory] = 0.0;
    }

    _categoryInteractions[normalizedCategory] =
        (_categoryInteractions[normalizedCategory] ?? 0) + 1;
    _categoryViewTimes[normalizedCategory] =
        (_categoryViewTimes[normalizedCategory] ?? 0.0) + viewTime;
    _lastInteractionTimes[normalizedCategory] = DateTime.now();

    print(
        '[EnhancedRecommendation] Category interaction recorded: $normalizedCategory (${_categoryInteractions[normalizedCategory]} times)');

    await _saveUserInteractions();
    await _updateTrendingScores();
  }

  // Record user interaction with a specific place
  Future<void> recordPlaceInteraction(String placeId, String category,
      {double viewTime = 0.0}) async {
    _placeInteractions[placeId] = (_placeInteractions[placeId] ?? 0) + 1;

    // Also record category interaction
    await recordCategoryInteraction(category, viewTime: viewTime);

    print(
        '[EnhancedRecommendation] Place interaction recorded: $placeId in $category');
  }

  // Get dynamic recommendations based on user behavior
  Future<List<Map<String, dynamic>>> getDynamicRecommendations(
      {int limit = 10}) async {
    try {
      // Calculate category priorities based on interactions
      final categoryPriorities = _calculateCategoryPriorities();

      print(
          '[EnhancedRecommendation] Category priorities: $categoryPriorities');

      List<Map<String, dynamic>> recommendations = [];

      // If no user interactions, get places from all categories with equal priority
      if (categoryPriorities.isEmpty) {
        try {
          final allPlaces = await PlacesService.getAllPlaces();

          // Add equal recommendation score to all places
          for (final place in allPlaces) {
            place['recommendation_score'] = 50.0; // Base score for new users
            place['recommendation_reason'] = 'Discover amazing places';
          }

          // Shuffle for variety and limit results
          allPlaces.shuffle();
          return allPlaces.take(limit).toList();
        } catch (e) {
          print('[EnhancedRecommendation] Error getting all places: $e');
          return [];
        }
      }

      // Get places for each category based on priority
      for (final entry in categoryPriorities.entries) {
        final category = entry.key;
        final priority = entry.value;

        if (priority > 0) {
          try {
            final categoryPlaces =
                await PlacesService.getPlacesByCategory(category);

            // Calculate recommendation score for each place
            for (final place in categoryPlaces) {
              final placeId = place['id']?.toString() ??
                  place['name_eng']?.toString() ??
                  '';
              final placeInteractionCount = _placeInteractions[placeId] ?? 0;

              // Calculate recommendation score
              final score = _calculateRecommendationScore(
                categoryPriority: priority,
                placeInteractions: placeInteractionCount,
                category: category,
              );

              place['recommendation_score'] = score;
              place['recommendation_reason'] =
                  _getRecommendationReason(category, priority);
            }

            recommendations.addAll(categoryPlaces);
          } catch (e) {
            print(
                '[EnhancedRecommendation] Error getting places for category $category: $e');
          }
        }
      }

      // Sort by recommendation score and limit results
      recommendations.sort((a, b) => (b['recommendation_score'] ?? 0.0)
          .compareTo(a['recommendation_score'] ?? 0.0));

      return recommendations.take(limit).toList();
    } catch (e) {
      print(
          '[EnhancedRecommendation] Error getting dynamic recommendations: $e');
      return [];
    }
  }

  // Get trending places based on recent interactions
  Future<List<Map<String, dynamic>>> getTrendingPlaces({int limit = 10}) async {
    try {
      await _updateTrendingScores();

      final allPlaces = await PlacesService.getAllPlaces();

      // Calculate trending score for each place
      for (final place in allPlaces) {
        final placeId =
            place['id']?.toString() ?? place['name_eng']?.toString() ?? '';
        final category = place['category']?.toString().toLowerCase() ?? '';

        final trendingScore = _calculateTrendingScore(placeId, category);
        place['trending_score'] = trendingScore;
      }

      // Sort by trending score
      allPlaces.sort((a, b) =>
          (b['trending_score'] ?? 0.0).compareTo(a['trending_score'] ?? 0.0));

      return allPlaces.take(limit).toList();
    } catch (e) {
      print('[EnhancedRecommendation] Error getting trending places: $e');
      return [];
    }
  }

  // Calculate category priorities based on user interactions
  Map<String, double> _calculateCategoryPriorities() {
    final totalInteractions =
        _categoryInteractions.values.fold(0, (sum, count) => sum + count);

    if (totalInteractions == 0) {
      // Return empty map if no interactions - will be handled in getDynamicRecommendations
      return {};
    }

    final priorities = <String, double>{};

    // Sort categories by interaction count to prioritize most clicked
    final sortedCategories = _categoryInteractions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      final category = entry.key;
      final interactions = entry.value;
      final viewTime = _categoryViewTimes[category] ?? 0.0;

      // Calculate priority based on interactions (higher interactions = higher priority)
      double priority = interactions / totalInteractions;

      // Boost priority based on average view time
      if (interactions > 0) {
        final avgViewTime = viewTime / interactions;
        priority *= (1 + (avgViewTime / 60.0)); // Boost based on minutes viewed
      }

      // Apply recency boost (recent interactions are more valuable)
      final lastInteraction = _lastInteractionTimes[category];
      if (lastInteraction != null) {
        final daysSinceLastInteraction =
            DateTime.now().difference(lastInteraction).inDays;
        final recencyBoost = 1.0 / (1.0 + daysSinceLastInteraction * 0.1);
        priority *= recencyBoost;
      }

      priorities[category] = priority;
    }

    print(
        '[EnhancedRecommendation] Category priorities calculated: $priorities');
    return priorities;
  }

  // Calculate recommendation score for a place
  double _calculateRecommendationScore({
    required double categoryPriority,
    required int placeInteractions,
    required String category,
  }) {
    double score = categoryPriority * 100;

    // Reduce score for places already heavily interacted with (diversity)
    if (placeInteractions > 0) {
      score *= (1.0 / (1.0 + placeInteractions * 0.2));
    }

    // Add randomness for discovery
    score += (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;

    return score;
  }

  // Calculate trending score for a place
  double _calculateTrendingScore(String placeId, String category) {
    final placeInteractions = _placeInteractions[placeId] ?? 0;
    final categoryInteractions = _categoryInteractions[category] ?? 0;

    // Base score from interactions
    double score = placeInteractions * 10.0 + categoryInteractions * 2.0;

    // Apply time decay (recent interactions are more valuable)
    final lastInteraction = _lastInteractionTimes[category];
    if (lastInteraction != null) {
      final hoursSinceLastInteraction =
          DateTime.now().difference(lastInteraction).inHours;
      final timeDecay = 1.0 / (1.0 + hoursSinceLastInteraction * 0.1);
      score *= timeDecay;
    }

    return score;
  }

  // Get recommendation reason text
  String _getRecommendationReason(String category, double priority) {
    final percentage = (priority * 100).round();
    return 'Based on your $percentage% preference for $category places';
  }

  // Save user interactions to persistent storage
  Future<void> _saveUserInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
          'category_interactions', json.encode(_categoryInteractions));
      await prefs.setString(
          'category_view_times', json.encode(_categoryViewTimes));
      await prefs.setString(
          'place_interactions', json.encode(_placeInteractions));

      // Save last interaction times as timestamps
      final lastInteractionTimestamps = <String, int>{};
      for (final entry in _lastInteractionTimes.entries) {
        lastInteractionTimestamps[entry.key] =
            entry.value.millisecondsSinceEpoch;
      }
      await prefs.setString(
          'last_interaction_times', json.encode(lastInteractionTimestamps));
      
      // Save timestamp of last save for debugging
      await prefs.setString('last_data_save', DateTime.now().toIso8601String());
      
      print('[EnhancedRecommendation] User interactions saved successfully');
    } catch (e) {
      print('[EnhancedRecommendation] Error saving user interactions: $e');
    }
  }

  // Load user interactions from persistent storage
  Future<void> _loadUserInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final categoryInteractionsStr = prefs.getString('category_interactions');
      if (categoryInteractionsStr != null) {
        final decoded =
            json.decode(categoryInteractionsStr) as Map<String, dynamic>;
        _categoryInteractions =
            decoded.map((key, value) => MapEntry(key, value as int));
      }

      final categoryViewTimesStr = prefs.getString('category_view_times');
      if (categoryViewTimesStr != null) {
        final decoded =
            json.decode(categoryViewTimesStr) as Map<String, dynamic>;
        _categoryViewTimes = decoded
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
      }

      final placeInteractionsStr = prefs.getString('place_interactions');
      if (placeInteractionsStr != null) {
        final decoded =
            json.decode(placeInteractionsStr) as Map<String, dynamic>;
        _placeInteractions =
            decoded.map((key, value) => MapEntry(key, value as int));
      }

      final lastInteractionTimesStr = prefs.getString('last_interaction_times');
      if (lastInteractionTimesStr != null) {
        final decoded =
            json.decode(lastInteractionTimesStr) as Map<String, dynamic>;
        _lastInteractionTimes = decoded.map((key, value) =>
            MapEntry(key, DateTime.fromMillisecondsSinceEpoch(value as int)));
      }

      print(
          '[EnhancedRecommendation] User interactions loaded: $_categoryInteractions');
    } catch (e) {
      print('[EnhancedRecommendation] Error loading user interactions: $e');
    }
  }

  // Calculate and update trending scores
  Future<void> _calculateTrendingScores() async {
    _lastTrendingUpdate = DateTime.now();
    // Trending scores are calculated on-demand in getTrendingPlaces
  }

  // Update trending scores (called after each interaction)
  Future<void> _updateTrendingScores() async {
    final now = DateTime.now();
    if (_lastTrendingUpdate == null ||
        now.difference(_lastTrendingUpdate!).inMinutes > 5) {
      await _calculateTrendingScores();
    }
  }

  // Get user interaction statistics
  Map<String, dynamic> getUserStats() {
    final totalInteractions =
        _categoryInteractions.values.fold(0, (sum, count) => sum + count);
    final priorities = _calculateCategoryPriorities();

    return {
      'total_interactions': totalInteractions,
      'category_interactions': Map.from(_categoryInteractions),
      'category_priorities': priorities,
      'most_preferred_category':
          priorities.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    };
  }

  // Reset user data (for testing or user preference)
  Future<void> resetUserData() async {
    _categoryInteractions.clear();
    _categoryViewTimes.clear();
    _placeInteractions.clear();
    _lastInteractionTimes.clear();
    _trendingScores.clear();

    await _saveUserInteractions();
    print('[EnhancedRecommendation] User data reset');
  }
}
