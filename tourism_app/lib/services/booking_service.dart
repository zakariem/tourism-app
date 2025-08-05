import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingService {
  static const String baseUrl = 'http://localhost:9000/api/bookings';

  /// Create a new booking
  static Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String placeId,
    required String bookingDate,
    required int numberOfPeople,
    String? authToken,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode({
          'placeId': placeId,
          'bookingDate': bookingDate,
          'numberOfPeople': numberOfPeople,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Booking created successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Booking failed',
        };
      }
    } catch (e) {
      print('❌ Booking creation error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  /// Get user's bookings
  static Future<Map<String, dynamic>> getUserBookings({
    required String userId,
    String? authToken,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load bookings',
        };
      }
    } catch (e) {
      print('❌ Get bookings error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Get booking details by ID
  static Future<Map<String, dynamic>> getBookingDetails({
    required String bookingId,
    String? authToken,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$bookingId'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load booking details',
        };
      }
    } catch (e) {
      print('❌ Get booking details error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Update booking status
  static Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
    String? authToken,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$bookingId/status'),
        headers: headers,
        body: json.encode({
          'status': status,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Booking status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update booking status',
        };
      }
    } catch (e) {
      print('❌ Update booking status error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Cancel a booking
  static Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    String? authToken,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$bookingId'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel booking',
        };
      }
    } catch (e) {
      print('❌ Cancel booking error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Initiate payment for booking (Hormuud/WaafiPay)
  static Future<Map<String, dynamic>> initiatePayment({
    required String bookingId,
    String? authToken,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payment/initiate'),
        headers: headers,
        body: json.encode({
          'bookingId': bookingId,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Payment initiated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to initiate payment',
        };
      }
    } catch (e) {
      print('❌ Initiate payment error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}