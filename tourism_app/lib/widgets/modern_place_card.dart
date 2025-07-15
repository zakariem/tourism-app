import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/services/database_helper.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/screens/place_details_screen.dart';

class ModernPlaceCard extends StatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback? onFavoriteChanged;
  final bool modern;

  const ModernPlaceCard({
    Key? key,
    required this.place,
    this.onFavoriteChanged,
    this.modern = true,
  }) : super(key: key);

  @override
  State<ModernPlaceCard> createState() => _ModernPlaceCardState();
}

class _ModernPlaceCardState extends State<ModernPlaceCard>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isFavorite = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _setupAnimation();
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
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      final isFavorite = await _dbHelper.isPlaceFavorite(
        user['id'],
        widget.place['id'],
      );
      if (mounted) {
        setState(() => _isFavorite = isFavorite);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      try {
        if (_isFavorite) {
          await _dbHelper.removeFromFavorites(user['id'], widget.place['id']);
        } else {
          await _dbHelper.addToFavorites(user['id'], widget.place['id']);
        }

        if (mounted) {
          setState(() {
            _isFavorite = !_isFavorite;
            _isLoading = false;
          });
          widget.onFavoriteChanged?.call();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _onCardTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailsScreen(place: widget.place),
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
    final imagePath = widget.place['image_path'];
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
                            color: _getCategoryColor(category).withOpacity(0.9),
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
                                    _isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isFavorite
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
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Rating and Visit Button
                      Row(
                        children: [
                          // Rating
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.orange, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Visit Button
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Visit',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
  }

  Widget _buildImage(String imagePath) {
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
        errorWidget: (context, url, error) => Container(
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
        ),
      );
    } else {
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
      default:
        return AppColors.primary;
    }
  }
}
