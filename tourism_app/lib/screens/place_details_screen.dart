import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/services/database_helper.dart';
import 'package:tourism_app/utils/app_colors.dart';
// import 'package:tourism_app/widgets/language_toggle.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:tourism_app/providers/user_behavior_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

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
  final PageController _imagePageController = PageController();

  bool _isFavorite = false;
  bool _isLoading = false; // Added missing variable
  late DateTime _enterTime;
  UserBehaviorProvider? _userBehaviorProvider;
  int _currentImageIndex = 0;

  late AnimationController _animationController;
  late AnimationController _favoriteAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _favoriteScaleAnimation;
  late Animation<double> _fabSlideAnimation;

  // Mock data for enhanced features
  late List<String> _imageGallery;

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Ahmed Hassan',
      'rating': 5,
      'comment': 'Amazing place with beautiful views!',
      'date': '2 days ago',
      'avatar': 'AH'
    },
    {
      'name': 'Fatima Ali',
      'rating': 4,
      'comment': 'Great experience, highly recommended.',
      'date': '1 week ago',
      'avatar': 'FA'
    },
    {
      'name': 'Omar Mohamed',
      'rating': 5,
      'comment': 'Perfect for family trips!',
      'date': '2 weeks ago',
      'avatar': 'OM'
    },
  ];

  @override
  void initState() {
    super.initState();
    _enterTime = DateTime.now();
    // Initialize image gallery with the place's image and related images
    _imageGallery = _getPlaceImages(widget.place['image_path']);
    _checkFavoriteStatus();
    _setupAnimations();
  }

  List<String> _getPlaceImages(String mainImagePath) {
    List<String> images = [mainImagePath];

    // Try to find related images for the same place
    String baseName = mainImagePath.split('.').first;

    // Check for numbered variations with different extensions
    List<String> extensions = ['.png', '.jpg', '.jpeg'];
    for (int i = 2; i <= 4; i++) {
      for (String ext in extensions) {
        String variation = 'assets/places/${baseName}$i$ext';
        if (_imageExists(variation)) {
          images.add(variation);
          break; // Found one variation, move to next number
        }
      }
    }

    // If we don't have enough images, add some fallback images
    while (images.length < 3) {
      images.add(mainImagePath); // Repeat the main image
    }

    return images;
  }

  bool _imageExists(String imagePath) {
    // This is a simple check - in a real app you might want to check file existence
    // For now, we'll assume common variations exist
    String path = imagePath.toLowerCase();
    return path.contains('liido') ||
        path.contains('jimcale') ||
        path.contains('nimow') ||
        path.contains('warshiikh') ||
        path.contains('jaziira') ||
        path.contains('berbera') ||
        path.contains('hargeisa') ||
        path.contains('laas_geel') ||
        path.contains('national_museum') ||
        path.contains('sheikh_sufi');
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
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null && user['_id'] != null) {
      try {
        final isFavorite = await _dbHelper.isPlaceFavorite(
          user['_id'],
          widget.place['id'],
        );
        if (mounted) {
          setState(() => _isFavorite = isFavorite);
        }
      } catch (e) {
        print('Error checking favorite status: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null && user['_id'] != null) {
      try {
        if (_isFavorite) {
          await _dbHelper.removeFromFavorites(user['_id'], widget.place['id']);
        } else {
          await _dbHelper.addToFavorites(user['_id'], widget.place['id']);
        }

        if (mounted) {
          setState(() {
            _isFavorite = !_isFavorite;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error toggling favorite: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImageGallery() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: _currentImageIndex),
              itemCount: _imageGallery.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.asset(
                      _imageGallery[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white,
                                  size: 60,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Image not found',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _imageGallery.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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
            // Enhanced App Bar with Image Gallery
            SliverAppBar(
              expandedHeight: 400,
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
                  icon: Icon(Icons.arrow_back, color: AppColors.primary),
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
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.grey),
                    onPressed: () {
                      // Share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.share, color: Colors.white),
                              SizedBox(width: 12),
                              Text('Shared successfully!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
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
                    // Image Gallery
                    GestureDetector(
                      onTap: _showImageGallery,
                      child: PageView.builder(
                        controller: _imagePageController,
                        itemCount: _imageGallery.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Image.asset(
                            _imageGallery[index],
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
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
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

                    // Image Indicators
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _imageGallery.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Gallery Icon
                    Positioned(
                      bottom: 60,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${_imageGallery.length}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
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

                      // Quick Info Cards
                      _buildQuickInfoSection(),

                      const SizedBox(height: 32),

                      // Description Section
                      _buildDescriptionSection(description, languageProvider),

                      const SizedBox(height: 32),

                      // Weather Section
                      _buildWeatherSection(),

                      const SizedBox(height: 32),

                      // Reviews Section
                      _buildReviewsSection(languageProvider),

                      const SizedBox(height: 32),

                      // Map Section
                      _buildMapSection(),

                      const SizedBox(height: 32),

                      // Nearby Places Section
                      _buildNearbyPlacesSection(),

                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Buttons
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _fabSlideAnimation.value),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "directions",
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.directions, color: Colors.white),
                            const SizedBox(width: 12),
                            const Text('Opening directions...'),
                          ],
                        ),
                        backgroundColor: Colors.blue,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.directions, color: Colors.white),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
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
              ],
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
                  Icon(Icons.location_on, color: AppColors.primary, size: 20),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 16,
                      color: index < 4 ? Colors.orange : Colors.grey[300],
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '4.8 (124 reviews)',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
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

  Widget _buildQuickInfoSection() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.access_time,
            title: 'Duration',
            value: '2-3 hrs',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.attach_money,
            title: 'Entry Fee',
            value: 'Free',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.people,
            title: 'Visitors',
            value: '1.2K',
            color: Colors.purple,
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
                child:
                    Icon(Icons.description, color: AppColors.primary, size: 20),
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

  Widget _buildWeatherSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.cyan.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Weather Today',
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
              const Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '28°C',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Sunny, Perfect for visiting!',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(LanguageProvider languageProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Reviews (${_reviews.length})',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_reviews
            .take(2)
            .map((review) => _buildReviewCard(review))
            .toList()),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  review['avatar'],
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 12,
                            color: index < review['rating']
                                ? Colors.orange
                                : Colors.grey[300],
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          review['date'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'],
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 50, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Map View', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.fullscreen, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.near_me, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Nearby Places',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.place, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Nearby Place ${index + 1}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(index + 1) * 0.5} km away',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Book Your Visit'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Select your preferred date and time for visiting this place.'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text('Booking confirmed!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: const Text('Select Date',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
