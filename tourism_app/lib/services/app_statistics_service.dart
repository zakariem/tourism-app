import 'package:tourism_app/services/places_service.dart';
import 'package:tourism_app/services/favorites_service.dart';
import 'package:tourism_app/providers/enhanced_user_behavior_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';

class AppStatisticsService {
  static Future<Map<String, dynamic>> getAppStatistics({
    EnhancedUserBehaviorProvider? userBehavior,
    AuthProvider? authProvider,
  }) async {
    try {
      // Get all places data
      final places = await PlacesService.getAllPlaces();
      
      // Get user favorites count
      int favoritesCount = 0;
      try {
        if (authProvider?.isAuthenticated == true) {
          final favorites = await FavoritesService.getFavorites();
          favoritesCount = favorites.length;
        }
      } catch (e) {
        print('Could not fetch favorites: $e');
      }
      
      // Calculate categories
      final categories = <String>{};
      for (final place in places) {
        final category = place['category']?.toString();
        if (category != null && category.isNotEmpty) {
          categories.add(category.toLowerCase());
        }
      }
      
      // Calculate user activity stats
      int totalClicks = 0;
      String mostActiveCategory = 'beach';
      if (userBehavior != null) {
        final categoryInteractions = userBehavior.categoryInteractions;
        totalClicks = categoryInteractions.values.fold(0, (sum, count) => sum + count);
        
        // Find most active category
        final clickCounts = {
          'beach': categoryInteractions['beach'] ?? 0,
          'historical': categoryInteractions['historical'] ?? 0,
          'cultural': categoryInteractions['cultural'] ?? 0,
          'religious': categoryInteractions['religious'] ?? 0,
        };
        
        mostActiveCategory = clickCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }
      
      return {
        'totalPlaces': places.length,
        'categoriesCount': categories.length,
        'favoritesCount': favoritesCount,
        'userClicks': totalClicks,
        'mostActiveCategory': mostActiveCategory,
        'avgViewTime': 0.0, // Not available in enhanced provider
        'viewCount': userBehavior?.totalInteractions ?? 0,
        'categories': categories.toList(),
      };
    } catch (e) {
      print('Error getting app statistics: $e');
      // Return default values on error
      return {
        'totalPlaces': 0,
        'categoriesCount': 4, // Default categories
        'favoritesCount': 0,
        'userClicks': 0,
        'mostActiveCategory': 'beach',
        'avgViewTime': 0.0,
        'viewCount': 0,
        'categories': ['beach', 'historical', 'cultural', 'religious'],
      };
    }
  }
}