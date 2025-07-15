import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/services/database_helper.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/widgets/place_card.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({Key? key}) : super(key: key);

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      final favorites = await _dbHelper.getFavoritePlaces(user['id']);
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getText('favorites')),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        languageProvider.getText('no_favorites'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final place = _favorites[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PlaceCard(
                          place: place,
                          onFavoriteChanged: () => _loadFavorites(),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
