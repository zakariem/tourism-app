// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;

  static const String _baseUrl = 'http://10.0.2.2:9000/api/auth';

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('Attempting login for: $usernameOrEmail');
      print('Backend URL: $_baseUrl/login');

      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': usernameOrEmail,
          'username': usernameOrEmail,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed response data: $responseData');

        // Check if token exists in response
        if (responseData['token'] == null) {
          print('ERROR: No token found in response');
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _currentUser = responseData;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(responseData));
        await prefs.setString('token', responseData['token']);
        print('Login successful, user data stored');
        print('Current user: $_currentUser');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('Login failed with status: ${response.statusCode}');
        print('Error response: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      print('Error type: ${e.runtimeType}');
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
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': 'tourist', // or 'admin' if needed
        }),
      );

      if (response.statusCode == 201) {
        _currentUser = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile(String email, String fullName) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 200) {
        final updatedUser = jsonDecode(response.body);
        _currentUser = updatedUser;
        await prefs.setString('user', jsonEncode(updatedUser));
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkAuthStatus() async {
    try {
      print('Checking auth status...');
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      final token = prefs.getString('token');

      print('Stored user: $userString');
      print('Stored token: ${token != null ? 'exists' : 'null'}');

      if (userString != null && token != null) {
        print('User and token found, verifying with backend...');
        // Verify token with backend
        final response = await http.get(
          Uri.parse('$_baseUrl/verify'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('Verify response status: ${response.statusCode}');
        print('Verify response body: ${response.body}');

        if (response.statusCode == 200) {
          _currentUser = jsonDecode(userString);
          print('Token verified, user authenticated');
          notifyListeners();
          return true;
        } else {
          print('Token verification failed, clearing stored data');
          // Token invalid, clear stored data
          await logout();
          return false;
        }
      } else {
        print('No stored user or token found');
      }
      return false;
    } catch (e) {
      print('Auth check error: $e');
      return false;
    }
  }
}
