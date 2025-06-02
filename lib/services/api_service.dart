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
import '../models/ad_slider.dart';
import '../utils/app_exception.dart';
import '../utils/logger.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // static const String baseUrl = 'http://localhost:8000/api'; // For local Django backend
  // static const String baseUrl = 'https://keralify.com/api'; // For production
  // String baseUrl = 'http://192.168.1.4:8000/api';
  String baseUrl = 'http://103.235.106.114:8000/api'; // Using HTTP instead of HTTPS
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
    
    // Disable certificate validation for development
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true; // Accept all certificates
      };
      return client;
    };
    
    // Only use certificate pinning in production with proper SSL setup
    /*
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
    */
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
    try {
      AppLogger.info('Fetching universities without auth requirement');
      final response = await http.get(Uri.parse('$baseUrl/universities/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => University.fromJson(json)).toList();
      } else {
        AppLogger.error('Failed to load universities [${response.statusCode}]', response.body);
        throw AppException('Failed to load universities',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching universities', e);
      throw AppException('Failed to load universities', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }

  // Degrees
  Future<List<Degree>> getDegrees({int? universityId}) async {
    try {
      String url = '$baseUrl/degrees/';
      if (universityId != null) {
        url += '?university=$universityId';
      }
      
      AppLogger.info('Fetching degrees without auth requirement: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Degree.fromJson(json)).toList();
      } else {
        AppLogger.error('Failed to load degrees [${response.statusCode}]', response.body);
        throw AppException('Failed to load degrees',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching degrees', e);
      throw AppException('Failed to load degrees', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }

  // Question Papers
  Future<List<QuestionPaper>> getQuestionPapers({
    int? degreeId,
    int? semester,
    int? year,
    int? universityId,
  }) async {
    try {
      String url = '$baseUrl/question-papers/';
      List<String> params = [];
      
      if (degreeId != null) params.add('degree=$degreeId');
      if (semester != null) params.add('semester=$semester');
      if (year != null) params.add('year=$year');
      if (universityId != null) params.add('university_id=$universityId');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.info('Fetching question papers without auth requirement: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => QuestionPaper.fromJson(json)).toList();
      } else {
        AppLogger.error('Failed to load question papers [${response.statusCode}]', response.body);
        throw AppException('Failed to load question papers',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching question papers', e);
      throw AppException('Failed to load question papers', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
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
    try {
      String url = '$baseUrl/notes/';
      List<String> params = [];
      
      if (degreeId != null) params.add('degree=$degreeId');
      if (semester != null) params.add('semester=$semester');
      if (year != null) params.add('year=$year');
      if (universityId != null) params.add('university=$universityId');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.info('Fetching notes without auth requirement: $url');
      print('DEBUG: Calling getNotes with URL: $url');
      
      final response = await http.get(Uri.parse(url));
      print('DEBUG: getNotes response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('DEBUG: getNotes response body: ${response.body}');
        List<dynamic> data = json.decode(response.body);
        print('DEBUG: getNotes parsed JSON data: $data');
        
        final notes = data.map((json) {
          print('DEBUG: Parsing note JSON: $json');
          try {
            final note = Note.fromJson(json);
            print('DEBUG: Successfully parsed note: id=${note.id}, title=${note.title}, subject=${note.subject}');
            return note;
          } catch (e) {
            print('DEBUG: Error parsing note: $e');
            rethrow;
          }
        }).toList();
        
        print('DEBUG: getNotes returning ${notes.length} notes');
        return notes;
      } else {
        AppLogger.error('Failed to load notes [${response.statusCode}]', response.body);
        print('DEBUG: getNotes error response: ${response.body}');
        throw AppException('Failed to load notes',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching notes', e);
      print('DEBUG: getNotes exception: $e');
      throw AppException('Failed to load notes', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
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

    try {
      print('DEBUG: Fetching exams from $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('DEBUG: Exams data received: ${data.length} items');
        
        // Print the first item to debug
        if (data.isNotEmpty) {
          print('DEBUG: First exam item: ${data[0]}');
        }
        
        List<Exam> exams = [];
        for (var i = 0; i < data.length; i++) {
          try {
            exams.add(Exam.fromJson(data[i]));
          } catch (e) {
            print('DEBUG: Error parsing exam at index $i: $e');
            print('DEBUG: Problematic data: ${data[i]}');
          }
        }
        return exams;
      } else {
        print('DEBUG: API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load exams: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Exception in getExams: $e');
      throw Exception('Failed to load exams: $e');
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
    try {
      print('DEBUG: Making GET request to $baseUrl/events/');
      final response = await http.get(Uri.parse('$baseUrl/events/'));
      print('DEBUG: Events API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('DEBUG: Events API response body: ${response.body}');
        List<dynamic> data = json.decode(response.body);
        print('DEBUG: Parsed JSON data count: ${data.length}');
        
        final events = data.map((json) {
          print('DEBUG: Processing event JSON: $json');
          try {
            final event = Event.fromJson(json);
            print('DEBUG: Successfully parsed event: id=${event.id}, title=${event.title}, categoryId=${event.categoryId}, districtId=${event.districtId}');
            return event;
          } catch (e) {
            print('DEBUG: Error parsing event: $e');
            rethrow;
          }
        }).toList();
        
        print('DEBUG: Returning ${events.length} events');
        return events;
      } else {
        AppLogger.error('Failed to load events [${response.statusCode}]', response.body);
        print('DEBUG: Events API error response: ${response.body}');
        throw AppException('Failed to load events',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching events', e);
      print('DEBUG: Exception in getEvents: $e');
      throw AppException('Failed to load events', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }

  Future<List<Map<String, dynamic>>> getEventCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/event-categories/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        AppLogger.error('Failed to load event categories [${response.statusCode}]', response.body);
        throw AppException('Failed to load event categories',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching event categories', e);
      throw AppException('Failed to load event categories', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }

  Future<List<Map<String, dynamic>>> getDistricts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/districts/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        AppLogger.error('Failed to load districts [${response.statusCode}]', response.body);
        throw AppException('Failed to load districts',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching districts', e);
      throw AppException('Failed to load districts', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }

  Future<Event> getEventDetail(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/$id/'));
      if (response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      } else {
        AppLogger.error('Failed to load event detail [${response.statusCode}]', response.body);
        throw AppException('Failed to load event detail',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching event detail', e);
      throw AppException('Failed to load event detail', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
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
    try {
      print('DEBUG: Making GET request to $baseUrl/faqs/');
      final response = await http.get(Uri.parse('$baseUrl/faqs/'));
      print('DEBUG: FAQs API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('DEBUG: FAQs API response body: ${response.body}');
        List<dynamic> data = json.decode(response.body);
        print('DEBUG: Parsed JSON data count: ${data.length}');
        
        final faqs = data.map((json) {
          print('DEBUG: Processing FAQ JSON: $json');
          try {
            final faq = FAQ.fromJson(json);
            print('DEBUG: Successfully parsed FAQ: id=${faq.id}, question=${faq.question}');
            return faq;
          } catch (e) {
            print('DEBUG: Error parsing FAQ: $e');
            rethrow;
          }
        }).toList();
        
        print('DEBUG: Returning ${faqs.length} FAQs');
        return faqs;
      } else {
        AppLogger.error('Failed to load FAQs [${response.statusCode}]', response.body);
        print('DEBUG: FAQs API error response: ${response.body}');
        throw AppException('Failed to load FAQs',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching FAQs', e);
      print('DEBUG: Exception in getFaqs: $e');
      throw AppException('Failed to load FAQs', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }

  Future<List<FAQ>> searchFaqs(String query) async {
    try {
      print('DEBUG: Making GET request to $baseUrl/faqs/?search=$query');
      final response = await http.get(Uri.parse('$baseUrl/faqs/?search=$query'));
      print('DEBUG: FAQs search API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('DEBUG: FAQs search API response body: ${response.body}');
        List<dynamic> data = json.decode(response.body);
        print('DEBUG: Parsed JSON data count: ${data.length}');
        
        final faqs = data.map((json) {
          try {
            return FAQ.fromJson(json);
          } catch (e) {
            print('DEBUG: Error parsing FAQ during search: $e');
            rethrow;
          }
        }).toList();
        
        print('DEBUG: Returning ${faqs.length} FAQs from search');
        return faqs;
      } else {
        AppLogger.error('Failed to search FAQs [${response.statusCode}]', response.body);
        print('DEBUG: FAQs search API error response: ${response.body}');
        throw AppException('Failed to search FAQs',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error searching FAQs', e);
      print('DEBUG: Exception in searchFaqs: $e');
      throw AppException('Failed to search FAQs', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }

  Future<void> sendMessageUs({required String name, required String email, required String subject, required String message}) async {
    try {
      print('DEBUG: Sending message to $baseUrl/contact/');
      print('DEBUG: Data: name=$name, email=$email, subject=$subject');
      
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
      
      print('DEBUG: Message API response status: ${response.statusCode}');
      print('DEBUG: Message API response body: ${response.body}');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AppException('Failed to send message', 
          details: 'Status code: ${response.statusCode}, Response: ${response.body}',
          type: AppExceptionType.server);
      }
    } catch (e, st) {
      AppLogger.error('Error sending message', e, st);
      throw AppException('Failed to send message', 
        details: e.toString(),
        type: e is AppException ? (e as AppException).type : AppExceptionType.unknown);
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
  
  // Ad Sliders
  Future<List<AdSlider>> getAdSliders() async {
    try {
      AppLogger.info('Fetching ad sliders without auth requirement');
      final response = await http.get(Uri.parse('$baseUrl/ad-sliders/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => AdSlider.fromJson(json)).toList();
      } else {
        AppLogger.error('Failed to load ad sliders [${response.statusCode}]', response.body);
        throw AppException('Failed to load ad sliders',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching ad sliders', e);
      throw AppException('Failed to load ad sliders', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }
  
  // Featured Jobs for Home Page
  Future<List<Job>> getFeaturedJobs() async {
    try {
      AppLogger.info('Fetching featured jobs for home page');
      final response = await http.get(Uri.parse('$baseUrl/featured-jobs/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Job.fromJson(json)).toList();
      } else {
        AppLogger.error('Failed to load featured jobs [${response.statusCode}]', response.body);
        throw AppException('Failed to load featured jobs',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching featured jobs', e);
      throw AppException('Failed to load featured jobs', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }
  
  // Featured Events for Home Page
  Future<List<Event>> getFeaturedEvents() async {
    try {
      AppLogger.info('Fetching featured events for home page');
      final response = await http.get(Uri.parse('$baseUrl/featured-events/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        AppLogger.error('Failed to load featured events [${response.statusCode}]', response.body);
        throw AppException('Failed to load featured events',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching featured events', e);
      throw AppException('Failed to load featured events', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }
  
  // Featured News for Home Page
  Future<List<News>> getFeaturedNews() async {
    try {
      AppLogger.info('Fetching featured news for home page');
      final response = await http.get(Uri.parse('$baseUrl/featured-news/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => News.fromJson(json)).toList();
      } else {
        AppLogger.error('Failed to load featured news [${response.statusCode}]', response.body);
        throw AppException('Failed to load featured news',
          details: 'Status code: ${response.statusCode}',
          type: AppExceptionType.server);
      }
    } catch (e) {
      AppLogger.error('Error fetching featured news', e);
      throw AppException('Failed to load featured news', 
        details: e.toString(), 
        type: AppExceptionType.unknown);
    }
  }
} 