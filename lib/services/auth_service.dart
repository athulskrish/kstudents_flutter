import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../utils/logger.dart';
import 'secure_storage_service.dart';
import '../utils/constants.dart';

class AuthService {
  // static const String baseUrl = 'https://keralify.com/api';
  // static const String baseUrl = 'http://192.168.1.4:8000/api';
  static const String baseUrl = AppConstants.kBaseUrl;
  final SecureStorageService _secureStorage = SecureStorageService();

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
      
      // Explicitly await all storage operations to ensure they complete
      await _secureStorage.saveAuthData(authResponse);
      
      // Double-check that authentication data was stored properly
      final isAuth = await _secureStorage.isAuthenticated();
      AppLogger.debug('After login, isAuthenticated: $isAuth');
      
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
    
    // Password strength validation
    if (!_isPasswordStrong(password)) {
      AppLogger.warning('Weak password for $username');
      throw Exception('Password must be at least 8 characters long and include uppercase, lowercase, numbers, and special characters');
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
      await _secureStorage.saveAuthData(authResponse);
      return authResponse;
    } else {
      final error = json.decode(response.body);
      AppLogger.error('Register failed for $username', error);
      throw Exception(error['detail'] ?? 'Failed to register');
    }
  }

  // Password strength validation
  bool _isPasswordStrong(String password) {
    // At least 8 characters
    if (password.length < 8) return false;
    
    // Check for uppercase, lowercase, numbers, and special characters
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUppercase && hasLowercase && hasNumber && hasSpecial;
  }

  // Refresh Token
  Future<String> refreshToken() async {
    AppLogger.info('Refreshing token');
    final refreshToken = await _secureStorage.getRefreshToken();
    
    if (refreshToken == null) {
      AppLogger.error('No refresh token available');
      throw Exception('No refresh token available');
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh': refreshToken}),
    );
    AppLogger.debug('Refresh token response [${response.statusCode}]');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newAccessToken = data['access'];
      await _secureStorage.saveAccessToken(newAccessToken);
      return newAccessToken;
    } else {
      AppLogger.error('Token refresh failed', response.body);
      throw Exception('Failed to refresh token');
    }
  }

  // Logout
  Future<void> logout() async {
    await _secureStorage.clearAll();
  }

  // Get current user
  Future<UserProfile?> getCurrentUser() async {
    return _secureStorage.getCurrentUser();
  }

  // Get access token with auto-refresh if expired
  Future<String?> getAccessToken() async {
    // Check if token is expired
    if (await _secureStorage.isTokenExpired()) {
      try {
        // Try to refresh the token
        await refreshToken();
      } catch (e) {
        // If refresh fails, return null (user needs to login again)
        return null;
      }
    }
    
    // Return the (possibly refreshed) token
    return _secureStorage.getAccessToken();
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      print("Checking authentication status...");
      final isAuth = await _secureStorage.isAuthenticated();
      print("Authentication check result: $isAuth");
      return isAuth;
    } catch (e) {
      print("Error checking authentication: ${e.toString()}");
      return false;
    }
  }
} 