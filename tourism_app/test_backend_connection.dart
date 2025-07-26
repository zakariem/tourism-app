import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing backend connection...');

  try {
    final response = await http.get(Uri.parse('http://10.0.2.2:9000/'));
    print('Backend response: ${response.statusCode}');
    print('Response body: ${response.body}');
  } catch (e) {
    print('Backend connection failed: $e');
  }

  // Test login endpoint
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:9000/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'test@test.com',
        'username': 'test@test.com',
        'password': 'password123',
      }),
    );
    print('Login test response: ${response.statusCode}');
    print('Login response body: ${response.body}');
  } catch (e) {
    print('Login test failed: $e');
  }
}
