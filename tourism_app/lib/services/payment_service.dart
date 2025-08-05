import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  static const String baseUrl = 'http://localhost:9000/api/payments';

  /// Create a payment for place booking
  static Future<Map<String, dynamic>> createPayment({
    required String userId,
    required String userFullName,
    required String userAccountNo,
    required String placeId,
    required String bookingDate,
    required String timeSlot,
    required int visitorCount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'userFullName': userFullName,
          'userAccountNo': userAccountNo,
          'placeId': placeId,
          'bookingDate': bookingDate,
          'timeSlot': timeSlot,
          'visitorCount': visitorCount,
        }),
      );

      // Check if response is HTML (server error page)
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html')) {
        print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
        print('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
        return {
          'success': false,
          'message': 'Server is not responding correctly. Please ensure the backend server is running on port 9000.',
          'error': 'Server returned HTML instead of JSON',
        };
      }

      // Try to decode JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (jsonError) {
        print('❌ Failed to parse JSON response: $jsonError');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Invalid response format from server.',
          'error': 'JSON parsing failed: $jsonError',
        };
      }

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Payment failed',
          'error': responseData['error'],
        };
      }
    } catch (e) {
      print('❌ Payment creation error: $e');
      
      // Check for specific timeout errors
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Payment service timeout. Server is not responding.',
          'error': e.toString(),
        };
      }
      
      return {
        'success': false,
        'message': 'Network error. Please check your connection and ensure the backend server is running.',
        'error': e.toString(),
      };
    }
  }

  /// Get payment history for a user
  static Future<Map<String, dynamic>> getPaymentHistory({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history/$userId?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // Check if response is HTML (server error page)
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html')) {
        print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server is not responding correctly. Please ensure the backend server is running on port 9000.',
        };
      }

      // Try to decode JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (jsonError) {
        print('❌ Failed to parse JSON response: $jsonError');
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load payment history',
        };
      }
    } catch (e) {
      print('❌ Payment history error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and ensure the backend server is running.',
      };
    }
  }

  /// Get payment details by ID
  static Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$paymentId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // Check if response is HTML (server error page)
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html')) {
        print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server is not responding correctly. Please ensure the backend server is running on port 9000.',
        };
      }

      // Try to decode JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (jsonError) {
        print('❌ Failed to parse JSON response: $jsonError');
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load payment details',
        };
      }
    } catch (e) {
      print('❌ Payment details error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and ensure the backend server is running.',
      };
    }
  }

  /// Cancel a payment
  static Future<Map<String, dynamic>> cancelPayment(String paymentId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$paymentId/status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // Check if response is HTML (server error page)
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html')) {
        print('❌ Server returned HTML instead of JSON. Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server is not responding correctly. Please ensure the backend server is running on port 9000.',
        };
      }

      // Try to decode JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (jsonError) {
        print('❌ Failed to parse JSON response: $jsonError');
        return {
          'success': false,
          'message': 'Invalid response format from server.',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel payment',
        };
      }
    } catch (e) {
      print('❌ Payment cancellation error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and ensure the backend server is running.',
      };
    }
  }
}