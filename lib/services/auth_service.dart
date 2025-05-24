import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../utils/logger.dart';

class AuthService {
  static const String baseUrl = 'https://keralify.com /api';
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Login
  Future<AuthResponse> login(String username, String password) async {
    AppLogger.info('Login attempt for $username');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );
    AppLogger.debug('Login response [${response.statusCode}] for $username');
    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      await _saveAuthData(authResponse);
      return authResponse;
    } else {
      final error = json.decode(response.body);
      AppLogger.error('Login failed for $username', error);
      throw Exception(error['detail'] ?? 'Failed to login');
    }
  }

  // Register
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
    int? district,
  }) async {
    if (password != confirmPassword) {
      AppLogger.warning('Password mismatch for $username');
      throw Exception('Passwords do not match');
    }
    AppLogger.info('Register attempt for $username');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'password2': confirmPassword,
        if (phone != null) 'phone': phone,
        if (district != null) 'district': district,
      }),
    );
    AppLogger.debug('Register response [${response.statusCode}] for $username');
    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      await _saveAuthData(authResponse);
      return authResponse;
    } else {
      final error = json.decode(response.body);
      AppLogger.error('Register failed for $username', error);
      throw Exception(error['detail'] ?? 'Failed to register');
    }
  }

  // Refresh Token
  Future<String> refreshToken(String refreshToken) async {
    AppLogger.info('Refreshing token');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh': refreshToken}),
    );
    AppLogger.debug('Refresh token response [${response.statusCode}]');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newAccessToken = data['access'];
      await _saveAccessToken(newAccessToken);
      return newAccessToken;
    } else {
      AppLogger.error('Token refresh failed', response.body);
      throw Exception('Failed to refresh token');
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(userKey);
  }

  // Get current user
  Future<UserProfile?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);
    if (userData != null) {
      return UserProfile.fromJson(json.decode(userData));
    }
    return null;
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Save authentication data
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, authResponse.accessToken);
    await prefs.setString(refreshTokenKey, authResponse.refreshToken);
    if (authResponse.user != null) {
      await prefs.setString(userKey, json.encode(authResponse.user!.toJson()));
    } else {
      await prefs.remove(userKey);
    }
  }

  // Save access token
  Future<void> _saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }
} 