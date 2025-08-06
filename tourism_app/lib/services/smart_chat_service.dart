import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:tourism_app/services/database_adapter.dart';
import 'package:tourism_app/services/places_service.dart';
import 'package:tourism_app/services/favorites_service.dart';
import 'package:tourism_app/providers/auth_provider.dart';

class SmartChatService {
  static final DatabaseAdapter _dbHelper = DatabaseAdapter.instance;
  static GenerativeModel? _model;
  static String? _apiKey;

  // Default API key - replace with your actual Gemini API key
  static const String _defaultApiKey = 'AIzaSyBkmPBOnU2uOmuu0Fotj9QXcEKP2vo-GzI';

  // API configuration status
  static final Map<String, bool> _apiStatus = {
    'gemini': false,
  };

  // Initialize with default API key
  static void initialize() {
    configureGeminiKey(_defaultApiKey);
  }

  // Configure Gemini API key
  static bool configureGeminiKey(String geminiKey) {
    try {
      if (geminiKey.isEmpty) {
        return false;
      }

      _apiKey = geminiKey;
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: geminiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      _apiStatus['gemini'] = true;
      print('✅ Gemini AI configured successfully');
      return true;
    } catch (e) {
      print('❌ Error configuring Gemini: $e');
      _apiStatus['gemini'] = false;
      return false;
    }
  }

  // Check API status
  static Map<String, bool> checkApiStatus() {
    return Map.from(_apiStatus);
  }

  // Get current API status
  static Map<String, bool> getApiStatus() {
    return Map.from(_apiStatus);
  }

  // Send message to Gemini AI with full context
  static Future<String> sendSmartMessage(
      String message, String language, AuthProvider authProvider) async {
    try {
      if (_model == null || _apiKey == null) {
        return _getServiceUnavailableMessage(language);
      }

      // Get complete context data
      final userContext = await _getUserContext(authProvider);
      final placesContext = await _getPlacesContext();
      final favoritesContext = await _getFavoritesContext(authProvider);

      // Build comprehensive context prompt
      final contextPrompt = _buildContextPrompt(
        message, language, userContext, placesContext, favoritesContext);

      print('🤖 Sending message to Gemini AI...');
      
      // Send to Gemini AI
      final content = [Content.text(contextPrompt)];
      final response = await _model!.generateContent(content);
      
      final aiResponse = response.text;
      if (aiResponse != null && aiResponse.isNotEmpty) {
        print('✅ Received response from Gemini AI');
        return aiResponse;
      } else {
        print('❌ Empty response from Gemini AI');
        return _getServiceUnavailableMessage(language);
      }
    } catch (e) {
      print('❌ Error communicating with Gemini AI: $e');
      return _getServiceUnavailableMessage(language);
    }
  }

  // Build context prompt for Gemini AI
  static String _buildContextPrompt(
    String message,
    String language,
    Map<String, dynamic> userContext,
    List<Map<String, dynamic>> placesContext,
    List<Map<String, dynamic>> favoritesContext,
  ) {
    final userName = userContext['full_name'] ?? userContext['username'] ?? 
                    (language == 'so' ? 'Saaxiib' : 'Friend');
    
    final prompt = '''
You are a smart tourism assistant for Somalia. Your name is "Somalia Tourism AI Assistant".

User Information:
- Name: $userName
- Language: ${language == 'so' ? 'Somali' : 'English'}
- Logged in: ${userContext['is_logged_in'] ?? false}

Available Places (${placesContext.length} total):
${_formatPlacesData(placesContext)}

User's Favorites (${favoritesContext.length} total):
${_formatFavoritesData(favoritesContext)}

Instructions:
1. Always respond in ${language == 'so' ? 'Somali' : 'English'} language
2. Be helpful, friendly, and knowledgeable about Somalia tourism
3. Use the provided data to give accurate information about places, prices, and recommendations
4. Include relevant emojis to make responses engaging
5. Address the user by their name when appropriate
6. Provide specific details from the places data when recommending locations
7. Consider the user's favorites when making recommendations
8. Be concise but informative

User's Question: $message

Please provide a helpful response based on the context above.''';

    return prompt;
  }

  // Format places data for context
  static String _formatPlacesData(List<Map<String, dynamic>> places) {
    if (places.isEmpty) return 'No places available';
    
    final buffer = StringBuffer();
    for (int i = 0; i < places.length && i < 20; i++) { // Limit to first 20 places
      final place = places[i];
      buffer.writeln('- ${place['name_eng']} (${place['name_som']})');
      buffer.writeln('  Category: ${place['category']}');
      buffer.writeln('  Location: ${place['location']}');
      buffer.writeln('  Price: \$${place['pricePerPerson'] ?? place['price_per_person'] ?? 'Free'}');
      if (place['desc_eng'] != null) {
        final desc = place['desc_eng'].toString();
        buffer.writeln('  Description: ${desc.length > 100 ? desc.substring(0, 100) + '...' : desc}');
      }
      buffer.writeln('');
    }
    
    if (places.length > 20) {
      buffer.writeln('... and ${places.length - 20} more places');
    }
    
    return buffer.toString();
  }

  // Format favorites data for context
  static String _formatFavoritesData(List<Map<String, dynamic>> favorites) {
    if (favorites.isEmpty) return 'No favorites yet';
    
    final buffer = StringBuffer();
    for (final favorite in favorites) {
      buffer.writeln('- ${favorite['name_eng']} (${favorite['category']})');
    }
    
    return buffer.toString();
  }

  // Service unavailable message
  static String _getServiceUnavailableMessage(String language) {
    return language == 'so'
        ? '⚠️ Waan ka xumahay, adeegga AI-ga hadda lama heli karo. Fadlan API key-ga Gemini hubi ama mar kale isku day.'
        : '⚠️ Sorry, the AI service is currently unavailable. Please check your Gemini API key or try again later.';
  }



  // Get user context for personalization
  static Future<Map<String, dynamic>> _getUserContext(
      AuthProvider authProvider) async {
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

  // Get complete places context with full JSON from backend
  static Future<List<Map<String, dynamic>>> _getPlacesContext() async {
    try {
      // Get the complete JSON data from backend API
      final places = await PlacesService.getAllPlaces();
      print('🔍 AI Support: Found ${places.length} places from backend API');

      // Return the complete JSON data without filtering
      return places;
    } catch (e) {
      print('❌ AI Support: Error fetching places from backend: $e');
      // Fallback to local database if backend fails
      try {
        if (_dbHelper.supportsPlaces) {
          final places = await _dbHelper.getAllPlaces();
          print(
              '🔄 AI Support: Fallback to local database, found ${places.length} places');
          return places;
        }
      } catch (fallbackError) {
        print(
            '❌ AI Support: Fallback to local database also failed: $fallbackError');
      }
      return [];
    }
  }

  // Get complete user favorites context with full JSON from backend
  static Future<List<Map<String, dynamic>>> _getFavoritesContext(
      AuthProvider authProvider) async {
    try {
      final user = authProvider.currentUser;
      if (user == null) {
        print('🔍 AI Support: No user logged in, skipping favorites');
        return [];
      }

      // Get the complete JSON data from backend API
      final favorites = await FavoritesService.getFavorites();
      print(
          '🔍 AI Support: Found ${favorites.length} favorites from backend API');

      // Return the complete JSON data without filtering
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
            print(
                '🔄 AI Support: Fallback to local database, found ${favorites.length} favorites');
            return favorites;
          }
        }
      } catch (fallbackError) {
        print(
            '❌ AI Support: Fallback to local database also failed: $fallbackError');
      }
      return [];
    }
  }
}
