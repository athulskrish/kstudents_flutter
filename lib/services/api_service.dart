import 'dart:convert';
import 'package:http/http.dart' as http;
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

class ApiService {
  // static const String baseUrl = 'http://localhost:8000/api'; // For local Django backend
  static const String baseUrl = 'https://keralify.com/api'; // For production

  // Generic GET method
  Future<List<T>> _getList<T>(String url, T Function(dynamic) fromJson) async {
    try {
      AppLogger.info('GET request: $url');
      final response = await http.get(Uri.parse(url));
      AppLogger.debug('Response [${response.statusCode}]: $url');
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => fromJson(json)).toList();
      } else {
        AppLogger.error('API error [${response.statusCode}]: $url', response.body);
        throw AppException('Failed to load data',
          details: 'Status code: \\${response.statusCode}',
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
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return fromJson(json.decode(response.body));
      } else {
        throw AppException('Failed to load item',
          details: 'Status code: \\${response.statusCode}',
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

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => QuestionPaper.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load question papers');
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

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notes');
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