import 'package:flutter/material.dart';
import '../models/university.dart';
import '../models/degree.dart';
import '../models/question_paper.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'question_paper_upload_screen.dart';
import '../utils/secure_file_util.dart';
import 'dart:convert'; // Import for json encoding/decoding

class SavedQuestionPaper {
  final QuestionPaper paper;
  SavedQuestionPaper(this.paper);
  Map<String, dynamic> toJson() => paper.toJson();
  static SavedQuestionPaper fromJson(Map<String, dynamic> json) => SavedQuestionPaper(QuestionPaper.fromJson(json));
}

class QuestionPapersScreen extends StatefulWidget {
  final bool showBottomBar;
  final bool showSavedOnly;
  final bool showUploadFab;
  
  const QuestionPapersScreen({
    super.key,
    this.showBottomBar = true,
    this.showSavedOnly = false,
    this.showUploadFab = true,
  });

  @override
  State<QuestionPapersScreen> createState() => _QuestionPapersScreenState();
}

class _QuestionPapersScreenState extends State<QuestionPapersScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<University> _universities = [];
  List<Degree> _degrees = [];
  List<QuestionPaper> _allQuestionPapers = []; // Renamed from _questionPapers
  List<SavedQuestionPaper> _savedQuestionPapers = []; // List for saved question papers
  University? _selectedUniversity;
  Degree? _selectedDegree;
  int? _selectedSemester;
  int? _selectedYear;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isUploading = false;
  int _adCounter = 0;
  RewardedAd? _rewardedAd;
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  bool _showSavedQuestionPapers = false; // State variable to toggle view

  @override
  void initState() {
    super.initState();
    _loadUniversities();
    _loadAdCounter();
    _initRewardedAd();
    _loadUserSelections();
    _loadSavedQuestionPapers(); // Load saved question papers on init
  }

  Future<void> _loadUniversities() async {
    setState(() => _isLoading = true);
    try {
      final universities = await _apiService.getUniversities();
      setState(() {
        _universities = universities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load universities');
    }
  }

  Future<void> _loadDegrees() async {
    if (_selectedUniversity == null) return;
    setState(() => _isLoading = true);
    try {
      final degrees = await _apiService.getDegrees(universityId: _selectedUniversity!.id);
      setState(() {
        _degrees = degrees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load degrees');
    }
  }

  Future<void> _loadQuestionPapers() async {
    setState(() => _isLoading = true);
    try {
      final papers = await _apiService.getQuestionPapers(
        degreeId: _selectedDegree?.id,
        semester: _selectedSemester,
        year: _selectedYear,
        universityId: _selectedUniversity?.id,
      );
      setState(() {
        _allQuestionPapers = papers; // Update _allQuestionPapers
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load question papers');
    }
  }

  Future<void> _searchQuestionPapers(String query) async {
    if (query.isEmpty) {
      _loadQuestionPapers(); // Search applies to all question papers
      return;
    }
    setState(() => _isLoading = true);
    try {
      final papers = await _apiService.searchQuestionPapers(query);
      setState(() {
        _allQuestionPapers = papers; // Search results update _allQuestionPapers
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to search question papers');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadAdCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adCounter = prefs.getInt('question_ad_counter') ?? 0;
    });
  }

  Future<void> _saveAdCounter(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('question_ad_counter', value);
  }

  void _initRewardedAd() {
    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _initRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _initRewardedAd();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {});
      _rewardedAd = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad not ready.')));
      _initRewardedAd();
    }
  }

  void _viewQuestionPaper(QuestionPaper paper) async {
    int newCounter = _adCounter + 1;
    if (newCounter % 5 == 0) {
      _showRewardedAd();
      newCounter = 0;
    }
    await _saveAdCounter(newCounter);
    setState(() => _adCounter = newCounter);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          url: paper.filePath,
          title: paper.subject,
        ),
      ),
    );
  }

  Future<void> _openQuestionPaper(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Could not open the file');
    }
  }

  Future<void> _pickAndUploadPDF() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionPaperUploadScreen(
          initialUniversity: _selectedUniversity,
          initialDegree: _selectedDegree,
          initialSemester: _selectedSemester,
          initialYear: _selectedYear,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadQuestionPapers();
      }
    });
  }

  Future<void> _loadUserSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final universityId = prefs.getInt('selected_university_id');
    final degreeId = prefs.getInt('selected_degree_id');
    final semester = prefs.getInt('selected_semester');
    final year = prefs.getInt('selected_year');

    // Load universities first
    await _loadUniversities();

    // Find and set saved university and degree after lists are loaded
    University? savedUniversity;
    if (universityId != null && _universities.isNotEmpty) {
      try {
        savedUniversity = _universities.firstWhere((university) => university.id == universityId);
      } catch (e) {
        print('Saved university with ID $universityId not found.');
      }
    }

    // Load degrees if a university was loaded and found
    if (_selectedUniversity != null) {
      await _loadDegrees();
    }

    // Find and set saved degree after degrees are loaded
    Degree? savedDegree;
    if (degreeId != null && _degrees.isNotEmpty) {
      try {
        savedDegree = _degrees.firstWhere((degree) => degree.id == degreeId);
      } catch (e) {
        print('Saved degree with ID $degreeId not found.');
        }
      }
      
    // Update state with found selections
      setState(() {
       _selectedUniversity = savedUniversity;
       _selectedDegree = savedDegree;
      });

    // Set the remaining selections
      setState(() {
       _selectedSemester = semester;
        _selectedYear = year;
      });

    // If we have all selections, load the question papers
    _loadQuestionPapersIfReady();
  }

  Future<void> _loadQuestionPapersIfReady() async {
    // Only load question papers when all required filters are selected
    if (_selectedUniversity != null && _selectedDegree != null && _selectedSemester != null && _selectedYear != null) {
      if (!_showSavedQuestionPapers) { // Only load all question papers if not in saved view
      _loadQuestionPapers();
      }
    }
  }

  // Modified methods to save selections when they change
  void _onUniversityChanged(University? university) {
    setState(() {
      _selectedUniversity = university;
      _selectedDegree = null;
      _selectedSemester = null;
      _selectedYear = null;
      _allQuestionPapers = []; // Clear all question papers on filter change
    });
    _saveUserSelections();
    _loadDegrees();
  }

  void _onDegreeChanged(Degree? degree) {
    setState(() {
      _selectedDegree = degree;
      _selectedSemester = null;
      _selectedYear = null;
      _allQuestionPapers = []; // Clear all question papers on filter change
    });
    _saveUserSelections();
  }

  void _onSemesterChanged(int? semester) {
    setState(() {
      _selectedSemester = semester;
      _selectedYear = null;
      _allQuestionPapers = []; // Clear all question papers on filter change
    });
    _saveUserSelections();
  }

  void _onYearChanged(int? year) {
    setState(() {
      _selectedYear = year;
      _allQuestionPapers = []; // Clear all question papers on filter change
    });
    _saveUserSelections();
    _loadQuestionPapersIfReady();
  }

  // Save user selections to shared preferences
  Future<void> _saveUserSelections() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedUniversity != null) {
      await prefs.setInt('selected_university_id', _selectedUniversity!.id);
    }
    if (_selectedDegree != null) {
      await prefs.setInt('selected_degree_id', _selectedDegree!.id);
    }
    if (_selectedSemester != null) {
      await prefs.setInt('selected_semester', _selectedSemester!);
    }
    if (_selectedYear != null) {
      await prefs.setInt('selected_year', _selectedYear!);
    }
  }

  void _shareQuestionPaper(QuestionPaper paper) {
    Share.share('Check out this question paper: ${paper.subject}\n${paper.filePath}');
  }

  Future<void> _loadSavedQuestionPapers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_question_papers') ?? [];
    setState(() {
      _savedQuestionPapers = saved.map((e) => SavedQuestionPaper.fromJson(json.decode(e))).toList();
    });
  }

  Future<void> _saveQuestionPaper(QuestionPaper paper) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_question_papers') ?? [];
    if (!saved.any((e) => QuestionPaper.fromJson(json.decode(e)).id == paper.id)) {
      saved.add(json.encode(paper.toJson()));
      await prefs.setStringList('saved_question_papers', saved);
      _loadSavedQuestionPapers(); // Refresh saved list
      // Optionally show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question paper saved!')));
    }
  }

  Future<void> _removeSavedQuestionPaper(QuestionPaper paper) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_question_papers') ?? [];
    saved.removeWhere((e) => QuestionPaper.fromJson(json.decode(e)).id == paper.id);
    await prefs.setStringList('saved_question_papers', saved);
    _loadSavedQuestionPapers(); // Refresh saved list
    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question paper removed from saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.showSavedOnly)
            // Display saved question papers list when showSavedOnly is true
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _savedQuestionPapers.isEmpty
                      ? const Center(child: Text('No saved question papers yet.'))
                      : ListView.builder(
                          itemCount: _savedQuestionPapers.length,
                          itemBuilder: (context, index) {
                            final paper = _savedQuestionPapers[index].paper; // Get QuestionPaper from SavedQuestionPaper
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: ListTile(
                                onTap: () => _viewQuestionPaper(paper), // View PDF
                                title: Text(paper.subject, style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${paper.degreeName} | Semester ${paper.semester} | ${paper.year}'),
                                isThreeLine: true,
                                trailing: Container(
                                  width: 120, // Adjusted width for saved view icons
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.bookmark), // Always show filled bookmark for saved
                                        tooltip: 'Remove from saved',
                                        onPressed: () => _removeSavedQuestionPaper(paper), // Remove functionality
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share), // Share icon
                                        tooltip: 'Share',
                                        onPressed: () => _shareQuestionPaper(paper), // Share functionality
                                      ),
            ],
          ),
        ),
                              ),
                            );
                          },
                        ),
            )
          else
            // Display all question papers list with filters and search when showSavedOnly is false
            Expanded(
              child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search question papers...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onChanged: _searchQuestionPapers,
                      ),
                      const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<University>(
                        decoration: const InputDecoration(
                          labelText: 'University',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedUniversity,
                        items: _universities.map((university) {
                          return DropdownMenuItem<University>(
                            value: university,
                            child: Text(university.name),
                          );
                        }).toList(),
                        onChanged: _onUniversityChanged,
                      ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: DropdownButtonFormField<Degree>(
                        decoration: const InputDecoration(
                          labelText: 'Degree',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedDegree,
                        items: _degrees.map((degree) {
                          return DropdownMenuItem<Degree>(
                            value: degree,
                            child: Text(degree.name),
                          );
                        }).toList(),
                        onChanged: _onDegreeChanged,
                              ),
                            ),
                          ],
                      ),
                      const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSemester,
                        items: [1, 2, 3, 4, 5, 6, 7, 8].map((semester) {
                          return DropdownMenuItem<int>(
                            value: semester,
                            child: Text('Semester $semester'),
                          );
                        }).toList(),
                        onChanged: _onSemesterChanged,
                      ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedYear,
                        items: List.generate(10, (index) => DateTime.now().year - index).map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: _onYearChanged,
                              ),
                            ),
                          ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                        : _allQuestionPapers.isEmpty
                          ? const Center(child: Text('No question papers found'))
                          : ListView.builder(
                                itemCount: _allQuestionPapers.length,
                              itemBuilder: (context, index) {
                                  final paper = _allQuestionPapers[index];
                                  final isSaved = _savedQuestionPapers.any((sqp) => sqp.paper.id == paper.id); // Check if paper is saved
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: ListTile(
                                      onTap: () => _viewQuestionPaper(paper), // View PDF
                                      title: Text(paper.subject, style: TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${paper.degreeName} | Semester ${paper.semester} | ${paper.year}'),
                                      isThreeLine: true,
                                      trailing: Container(
                                        width: 120, // Adjusted width for icons
                                        child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                            Icon(Icons.picture_as_pdf), // PDF icon
                                            const SizedBox(width: 8), // Space between icons
                                        IconButton(
                                              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border), // Toggle save icon
                                              tooltip: isSaved ? 'Remove from saved' : 'Save question paper', // Toggle tooltip
                                              onPressed: () => isSaved ? _removeSavedQuestionPaper(paper) : _saveQuestionPaper(paper), // Toggle save/remove functionality
                                        ),
                                        IconButton(
                                              icon: const Icon(Icons.share), // Share icon
                                          tooltip: 'Share',
                                              onPressed: () => _shareQuestionPaper(paper), // Share functionality
                                        ),
                                      ],
                                        ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
                              ),
                            ],
                          ),
      floatingActionButton: widget.showUploadFab ? FloatingActionButton.extended( // Conditionally show FAB
                    onPressed: _pickAndUploadPDF,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload PDF'),
      ) : null, // Hide FAB when showUploadFab is false
      bottomNavigationBar: widget.showBottomBar // Keep bottom nav if applicable
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: 1, // Set to 1 for Questions
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.description),
                    label: 'Questions',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.event),
                    label: 'Events',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.work),
                    label: 'Jobs',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.note),
                    label: 'Notes',
                  ),
                ],
                onTap: (index) {
                  if (index != 1) { // If not Questions tab
                    Navigator.pop(context);
                    // Let parent handle navigation
                  }
                },
              )
            : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}