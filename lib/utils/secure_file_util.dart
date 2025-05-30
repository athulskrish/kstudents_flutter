import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';  // Import for IOHttpClientAdapter
import 'logger.dart';

class SecureFileUtil {
  // Maximum file size (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;
  
  // Allowed file extensions
  static const List<String> allowedExtensions = ['pdf'];
  
  // Validate file
  static Future<bool> validateFile(File file) async {
    try {
      // Check file extension
      final extension = file.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        AppLogger.warning('Invalid file extension: $extension');
        return false;
      }
      
      // Check file size
      final size = await file.length();
      if (size > maxFileSize) {
        AppLogger.warning('File too large: ${size ~/ 1024} KB');
        return false;
      }
      
      return true;
    } catch (e) {
      AppLogger.error('File validation error', e);
      return false;
    }
  }
  
  // Generate secure filename
  static String generateSecureFilename(String originalFilename) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString();
    final extension = originalFilename.split('.').last.toLowerCase();
    return 'secure_${random}_$timestamp.$extension';
  }
  
  // Calculate file hash (for integrity verification)
  static Future<String> calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      AppLogger.error('Failed to calculate file hash', e);
      throw Exception('Failed to calculate file hash');
    }
  }
  
  // Securely download file
  static Future<File> secureDownload(String url, String filename) async {
    try {
      // Check if this is a local file path
      if (url.startsWith('/data/') || 
          url.startsWith('/storage/') || 
          url.startsWith('/var/') ||
          url.startsWith('/private/')) {
        // It's a local file, verify it exists and return it
        final file = File(url);
        if (await file.exists()) {
          // Validate the file
          if (!await validateFile(file)) {
            throw Exception('Local file validation failed');
          }
          return file;
        } else {
          throw Exception('Local file does not exist: $url');
        }
      }
      
      // Get secure local path
      final dir = await getApplicationDocumentsDirectory();
      final secureFilename = generateSecureFilename(filename);
      final filePath = '${dir.path}/$secureFilename';
      
      // Download file with Dio
      final dio = Dio();
      
      // Handle potential HTTP/HTTPS issues
      if (url.startsWith('http://')) {
        (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };
      }
      
      await dio.download(url, filePath);
      
      // Verify downloaded file
      final file = File(filePath);
      if (!await validateFile(file)) {
        await file.delete();
        throw Exception('Downloaded file validation failed');
      }
      
      return file;
    } catch (e) {
      AppLogger.error('Secure download failed', e);
      rethrow;
    }
  }
  
  // Securely save file
  static Future<File> secureSave(Uint8List data, String filename) async {
    try {
      // Get secure local path
      final dir = await getApplicationDocumentsDirectory();
      final secureFilename = generateSecureFilename(filename);
      final filePath = '${dir.path}/$secureFilename';
      
      // Write file
      final file = File(filePath);
      await file.writeAsBytes(data);
      
      // Verify file
      if (!await validateFile(file)) {
        await file.delete();
        throw Exception('Saved file validation failed');
      }
      
      return file;
    } catch (e) {
      AppLogger.error('Secure save failed', e);
      rethrow;
    }
  }
  
  // Securely delete file
  static Future<bool> secureDelete(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Overwrite with random data before deletion
        if (!kIsWeb) {
          final size = await file.length();
          final randomData = List<int>.generate(size, (_) => DateTime.now().millisecondsSinceEpoch % 256);
          await file.writeAsBytes(randomData);
        }
        
        // Delete file
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Secure delete failed', e);
      return false;
    }
  }
} 