import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/screens/auth/login_screen.dart';
import 'package:tourism_app/screens/dashboard/dashboard_screen.dart';
import 'package:tourism_app/utils/app_colors.dart';
import 'package:tourism_app/widgets/language_toggle.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🚀 SplashScreen: Starting app initialization');
    // Add a small delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // ignore: unused_local_variable
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    print('Checking authentication status...');
    // Check if user is logged in
    final isLoggedIn = await authProvider.checkAuthStatus();
    print('Authentication check result: $isLoggedIn');

    if (!mounted) return;

    // Navigate to appropriate screen
    print('Navigating to: ${isLoggedIn ? 'Dashboard' : 'Login'}');
    print('🚀 About to navigate to DashboardScreen');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          print('🚀 Building DashboardScreen route');
          return isLoggedIn ? const DashboardScreen() : const LoginScreen();
        },
      ),
    );
    print('🚀 Navigation completed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Icon(
                  Icons.travel_explore,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                // App name
                Text(
                  Provider.of<LanguageProvider>(context).getText('app_name'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
          // Language toggle in top-right corner
          Positioned(
            top: 48,
            right: 16,
            child: const LanguageToggle(
              showLabel: true,
              iconColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
