import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:tourism_app/services/mock_payment_service.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({Key? key}) : super(key: key);

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isLoading) {
        _loadMorePayments();
      }
    }
  }

  Future<void> _loadPaymentHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        setState(() {
          _error = languageProvider.getText('please_login_payment_history');
          _isLoading = false;
        });
        return;
      }

      final user = authProvider.currentUser;
      final userId = user?['_id'] ?? user?['id'];

      // Try real API first, fallback to mock service if it fails
      Map<String, dynamic> responseData;
      bool usedMockService = false;
      
      try {
        final response = await http.get(
          Uri.parse('http://localhost:9000/api/payments/history/$userId?page=1&limit=10'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        // Check if response is HTML (server error page)
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html')) {
          throw Exception('Server returned HTML instead of JSON');
        }

        if (response.statusCode == 200) {
          // Try to decode JSON response
          try {
            responseData = json.decode(response.body);
          } catch (jsonError) {
            throw Exception('Failed to parse JSON response');
          }
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('Real payment history API failed, using mock service: $e');
        
        // Use mock service as fallback
        final mockResult = await MockPaymentService.getPaymentHistory(
          userId: userId,
          page: 1,
          limit: 10,
        );
        
        if (mockResult['success']) {
          responseData = mockResult;
          usedMockService = true;
        } else {
          throw Exception('Both real and mock services failed');
        }
      }

      if (responseData['success']) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(responseData['data']['payments']);
          _hasMoreData = responseData['data']['currentPage'] < responseData['data']['totalPages'];
          _isLoading = false;
        });
        
        // Show info message if using mock service
        if (usedMockService && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Using offline demo mode - showing mock payment history'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        setState(() {
          _error = responseData['message'] ?? languageProvider.getText('failed_load_payment_history');
          _isLoading = false;
        });
      }
    } catch (error) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _error = languageProvider.getText('network_error_check_connection');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePayments() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final userId = user?['_id'] ?? user?['id'];

      // Try real API first, fallback to mock service if it fails
      Map<String, dynamic> responseData;
      
      try {
        final response = await http.get(
          Uri.parse('http://localhost:9000/api/payments/history/$userId?page=${_currentPage + 1}&limit=10'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        // Check if response is HTML (server error page)
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html')) {
          throw Exception('Server returned HTML instead of JSON');
        }

        if (response.statusCode == 200) {
          // Try to decode JSON response
          try {
            responseData = json.decode(response.body);
          } catch (jsonError) {
            throw Exception('Failed to parse JSON response');
          }
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        // Use mock service as fallback
        final mockResult = await MockPaymentService.getPaymentHistory(
          userId: userId,
          page: _currentPage + 1,
          limit: 10,
        );
        
        if (mockResult['success']) {
          responseData = mockResult;
        } else {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (responseData['success']) {
        setState(() {
          _payments.addAll(List<Map<String, dynamic>>.from(responseData['data']['payments']));
          _currentPage++;
          _hasMoreData = responseData['data']['currentPage'] < responseData['data']['totalPages'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPayments() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });
    await _loadPaymentHistory();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.payment,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.getText('payment_history'),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          languageProvider.getText('track_booking_payments'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshPayments,
                    icon: Icon(
                      Icons.refresh,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    if (_isLoading && _payments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshPayments,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                languageProvider.getText('retry'),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              languageProvider.getText('no_payments_made'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              languageProvider.getText('make_first_booking'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPayments,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _payments.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final payment = _payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final bookingDate = DateTime.parse(payment['bookingDate']);
    final paidAt = DateTime.parse(payment['paidAt']);
    final status = payment['bookingStatus'] ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPaymentDetails(payment),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['placeName'] ?? Provider.of<LanguageProvider>(context).getText('unknown_place'),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(bookingDate),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.people,
                      Provider.of<LanguageProvider>(context).getText('visitors'),
                      '${payment['visitorCount']} ${Provider.of<LanguageProvider>(context).getText('people')}',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.schedule,
                      Provider.of<LanguageProvider>(context).getText('time'),
                      payment['timeSlot'] ?? 'N/A',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Amount Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Provider.of<LanguageProvider>(context).getText('total_amount'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '\$${(payment['totalAmount'] ?? 0).toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Provider.of<LanguageProvider>(context).getText('paid_amount'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          '\$${(payment['actualPaidAmount'] ?? 0).toStringAsFixed(2)} (Test)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Payment Date
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${Provider.of<LanguageProvider>(context).getText('paid_on')} ${DateFormat('MMM dd, yyyy • hh:mm a').format(paidAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          Provider.of<LanguageProvider>(context).getText('payment_details'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('place'), payment['placeName'] ?? 'N/A'),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('booking_date'), DateFormat('MMM dd, yyyy').format(DateTime.parse(payment['bookingDate']))),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('time_slot'), payment['timeSlot'] ?? 'N/A'),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('visitors'), '${payment['visitorCount']} ${Provider.of<LanguageProvider>(context).getText('people')}'),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('contact_name'), payment['userFullName'] ?? 'N/A'),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('phone'), payment['userAccountNo'] ?? 'N/A'),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('total_amount'), '\$${(payment['totalAmount'] ?? 0).toStringAsFixed(2)}'),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('paid_amount'), '\$${(payment['actualPaidAmount'] ?? 0).toStringAsFixed(2)} (Test)'),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('status'), payment['bookingStatus']?.toUpperCase() ?? 'PENDING'),
              _buildDetailRow(Provider.of<LanguageProvider>(context).getText('payment_date'), DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(payment['paidAt']))),
              if (payment['waafiResponse'] != null && payment['waafiResponse']['transactionId'] != null)
                _buildDetailRow(Provider.of<LanguageProvider>(context).getText('transaction_id'), payment['waafiResponse']['transactionId']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Provider.of<LanguageProvider>(context).getText('close'),
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}