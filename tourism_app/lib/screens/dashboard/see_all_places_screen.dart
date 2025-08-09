import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/widgets/modern_place_card.dart';
import 'package:google_fonts/google_fonts.dart';

class SeeAllPlacesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allPlaces;

  const SeeAllPlacesScreen({
    Key? key,
    required this.allPlaces,
  }) : super(key: key);

  @override
  State<SeeAllPlacesScreen> createState() => _SeeAllPlacesScreenState();
}

class _SeeAllPlacesScreenState extends State<SeeAllPlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPlaces = [];
  String _selectedCategory = 'all';
  String _sortBy = 'name'; // name, category, newest

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'All', 'icon': '🏛️'},
    {'key': 'beach', 'label': 'Beach', 'icon': '🏖️'},
    {'key': 'historical', 'label': 'Historical', 'icon': '🏛️'},
    {'key': 'cultural', 'label': 'Cultural', 'icon': '🎭'},
    {'key': 'natural', 'label': 'Natural', 'icon': '🌿'},
    {'key': 'urban', 'label': 'Urban', 'icon': '🏙️'},
    {'key': 'adventure', 'label': 'Adventure', 'icon': '⛰️'},
    {'key': 'religious', 'label': 'Religious', 'icon': '🕌'},
  ];

  @override
  void initState() {
    super.initState();
    _filteredPlaces = widget.allPlaces;
    _applySorting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _applyFilters();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      List<Map<String, dynamic>> filtered = widget.allPlaces;

      // Filter by category
      if (_selectedCategory != 'all') {
        filtered = filtered.where((place) {
          final category =
              place['category']?.toString().toLowerCase().trim() ?? '';
          return category == _selectedCategory.toLowerCase().trim();
        }).toList();
      }

      // Filter by search query
      final query = _searchController.text;
      if (query.isNotEmpty) {
        final searchQuery = query.toLowerCase().trim();
        filtered = filtered.where((place) {
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

      _filteredPlaces = filtered;
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
        case 'newest':
          _filteredPlaces.sort((a, b) {
            final dateA = a['createdAt']?.toString() ?? '';
            final dateB = b['createdAt']?.toString() ?? '';
            return dateB.compareTo(dateA); // Newest first
          });
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
              _buildSortOption('Name (A-Z)', 'name', Icons.sort_by_alpha),
              _buildSortOption('Category', 'category', Icons.category),
              _buildSortOption('Newest First', 'newest', Icons.access_time),
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

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'all';
      _searchController.clear();
      _filteredPlaces = widget.allPlaces;
    });
    _applySorting();
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
              'All Places',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Explore all destinations',
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
                hintText: 'Search all places...',
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
          // Category chips
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['key'];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category['icon']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            category['label']!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      _onCategoryChanged(category['key']!);
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: Colors.grey[100],
                    side: BorderSide(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                );
              },
            ),
          ),

          // Results counter and filters
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  '${_filteredPlaces.length} places found',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_selectedCategory != 'all' ||
                    _searchController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_sortBy != 'name')
                  Container(
                    margin: const EdgeInsets.only(left: 8),
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
                          'No places found',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Clear Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ModernPlaceCard(
                          place: place,
                          onFavoriteChanged: () {
                            // Refresh callback if needed
                          },
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
}
