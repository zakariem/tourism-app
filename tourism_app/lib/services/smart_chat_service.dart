import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tourism_app/services/database_adapter.dart';
import 'package:tourism_app/services/places_service.dart';
import 'package:tourism_app/services/favorites_service.dart';
import 'package:tourism_app/providers/auth_provider.dart';

class SmartChatService {
  static const String _baseUrl = 'http://localhost:5000';
  static const String _fallbackUrl = 'http://10.0.2.2:5000';
  static const String _networkUrl = 'http://10.1.1.33:5000';
  
  static final DatabaseAdapter _dbHelper = DatabaseAdapter.instance;
  
  // API configuration status
  static Map<String, bool> _apiStatus = {
    'gemini': false,
    'openai': false,
    'claude': false,
    'backend_available': false,
  };

  // Configure API key for external AI services
  static Future<bool> configureApiKey({
    String? geminiKey,
    String? openaiKey,
    String? claudeKey,
  }) async {
    try {
      final payload = <String, String>{};
      
      if (geminiKey != null && geminiKey.isNotEmpty) {
        payload['gemini_api_key'] = geminiKey;
      }
      if (openaiKey != null && openaiKey.isNotEmpty) {
        payload['openai_api_key'] = openaiKey;
      }
      if (claudeKey != null && claudeKey.isNotEmpty) {
        payload['claude_api_key'] = claudeKey;
      }
      
      if (payload.isEmpty) {
        return false;
      }
      
      final urls = [_baseUrl, _fallbackUrl, _networkUrl];
      
      for (String url in urls) {
        try {
          final response = await http.post(
            Uri.parse('$url/set-api-key'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              // Update API status
              if (geminiKey != null) _apiStatus['gemini'] = true;
              if (openaiKey != null) _apiStatus['openai'] = true;
              if (claudeKey != null) _apiStatus['claude'] = true;
              _apiStatus['backend_available'] = true;
              return true;
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check API status
  static Future<Map<String, bool>> checkApiStatus() async {
    try {
      final urls = [_baseUrl, _fallbackUrl, _networkUrl];
      
      for (String url in urls) {
        try {
          final response = await http.get(
            Uri.parse('$url/health'),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['api_keys_configured'] != null) {
              _apiStatus['gemini'] = data['api_keys_configured']['gemini'] ?? false;
              _apiStatus['openai'] = data['api_keys_configured']['openai'] ?? false;
              _apiStatus['claude'] = data['api_keys_configured']['claude'] ?? false;
              _apiStatus['backend_available'] = true;
              return _apiStatus;
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      _apiStatus['backend_available'] = false;
      return _apiStatus;
    } catch (e) {
      _apiStatus['backend_available'] = false;
      return _apiStatus;
    }
  }

  // Get current API status
  static Map<String, bool> getApiStatus() {
    return Map.from(_apiStatus);
  }

  // Optimized message sending with faster response
  static Future<String> sendSmartMessage(
    String message, 
    String language, 
    AuthProvider authProvider
  ) async {
    try {
      // Quick context gathering - get all data for accurate counts
      final userContext = await _getUserContext(authProvider);
      final placesContext = await _getPlacesContext(); // Get all places
      final favoritesContext = await _getFavoritesContext(authProvider); // Get all favorites
      
      // Optimized payload - complete but efficient
      final payload = {
        'message': message,
        'language': language,
        'user_context': userContext,
        'places_data': placesContext,
        'favorites_data': favoritesContext,
      };

      // Try backend with optimized timeout for speed
      final urls = [_baseUrl, _fallbackUrl, _networkUrl];
      
      for (String url in urls) {
        try {
          final response = await http.post(
            Uri.parse('$url/smart-chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 5)); // Faster timeout

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return data['response'] ?? 'Sorry, I couldn\'t process that request.';
          }
        } catch (e) {
          continue;
        }
      }
      
      // Fast fallback response
      return _getFastOfflineResponse(message, language, userContext, placesContext);
      
    } catch (e) {
      return _getFastOfflineResponse(message, language, {}, []);
    }
  }

  // Fast offline response for quick fallback
  static String _getFastOfflineResponse(
    String message,
    String language,
    Map<String, dynamic> userContext,
    List<Map<String, dynamic>> placesContext,
  ) {
    final messageLower = message.toLowerCase();
    final userName = userContext['full_name'] ?? userContext['username'] ?? (language == 'so' ? 'Saaxiib' : 'Friend');
    
    // Quick greeting response
    if (_isGreeting(messageLower)) {
      return language == 'so'
          ? '🌟 Salaam $userName! Sidee kuu caawin karaa dalxiiska Soomaaliya?'
          : '🌟 Hello $userName! How can I help you with Somalia tourism?';
    }

    // Quick list all places response
    if (_isListAllQuery(messageLower)) {
      final placesCount = placesContext.length;
      return language == 'so'
          ? '📍 $userName, waxaan haynaa $placesCount meel oo dalxiis ah. Halkan waa kuwa ugu muhiimsan...'
          : '📍 $userName, we have $placesCount tourism places. Here are the highlights...';
    }

    // Quick free places response
    if (_isFreeQuery(messageLower)) {
      final freePlaces = placesContext.where((place) => (place['price_per_person'] ?? 0) == 0).length;
      return language == 'so'
          ? '🆓 $userName, waxaan haynaa $freePlaces meel oo bilaash ah!'
          : '🆓 $userName, we have $freePlaces free places available!';
    }

    // Quick cost response
    if (_isCostQuery(messageLower)) {
      final freePlaces = placesContext.where((place) => (place['price_per_person'] ?? 0) == 0).length;
      return language == 'so'
          ? '💰 $userName, qiimaha guud: Xeebaha \$3-12, Taariikhiga \$5-25. Waxaa jira $freePlaces meel oo bilaash ah!'
          : '💰 $userName, general costs: Beaches \$3-12, Historical \$5-25. We have $freePlaces free places!';
    }

    // Quick place recommendation
    if (_isPlaceQuery(messageLower)) {
      return language == 'so'
          ? '🏖️ $userName, waxaan kugula talinayaa Lido Beach, Laas Geel, iyo Zeila.'
          : '🏖️ $userName, I recommend Lido Beach, Laas Geel, and Zeila.';
    }

    // Default quick response
     return language == 'so'
         ? '🤖 $userName, wax ka weydiiso dalxiiska Soomaaliya!'
         : '🤖 $userName, ask me about Somalia tourism!';
   }
   
   // Helper methods for enhanced intent detection
   static bool _isGreeting(String message) {
     return ['hello', 'hi', 'salaam', 'hey', 'good morning'].any((greeting) => message.contains(greeting));
   }
   
   static bool _isCostQuery(String message) {
     return ['cost', 'price', 'expensive', 'cheap', 'budget', 'money', 'free', 'zero'].any((word) => message.contains(word));
   }
   
   static bool _isListAllQuery(String message) {
     return ['list all', 'show all', 'all places', 'every place', 'complete list', 'full list', 'everything available'].any((phrase) => message.contains(phrase));
   }
   
   static bool _isFreeQuery(String message) {
     return ['free', 'no cost', 'zero cost', 'without charge', 'complimentary', 'free places'].any((phrase) => message.contains(phrase));
   }
   
   static bool _isPlaceQuery(String message) {
     return ['place', 'recommend', 'suggest', 'visit', 'where', 'best'].any((word) => message.contains(word));
   }

  // Get user context for personalization
  static Future<Map<String, dynamic>> _getUserContext(AuthProvider authProvider) async {
    try {
      final user = authProvider.currentUser;
      if (user == null) return {};
      
      return {
        'id': user['id'] ?? user['_id'],
        'username': user['username'] ?? 'User',
        'full_name': user['full_name'] ?? user['username'] ?? 'User',
        'email': user['email'],
        'is_logged_in': true,
      };
    } catch (e) {
      return {'is_logged_in': false};
    }
  }

  // Get optimized places context - using same source as home tab
  static Future<List<Map<String, dynamic>>> _getPlacesContext() async {
    try {
      // Use PlacesService to get the same data as home tab
      final places = await PlacesService.getAllPlaces();
      print('🔍 AI Support: Found ${places.length} places from backend API');
      
      return places.map((place) => {
        'id': place['id'] ?? place['_id'],
        'name_eng': place['name_eng'],
        'name_som': place['name_som'],
        'category': place['category'],
        'location': place['location'],
        'price_per_person': place['pricePerPerson'] ?? place['price_per_person'] ?? 5.0,
        'description_eng': place['desc_eng'],
        'description_som': place['desc_som'],
        'image_url': place['image_url'],
        'image_data': place['image_data'],
      }).toList();
    } catch (e) {
      print('❌ AI Support: Error fetching places from backend: $e');
      // Fallback to local database if backend fails
      try {
        if (_dbHelper.supportsPlaces) {
          final places = await _dbHelper.getAllPlaces();
          print('🔄 AI Support: Fallback to local database, found ${places.length} places');
          return places.map((place) => {
            'id': place['id'] ?? place['_id'],
            'name_eng': place['name_eng'],
            'name_som': place['name_som'],
            'category': place['category'],
            'location': place['location'],
            'price_per_person': place['pricePerPerson'] ?? place['price_per_person'] ?? 5.0,
            'description_eng': place['desc_eng'],
            'description_som': place['desc_som'],
          }).toList();
        }
      } catch (fallbackError) {
        print('❌ AI Support: Fallback to local database also failed: $fallbackError');
      }
      return [];
    }
  }

  // Get optimized user favorites context - using same source as home tab
  static Future<List<Map<String, dynamic>>> _getFavoritesContext(AuthProvider authProvider) async {
    try {
      final user = authProvider.currentUser;
      if (user == null) {
        print('🔍 AI Support: No user logged in, skipping favorites');
        return [];
      }
      
      // Use FavoritesService to get the same data as home tab
      final favorites = await FavoritesService.getFavorites();
      print('🔍 AI Support: Found ${favorites.length} favorites from backend API');
      
      return favorites;
    } catch (e) {
      print('❌ AI Support: Error fetching favorites from backend: $e');
      // Fallback to local database if backend fails
      try {
        if (_dbHelper.supportsFavorites) {
          final user = authProvider.currentUser;
          if (user != null) {
            final userId = user['id'] ?? user['_id'];
            final favorites = await _dbHelper.getFavoritePlaces(userId);
            print('🔄 AI Support: Fallback to local database, found ${favorites.length} favorites');
            return favorites;
          }
        }
      } catch (fallbackError) {
        print('❌ AI Support: Fallback to local database also failed: $fallbackError');
      }
      return [];
    }
  }

  // Enhanced offline response with context awareness

}