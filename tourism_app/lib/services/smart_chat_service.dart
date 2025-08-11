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

      // Check for user frustration first
      final isFrustrated = _detectFrustration(message);
      
      // If user is frustrated, provide support contact information
      if (isFrustrated) {
        return _getFrustrationSupportMessage(language);
      }
      
      // Detect the actual language of the user's message
      final detectedLanguage = _detectMessageLanguage(message);
      
      // Use detected language if it differs from app language
      final responseLanguage = detectedLanguage ?? language;

      // Get complete context data
      final userContext = await _getUserContext(authProvider);
      final placesContext = await _getPlacesContext();
      final favoritesContext = await _getFavoritesContext(authProvider);

      // Build comprehensive context prompt with detected language
      final contextPrompt = _buildContextPrompt(
        message, responseLanguage, userContext, placesContext, favoritesContext);

      print('🤖 Sending message to Gemini AI...');
      print('🔍 Detected language: $detectedLanguage, App language: $language, Response language: $responseLanguage');
      
      // Send to Gemini AI
      final content = [Content.text(contextPrompt)];
      final response = await _model!.generateContent(content);
      
      final aiResponse = response.text;
      if (aiResponse != null && aiResponse.isNotEmpty) {
        print('✅ Received response from Gemini AI');
        return aiResponse;
      } else {
        print('❌ Empty response from Gemini AI');
        return _getServiceUnavailableMessage(responseLanguage);
      }
    } catch (e) {
      print('❌ Error communicating with Gemini AI: $e');
      return _getServiceUnavailableMessage(language);
    }
  }

  // Detect frustration in user message
  static bool _detectFrustration(String message) {
    final lowerMessage = message.toLowerCase();
    
    // English frustration indicators
    final englishFrustrationWords = [
      'frustrated', 'angry', 'annoyed', 'upset', 'mad', 'furious', 'irritated',
      'stupid', 'useless', 'terrible', 'awful', 'horrible', 'worst', 'hate',
      'sucks', 'damn', 'shit', 'fuck', 'wtf', 'omg', 'seriously', 'ridiculous',
      'pathetic', 'garbage', 'trash', 'broken', 'doesn\'t work', 'not working',
      'help me', 'i need help', 'this is not working', 'nothing works',
      'give up', 'fed up', 'can\'t take', 'enough', 'tired of'
    ];
    
    // Somali frustration indicators
    final somaliFrustrationWords = [
      'cadhaysan', 'xanaaq', 'xumaan', 'nacayb', 'xun', 'dhibaato',
      'mashquul', 'daal', 'daalan', 'ka daalay', 'waan ka daalay',
      'ma shaqeynayo', 'khalad', 'qalad', 'xun', 'aan shaqeyn',
      'i caawiyo', 'caawimaad', 'waan u baahanahay', 'ma fahmin'
    ];
    
    // Check for frustration words
    for (final word in englishFrustrationWords) {
      if (lowerMessage.contains(word)) {
        return true;
      }
    }
    
    for (final word in somaliFrustrationWords) {
      if (lowerMessage.contains(word)) {
        return true;
      }
    }
    
    // Check for excessive punctuation (signs of frustration)
    if (RegExp(r'[!]{2,}').hasMatch(message) || 
        RegExp(r'[?]{2,}').hasMatch(message) ||
        message.toUpperCase() == message && message.length > 10) {
      return true;
    }
    
    return false;
  }

  // Detect the language of the user's message
  static String? _detectMessageLanguage(String message) {
    // Convert message to lowercase for better detection
    final lowerMessage = message.toLowerCase();
    
    // Common Somali words and patterns
    final somaliIndicators = [
      // Common Somali words
      'waa', 'baa', 'ayaa', 'oo', 'iyo', 'ama', 'laakiin', 'haddii', 'markii',
      'waxa', 'waxaa', 'maxaa', 'xaggee', 'goorma', 'sidee', 'yaa', 'kumee',
      'halka', 'meesha', 'goobta', 'magaalada', 'dalka', 'somalia', 'soomaaliya',
      'fadlan', 'mahadsanid', 'waan', 'kuma', 'maya', 'haa', 'saaxiib',
      // Tourism related Somali words
      'dalxiis', 'booqasho', 'meel', 'goob', 'magaalo', 'badda', 'buur',
      'taariikh', 'dhaqan', 'cunto', 'hotel', 'guri', 'safar', 'socod'
    ];
    
    // Common English words and patterns
    final englishIndicators = [
      'the', 'and', 'or', 'but', 'if', 'when', 'where', 'what', 'how', 'who',
      'can', 'could', 'would', 'should', 'will', 'have', 'has', 'had',
      'is', 'are', 'was', 'were', 'be', 'been', 'being',
      'place', 'places', 'visit', 'tourism', 'travel', 'hotel', 'restaurant',
      'beach', 'mountain', 'city', 'country', 'somalia', 'somali'
    ];
    
    int somaliScore = 0;
    int englishScore = 0;
    
    // Count Somali indicators
    for (final indicator in somaliIndicators) {
      if (lowerMessage.contains(indicator)) {
        somaliScore++;
      }
    }
    
    // Count English indicators
    for (final indicator in englishIndicators) {
      if (lowerMessage.contains(indicator)) {
        englishScore++;
      }
    }
    
    // Additional pattern checks
    // Somali often has double vowels and specific letter combinations
    if (RegExp(r'[aeiou]{2,}').hasMatch(lowerMessage) || 
        lowerMessage.contains('dh') || lowerMessage.contains('kh') || 
        lowerMessage.contains('sh') || lowerMessage.contains('ch')) {
      somaliScore++;
    }
    
    // English pattern checks
    if (RegExp(r'\b(a|an|the)\b').hasMatch(lowerMessage) ||
        RegExp(r'ing\b').hasMatch(lowerMessage) ||
        RegExp(r'ed\b').hasMatch(lowerMessage)) {
      englishScore++;
    }
    
    // Return detected language if there's a clear winner
    if (somaliScore > englishScore && somaliScore > 0) {
      return 'so';
    } else if (englishScore > somaliScore && englishScore > 0) {
      return 'en';
    }
    
    // If no clear detection, return null to use app language
    return null;
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
1. IMPORTANT: Always respond in ${language == 'so' ? 'Somali' : 'English'} language, regardless of the app's language setting
2. The user asked their question in ${language == 'so' ? 'Somali' : 'English'}, so respond in the same language
3. Be helpful, friendly, and knowledgeable about Somalia tourism
4. Use the provided data to give accurate information about places, prices, and recommendations
5. Include relevant emojis to make responses engaging
6. Address the user by their name when appropriate
7. Provide specific details from the places data when recommending locations
8. Consider the user's favorites when making recommendations
9. Be concise but informative
10. IMPORTANT: If the user asks about topics outside Somalia tourism (like world facts, general knowledge, etc.), politely redirect them to tourism topics and provide this contact information:
    📞 For general inquiries, please call: 619071794
    🕐 Available from 09:00 AM to 07:00 PM
    Example response: "I'm specialized in Somalia tourism. For general questions, please contact us at 619071794 (available 09:00 AM - 07:00 PM). How can I help you explore Somalia's amazing destinations?"

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
        final desc = place['desc_eng']?.toString() ?? '';
        if (desc.isNotEmpty) {
          buffer.writeln('  Description: ${desc.length > 100 ? desc.substring(0, 100) + '...' : desc}');
        }
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

  // Frustration support message with contact information
  static String _getFrustrationSupportMessage(String language) {
    return language == 'so'
        ? '😔 Waan ogahay inaad dhibaato la kulantay. Waan ka xumahay!\n\n'
          '📞 Haddii aad u baahan tahay caawimaad degdeg ah, fadlan wac lambarkaan:\n'
          '**619071794**\n\n'
          '🕐 Wakhtiga adeegga: 09:00 subaxnimo - 07:00 fiidnimo\n'
          '💬 Ama sii wad wadahadalka halkan, waan kaa caawin doonaa si fiican!\n\n'
          'Maxaan kuu samayn karaa si aan kaa caawiyo?'
        : '😔 I understand you\'re experiencing some frustration. I\'m sorry about that!\n\n'
          '📞 If you need immediate assistance, please call this number:\n'
          '**619071794**\n\n'
          '🕐 Service hours: 09:00 AM - 07:00 PM\n'
          '💬 Or continue chatting here, I\'m here to help you better!\n\n'
          'What can I do to assist you properly?';
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
