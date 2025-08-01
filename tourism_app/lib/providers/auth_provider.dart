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

  // Use localhost for web, 10.0.2.2 for Android emulator
  static const String _baseUrl = 'http://localhost:9000/api/auth';

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('Attempting login for: $usernameOrEmail');
      print('Backend URL: $_baseUrl/login');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': usernameOrEmail,
              'username': usernameOrEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Login response status: ${response.statusCode}');
      // print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // print('Parsed response data: $responseData');

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
        // print('Error response: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      print('Error type: ${e.runtimeType}');

      // Provide more specific error messages
      String errorMessage = 'Login failed';
      if (e.toString().contains('SocketException')) {
        errorMessage =
            'Cannot connect to server. Please check if the backend is running.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again.';
      }

      print('Error message: $errorMessage');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String? _registrationError;
  String? get registrationError => _registrationError;

  Future<bool> register(
      String username, String password, String email) async {
    _isLoading = true;
    _registrationError = null;
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
        final responseData = jsonDecode(response.body);
        _currentUser = responseData;
        
        // Store user data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(responseData));
        await prefs.setString('token', responseData['token']);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Handle specific error messages
        if (response.statusCode == 400) {
          final errorData = jsonDecode(response.body);
          _registrationError = errorData['message'] ?? 'Registration failed';
        } else {
          _registrationError = 'Registration failed';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _registrationError = 'Network error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    
    // Clear stored user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    
    notifyListeners();
  }

  Future<bool> updateProfile(String email, String username) async {
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
          'username': username,
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

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await prefs.setString('token', responseData['token']);
        print('Token refreshed successfully');
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }

  // Proactively refresh token if it's about to expire
  Future<void> checkAndRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && _currentUser != null) {
        // Check if token is still valid
        final response = await http.get(
          Uri.parse('$_baseUrl/verify'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 3));
        
        // If token is invalid or about to expire, refresh it
        if (response.statusCode == 401) {
          print('Token expired, refreshing...');
          await refreshToken();
        }
      }
    } catch (e) {
      print('Token check failed: $e');
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
        ).timeout(const Duration(seconds: 5));

        print('Verify response status: ${response.statusCode}');
        // print('Verify response body: ${response.body}');

        if (response.statusCode == 200) {
          _currentUser = jsonDecode(userString);
          print('Token verified, user authenticated');
          notifyListeners();
          return true;
        } else if (response.statusCode == 401) {
          // Try to refresh token before giving up
          print('Token expired, attempting refresh...');
          if (await refreshToken()) {
            _currentUser = jsonDecode(userString);
            print('Token refreshed, user authenticated');
            notifyListeners();
            return true;
          }
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
      // If backend is not available, still allow local auth
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        print('Backend unavailable, using local auth');
        _currentUser = jsonDecode(userString);
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      print('Backend not available: $e');
      return false;
    }
  }
}
