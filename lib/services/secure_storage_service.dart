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

  // Save authentication data securely
  Future<void> saveAuthData(AuthResponse authResponse) async {
    try {
      await _storage.write(key: _tokenKey, value: authResponse.accessToken);
      await _storage.write(key: _refreshTokenKey, value: authResponse.refreshToken);
      
      // Set token expiry (typically 1 hour from now for JWT)
      final expiry = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch.toString();
      await _storage.write(key: _tokenExpiryKey, value: expiry);
      
      if (authResponse.user != null) {
        await _storage.write(
          key: _userKey, 
          value: json.encode(authResponse.user!.toJson())
        );
      }
      AppLogger.info('Auth data saved securely');
    } catch (e) {
      AppLogger.error('Failed to save auth data securely', e);
      rethrow;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
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
      final token = await getAccessToken();
      if (token == null) return false;
      
      // Check if token is expired
      return !(await isTokenExpired());
    } catch (e) {
      AppLogger.error('Authentication check failed', e);
      return false;
    }
  }
} 