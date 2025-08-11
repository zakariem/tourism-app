import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/favorites_provider.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tourism_app/screens/place_details_screen.dart';

import 'package:tourism_app/providers/enhanced_user_behavior_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceCard extends StatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback onFavoriteChanged;
  final bool modern;

  const PlaceCard({
    Key? key,
    required this.place,
    required this.onFavoriteChanged,
    this.modern = false,
  }) : super(key: key);

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      await favoritesProvider.loadFavorites();
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add favorites'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await favoritesProvider.toggleFavorite(
          widget.place['_id'] ?? widget.place['id'], widget.place);
      widget.onFavoriteChanged.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favoritesProvider
                    .isFavorite(widget.place['_id'] ?? widget.place['id'])
                ? 'Added to favorites'
                : 'Removed from favorites',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImage(String imagePath) {
    // Check if it's a data URL (base64 image from MongoDB)
    if (imagePath.startsWith('data:')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: 120,
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
                  size: 30,
                ),
                const SizedBox(height: 4),
                Text(
                  'Image not available',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 10,
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
        height: 120,
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
                  size: 30,
                ),
                const SizedBox(height: 4),
                Text(
                  'Image not available',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 10,
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
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: Colors.grey[400],
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                'Image not found',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final languageProvider = Provider.of<LanguageProvider>(context);
        final category = widget.place['category'] ?? 'unknown';

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

        // Truncate description to 100 characters
        final truncatedDescription = description.length > 100
            ? '${description.substring(0, 100)}...'
            : description;

        if (widget.modern) {
          // Modern Card Design
          return Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                // Record quick interaction with EnhancedUserBehaviorProvider
                try {
                  final placeId = widget.place['id']?.toString() ?? widget.place['_id']?.toString() ?? widget.place['name_eng']?.toString() ?? '';
                  final category = widget.place['category']?.toString().toLowerCase() ?? 'unknown';
                  Provider.of<EnhancedUserBehaviorProvider>(context, listen: false).recordQuickInteraction(placeId, category);
                } catch (e) {
                  print('[PlaceCard Modern] Error recording quick interaction: $e');
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PlaceDetailsScreen(place: widget.place),
                  ),
                ).then((_) => {
                      widget.onFavoriteChanged(),
                    });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with floating favorite button
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: SizedBox(
                          height: 170,
                          width: double.infinity,
                          child: _buildImage(imagePath),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: IconButton(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(
                                    favoritesProvider.isFavorite(
                                            widget.place['_id'] ??
                                                widget.place['id'])
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: favoritesProvider.isFavorite(
                                            widget.place['_id'] ??
                                                widget.place['id'])
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                            onPressed: _isLoading ? null : _toggleFavorite,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                languageProvider.getText(category) ,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.place['location'],
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Pricing Information
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${(widget.place['pricePerPerson'] ?? 0).toStringAsFixed(2)} per person',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if ((widget.place['maxCapacity'] ?? 0) > 0)
                              Text(
                                'Max ${widget.place['maxCapacity']} people',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          truncatedDescription,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Record quick interaction with EnhancedUserBehaviorProvider
                              try {
                                final placeId = widget.place['id']?.toString() ?? widget.place['_id']?.toString() ?? widget.place['name_eng']?.toString() ?? '';
                                final category = widget.place['category']?.toString().toLowerCase() ?? 'unknown';
                                Provider.of<EnhancedUserBehaviorProvider>(context, listen: false).recordQuickInteraction(placeId, category);
                              } catch (e) {
                                print('[PlaceCard Modern] Error recording quick interaction: $e');
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PlaceDetailsScreen(place: widget.place),
                                ),
                              ).then((_) => {
                                    widget.onFavoriteChanged(),
                                  });
                            },
                            child: Text(
                              languageProvider.getText('read_more'),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
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

        // Default (old) Card Design
        return Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // Record quick interaction with EnhancedUserBehaviorProvider
              try {
                final placeId = widget.place['id']?.toString() ?? widget.place['_id']?.toString() ?? widget.place['name_eng']?.toString() ?? '';
                final category = widget.place['category']?.toString().toLowerCase() ?? 'unknown';
                Provider.of<EnhancedUserBehaviorProvider>(context, listen: false).recordQuickInteraction(placeId, category);
              } catch (e) {
                print('[PlaceCard] Error recording quick interaction: $e');
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaceDetailsScreen(place: widget.place),
                ),
              ).then((_) => {
                    widget.onFavoriteChanged(),
                  });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: _buildImage(imagePath),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Category
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              languageProvider.getText(category) ,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                              widget.place['location'],
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // // Description
                      // Text(
                      //   truncatedDescription,
                      //   style: TextStyle(
                      //     color: AppColors.textSecondary,
                      //     fontSize: 14,
                      //   ),
                      //   maxLines: 3,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      const SizedBox(height: 8),

                      // Pricing Information
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '\$${(widget.place['pricePerPerson'] ?? 0).toStringAsFixed(2)} per person',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if ((widget.place['maxCapacity'] ?? 0) > 0)
                            Text(
                              'Max ${widget.place['maxCapacity']} people',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Read More Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                              // Record quick interaction with EnhancedUserBehaviorProvider
                              try {
                                final placeId = widget.place['id']?.toString() ?? widget.place['_id']?.toString() ?? widget.place['name_eng']?.toString() ?? '';
                                final category = widget.place['category']?.toString().toLowerCase() ?? 'unknown';
                                Provider.of<EnhancedUserBehaviorProvider>(context, listen: false).recordQuickInteraction(placeId, category);
                              } catch (e) {
                                print('[PlaceCard] Error recording quick interaction: $e');
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PlaceDetailsScreen(place: widget.place),
                                ),
                              ).then((_) => {
                                    widget.onFavoriteChanged(),
                                  });
                            },
                          child: Text(
                            languageProvider.getText('read_more'),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
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
      },
    );
  }
}
