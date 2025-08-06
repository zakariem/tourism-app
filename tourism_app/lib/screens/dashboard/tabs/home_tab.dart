import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/user_behavior_provider.dart';
import 'package:tourism_app/providers/favorites_provider.dart';
import 'package:tourism_app/services/places_service.dart';
import 'package:tourism_app/services/recommendation_service.dart';
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
  bool _isRecommending = false;
  double _scrollOffset = 0.0;

  late AnimationController _heroAnimationController;
  late Animation<double> _heroParallaxAnimation;

  @override
  void initState() {
    super.initState();
    // print('🚀 HomeTab initState called');
    _loadPlaces();
    _loadLastRecommendation();
    _maybeRecommend();
    _setupAnimations();
    _setupScrollListener();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    await favoritesProvider.loadFavorites();
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
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    _heroAnimationController.dispose();
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
    final prefs = await SharedPreferences.getInstance();
    final lastCategory = prefs.getString('last_recommended_category');
    if (lastCategory != null) {
      try {
        final places = await PlacesService.getPlacesByCategory(lastCategory);
        
        setState(() {
          _recommendedCategory = lastCategory;
          _recommendedPlaces = places;
        });
      } catch (e) {
        print('❌ Error loading last recommendation: $e');
      }
    }
  }

  void _maybeRecommend() async {
    if (_isRecommending || !mounted) return;

    setState(() => _isRecommending = true);

    try {
      final behavior =
          Provider.of<UserBehaviorProvider>(context, listen: false);
      final recommendedCategory = await RecommendationService()
          .getRecommendedCategory(behavior.featureVector);

      if (recommendedCategory != null &&
          recommendedCategory != _recommendedCategory &&
          mounted) {
        final places =
            await PlacesService.getPlacesByCategory(recommendedCategory);

        if (mounted) {
          setState(() {
            _recommendedCategory = recommendedCategory;
            _recommendedPlaces = places;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'last_recommended_category', recommendedCategory);
        }
      }
    } catch (e) {
      print('❌ Error getting recommendations: $e');
    } finally {
      if (mounted) {
        setState(() => _isRecommending = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new timer for debounced search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
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

            // Recommended Section (only show when no search and category is 'all')
            if (_recommendedPlaces.isNotEmpty && 
                _searchController.text.isEmpty && 
                _selectedCategory == 'all')
              _buildRecommendedSection(
                Provider.of<LanguageProvider>(context, listen: false),
              ),

            // Trending Section (only show when no search and category is 'all')
            if (_searchController.text.isEmpty && _selectedCategory == 'all')
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

  Widget _buildRecommendedSection(LanguageProvider languageProvider) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader(
            'Recommended for You',
            Icons.recommend,
            onSeeAllPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeeAllRecommendedScreen(
                    recommendedPlaces: _recommendedPlaces,
                    recommendedCategory: _recommendedCategory,
                  ),
                ),
              );
            },
          ),
          SizedBox(
            height: 340,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendedPlaces.length,
              itemBuilder: (context, index) {
                if (index >= _recommendedPlaces.length) {
                  return const SizedBox.shrink();
                }
                final place = _recommendedPlaces[index];
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: ModernPlaceCard(
                    place: place,
                    onFavoriteChanged: _loadPlaces,
                    modern: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(LanguageProvider languageProvider) {
    final trendingPlaces = _places.take(5).toList();

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
                    trendingPlaces: _places, // Pass all places for trending
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
                if (index >= trendingPlaces.length) {
                  return const SizedBox.shrink();
                }
                final place = trendingPlaces[index];
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: ModernPlaceCard(
                    place: place,
                    onFavoriteChanged: _loadPlaces,
                    modern: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Icon(
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
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : 'all';
            // Clear search when changing category for better UX
            if (!selected) {
              _searchController.clear();
            }
            _performSearch(_searchController.text);
          });
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
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
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
}
