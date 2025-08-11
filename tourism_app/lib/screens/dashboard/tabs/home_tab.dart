import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';

import 'package:tourism_app/providers/enhanced_user_behavior_provider.dart';
import 'package:tourism_app/providers/favorites_provider.dart';
import 'package:tourism_app/services/places_service.dart';
import 'package:tourism_app/services/enhanced_recommendation_service.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/widgets/modern_place_card.dart';

import 'package:tourism_app/screens/dashboard/see_all_recommended_screen.dart';
import 'package:tourism_app/screens/dashboard/see_all_trending_screen.dart';
import 'package:tourism_app/screens/dashboard/see_all_places_screen.dart';
import 'package:tourism_app/screens/dashboard/see_all_categories_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;

  List<Map<String, dynamic>> _places = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  String? _recommendedCategory;
  List<Map<String, dynamic>> _recommendedPlaces = [];
  final List<Map<String, dynamic>> _trendingPlaces = [];
  List<Map<String, dynamic>> _enhancedRecommendations = [];
  List<Map<String, dynamic>> _enhancedTrendingPlaces = [];
  bool _isRecommending = false;
  bool _isLoadingEnhancedContent = true;
  final bool _useEnhancedRecommendations = true;
  double _scrollOffset = 0.0;
  late EnhancedRecommendationService _enhancedRecommendationService;
  
  // Store reference to the provider listener for proper cleanup
  VoidCallback? _providerListener;

  late AnimationController _heroAnimationController;
  late Animation<double> _heroParallaxAnimation;

  @override
  void initState() {
    super.initState();
    // print('🚀 HomeTab initState called');
    _loadPlaces();
    _loadLastRecommendation();
    _maybeRecommend();
    _initializeEnhancedRecommendations();
    _setupAnimations();
    _setupScrollListener();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    await favoritesProvider.loadFavorites();
  }

  Future<void> _initializeEnhancedRecommendations() async {
    try {
      final enhancedBehaviorProvider =
          Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);
      
      // Set up a listener to update UI when cached data is loaded
      _providerListener = () async {
        if (!mounted) return;
        
        try {
          final recommendations = await enhancedBehaviorProvider.getRecommendations();
          final trendingPlaces = await enhancedBehaviorProvider.getTrendingPlaces();
          
          if (mounted) {
            setState(() {
              _enhancedRecommendations = recommendations;
              _enhancedTrendingPlaces = trendingPlaces;
              _isLoadingEnhancedContent = false;
            });
          }
        } catch (e) {
          print('❌ Error in provider listener: $e');
          if (mounted) {
            setState(() {
              _isLoadingEnhancedContent = false;
            });
          }
        }
      };
      
      // Add listener for immediate updates when cached data is available
      enhancedBehaviorProvider.addListener(_providerListener!);
      
      // Initialize the provider (this will load cached data first, then fresh data)
      await enhancedBehaviorProvider.initialize();

      // Load current recommendations and trending
      if (mounted) {
        final recommendations = await enhancedBehaviorProvider.getRecommendations();
        final trendingPlaces = await enhancedBehaviorProvider.getTrendingPlaces();

        if (mounted) {
          setState(() {
            _enhancedRecommendations = recommendations;
            _enhancedTrendingPlaces = trendingPlaces;
            _isLoadingEnhancedContent = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error initializing enhanced recommendations: $e');
      if (mounted) {
        setState(() {
          _isLoadingEnhancedContent = false;
        });
      }
    }
  }

  void _setupAnimations() {
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _heroParallaxAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _heroAnimationController, curve: Curves.easeInOut),
    );

    _heroAnimationController.repeat(reverse: true);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    _heroAnimationController.dispose();
    
    // Remove the provider listener if it exists
    if (_providerListener != null) {
      try {
        final enhancedBehaviorProvider =
            Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);
        enhancedBehaviorProvider.removeListener(_providerListener!);
        _providerListener = null;
      } catch (e) {
        // Ignore errors during disposal
      }
    }
    
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final places = await PlacesService.getAllPlaces();

      if (!mounted) return;

      setState(() {
        _places = places;
        _filteredPlaces = places;
        _isLoading = false;
      });

      // Apply current filters after loading
      _performSearch(_searchController.text);
    } catch (e) {
      print('❌ Error loading places: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLastRecommendation() async {
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final lastCategory = prefs.getString('last_recommended_category');
    if (lastCategory != null && mounted) {
      try {
        final places = await PlacesService.getPlacesByCategory(lastCategory);

        if (mounted) {
          setState(() {
            _recommendedCategory = lastCategory;
            _recommendedPlaces = places;
          });
        }
      } catch (e) {
        print('❌ Error loading last recommendation: $e');
      }
    }
  }

  void _maybeRecommend() async {
    if (_isRecommending || !mounted) return;

    if (mounted) {
      setState(() => _isRecommending = true);
    }

    try {
      // Initialize enhanced recommendation service
      _enhancedRecommendationService = EnhancedRecommendationService();
      await _enhancedRecommendationService.initialize();

      if (!mounted) return;

      // Get dynamic recommendations based on user behavior
      final recommendations = await _enhancedRecommendationService
          .getDynamicRecommendations(limit: 10);

      if (recommendations.isNotEmpty && mounted) {
        // Get the top category from recommendations
        final topRecommendation = recommendations.first;
        final topCategory =
            topRecommendation['category']?.toString().toLowerCase();

        if (topCategory != null && topCategory != _recommendedCategory && mounted) {
          setState(() {
            _recommendedCategory = topCategory;
            _recommendedPlaces = recommendations.take(5).toList();
          });

          if (mounted) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_recommended_category', topCategory);

            print(
                '✅ Dynamic recommendations updated: $topCategory with ${recommendations.length} places');
          }
        }
      }
    } catch (e) {
      print('❌ Error getting enhanced recommendations: $e');
      // Fallback to basic recommendation if enhanced fails
      if (mounted) {
        await _fallbackToBasicRecommendation();
      }
    } finally {
      if (mounted) {
        setState(() => _isRecommending = false);
      }
    }
  }

  Future<void> _fallbackToBasicRecommendation() async {
    if (!mounted) return;
    
    try {
      final enhancedBehavior =
          Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);

      // Use enhanced behavior provider for fallback
      final categoryInteractions = enhancedBehavior.categoryInteractions;

      if (categoryInteractions.isEmpty) {
        // No interactions yet, show default beach category
        if (mounted) {
          final places = await PlacesService.getPlacesByCategory('beach');
          if (mounted) {
            setState(() {
              _recommendedCategory = 'beach';
              _recommendedPlaces = places;
            });
          }
        }
        return;
      }

      final topCategory = categoryInteractions.entries
           .reduce((a, b) => a.value > b.value ? a : b).key;

      if (topCategory != _recommendedCategory && mounted) {
        final places = await PlacesService.getPlacesByCategory(topCategory);

        if (mounted) {
          setState(() {
            _recommendedCategory = topCategory;
            _recommendedPlaces = places;
          });

          print('✅ Fallback recommendation: $topCategory');
        }
      }
    } catch (e) {
      print('❌ Error in fallback recommendation: $e');
    }
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new timer for debounced search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      // First filter by category
      List<Map<String, dynamic>> categoryFiltered = _places;
      if (_selectedCategory != 'all') {
        categoryFiltered = _places.where((place) {
          final category =
              place['category']?.toString().toLowerCase().trim() ?? '';
          final selectedCat = _selectedCategory.toLowerCase().trim();
          return category == selectedCat;
        }).toList();
      }

      // Then filter by search query
      if (query.isEmpty) {
        _filteredPlaces = categoryFiltered;
      } else {
        final searchQuery = query.toLowerCase().trim();
        _filteredPlaces = categoryFiltered.where((place) {
          final nameEng = place['name_eng']?.toString().toLowerCase() ?? '';
          final nameSom = place['name_som']?.toString().toLowerCase() ?? '';
          final descEng = place['desc_eng']?.toString().toLowerCase() ?? '';
          final descSom = place['desc_som']?.toString().toLowerCase() ?? '';
          final location = place['location']?.toString().toLowerCase() ?? '';
          final category = place['category']?.toString().toLowerCase() ?? '';

          return nameEng.contains(searchQuery) ||
              nameSom.contains(searchQuery) ||
              descEng.contains(searchQuery) ||
              descSom.contains(searchQuery) ||
              location.contains(searchQuery) ||
              category.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchDebounceTimer?.cancel();
    _performSearch('');
  }

  void _resetAllFilters() {
    setState(() {
      _selectedCategory = 'all';
      _searchController.clear();
      _searchDebounceTimer?.cancel();
      _filteredPlaces = _places;
    });
  }

  @override
  Widget build(BuildContext context) {
    // print('🎨 Building HomeTab UI');
    // print('🎨 _isLoading: $_isLoading');
    // print('🎨 _places.length: ${_places.length}');
    // print('🎨 _filteredPlaces.length: ${_filteredPlaces.length}');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Hero Banner
            SliverToBoxAdapter(
              child: _buildEnhancedHeroBanner(
                Provider.of<LanguageProvider>(context, listen: false),
              ),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: _buildQuickStatsCards(),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: _buildModernSearchBar(
                Provider.of<LanguageProvider>(context, listen: false),
              ),
            ),

            // Category Chips
            SliverToBoxAdapter(
              child: _buildEnhancedCategoryChips(
                Provider.of<LanguageProvider>(context, listen: false),
              ),
            ),

            // Enhanced Recommended Section (only show when no search and category is 'all')
            if (_useEnhancedRecommendations &&
                _searchController.text.isEmpty &&
                _selectedCategory == 'all')
              _buildEnhancedRecommendedSection(
                Provider.of<LanguageProvider>(context, listen: false),
              ),

            // Fallback Recommended Section
            if (!_useEnhancedRecommendations &&
                _recommendedPlaces.isNotEmpty &&
                _searchController.text.isEmpty &&
                _selectedCategory == 'all')
              _buildRecommendedSection(
                Provider.of<LanguageProvider>(context, listen: false),
              ),

            // Enhanced Trending Section (only show when no search and category is 'all')
            if (_useEnhancedRecommendations &&
                _searchController.text.isEmpty &&
                _selectedCategory == 'all')
              _buildEnhancedTrendingSection(
                Provider.of<LanguageProvider>(context, listen: false),
              ),

            // Fallback Trending Section
            if (!_useEnhancedRecommendations &&
                _searchController.text.isEmpty &&
                _selectedCategory == 'all')
              _buildTrendingSection(
                Provider.of<LanguageProvider>(context, listen: false),
              ),

            // Search Results Counter
            if (_searchController.text.isNotEmpty || _selectedCategory != 'all')
              _buildSearchResultsCounter(
                Provider.of<LanguageProvider>(context, listen: false),
              ),

            // All Places Section
            _buildAllPlacesSection(
              Provider.of<LanguageProvider>(context, listen: false),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced recommendation helper methods

  Widget _buildEnhancedSectionHeader(
    String title,
    IconData icon, {
    String? subtitle,
    VoidCallback? onSeeAllPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (onSeeAllPressed != null)
                TextButton(
                  onPressed: onSeeAllPressed,
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedPlaceCard(
    Map<String, dynamic> place, {
    bool showRecommendationBadge = false,
    String? recommendationReason,
  }) {
    return GestureDetector(
      onTap: () => _handlePlaceCardTap(place),
      child: ModernPlaceCard(
        place: place,
        onFavoriteChanged: _loadPlaces,
        modern: true,
        showRecommendationBadge: showRecommendationBadge,
        recommendationReason:
            recommendationReason ?? place['recommendation_reason'],
      ),
    );
  }

  void _handlePlaceCardTap(Map<String, dynamic> place) async {
    final placeId =
        place['id']?.toString() ?? place['name_eng']?.toString() ?? '';
    final category = place['category']?.toString().toLowerCase() ?? '';

    // Record interaction with enhanced behavior provider
    try {
      final enhancedBehaviorProvider =
          Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);
      await enhancedBehaviorProvider.recordQuickInteraction(placeId, category);

      // Refresh recommendations after interaction
      await _refreshEnhancedRecommendations();
    } catch (e) {
      print('❌ Error recording place interaction: $e');
    }

    // Navigate to place details (implement your navigation logic here)
    // Navigator.push(context, MaterialPageRoute(builder: (context) => PlaceDetailsScreen(place: place)));
  }

  Future<void> _refreshEnhancedRecommendations() async {
    if (mounted) {
      setState(() {
        _isLoadingEnhancedContent = true;
      });
    }

    try {
      final enhancedBehaviorProvider =
          Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);

      // Load recommendations and trending in parallel for faster refresh
      final futures = await Future.wait([
        enhancedBehaviorProvider.getRecommendations(forceRefresh: true),
        enhancedBehaviorProvider.getTrendingPlaces(forceRefresh: true),
      ]);

      final recommendations = futures[0];
      final trendingPlaces = futures[1];

      if (mounted) {
        setState(() {
          _enhancedRecommendations = recommendations;
          _enhancedTrendingPlaces = trendingPlaces;
          _isLoadingEnhancedContent = false;
        });
      }
    } catch (e) {
      print('❌ Error refreshing enhanced recommendations: $e');
      if (mounted) {
        setState(() {
          _isLoadingEnhancedContent = false;
        });
      }
    }
  }



  String _getRecommendationSubtitle() {
    try {
      final enhancedBehaviorProvider =
          Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);
      return enhancedBehaviorProvider.getRecommendationExplanation();
    } catch (e) {
      return 'Personalized recommendations for you';
    }
  }

  String _getMostPreferredCategory() {
    try {
      final enhancedBehaviorProvider =
          Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);
      return enhancedBehaviorProvider.mostPreferredCategory;
    } catch (e) {
      return 'beach';
    }
  }

  Widget _buildRecommendedSection(LanguageProvider languageProvider) {
    if (_recommendedPlaces.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.recommend,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recommended for You',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SeeAllRecommendedScreen(
                              recommendedPlaces: _recommendedPlaces,
                              recommendedCategory: _recommendedCategory,
                              isEnhanced: false,
                            ),
                          ),
                        );
                      },
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
                const SizedBox(height: 4),
                Text(
                  _getRecommendationExplanation(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendedPlaces.length,
              itemBuilder: (context, index) {
                final place = _recommendedPlaces[index];
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => _handlePlaceInteraction(place),
                    child: Stack(
                      children: [
                        ModernPlaceCard(
                          place: place,
                          onFavoriteChanged: _loadPlaces,
                          modern: true,
                        ),
                        // Recommendation badge
                        if (place['recommendation_score'] != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(place['recommendation_score'] as double).toInt()}%',
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getRecommendationExplanation() {
    try {
      final enhancedBehavior =
          Provider.of<EnhancedUserBehaviorProvider>(context, listen: false);
      
      return enhancedBehavior.getRecommendationExplanation();
    } catch (e) {
      return 'Personalized recommendations for you';
    }
  }

  Widget _buildTrendingSection(LanguageProvider languageProvider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadTrendingPlaces(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Container(
              height: 350,
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final trendingPlaces = snapshot.data ?? [];

        if (trendingPlaces.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Column(
            children: [
              _buildSectionHeader(
                'Trending Now',
                Icons.trending_up,
                onSeeAllPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeeAllTrendingScreen(
                        trendingPlaces: trendingPlaces,
                        isEnhanced: false,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(
                height: 350,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: trendingPlaces.length,
                  itemBuilder: (context, index) {
                    final place = trendingPlaces[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => _handlePlaceInteraction(place),
                        child: Stack(
                          children: [
                            ModernPlaceCard(
                              place: place,
                              onFavoriteChanged: _loadPlaces,
                              modern: true,
                            ),
                            // Trending badge
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.trending_up,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Trending',
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadTrendingPlaces() async {
    try {
      if (_enhancedRecommendationService == null) {
        _enhancedRecommendationService = EnhancedRecommendationService();
        await _enhancedRecommendationService.initialize();
      }

      final trendingPlaces =
          await _enhancedRecommendationService.getTrendingPlaces(limit: 5);

      // If no trending places from enhanced service, fallback to recent places
      if (trendingPlaces.isEmpty) {
        return _places.take(5).toList();
      }

      return trendingPlaces;
    } catch (e) {
      print('❌ Error loading trending places: $e');
      return _places.take(5).toList();
    }
  }

  void _handlePlaceInteraction(Map<String, dynamic> place) async {
    try {
      final placeId =
          place['id']?.toString() ?? place['name_eng']?.toString() ?? '';
      final category = place['category']?.toString().toLowerCase() ?? '';

      // Record interaction with enhanced recommendation service
      await _enhancedRecommendationService.recordPlaceInteraction(
          placeId, category);

      print('✅ Recorded interaction: $placeId in $category');

      // Refresh recommendations after interaction
      _maybeRecommend();
    } catch (e) {
      print('❌ Error recording place interaction: $e');
    }
  }

  Widget _buildAllPlacesSection(LanguageProvider languageProvider) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // Building section header
            return _buildSectionHeader(
              'All Places',
              Icons.explore,
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeeAllPlacesScreen(
                      allPlaces: _places,
                    ),
                  ),
                );
              },
            );
          }

          if (_isLoading) {
            // print('⏳ Showing loading indicator');
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (_filteredPlaces.isEmpty) {
            // print('⚠️ No places to display');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      languageProvider.getText('no_places_found'),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _resetAllFilters();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  await _loadPlaces();
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Reload Places'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          final placeIndex = index - 1;
          if (placeIndex >= _filteredPlaces.length) {
            return const SizedBox.shrink();
          }

          final place = _filteredPlaces[placeIndex];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ModernPlaceCard(
              place: place,
              onFavoriteChanged: _loadPlaces,
              modern: true,
            ),
          );
        },
        childCount: _isLoading
            ? 2
            : (_filteredPlaces.isEmpty ? 2 : _filteredPlaces.length + 1),
      ),
    );
  }

  Widget _buildEnhancedHeroBanner(LanguageProvider languageProvider) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Parallax Background
          AnimatedBuilder(
            animation: _heroAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0,
                    -_scrollOffset * 0.5 + _heroParallaxAnimation.value * 10),
                child: Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    image: DecorationImage(
                      image: AssetImage('assets/places/liido.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),

          // Gradient Overlay
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Somalia',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Welcome Text
                  Text(
                    languageProvider.getText('welcome'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    languageProvider.getText('explore_somalia'),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.place,
              title: 'Places',
              value: '${_places.length}',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, child) {
                return _buildStatCard(
                  icon: Icons.favorite,
                  title: 'Favorites',
                  value: '${favoritesProvider.favorites.length}',
                  color: Colors.red,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.star,
              title: 'Rating',
              value: '4.8', // TODO: Calculate average rating
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
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

  Widget _buildModernSearchBar(LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: languageProvider.getText('search'),
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.search, color: AppColors.primary),
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return value.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: () {
                          _clearSearch();
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          style: GoogleFonts.poppins(),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildEnhancedCategoryChips(LanguageProvider languageProvider) {
    final allCategories = [
      {'key': 'all', 'icon': Icons.public},
      {'key': 'beach', 'icon': Icons.beach_access},
      {'key': 'historical', 'icon': Icons.account_balance},
      {'key': 'cultural', 'icon': Icons.palette},
      {'key': 'religious', 'icon': Icons.mosque},
      {'key': 'suburb', 'icon': Icons.location_city},
      {'key': 'urban park', 'icon': Icons.park},
    ];

    // Show only first 3 categories plus 'See All' button
    final displayCategories = allCategories.take(3).toList();

    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayCategories.length,
              itemBuilder: (context, index) {
                final category = displayCategories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildEnhancedCategoryChip(
                    category['key'] as String,
                    languageProvider,
                    category['icon'] as IconData,
                  ),
                );
              },
            ),
          ),
          // See All Categories Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SeeAllCategoriesScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.grid_view,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    languageProvider.getText('see_all'),
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCategoryChip(
      String category, LanguageProvider languageProvider, IconData icon) {
    final isSelected = _selectedCategory == category;
    final categoryText = languageProvider.getText(category);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                categoryText,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        onSelected: (selected) async {
          setState(() {
            _selectedCategory = selected ? category : 'all';
            // Clear search when changing category for better UX
            if (!selected) {
              _searchController.clear();
            }
            _performSearch(_searchController.text);
          });
          // Record category interaction using enhanced provider
          try {
            if (_selectedCategory != 'all') {
              await Provider.of<EnhancedUserBehaviorProvider>(context, listen: false)
                  .recordCategoryInteraction(_selectedCategory);
            }
          } catch (e) {
            // Silently ignore
          }
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: isSelected ? 8 : 2,
        shadowColor: isSelected
            ? AppColors.primary.withOpacity(0.3)
            : Colors.black.withOpacity(0.1),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSearchResultsCounter(LanguageProvider languageProvider) {
    final hasSearch = _searchController.text.isNotEmpty;
    final hasCategory = _selectedCategory != 'all';
    final resultCount = _filteredPlaces.length;

    String counterText;
    if (hasSearch && hasCategory) {
      counterText =
          'Found $resultCount places for "${_searchController.text}" in ${languageProvider.getText(_selectedCategory)}';
    } else if (hasSearch) {
      counterText = 'Found $resultCount places for "${_searchController.text}"';
    } else if (hasCategory) {
      counterText =
          'Found $resultCount places in ${languageProvider.getText(_selectedCategory)}';
    } else {
      counterText = 'Showing $resultCount places';
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.filter_list,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                counterText,
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasSearch || hasCategory)
              GestureDetector(
                onTap: _resetAllFilters,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {VoidCallback? onSeeAllPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          TextButton(
            onPressed: onSeeAllPressed,
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
    );
  }

  Widget _buildEnhancedRecommendedSection(LanguageProvider languageProvider) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildEnhancedSectionHeader(
            'Recommended for You',
            Icons.star,
            onSeeAllPressed: _isLoadingEnhancedContent || _enhancedRecommendations.isEmpty ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeeAllRecommendedScreen(
                    recommendedPlaces: _enhancedRecommendations,
                    recommendedCategory: _getMostPreferredCategory(),
                    isEnhanced: true,
                  ),
                ),
              );
            },
            subtitle: _isLoadingEnhancedContent ? 'Loading personalized recommendations...' : _getRecommendationSubtitle(),
          ),
          SizedBox(
            height: 350,
            child: _isLoadingEnhancedContent
                ? _buildUnifiedLoadingIndicator()
                : _enhancedRecommendations.isEmpty
                    ? _buildEmptyState('No recommendations available', Icons.star_outline)
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _enhancedRecommendations.take(5).length,
                        itemBuilder: (context, index) {
                          final place = _enhancedRecommendations[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildEnhancedPlaceCard(
                              place,
                              showRecommendationBadge: true,
                              recommendationReason: place['recommendationReason'],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEnhancedTrendingSection(LanguageProvider languageProvider) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildEnhancedSectionHeader(
            'Trending Now',
            Icons.trending_up,
            onSeeAllPressed: _isLoadingEnhancedContent || _enhancedTrendingPlaces.isEmpty ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeeAllTrendingScreen(
                    trendingPlaces: _enhancedTrendingPlaces,
                    isEnhanced: true,
                  ),
                ),
              );
            },
            subtitle: _isLoadingEnhancedContent ? 'Loading trending destinations...' : 'Popular destinations right now',
          ),
          SizedBox(
            height: 350,
            child: _isLoadingEnhancedContent
                ? _buildUnifiedLoadingIndicator()
                : _enhancedTrendingPlaces.isEmpty
                    ? _buildEmptyState('No trending places available', Icons.trending_up_outlined)
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _enhancedTrendingPlaces.take(5).length,
                        itemBuilder: (context, index) {
                          final place = _enhancedTrendingPlaces[index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildEnhancedPlaceCard(
                              place,
                              showRecommendationBadge: true,
                              recommendationReason: place['trendingReason'],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUnifiedLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading recommendations and trending places...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
