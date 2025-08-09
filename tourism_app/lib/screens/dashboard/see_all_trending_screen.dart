import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/widgets/modern_place_card.dart';
import 'package:google_fonts/google_fonts.dart';

class SeeAllTrendingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> trendingPlaces;
  final bool isEnhanced;

  const SeeAllTrendingScreen({
    Key? key,
    required this.trendingPlaces,
    this.isEnhanced = false,
  }) : super(key: key);

  @override
  State<SeeAllTrendingScreen> createState() => _SeeAllTrendingScreenState();
}

class _SeeAllTrendingScreenState extends State<SeeAllTrendingScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPlaces = [];
  String _sortBy = 'popularity'; // popularity, name, category

  @override
  void initState() {
    super.initState();
    _filteredPlaces = widget.trendingPlaces;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPlaces = widget.trendingPlaces;
      } else {
        final searchQuery = query.toLowerCase().trim();
        _filteredPlaces = widget.trendingPlaces.where((place) {
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
      _applySorting();
    });
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredPlaces.sort((a, b) {
            final nameA = a['name_eng']?.toString() ?? '';
            final nameB = b['name_eng']?.toString() ?? '';
            return nameA.compareTo(nameB);
          });
          break;
        case 'category':
          _filteredPlaces.sort((a, b) {
            final catA = a['category']?.toString() ?? '';
            final catB = b['category']?.toString() ?? '';
            return catA.compareTo(catB);
          });
          break;
        case 'popularity':
        default:
          // Keep original order (trending order)
          break;
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Popularity', 'popularity', Icons.trending_up),
              _buildSortOption('Name', 'name', Icons.sort_by_alpha),
              _buildSortOption('Category', 'category', Icons.category),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey[600],
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : Colors.black87,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        _applySorting();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trending Now',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Most popular destinations',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.black87),
            onPressed: _showSortOptions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search trending places...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Results counter and sort indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  '${_filteredPlaces.length} trending places',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_sortBy != 'popularity')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Sorted by ${_sortBy}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Places list
          Expanded(
            child: _filteredPlaces.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trending places found',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search terms',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPlaces.length,
                    itemBuilder: (context, index) {
                      final place = _filteredPlaces[index];
                      final trendingReason = widget.isEnhanced && place['trendingReason'] != null
                          ? place['trendingReason']
                          : 'Trending #${index + 1}';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ModernPlaceCard(
                          place: place,
                          onFavoriteChanged: () {
                            // Refresh callback if needed
                          },
                          modern: true,
                          showRecommendationBadge: true,
                          recommendationReason: trendingReason,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
