// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourism_app/providers/language_provider.dart';
import 'package:tourism_app/providers/auth_provider.dart';
import 'package:tourism_app/providers/favorites_provider.dart';
import 'package:tourism_app/screens/auth/login_screen.dart';
import 'package:tourism_app/screens/auth/register_screen.dart';
import 'package:tourism_app/screens/dashboard/dashboard_screen.dart';
import 'package:tourism_app/screens/splash_screen.dart';
import 'package:tourism_app/utils/app_colors.dart';

import 'package:tourism_app/providers/enhanced_user_behavior_provider.dart';
import 'package:tourism_app/services/smart_chat_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for different platforms
  if (!kIsWeb) {
    // For mobile (Android/iOS) and desktop platforms
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } catch (e) {
      print('Database initialization failed: $e');
      // Fallback to default sqflite for mobile
    }
  }
  // For web platform, sqflite will use IndexedDB automatically

  // Initialize SmartChatService with Gemini AI
  SmartChatService.initialize();
  print('🤖 SmartChatService initialized');

  print('🚀 Starting app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🎨 Building MyApp');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => EnhancedUserBehaviorProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: Consumer2<LanguageProvider, AuthProvider>(
        builder: (context, languageProvider, authProvider, _) {
          return MaterialApp(
            title: languageProvider.getText('app_name'),
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.surface,
                background: AppColors.background,
                error: AppColors.error,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              textTheme: const TextTheme(
                headlineLarge: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                headlineMedium: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                bodyLarge: TextStyle(color: AppColors.textPrimary),
                bodyMedium: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/dashboard': (context) => const DashboardScreen(),
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
