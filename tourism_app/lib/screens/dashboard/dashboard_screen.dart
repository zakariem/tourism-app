import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/screens/dashboard/tabs/home_tab.dart';
import 'package:tourism_app/screens/dashboard/tabs/favorites_tab.dart';
import 'package:tourism_app/screens/dashboard/tabs/support_tab.dart';
import 'package:tourism_app/screens/dashboard/tabs/about_tab.dart';
import 'package:tourism_app/screens/dashboard/tabs/profile_tab.dart';
import 'package:tourism_app/utils/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const FavoritesTab(),
    const SupportTab(),
    const AboutTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    print('🏠 Building DashboardScreen');
    print('🏠 Current tab index: $_currentIndex');
    print('🏠 Selected tab: ${_tabs[_currentIndex].runtimeType}');

    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          print('🏠 Tab changed to index: $index');
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: languageProvider.getText('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon: const Icon(Icons.favorite),
            label: languageProvider.getText('favorites'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.support_agent_outlined),
            activeIcon: const Icon(Icons.support_agent),
            label: languageProvider.getText('support'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            activeIcon: const Icon(Icons.info),
            label: languageProvider.getText('about'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: languageProvider.getText('profile'),
          ),
        ],
      ),
    );
  }
}
