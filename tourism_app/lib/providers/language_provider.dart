import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'app_language';
  late SharedPreferences _prefs;
  String _currentLanguage = 'en';

  // Simple translation map
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'Tourism App',
      'home': 'Home',
      'favorites': 'Favorites',
      'about': 'About',
      'profile': 'Profile',
      'search': 'Search places...',
      'login': 'Login',
      'register': 'Register',
      'username': 'Username',
      'password': 'Password',
      'email': 'Email',
      'full_name': 'Full Name',
      'submit': 'Submit',
      'cancel': 'Cancel',
      'logout': 'Logout',
      'settings': 'Settings',
      'language': 'Language',
      'categories': 'Categories',
      'all_places': 'All Places',
      'beach': 'Beach',
      'historical': 'Historical',
      'cultural': 'Cultural',
      'religious': 'Religious',
      'location': 'Location',
      'description': 'Description',
      'add_to_favorites': 'Add to Favorites',
      'remove_from_favorites': 'Remove from Favorites',
      'about_app': 'About App',
      'developer_team': 'Developer Team',
      'version': 'Version',
      'no_places_found': 'No places found',
      'enter_email': 'Enter your email',
      'enter_full_name': 'Enter your full name',
      'email_required': 'Email is required',
      'invalid_email': 'Please enter a valid email',
      'name_required': 'Name is required',
      'save': 'Save',
      'confirm_logout': 'Confirm Logout',
      'logout_message': 'Are you sure you want to logout?',
      'profile_updated': 'Profile updated successfully',
      'update_failed': 'Failed to update profile',
      'login_failed': 'Login failed. Please check your credentials.',
      'registration_successful': 'Registration successful!',
      'registration_failed': 'Registration failed. Please try again.',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'password_required': 'Password is required',
      'password_too_short': 'Password must be at least 6 characters',
      'confirm_password_required': 'Please confirm your password',
      'passwords_dont_match': 'Passwords do not match',
      'login_to_explore': 'Login to explore tourist places',
      'create_account': 'Create Account',
      'start_exploring': 'Start exploring tourist places',
      'support': 'Support',
      'coming_soon': 'Coming Soon!',
      'support_coming_soon':
          'Our support chat feature is under development. Stay tuned for updates!',
      'read_more': 'Read More',
    },
    'so': {
      'app_name': 'App-ka Dalxiiska',
      'home': 'Guriga',
      'favorites': 'La Jecel yahay',
      'about': 'Ku Saabsan',
      'profile': 'Profile',
      'search': 'Raadi meelaha...',
      'login': 'Soo Geli',
      'register': 'Diiwaan geli',
      'username': 'Magaca isticmaalaha',
      'password': 'Lambarka sirta ah',
      'email': 'Email',
      'full_name': 'Magaca Oo Dhammeystiran',
      'submit': 'Dir',
      'cancel': 'Jooji',
      'logout': 'Ka Bax',
      'settings': 'Dejinta',
      'language': 'Luuqadda',
      'categories': 'Qaybaha',
      'all_places': 'Dhamaan Meelaha',
      'beach': 'Xeebta',
      'historical': 'Taariikhiga',
      'cultural': 'Dhaqanka',
      'religious': 'Diiniga',
      'location': 'Goobta',
      'description': 'Sharaxaada',
      'add_to_favorites': 'Ku Dar La Jecel yahay',
      'remove_from_favorites': 'Ka Saar La Jecel yahay',
      'about_app': 'Ku Saabsan App-ka',
      'developer_team': 'Kooxda Horumariyayaasha',
      'version': 'Version',
      'no_places_found': 'Ma jiraan meelo la heli karo',
      'enter_email': 'Geli emailkaaga',
      'enter_full_name': 'Geli magacaaga oo dhammeystiran',
      'email_required': 'Emailka waa lagama maarmaanka ah',
      'invalid_email': 'Fadlan geli email sax ah',
      'name_required': 'Magaca waa lagama maarmaanka ah',
      'save': 'Keydii',
      'confirm_logout': 'Xaqiiji Ka Baxista',
      'logout_message': 'Ma hubtaa inaad ka baxayso?',
      'profile_updated': 'Profile-ka waa la cusboonaysiiyey',
      'update_failed': 'Ma suurto gelin karin cusboonaysiinta profile-ka',
      'login_failed': 'Ma suurto gelin karin galitaanka. Fadlan hubi xogtaaga.',
      'registration_successful': 'Diiwaangelinta waa la sameeyey!',
      'registration_failed':
          'Ma suurto gelin karin diiwaangelinta. Fadlan isku day mar kale.',
      'dont_have_account': 'Ma haysaa akoon?',
      'already_have_account': 'Horey u haysaa akoon?',
      'password_required': 'Lambarka sirta ah waa lagama maarmaanka ah',
      'password_too_short': 'Lambarka sirta ah waa inuu ka yaraadaa 6 xaraf',
      'confirm_password_required': 'Fadlan xaqiiji lambarkaaga sirta ah',
      'passwords_dont_match': 'Lambarrada sirta ah ma isu raacayaan',
      'login_to_explore': 'Gali si aad u baahdo meelaha dalxiiska',
      'create_account': 'Samee Akoon',
      'start_exploring': 'Bilow baahitaanka meelaha dalxiiska',
      'support': 'Caawimaad',
      'coming_soon': 'Dhawaan!',
      'support_coming_soon':
          'Astaamaha caawimaadka waa la horumarinayaa. La soco cusboonaysiinta!',
      'read_more': 'Akhri Wax Dheeraad ah',
    },
  };

  LanguageProvider() {
    _loadLanguage();
  }

  String get currentLanguage => _currentLanguage;

  Future<void> _loadLanguage() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs.getString(_languageKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (language != _currentLanguage) {
      _currentLanguage = language;
      await _prefs.setString(_languageKey, language);
      notifyListeners();
    }
  }

  String getText(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }
}
