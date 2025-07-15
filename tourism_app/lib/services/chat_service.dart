import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _apiKey =
      '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';
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> sendMessage(String message, String language) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'http://localhost:5000',
          'X-Title': 'Tourism App Chat Support',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-r1:free',
          'messages': [
            {
              'role': 'system',
              'content': language == 'en'
                  ? 'You are a helpful tourism assistant for Somalia. Provide accurate and helpful information about tourist destinations, cultural sites, and travel tips in Somalia. Keep responses concise and friendly. do not respond any thing rather than tourism related questions.'
                  : 'Waxaad tahay caawimaad dalxiis oo Soomaaliya ah. Siin macluumaad sax ah oo faahfaahsan oo ku saabsan meelaha dalxiiska, meelaha dhaqanka, iyo tilmaamaha safarka ee Soomaaliya. Jawaabaha aad bixiso ay noqdaan gaar ah oo saaxiib ah. haka jawaabin wax aan la xiriirin su’aalaha dalxiiska.',
            },
            {
              'role': 'user',
              'content': message,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null &&
            data['choices'].isNotEmpty &&
            data['choices'][0]['message'] != null) {
          return data['choices'][0]['message']['content'];
        } else {
          throw Exception('Invalid response format from API');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error']?['message'] ?? 'Unknown error occurred';
        throw Exception(
            'API Error: $errorMessage (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Chat API Error: $e'); // For debugging
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to communicate with chat service: $e');
    }
  }
}
