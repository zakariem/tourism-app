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
    
    // Clean up old data periodically (check if last cleanup was more than 7 days ago)
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanupStr = prefs.getString('last_data_cleanup');
      final now = DateTime.now();
      
      bool shouldCleanup = lastCleanupStr == null;
      if (lastCleanupStr != null) {
        try {
          final lastCleanup = DateTime.parse(lastCleanupStr);
          shouldCleanup = now.difference(lastCleanup).inDays >= 7;
        } catch (parseError) {
          shouldCleanup = true; // Force cleanup if timestamp is corrupted
        }
      }
      
      if (shouldCleanup) {
        await _cleanupOldData();
        await prefs.setString('last_data_cleanup', now.toIso8601String());
      }
    } catch (e) {
      print('[EnhancedRecommendation] Error during cleanup check: $e');
    }
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
            // Ensure essential fields are not null
            place['id'] = place['id']?.toString() ?? '';
            place['name_eng'] = place['name_eng']?.toString() ?? place['name']?.toString() ?? '';
            place['category'] = place['category']?.toString() ?? '';
            place['description'] = place['description']?.toString() ?? '';
            place['location'] = place['location']?.toString() ?? '';
            
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
              // Ensure essential fields are not null
              place['id'] = place['id']?.toString() ?? '';
              place['name_eng'] = place['name_eng']?.toString() ?? place['name']?.toString() ?? '';
              place['category'] = place['category']?.toString() ?? '';
              place['description'] = place['description']?.toString() ?? '';
              place['location'] = place['location']?.toString() ?? '';
              
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
        // Ensure essential fields are not null
        place['id'] = place['id']?.toString() ?? '';
        place['name_eng'] = place['name_eng']?.toString() ?? place['name']?.toString() ?? '';
        place['category'] = place['category']?.toString() ?? '';
        place['description'] = place['description']?.toString() ?? '';
        place['location'] = place['location']?.toString() ?? '';
        
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

      // Check data size before saving to prevent quota issues
      final categoryJson = json.encode(_categoryInteractions);
      final viewTimesJson = json.encode(_categoryViewTimes);
      final placeJson = json.encode(_placeInteractions);
      
      // Only save if data is reasonable size (less than 100KB each)
      if (categoryJson.length < 100000) {
        await prefs.setString('category_interactions', categoryJson);
      }
      if (viewTimesJson.length < 100000) {
        await prefs.setString('category_view_times', viewTimesJson);
      }
      if (placeJson.length < 100000) {
        await prefs.setString('place_interactions', placeJson);
      }

      // Save last interaction times as timestamps
      final lastInteractionTimestamps = <String, int>{};
      for (final entry in _lastInteractionTimes.entries) {
        lastInteractionTimestamps[entry.key] =
            entry.value.millisecondsSinceEpoch;
      }
      final timestampsJson = json.encode(lastInteractionTimestamps);
      if (timestampsJson.length < 100000) {
        await prefs.setString('last_interaction_times', timestampsJson);
      }
      
      // Save timestamp of last save for debugging
      await prefs.setString('last_data_save', DateTime.now().toIso8601String());
      
      print('[EnhancedRecommendation] User interactions saved successfully');
    } catch (e) {
      print('[EnhancedRecommendation] Error saving user interactions: $e');
      // If quota exceeded, clear some old data
      if (e.toString().contains('QuotaExceededError')) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('place_interactions'); // Clear least important data first
          print('[EnhancedRecommendation] Cleared place interactions due to quota limit');
        } catch (clearError) {
          print('[EnhancedRecommendation] Error clearing data: $clearError');
        }
      }
    }
  }

  // Load user interactions from persistent storage
  Future<void> _loadUserInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load category interactions with error handling
      final categoryInteractionsStr = prefs.getString('category_interactions');
      if (categoryInteractionsStr != null && categoryInteractionsStr.isNotEmpty) {
        try {
          final decoded = json.decode(categoryInteractionsStr) as Map<String, dynamic>;
          _categoryInteractions = decoded.map((key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0));
        } catch (decodeError) {
          print('[EnhancedRecommendation] Error decoding category interactions, resetting: $decodeError');
          await prefs.remove('category_interactions');
          _categoryInteractions = {};
        }
      }

      // Load category view times with error handling
      final categoryViewTimesStr = prefs.getString('category_view_times');
      if (categoryViewTimesStr != null && categoryViewTimesStr.isNotEmpty) {
        try {
          final decoded = json.decode(categoryViewTimesStr) as Map<String, dynamic>;
          _categoryViewTimes = decoded.map((key, value) => MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0.0));
        } catch (decodeError) {
          print('[EnhancedRecommendation] Error decoding category view times, resetting: $decodeError');
          await prefs.remove('category_view_times');
          _categoryViewTimes = {};
        }
      }

      // Load place interactions with error handling
      final placeInteractionsStr = prefs.getString('place_interactions');
      if (placeInteractionsStr != null && placeInteractionsStr.isNotEmpty) {
        try {
          final decoded = json.decode(placeInteractionsStr) as Map<String, dynamic>;
          _placeInteractions = decoded.map((key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0));
        } catch (decodeError) {
          print('[EnhancedRecommendation] Error decoding place interactions, resetting: $decodeError');
          await prefs.remove('place_interactions');
          _placeInteractions = {};
        }
      }

      // Load last interaction times with error handling
      final lastInteractionTimesStr = prefs.getString('last_interaction_times');
      if (lastInteractionTimesStr != null && lastInteractionTimesStr.isNotEmpty) {
        try {
          final decoded = json.decode(lastInteractionTimesStr) as Map<String, dynamic>;
          _lastInteractionTimes = decoded.map((key, value) {
            final timestamp = (value as num?)?.toInt() ?? 0;
            return MapEntry(key.toString(), DateTime.fromMillisecondsSinceEpoch(timestamp));
          });
        } catch (decodeError) {
          print('[EnhancedRecommendation] Error decoding interaction times, resetting: $decodeError');
          await prefs.remove('last_interaction_times');
          _lastInteractionTimes = {};
        }
      }

      print('[EnhancedRecommendation] User interactions loaded: $_categoryInteractions');
    } catch (e) {
      print('[EnhancedRecommendation] Error loading user interactions: $e');
      // Reset all data on critical error
      _categoryInteractions = {};
      _categoryViewTimes = {};
      _placeInteractions = {};
      _lastInteractionTimes = {};
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

    // Find most preferred category safely
    String? mostPreferredCategory;
    if (priorities.isNotEmpty) {
      mostPreferredCategory = priorities.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return {
      'total_interactions': totalInteractions,
      'category_interactions': Map.from(_categoryInteractions),
      'category_priorities': priorities,
      'most_preferred_category': mostPreferredCategory ?? 'beach', // Default fallback
    };
  }

  // Clean up old data to prevent storage quota issues
  Future<void> _cleanupOldData() async {
    try {
      // Remove interactions older than 30 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final keysToRemove = <String>[];
      
      for (final entry in _lastInteractionTimes.entries) {
        if (entry.value.isBefore(cutoffDate)) {
          keysToRemove.add(entry.key);
        }
      }
      
      // Remove old interactions
      for (final key in keysToRemove) {
        _categoryInteractions.remove(key);
        _categoryViewTimes.remove(key);
        _lastInteractionTimes.remove(key);
      }
      
      // Limit place interactions to most recent 100
      if (_placeInteractions.length > 100) {
        final sortedPlaces = _placeInteractions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _placeInteractions.clear();
        _placeInteractions.addAll(Map.fromEntries(sortedPlaces.take(100)));
      }
      
      if (keysToRemove.isNotEmpty) {
        await _saveUserInteractions();
        print('[EnhancedRecommendation] Cleaned up ${keysToRemove.length} old interactions');
      }
    } catch (e) {
      print('[EnhancedRecommendation] Error cleaning up old data: $e');
    }
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
