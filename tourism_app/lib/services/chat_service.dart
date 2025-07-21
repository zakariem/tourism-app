import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Use 10.0.2.2 for Android emulator to access host machine
  static const String _baseUrl = 'http://10.1.1.33:5000';

  static Future<String> sendMessage(String message, String language) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'language': language,
        }),
      );

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
    } catch (e) {
      print('Chat API Error: $e'); // For debugging
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to communicate with chat service: $e');
    }
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
