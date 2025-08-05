import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/favorites_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/services/database_helper.dart';
import 'package:tourism_app/services/payment_service.dart';
import 'package:tourism_app/services/mock_payment_service.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/providers/user_behavior_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';
import 'package:tourism_app/screens/dashboard/dashboard_screen.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;

  const PlaceDetailsScreen({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isFavorite = false;
  bool _isLoading = false;
  late DateTime _enterTime;
  UserBehaviorProvider? _userBehaviorProvider;

  late AnimationController _animationController;
  late AnimationController _favoriteAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _favoriteScaleAnimation;
  late Animation<double> _fabSlideAnimation;

  @override
  void initState() {
    super.initState();
    _enterTime = DateTime.now();
    _checkFavoriteStatus();
    _setupAnimations();
  }



  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _favoriteScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
          parent: _favoriteAnimationController, curve: Curves.elasticOut),
    );

    _fabSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _fabAnimationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _fabAnimationController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userBehaviorProvider =
        Provider.of<UserBehaviorProvider>(context, listen: false);
  }

  @override
  void dispose() {
    final seconds = DateTime.now().difference(_enterTime).inSeconds.toDouble();
    _userBehaviorProvider?.recordViewTime(seconds, notify: false);
    _animationController.dispose();
    _favoriteAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    final placeId =
        widget.place['_id']?.toString() ?? widget.place['id']?.toString() ?? '';

    if (placeId.isNotEmpty) {
      try {
        final isFavorite = await favoritesProvider.checkFavoriteStatus(placeId);
        if (mounted) {
          setState(() => _isFavorite = isFavorite);
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _favoriteAnimationController.forward().then((_) {
      _favoriteAnimationController.reverse();
    });

    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    final placeId =
        widget.place['_id']?.toString() ?? widget.place['id']?.toString() ?? '';

    if (placeId.isNotEmpty) {
      try {
        final success =
            await favoritesProvider.toggleFavorite(placeId, widget.place);

        if (mounted && success) {
          setState(() {
            _isFavorite = !_isFavorite;
            _isLoading = false;
          });

          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(_isFavorite
                      ? 'Added to favorites!'
                      : 'Removed from favorites!'),
                ],
              ),
              backgroundColor: _isFavorite ? Colors.red : Colors.grey[600],
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        print('Error toggling favorite: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Failed to update favorites'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.currentLanguage == 'en';
    final name =
        isEnglish ? widget.place['name_eng'] : widget.place['name_som'];
    final description =
        isEnglish ? widget.place['desc_eng'] : widget.place['desc_som'];
    final category = widget.place['category'];
    // final imagePath = widget.place['image_path'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Simple App Bar with Single Image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ScaleTransition(
                    scale: _favoriteScaleAnimation,
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.grey[600],
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Single Place Image
                    Image.asset(
                      widget.place['image_path'].startsWith('assets/')
                          ? widget.place['image_path']
                          : 'assets/places/${widget.place['image_path']}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not found',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Category Section
                      _buildTitleSection(name, category, languageProvider),

                      const SizedBox(height: 24),

                      // Description Section
                      _buildDescriptionSection(description, languageProvider),

                      const SizedBox(height: 24),

                      // Place Details Section
                      _buildPlaceDetailsSection(languageProvider),

                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _fabSlideAnimation.value),
            child: FloatingActionButton.extended(
              heroTag: "book",
              onPressed: () {
                _showBookingDialog();
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: Text(
                'Book Visit',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(
      String name, String category, LanguageProvider languageProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.place['location'],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            languageProvider.getText(category),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceDetailsSection(LanguageProvider languageProvider) {
    final pricePerPerson = widget.place['pricePerPerson'] ?? 5.0;
    final maxCapacity = widget.place['maxCapacity'] ?? 10;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                languageProvider.getText('place_details'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.attach_money,
                  label: 'Price per Person',
                  value: '\$${pricePerPerson.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.people,
                  label: 'Max Capacity',
                  value: '$maxCapacity people',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(
      String description, LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                languageProvider.getText('description'),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => BookingDialog(place: widget.place),
    );
  }
}

class BookingDialog extends StatefulWidget {
  final Map<String, dynamic> place;

  const BookingDialog({Key? key, required this.place}) : super(key: key);

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  int _visitorCount = 1;
  bool _isLoading = false;

  // Error state variables
  String? _dateError;
  String? _timeSlotError;
  String? _nameError;
  String? _phoneError;
  String? _emailError;

  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Controllers are already initialized above, no additional setup needed
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateError = null; // Clear date error when date is selected
        _selectedTimeSlot = null; // Reset time slot when date changes
        _timeSlotError = null; // Clear time slot error
      });
    }
  }

  // Comprehensive validation method
  bool _validateForm() {
    bool isValid = true;

    setState(() {
      // Clear all errors first
      _dateError = null;
      _timeSlotError = null;
      _nameError = null;
      _phoneError = null;
      _emailError = null;

      // Validate date
      if (_selectedDate == null) {
        _dateError = 'Please select a visit date';
        isValid = false;
      } else if (_selectedDate!
          .isBefore(DateTime.now().subtract(const Duration(hours: 1)))) {
        _dateError = 'Please select a future date';
        isValid = false;
      }

      // Validate time slot
      if (_selectedTimeSlot == null) {
        _timeSlotError = 'Please select a time slot';
        isValid = false;
      }

      // Validate full name
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _nameError = 'Please enter your full name';
        isValid = false;
      } else if (name.split(' ').length < 2) {
        _nameError = 'Please enter your full name (first and last name)';
        isValid = false;
      } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
        _nameError = 'Name can only contain letters and spaces';
        isValid = false;
      }

      // Validate phone number (must start with 61 and have 7 other digits)
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        _phoneError = 'Please enter your phone number';
        isValid = false;
      } else if (!RegExp(r'^61[0-9]{7}$').hasMatch(phone)) {
        _phoneError =
            'Phone number must start with 61 followed by 7 digits (e.g., 612177035)';
        isValid = false;
      }

      // Validate email
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'Please enter your email address';
        isValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> _confirmBooking() async {
    // Use comprehensive validation instead of form validation
    if (!_validateForm()) {
      return;
    }

    // Check visitor count against max capacity
    final maxCapacity = widget.place['maxCapacity'] ?? 20;
    if (_visitorCount > maxCapacity) {
      _showErrorSnackBar(
          'Visitor count exceeds maximum capacity of $maxCapacity');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        _showErrorSnackBar('Please login to make a booking');
        setState(() => _isLoading = false);
        return;
      }

      final user = authProvider.currentUser;
      // Ensure minimum price per person to avoid validation errors
      final pricePerPerson = (widget.place['pricePerPerson'] ?? 5.0).toDouble();
      final totalAmount = pricePerPerson * _visitorCount;

      // Validate totalAmount before sending
      if (totalAmount <= 0) {
        _showErrorSnackBar('Invalid booking amount. Please contact support.');
        setState(() => _isLoading = false);
        return;
      }

      // Try real PaymentService first, fallback to mock if it fails
      Map<String, dynamic> result;
      bool usedMockService = false;
      
      try {
        result = await PaymentService.createPayment(
          userId: user?['_id'] ?? user?['id'] ?? '',
          userFullName: _nameController.text.trim(),
          userAccountNo: _phoneController.text.trim(),
          placeId: widget.place['_id'] ?? widget.place['id'] ?? '',
          bookingDate: _selectedDate!.toIso8601String(),
          timeSlot: _selectedTimeSlot!,
          visitorCount: _visitorCount,
        );
        
        // If real service fails due to server issues, use mock service
        if (!result['success'] && 
            (result['message']?.contains('Server is not responding') == true ||
             result['message']?.contains('Network error') == true ||
             result['message']?.contains('timeout') == true)) {
          print('Real payment service failed, using mock service as fallback');
          
          result = await MockPaymentService.createPayment(
            userId: user?['_id'] ?? user?['id'] ?? '',
            userFullName: _nameController.text.trim(),
            userAccountNo: _phoneController.text.trim(),
            placeId: widget.place['_id'] ?? widget.place['id'] ?? '',
            bookingDate: _selectedDate!.toIso8601String(),
            timeSlot: _selectedTimeSlot!,
            visitorCount: _visitorCount,
            placeName: widget.place['name_eng'] ?? widget.place['name'] ?? 'Unknown Place',
          );
          usedMockService = true;
        }
      } catch (e) {
        print('Payment service error, using mock service: $e');
        
        result = await MockPaymentService.createPayment(
          userId: user?['_id'] ?? user?['id'] ?? '',
          userFullName: _nameController.text.trim(),
          userAccountNo: _phoneController.text.trim(),
          placeId: widget.place['_id'] ?? widget.place['id'] ?? '',
          bookingDate: _selectedDate!.toIso8601String(),
          timeSlot: _selectedTimeSlot!,
          visitorCount: _visitorCount,
          placeName: widget.place['name_eng'] ?? widget.place['name'] ?? 'Unknown Place',
        );
        usedMockService = true;
      }

      if (result['success']) {
        // Payment successful
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context);

          // Check if backend used demo mode
          bool backendDemoMode = result['data']?['demoMode'] == true ||
                                result['data']?['waafiResponse']?['responseCode'] == 'DEMO_MODE';
          bool isDemoMode = usedMockService || backendDemoMode;

          // Show success dialog with payment receipt
          _showPaymentSuccessDialog(result['data'], totalAmount, isDemoMode);
        }
      } else {
        // Payment failed
        final errorMessage = result['message'] ?? 'Payment failed';
        _showErrorSnackBar(errorMessage);
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print('Payment error: $error');
      _showErrorSnackBar('Network error. Please check your connection.');
      setState(() => _isLoading = false);
    }
  }

  void _showPaymentSuccessDialog(
      Map<String, dynamic> paymentData, double totalAmount, [bool usedMockService = false]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              usedMockService ? 'Booking Confirmed! (Demo Mode)' : 'Payment Successful!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (usedMockService)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Payment service unavailable - using demo mode',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Payment Receipt',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Divider(),
                  _buildReceiptRow('Place:', widget.place['name_eng']),
                  _buildReceiptRow('Date:',
                      '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                  _buildReceiptRow('Time:', _selectedTimeSlot ?? ''),
                  _buildReceiptRow('Visitors:', _visitorCount.toString()),
                  _buildReceiptRow(
                      'Total Amount:', '\$${totalAmount.toStringAsFixed(2)}'),
                  _buildReceiptRow('Paid Amount:', '\$0.01 (Test)',
                      isHighlight: true),
                  _buildReceiptRow('Status:', 'Confirmed', isHighlight: true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to payments tab
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DashboardScreen(initialIndex: 2), // Payments tab
                ),
              );
            },
            child: Text(
              'View Payment History',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Done',
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

  Widget _buildReceiptRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? AppColors.primary : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Book Your Visit',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Place Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage(widget.place['image_path']
                                          .startsWith('assets/')
                                      ? widget.place['image_path']
                                      : 'assets/places/${widget.place['image_path']}'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.place['name_eng'] ?? 'Unknown Place',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    widget.place['location'] ??
                                        'Unknown Location',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date Selection
                      Text(
                        'Select Date',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _dateError != null
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: _dateError != null
                                    ? Colors.red
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate == null
                                    ? 'Choose your visit date'
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                style: GoogleFonts.poppins(
                                  color: _selectedDate == null
                                      ? Colors.grey[600]
                                      : Colors.black,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                      if (_dateError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            _dateError!,
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Time Slot Selection
                      Text(
                        'Select Time Slot',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: _timeSlotError != null
                              ? Border.all(color: Colors.red)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: _timeSlotError != null
                            ? const EdgeInsets.all(8)
                            : EdgeInsets.zero,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _timeSlots.map((slot) {
                            final isSelected = _selectedTimeSlot == slot;
                            return InkWell(
                              onTap: () => setState(() {
                                _selectedTimeSlot = slot;
                                _timeSlotError =
                                    null; // Clear error when selected
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  slot,
                                  style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_timeSlotError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            _timeSlotError!,
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Visitor Count
                      Text(
                        'Number of Visitors',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _visitorCount > 1
                                ? () => setState(() => _visitorCount--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _visitorCount.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _visitorCount <
                                    (widget.place['maxCapacity'] ?? 20)
                                ? () => setState(() => _visitorCount++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Cost Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Summary',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Price per person:',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                                Text(
                                  '\$${(widget.place['pricePerPerson'] ?? 5.0).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Number of visitors:',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                                Text(
                                  _visitorCount.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '\$${((widget.place['pricePerPerson'] ?? 5.0) * _visitorCount).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Test payment: \$0.01 (for demo purposes)',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Contact Information
                      Text(
                        'Contact Information',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(
                            Icons.person,
                            color: _nameError != null ? Colors.red : null,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _nameError != null ? Colors.red : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _nameError != null
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _nameError != null
                                  ? Colors.red
                                  : AppColors.primary,
                            ),
                          ),
                          errorText: _nameError,
                          errorStyle: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (value) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number (61XXXXXXX)',
                          hintText: '61XXXXXXX',
                          prefixIcon: Icon(
                            Icons.phone,
                            color: _phoneError != null ? Colors.red : null,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _phoneError != null
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _phoneError != null
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _phoneError != null
                                  ? Colors.red
                                  : AppColors.primary,
                            ),
                          ),
                          errorText: _phoneError,
                          errorStyle: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          if (_phoneError != null) {
                            setState(() => _phoneError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(
                            Icons.email,
                            color: _emailError != null ? Colors.red : null,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _emailError != null
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _emailError != null
                                  ? Colors.red
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _emailError != null
                                  ? Colors.red
                                  : AppColors.primary,
                            ),
                          ),
                          errorText: _emailError,
                          errorStyle: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Confirm Booking',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
