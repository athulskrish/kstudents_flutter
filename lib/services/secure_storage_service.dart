import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import '../utils/logger.dart';

class SecureStorageService {
  static const String _tokenKey = 'secure_auth_token';
  static const String _refreshTokenKey = 'secure_refresh_token';
  static const String _userKey = 'secure_user_data';
  static const String _tokenExpiryKey = 'secure_token_expiry';
  
  // Create storage instance with AES encryption for Android
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Save authentication data securely with retry mechanism
  Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      // Use a try-catch for each operation to ensure they complete
      try {
        await _storage.write(key: _tokenKey, value: authResponse.accessToken);
      } catch (e) {
        AppLogger.warning('Failed to save access token, retrying... ${e.toString()}');
        await _storage.write(key: _tokenKey, value: authResponse.accessToken);
      }
      
      try {
        await _storage.write(key: _refreshTokenKey, value: authResponse.refreshToken);
      } catch (e) {
        AppLogger.warning('Failed to save refresh token, retrying... ${e.toString()}');
        await _storage.write(key: _refreshTokenKey, value: authResponse.refreshToken);
      }
      
      // Set token expiry (typically 1 hour from now for JWT)
      final expiry = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch.toString();
      try {
        await _storage.write(key: _tokenExpiryKey, value: expiry);
      } catch (e) {
        AppLogger.warning('Failed to save token expiry, retrying... ${e.toString()}');
        await _storage.write(key: _tokenExpiryKey, value: expiry);
      }
      
      if (authResponse.user != null) {
        final userData = json.encode(authResponse.user!.toJson());
        try {
          await _storage.write(key: _userKey, value: userData);
        } catch (e) {
          AppLogger.warning('Failed to save user data, retrying... ${e.toString()}');
          await _storage.write(key: _userKey, value: userData);
        }
      }
      
      // Double-check that the token was saved
      final savedToken = await getAccessToken();
      if (savedToken == null) {
        AppLogger.warning('Token was not saved properly despite attempts');
        throw Exception('Failed to save authentication data');
      }
      
      AppLogger.info('Auth data saved securely');
    } catch (e) {
      AppLogger.error('Failed to save auth data securely after retries: ${e.toString()}');
      rethrow;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      print("SecureStorage: Retrieved token: ${token?.isNotEmpty}");
      return token;
    } catch (e) {
      print("SecureStorage: Error getting access token: ${e.toString()}");
      AppLogger.error('Failed to get access token', e);
      return null;
    }
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      AppLogger.error('Failed to get refresh token', e);
      return null;
    }
  }

  // Get current user
  Future<UserProfile?> getCurrentUser() async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData != null) {
        return UserProfile.fromJson(json.decode(userData));
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get user data', e);
      return null;
    }
  }

  // Save access token
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      
      // Update token expiry
      final expiry = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch.toString();
      await _storage.write(key: _tokenExpiryKey, value: expiry);
      
      AppLogger.info('Access token updated securely');
    } catch (e) {
      AppLogger.error('Failed to save access token', e);
      rethrow;
    }
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return true;
      
      final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      AppLogger.error('Failed to check token expiry', e);
      return true; // Assume expired on error
    }
  }

  // Clear all secure storage (logout)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.info('Secure storage cleared');
    } catch (e) {
      AppLogger.error('Failed to clear secure storage', e);
      rethrow;
    }
  }

  // Check if user is authenticated with valid token
  Future<bool> isAuthenticated() async {
    try {
      print("SecureStorage: Checking if authenticated");
      final token = await getAccessToken();
      print("SecureStorage: Access token found: ${token != null}");
      
      if (token == null) {
        AppLogger.debug('Authentication check: No token found');
        return false;
      }
      
      // Check if token is expired
      final isExpired = await isTokenExpired();
      print("SecureStorage: Token expired check: $isExpired");
      AppLogger.debug('Authentication check: Token expired: $isExpired');
      return !isExpired;
    } catch (e) {
      print("SecureStorage: Error checking authentication: ${e.toString()}");
      AppLogger.error('Authentication check failed', e);
      return false;
    }
  }
} 