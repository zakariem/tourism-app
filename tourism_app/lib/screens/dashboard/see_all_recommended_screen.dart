import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/widgets/modern_place_card.dart';
import 'package:google_fonts/google_fonts.dart';

class SeeAllRecommendedScreen extends StatefulWidget {
  final List<Map<String, dynamic>> recommendedPlaces;
  final String? recommendedCategory;
  final bool isEnhanced;

  const SeeAllRecommendedScreen({
    Key? key,
    required this.recommendedPlaces,
    this.recommendedCategory,
    this.isEnhanced = false,
  }) : super(key: key);

  @override
  State<SeeAllRecommendedScreen> createState() =>
      _SeeAllRecommendedScreenState();
}

class _SeeAllRecommendedScreenState extends State<SeeAllRecommendedScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPlaces = [];

  @override
  void initState() {
    super.initState();
    _filteredPlaces = widget.recommendedPlaces;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPlaces = widget.recommendedPlaces;
      } else {
        final searchQuery = query.toLowerCase().trim();
        _filteredPlaces = widget.recommendedPlaces.where((place) {
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended for You',
                    style: GoogleFonts.poppins(
                      fontSize: constraints.maxWidth < 350 ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.recommendedCategory != null)
                    Text(
                      'Based on ${widget.recommendedCategory} preferences',
                      style: GoogleFonts.poppins(
                        fontSize: constraints.maxWidth < 350 ? 10 : 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              );
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  padding: EdgeInsets.all(constraints.maxWidth < 400 ? 12 : 16),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search recommended places...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: constraints.maxWidth < 400 ? 12 : 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: constraints.maxWidth < 400 ? 20 : 24,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: constraints.maxWidth < 400 ? 20 : 24,
                              ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth < 400 ? 16 : 20,
                        vertical: constraints.maxWidth < 400 ? 12 : 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        body: Column(
          children: [
            // Results counter
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 400 ? 16 : 20,
                    vertical: constraints.maxWidth < 400 ? 10 : 12,
                  ),
                  color: Colors.white,
                  child: Text(
                    '${_filteredPlaces.length} recommended places found',
                    style: GoogleFonts.poppins(
                      fontSize: constraints.maxWidth < 400 ? 12 : 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),

            // Places list
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 400;
                  final padding = isSmallScreen ? 12.0 : 16.0;
                  final bottomMargin = isSmallScreen ? 12.0 : 16.0;

                  return _filteredPlaces.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(padding),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: isSmallScreen ? 48 : 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Text(
                                  'No recommended places found',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                Text(
                                  'Try adjusting your search terms',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(padding),
                          itemCount: _filteredPlaces.length,
                          itemBuilder: (context, index) {
                            final place = _filteredPlaces[index];
                            final recommendationReason = widget.isEnhanced && place['recommendationReason'] != null
                                ? place['recommendationReason']
                                : (widget.recommendedCategory != null
                                    ? 'Recommended for ${widget.recommendedCategory}'
                                    : 'Recommended for you');
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: bottomMargin),
                              child: ModernPlaceCard(
                                place: place,
                                onFavoriteChanged: () {
                                  // Refresh callback if needed
                                },
                                modern: true,
                                showRecommendationBadge: true,
                                recommendationReason: recommendationReason,
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
