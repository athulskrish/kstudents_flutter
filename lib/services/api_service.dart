import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';  // Import for IOHttpClientAdapter
import '../models/university.dart';
import '../models/degree.dart';
import '../models/question_paper.dart';
import '../models/note.dart';
import '../models/exam.dart';
import '../models/entrance_notification.dart';
import '../models/news.dart';
import '../models/job.dart';
import '../models/initiative.dart';
import '../models/gallery.dart';
import '../models/event.dart';
import '../models/faq.dart';
import '../models/tech_pick.dart';
import '../utils/app_exception.dart';
import '../utils/logger.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // static const String baseUrl = 'http://localhost:8000/api'; // For local Django backend
  // static const String baseUrl = 'https://keralify.com/api'; // For production
  // String baseUrl = 'http://192.168.1.4:8000/api';
  String baseUrl = 'http://103.235.106.114:8000/api';
  final AuthService _authService = AuthService();
  final Dio _dio = Dio();
  
  // Certificate fingerprints for certificate pinning
  // These should be the SHA-256 fingerprints of your server's certificates
  static const List<String> _certificateFingerprints = [
    // Add your certificate fingerprints here
    // Example: '5E:1E:3F:82:44:F9:5E:3D:7D:D8:A4:6A:B8:0A:98:77:CB:5A:16:5A:FF:5E:A0:2D:54:9C:7A:B0:F5:CD:8C:2A'
  ];
  
  ApiService() {
    _configureDio();
  }
  
  void _configureDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptors for authentication
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add authentication token to all requests if available
        final token = await _authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Handle 401 errors (token expired)
        if (error.response?.statusCode == 401) {
          try {
            // Try to refresh the token
            await _authService.refreshToken();
            
            // Retry the request with the new token
            final token = await _authService.getAccessToken();
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              
              // Create a new request with the updated token
              final response = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              
              return handler.resolve(response);
            }
          } catch (e) {
            AppLogger.error('Token refresh failed during request retry', e);
          }
        }
        return handler.next(error);
      },
    ));
    
    // Add certificate pinning for release builds
    if (!kDebugMode) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            // Skip pinning in debug mode
            if (kDebugMode) return true;
            
            // If no fingerprints are defined, use default validation
            if (_certificateFingerprints.isEmpty) return false;
            
            // Check if the certificate matches any of our pinned fingerprints
            final fingerprint = _getFingerprint(cert);
            return _certificateFingerprints.contains(fingerprint);
          };
          return client;
        },
      );
    }
  }
  
  // Extract fingerprint from certificate
  String _getFingerprint(X509Certificate cert) {
    // This is a simplified implementation
    // In production, use a proper library to calculate SHA-256 fingerprint
    final bytes = cert.sha1;
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  // Add authorization header to requests
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Generic GET method
  Future<List<T>> _getList<T>(String url, T Function(dynamic) fromJson) async {
    try {
      final headers = await _getAuthHeaders();
      AppLogger.info('GET request: $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      AppLogger.debug('Response [${response.statusCode}]: $url');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await _authService.refreshToken();
          // Retry with new token
          return _getList(url, fromJson);
        } catch (e) {
          AppLogger.error('Token refresh failed', e);
          throw AppException('Authentication failed', 
            details: 'Please login again', 
            type: AppExceptionType.authentication);
        }
      } else {
        AppLogger.error('API error [${response.statusCode}]: $url', response.body);
        throw AppException('Failed to load data',
          details: 'Status code: [31m${response.statusCode}[0m\nBody: ${response.body}',
          type: AppExceptionType.server);
      }
    } on http.ClientException catch (e, st) {
      AppLogger.error('Network error: $url', e, st);
      throw AppException('Network error', details: e.message, type: AppExceptionType.network);
    } catch (e, st) {
      AppLogger.error('Unknown error: $url', e, st);
      throw AppException('Unknown error', details: e.toString(), type: AppExceptionType.unknown);
    }
  }

  Future<T> _getItem<T>(String url, T Function(dynamic) fromJson) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return fromJson(json.decode(response.body));
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await _authService.refreshToken();
          // Retry with new token
          return _getItem(url, fromJson);
        } catch (e) {
          throw AppException('Authentication failed', 
            details: 'Please login again', 
            type: AppExceptionType.authentication);
        }
      } else {
        throw AppException('Failed to load item',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } on http.ClientException catch (e) {
      throw AppException('Network error', details: e.message, type: AppExceptionType.network);
    } catch (e) {
      throw AppException('Unknown error', details: e.toString(), type: AppExceptionType.unknown);
    }
  }

  // Universities
  Future<List<University>> getUniversities() async {
    return _getList('$baseUrl/universities/', (json) => University.fromJson(json));
  }

  // Degrees
  Future<List<Degree>> getDegrees({int? universityId}) async {
    String url = '$baseUrl/degrees/';
    if (universityId != null) {
      url += '?university=$universityId';
    }
    return _getList(url, (json) => Degree.fromJson(json));
  }

  // Question Papers
  Future<List<QuestionPaper>> getQuestionPapers({
    int? degreeId,
    int? semester,
    int? year,
    int? universityId,
  }) async {
    String url = '$baseUrl/question-papers/';
    List<String> params = [];
    
    if (degreeId != null) params.add('degree=$degreeId');
    if (semester != null) params.add('semester=$semester');
    if (year != null) params.add('year=$year');
    if (universityId != null) params.add('university_id=$universityId');
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    return _getList(url, (json) => QuestionPaper.fromJson(json));
  }

  // Secure file upload for question papers
  Future<bool> uploadQuestionPaper({
    required File file,
    required String subject,
    required int degreeId,
    required int semester,
    required int year,
    required int universityId,
  }) async {
    try {
      // Validate file type
      final fileExtension = file.path.split('.').last.toLowerCase();
      if (fileExtension != 'pdf') {
        throw AppException('Invalid file type', 
          details: 'Only PDF files are allowed', 
          type: AppExceptionType.validation);
      }
      
      // Validate file size (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw AppException('File too large', 
          details: 'Maximum file size is 10MB', 
          type: AppExceptionType.validation);
      }
      
      // Get authentication token
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw AppException('Authentication required', 
          details: 'Please login to upload files', 
          type: AppExceptionType.authentication);
      }
      
      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'subject': subject,
        'degree': degreeId,
        'semester': semester,
        'year': year,
        'university_id': universityId,
      });
      
      // Upload file
      final response = await _dio.post(
        '$baseUrl/question-papers/upload/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      AppLogger.error('File upload error', e);
      if (e.response?.statusCode == 401) {
        throw AppException('Authentication failed', 
          details: 'Please login again', 
          type: AppExceptionType.authentication);
      } else {
        throw AppException('Upload failed', 
          details: e.message ?? 'Unknown error', 
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('File upload error', e);
      throw AppException('Upload failed', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }

  // Notes
  Future<List<Note>> getNotes({
    int? degreeId,
    int? semester,
    int? year,
    int? universityId,
  }) async {
    String url = '$baseUrl/notes/';
    List<String> params = [];
    
    if (degreeId != null) params.add('degree=$degreeId');
    if (semester != null) params.add('semester=$semester');
    if (year != null) params.add('year=$year');
    if (universityId != null) params.add('university=$universityId');
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    return _getList(url, (json) => Note.fromJson(json));
  }

  // Exams
  Future<List<Exam>> getExams({
    int? degreeId,
    String? semester,
    int? admissionYear,
    int? universityId,
  }) async {
    String url = '$baseUrl/exams/';
    List<String> params = [];
    
    if (degreeId != null) params.add('degree_name=$degreeId');
    if (semester != null) params.add('semester=$semester');
    if (admissionYear != null) params.add('admission_year=$admissionYear');
    if (universityId != null) params.add('university=$universityId');
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Exam.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load exams');
    }
  }

  // Entrance Notifications
  Future<List<EntranceNotification>> getEntranceNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/entrance-notifications/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => EntranceNotification.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load entrance notifications');
    }
  }

  // News
  Future<List<News>> getNews() async {
    final response = await http.get(Uri.parse('$baseUrl/news/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => News.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<News> getNewsDetail(String slug) async {
    final response = await http.get(Uri.parse('$baseUrl/news/$slug/'));
    if (response.statusCode == 200) {
      return News.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load news detail');
    }
  }

  // Jobs
  Future<List<Job>> getJobs() async {
    final response = await http.get(Uri.parse('$baseUrl/jobs/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load jobs');
    }
  }

  // Added getJobDetail method
  Future<Job> getJobDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/jobs/$id/'));
    if (response.statusCode == 200) {
      return Job.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load job detail');
    }
  }

  // Initiatives
  Future<List<Initiative>> getInitiatives() async {
    final response = await http.get(Uri.parse('$baseUrl/initiatives/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Initiative.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load initiatives');
    }
  }

  // Gallery
  Future<List<Gallery>> getGallery() async {
    final response = await http.get(Uri.parse('$baseUrl/gallery/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Gallery.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load gallery');
    }
  }

  // Search functions
  Future<List<QuestionPaper>> searchQuestionPapers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/question-papers/?search=$query'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => QuestionPaper.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search question papers');
    }
  }

  Future<List<Note>> searchNotes(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notes/?search=$query'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search notes');
    }
  }

  Future<List<Exam>> searchExams(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/exams/?search=$query'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Exam.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search exams');
    }
  }

  Future<List<EntranceNotification>> searchEntranceNotifications(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/entrance-notifications/?search=$query'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => EntranceNotification.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search entrance notifications');
    }
  }

  Future<List<News>> searchNews(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/news/?search=$query'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => News.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search news');
    }
  }

  Future<List<Job>> searchJobs(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/?search=$query'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search jobs');
    }
  }

  Future<List<Initiative>> searchInitiatives(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/initiatives/?search=$query'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Initiative.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search initiatives');
    }
  }

  // Events
  Future<List<Event>> getEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/events/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  Future<Event> getEventDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/events/$id/'));
    if (response.statusCode == 200) {
      return Event.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load event detail');
    }
  }

  Future<List<Event>> searchEvents(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/events/?search=$query'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search events');
    }
  }

  // FAQs
  Future<List<FAQ>> getFaqs() async {
    final response = await http.get(Uri.parse('$baseUrl/faqs/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FAQ.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load FAQs');
    }
  }

  Future<List<FAQ>> searchFaqs(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/faqs/?search=$query'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => FAQ.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search FAQs');
    }
  }

  Future<void> sendMessageUs({required String name, required String email, required String subject, required String message}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contact/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message');
    }
  }

  // Tech Picks (Affiliate Products)
  Future<List<TechPick>> getTechPicks() async {
    final response = await http.get(Uri.parse('$baseUrl/affiliate-products/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => TechPick.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tech picks');
    }
  }

  Future<List<String>> getTechPickCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/affiliate-categories/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map<String>((json) => json['name'] as String).toList();
    } else {
      throw Exception('Failed to load tech pick categories');
    }
  }
} 