import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/providers/favorites_provider.dart';
import 'package:tourism_app/providers/enhanced_user_behavior_provider.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/screens/place_details_screen.dart';

class ModernPlaceCard extends StatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback? onFavoriteChanged;
  final bool modern;
  final bool showRecommendationBadge;
  final String? recommendationReason;

  const ModernPlaceCard({
    Key? key,
    required this.place,
    this.onFavoriteChanged,
    this.modern = true,
    this.showRecommendationBadge = false,
    this.recommendationReason,
  }) : super(key: key);

  @override
  State<ModernPlaceCard> createState() => _ModernPlaceCardState();
}

class _ModernPlaceCardState extends State<ModernPlaceCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkFavoriteStatus();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);

    if (authProvider.isAuthenticated && widget.place['_id'] != null) {
      try {
        await favoritesProvider.checkFavoriteStatus(widget.place['_id']);
      } catch (e) {
        print('Error checking favorite status: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add favorites'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.place['_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid place data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await favoritesProvider.toggleFavorite(
        widget.place['_id'],
        widget.place,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          widget.onFavoriteChanged?.call();

          final isFavorite = favoritesProvider.isFavorite(widget.place['_id']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorite ? 'Added to favorites' : 'Removed from favorites',
              ),
              backgroundColor: isFavorite ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update favorites'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onCardTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Record quick interaction with EnhancedUserBehaviorProvider
    try {
      final placeId = widget.place['id']?.toString() ?? widget.place['_id']?.toString() ?? widget.place['name_eng']?.toString() ?? '';
      final category = widget.place['category']?.toString().toLowerCase() ?? 'unknown';
      final enhancedBehaviorProvider = Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);
      enhancedBehaviorProvider.recordQuickInteraction(placeId, category);
    } catch (e) {
      print('❌ Error recording quick interaction: $e');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailsScreen(place: widget.place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add null safety check for place object
    final languageProvider = Provider.of<LanguageProvider>(context);
    final category = widget.place['category'] ?? 'unknown';

    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final isFavorite = widget.place['_id'] != null
            ? favoritesProvider.isFavorite(widget.place['_id'])
            : false;

        // Use image_url if available, otherwise fall back to image_path
        final imagePath =
            widget.place['image_url'] ?? widget.place['image_path'];

        final name = languageProvider.currentLanguage == 'som'
            ? widget.place['name_som'] ?? widget.place['name_eng'] ?? 'Unknown'
            : widget.place['name_eng'] ?? 'Unknown';

        final description = languageProvider.currentLanguage == 'som'
            ? widget.place['desc_som'] ??
                widget.place['desc_eng'] ??
                'No description'
            : widget.place['desc_eng'] ?? 'No description';
        final location = widget.place['location'] ?? 'Unknown Location';

        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: _onCardTap,
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: _buildImage(imagePath),
                          ),

                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
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

                          // Category Badge
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category)
                                    .withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                languageProvider.getText(category),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          // Recommendation Badge
                          if (widget.showRecommendationBadge)
                            Positioned(
                              top: 12,
                              right: 60,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Recommended',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Favorite Button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _toggleFavorite,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Colors.red
                                            : Colors.grey[600],
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallCard = constraints.maxWidth < 300;
                              return Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallCard ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          // Location
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallCard = constraints.maxWidth < 300;
                              return Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: isSmallCard ? 14 : 16,
                                  ),
                                  SizedBox(width: isSmallCard ? 2 : 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: isSmallCard ? 12 : 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 8),

                          // Description
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallCard = constraints.maxWidth < 300;
                              return Text(
                                description,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: isSmallCard ? 11 : 13,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),

                          // Recommendation Reason
                          if (widget.recommendationReason != null)
                            Column(
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: Colors.orange[700],
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widget.recommendationReason!,
                                          style: GoogleFonts.poppins(
                                            color: Colors.orange[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 12),

                          // Rating and Visit Button
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmallCard = constraints.maxWidth < 300;
                              return Row(
                                children: [
                                  // Rating
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.orange,
                                            size: isSmallCard ? 14 : 16),
                                        SizedBox(width: isSmallCard ? 2 : 4),
                                        Text(
                                          '4.8',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[700],
                                            fontSize: isSmallCard ? 12 : 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Spacer(),

                                  // Visit Button
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isSmallCard ? 12 : 16,
                                        vertical: isSmallCard ? 6 : 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Visit',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: isSmallCard ? 10 : 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(String imagePath) {
    // Check if it's a data URL (base64 image from MongoDB)
    if (imagePath.startsWith('data:')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Data URL image error: $error');
          return Container(
            color: Colors.grey[200],
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
                  'Image not available',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Handle regular HTTP URLs
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          print('❌ Network image error: $error');
          return Container(
            color: Colors.grey[200],
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
                  'Image not available',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Handle local asset images
      return Image.asset(
        'assets/places/$imagePath',
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
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
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return Colors.blue;
      case 'historical':
        return Colors.brown;
      case 'cultural':
        return Colors.purple;
      case 'religious':
        return Colors.green;
      case 'suburb':
        return Colors.orange;
      case 'urban park':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }
}
