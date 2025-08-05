import 'dart:math';

class MockPaymentService {
  static final List<Map<String, dynamic>> _mockPayments = [];
  static int _paymentIdCounter = 1000;

  /// Create a mock payment for place booking (works offline)
  static Future<Map<String, dynamic>> createPayment({
    required String userId,
    required String userFullName,
    required String userAccountNo,
    required String placeId,
    required String bookingDate,
    required String timeSlot,
    required int visitorCount,
    String? placeName,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Generate mock payment data
      final paymentId = 'PAY${_paymentIdCounter++}';
      final transactionId = 'TXN${Random().nextInt(999999).toString().padLeft(6, '0')}';
      final now = DateTime.now();
      
      final mockPayment = {
        '_id': paymentId,
        'userId': userId,
        'userFullName': userFullName,
        'userAccountNo': userAccountNo,
        'placeId': placeId,
        'placeName': placeName ?? 'Mock Place',
        'bookingDate': bookingDate,
        'timeSlot': timeSlot,
        'visitorCount': visitorCount,
        'totalAmount': visitorCount * 5.0, // Mock price per person
        'actualPaidAmount': 0.01, // Test amount
        'bookingStatus': 'confirmed',
        'paymentStatus': 'completed',
        'paidAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'waafiResponse': {
          'transactionId': transactionId,
          'status': 'success',
          'message': 'Payment completed successfully (Mock)',
        },
      };

      // Store in mock database
      _mockPayments.add(mockPayment);

      return {
        'success': true,
        'data': mockPayment,
        'message': 'Payment completed successfully (Mock Mode)',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Mock payment failed: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Get mock payment history for a user
  static Future<Map<String, dynamic>> getPaymentHistory({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Filter payments by user
      final userPayments = _mockPayments
          .where((payment) => payment['userId'] == userId)
          .toList();

      // Sort by creation date (newest first)
      userPayments.sort((a, b) => 
          DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));

      // Paginate results
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      final paginatedPayments = userPayments.length > startIndex
          ? userPayments.sublist(
              startIndex,
              endIndex > userPayments.length ? userPayments.length : endIndex,
            )
          : <Map<String, dynamic>>[];

      final totalPages = (userPayments.length / limit).ceil();

      return {
        'success': true,
        'data': {
          'payments': paginatedPayments,
          'currentPage': page,
          'totalPages': totalPages,
          'totalPayments': userPayments.length,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load mock payment history: ${e.toString()}',
      };
    }
  }

  /// Get mock payment details by ID
  static Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      final payment = _mockPayments.firstWhere(
        (p) => p['_id'] == paymentId,
        orElse: () => {},
      );

      if (payment.isEmpty) {
        return {
          'success': false,
          'message': 'Payment not found',
        };
      }

      return {
        'success': true,
        'data': payment,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load mock payment details: ${e.toString()}',
      };
    }
  }

  /// Cancel a mock payment
  static Future<Map<String, dynamic>> cancelPayment(String paymentId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      final paymentIndex = _mockPayments.indexWhere(
        (p) => p['_id'] == paymentId,
      );

      if (paymentIndex == -1) {
        return {
          'success': false,
          'message': 'Payment not found',
        };
      }

      // Update payment status
      _mockPayments[paymentIndex]['bookingStatus'] = 'cancelled';
      _mockPayments[paymentIndex]['paymentStatus'] = 'refunded';
      _mockPayments[paymentIndex]['cancelledAt'] = DateTime.now().toIso8601String();

      return {
        'success': true,
        'message': 'Payment cancelled successfully (Mock Mode)',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to cancel mock payment: ${e.toString()}',
      };
    }
  }

  /// Clear all mock payments (for testing)
  static void clearMockPayments() {
    _mockPayments.clear();
    _paymentIdCounter = 1000;
  }

  /// Get all mock payments (for debugging)
  static List<Map<String, dynamic>> getAllMockPayments() {
    return List.from(_mockPayments);
  }
}