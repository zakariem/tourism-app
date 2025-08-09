import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/services/places_service.dart';
import 'package:tourism_app/widgets/modern_place_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tourism_app/providers/enhanced_user_behavior_provider.dart';

class SeeAllCategoriesScreen extends StatefulWidget {
  const SeeAllCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<SeeAllCategoriesScreen> createState() => _SeeAllCategoriesScreenState();
}

class _SeeAllCategoriesScreenState extends State<SeeAllCategoriesScreen> {
  String? _selectedCategory;
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'key': 'all', 'icon': Icons.public},
    {'key': 'beach', 'icon': Icons.beach_access},
    {'key': 'historical', 'icon': Icons.account_balance},
    {'key': 'cultural', 'icon': Icons.palette},
    {'key': 'religious', 'icon': Icons.mosque},
    {'key': 'suburb', 'icon': Icons.location_city},
    {'key': 'urban park', 'icon': Icons.park},
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          languageProvider.getText('categories'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Categories Grid
          if (_selectedCategory == null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryCard(
                      category['key'] as String,
                      category['icon'] as IconData,
                      languageProvider,
                    );
                  },
                ),
              ),
            )
          else
            // Selected Category Header
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _places = [];
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _categories.firstWhere(
                            (cat) => cat['key'] == _selectedCategory,
                            orElse: () => _categories[0],
                          )['icon'] as IconData,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          languageProvider.getText(_selectedCategory!),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_places.length} places',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Places List
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : _places.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No places found in this category',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _places.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: ModernPlaceCard(place: _places[index]),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String categoryKey,
    IconData icon,
    LanguageProvider languageProvider,
  ) {
    return GestureDetector(
      onTap: () async {
        // Record category interaction using EnhancedUserBehaviorProvider
        try {
          if (categoryKey != 'all') {
            await Provider.of<EnhancedUserBehaviorProvider>(context, listen: false)
                .recordCategoryInteraction(categoryKey);
          }
        } catch (e) {
          print('[SeeAllCategories] Error recording category interaction: $e');
        }
        await _selectCategory(categoryKey);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              languageProvider.getText(categoryKey),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCategory(String categoryKey) async {
    setState(() {
      _selectedCategory = categoryKey;
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> places;
      if (categoryKey == 'all') {
        places = await PlacesService.getAllPlaces();
      } else {
        places = await PlacesService.getPlacesByCategory(categoryKey);
      }

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading places for category $categoryKey: $e');
      setState(() {
        _places = [];
        _isLoading = false;
      });
    }
  }
}