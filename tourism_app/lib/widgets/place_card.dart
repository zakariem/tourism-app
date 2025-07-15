import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/services/database_helper.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tourism_app/screens/place_details_screen.dart';
import 'package:tourism_app/providers/user_behavior_provider.dart';

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
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      final isFavorite = await _dbHelper.isPlaceFavorite(
        user['id'],
        widget.place['id'],
      );
      setState(() {
        _isFavorite = isFavorite;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (_isFavorite) {
        await _dbHelper.removeFromFavorites(user['id'], widget.place['id']);
      } else {
        await _dbHelper.addToFavorites(user['id'], widget.place['id']);
      }
      setState(() => _isFavorite = !_isFavorite);
      widget.onFavoriteChanged();
    } finally {
      setState(() => _isLoading = false);
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
    final imagePath = widget.place['image_path'];

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailsScreen(place: widget.place),
              ),
            ).then((_) => {
                  widget.onFavoriteChanged(),
                  Provider.of<UserBehaviorProvider>(context, listen: false)
                      .recordClick(widget.place['category'])
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
                      child: imagePath.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: imagePath,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            )
                          : Image.asset(
                              'assets/places/$imagePath',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.error,
                                color: Colors.red,
                              ),
                            ),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : Colors.grey,
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
                            languageProvider.getText(category),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlaceDetailsScreen(place: widget.place),
                            ),
                          ).then((_) => {
                                widget.onFavoriteChanged(),
                                Provider.of<UserBehaviorProvider>(context,
                                        listen: false)
                                    .recordClick(widget.place['category'])
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
          print(
              '[PlaceCard] Place tapped: \\${widget.place['name_eng']} (\\${widget.place['category']})');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaceDetailsScreen(place: widget.place),
            ),
          ).then((_) => {
                widget.onFavoriteChanged(),
                Provider.of<UserBehaviorProvider>(context, listen: false)
                    .recordClick(widget.place['category'])
              });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 140,
              width: double.infinity,
              child: imagePath.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imagePath,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    )
                  : Image.asset(
                      'assets/places/$imagePath',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    ),
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
                          languageProvider.getText(category),
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
                  // const SizedBox(height: 8),

                  // Read More Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        print('[PlaceCard] Read More button pressed');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaceDetailsScreen(place: widget.place),
                          ),
                        ).then((_) => {
                              widget.onFavoriteChanged(),
                              Provider.of<UserBehaviorProvider>(context,
                                      listen: false)
                                  .recordClick(widget.place['category'])
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
}
