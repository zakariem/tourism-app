// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:tourism_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      final user = await _dbHelper.getUserById(userId);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _dbHelper.getUserByUsername(username);

      if (user != null && user['password'] == password) {
        _currentUser = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user['id']);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
      String username, String password, String email, String fullName) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if username already exists
      final existingUser = await _dbHelper.getUserByUsername(username);
      if (existingUser != null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create new user
      final userId = await _dbHelper.insertUser({
        'username': username,
        'password': password,
        'email': email,
        'full_name': fullName,
      });

      if (userId > 0) {
        final user = await _dbHelper.getUserById(userId);
        if (user != null) {
          _currentUser = user;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }

  Future<bool> updateProfile(String email, String fullName) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _dbHelper.updateUser(
        _currentUser!['id'],
        {
          'email': email,
          'full_name': fullName,
        },
      );

      if (success) {
        _currentUser = await _dbHelper.getUserById(_currentUser!['id']);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
