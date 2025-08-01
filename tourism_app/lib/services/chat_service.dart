import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Use localhost for Windows development, 10.0.2.2 for Android emulator
  static const String _baseUrl = 'http://localhost:5000';
  static const String _fallbackUrl = 'http://10.0.2.2:5000';
  static const String _networkUrl = 'http://10.1.1.33:5000';

  static Future<String> _tryUrl(String url, String message, String language) async {
    final response = await http.post(
      Uri.parse('$url/chat'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'language': language,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['response'] != null) {
        return data['response'];
      } else {
        throw Exception('Invalid response format from API');
      }
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['error'] ?? 'Unknown error occurred';
      throw Exception(
          'API Error: $errorMessage (Status: ${response.statusCode})');
    }
  }

  static String _getOfflineResponse(String message, String language) {
    final messageLower = message.toLowerCase();
    
    // Cost/price queries
    if (messageLower.contains('cost') || messageLower.contains('price') || 
        messageLower.contains('expensive') || messageLower.contains('cheap') ||
        messageLower.contains('budget') || messageLower.contains('money')) {
      if (language == 'so') {
        return '💰 Qiimaha Dalxiiska Soomaaliya:\n\n'
               '🏖️ Xeebaha: \$3-12 qof kasta\n'
               '🏛️ Meelaha Taariikhiga: \$5-25 qof kasta\n'
               '🕌 Masaajidda: Bilaash\n'
               '🏨 Hoyga: \$15-200 habeen kasta\n'
               '🚗 Gaadiidka: \$2-60 maalin kasta\n'
               '🍽️ Cuntada: \$2-40 cunto kasta';
      } else {
        return '💰 Somalia Tourism Costs:\n\n'
               '🏖️ Beaches: \$3-12 per person\n'
               '🏛️ Historical sites: \$5-25 per person\n'
               '🕌 Mosques: Free (donations welcome)\n'
               '🏨 Accommodation: \$15-200 per night\n'
               '🚗 Transportation: \$2-60 per day\n'
               '🍽️ Food: \$2-40 per meal';
      }
    }
    
    // Beach queries
    if (messageLower.contains('beach') || messageLower.contains('xeeb') ||
        messageLower.contains('coast') || messageLower.contains('sea')) {
      if (language == 'so') {
        return '🏖️ Xeebaha Soomaaliya:\n\n'
               '• Lido Beach - Muqdisho (\$5-10)\n'
               '• Jazeera Beach - Muqdisho (\$3-8)\n'
               '• Bosaso Beach - Bosaso (\$5-12)\n\n'
               'Xeebahan waa kuwo qurux badan oo leh hawlaha kala duwan.';
      } else {
        return '🏖️ Beautiful Beaches in Somalia:\n\n'
               '• Lido Beach - Mogadishu (\$5-10 per person)\n'
               '• Jazeera Beach - Mogadishu (\$3-8 per person)\n'
               '• Bosaso Beach - Bosaso (\$5-12 per person)\n\n'
               'These beaches offer beautiful scenery and various activities.';
      }
    }
    
    // Historical sites
    if (messageLower.contains('history') || messageLower.contains('historical') ||
        messageLower.contains('ancient') || messageLower.contains('taariikh')) {
      if (language == 'so') {
        return '🏛️ Meelaha Taariikhiga ah:\n\n'
               '• Laas Geel - Hargeysa (\$15-25)\n'
               '• Mogadishu Cathedral - Muqdisho (\$5-10)\n'
               '• Zeila Historic Town - Awdal (\$10-20)\n\n'
               'Meelahan waxay ka sheekeeyaan taariikhda hore ee Soomaaliya.';
      } else {
        return '🏛️ Historical Sites in Somalia:\n\n'
               '• Laas Geel Cave Paintings - Hargeisa (\$15-25)\n'
               '• Mogadishu Cathedral - Mogadishu (\$5-10)\n'
               '• Zeila Historic Town - Awdal (\$10-20)\n\n'
               'These sites showcase Somalia\'s rich historical heritage.';
      }
    }
    
    // Default response
    if (language == 'so') {
      return 'Salaam! Waxaan kaa caawin karaa su\'aalaha ku saabsan dalxiiska Soomaaliya. '
             'Wax ka weydiiso xeebaha, meelaha taariikhiga ah, qiimaha, ama wax kale oo ku saabsan safarka!';
    } else {
      return 'Hello! I can help you with questions about tourism in Somalia. '
             'Ask me about beaches, historical sites, costs, accommodation, or anything else related to traveling!';
    }
  }

  static Future<String> sendMessage(String message, String language) async {
    final urls = [_baseUrl, _fallbackUrl, _networkUrl];
    
    for (String url in urls) {
      try {
        print('Trying to connect to: $url');
        final response = await _tryUrl(url, message, language);
        print('Successfully connected to: $url');
        return response;
      } catch (e) {
        print('Failed to connect to $url: $e');
        continue;
      }
    }
    
    // If all URLs fail, return offline response
    print('All backend URLs failed, using offline response');
    return _getOfflineResponse(message, language);
  }

  // Optional: Streaming chat method for real-time responses
  static Stream<String> sendMessageStream(
      String message, String language) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/stream'),
      );

      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'message': message,
        'language': language,
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        await for (final chunk
            in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                return;
              }
              if (data.isNotEmpty) {
                yield data;
              }
            }
          }
        }
      } else {
        throw Exception('Stream API Error: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      print('Stream Chat API Error: $e');
      throw Exception('Failed to communicate with streaming chat service: $e');
    }
  }

  // Health check method to verify backend connectivity
  static Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}
