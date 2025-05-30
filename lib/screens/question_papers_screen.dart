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

class QuestionPapersScreen extends StatefulWidget {
  final bool showBottomBar;
  
  const QuestionPapersScreen({
    super.key,
    this.showBottomBar = true,
  });

  @override
  State<QuestionPapersScreen> createState() => _QuestionPapersScreenState();
}

class SavedPDF {
  final String filePath;
  final String subject;
  final String degreeName;
  final int semester;
  final int year;
  SavedPDF({required this.filePath, required this.subject, required this.degreeName, required this.semester, required this.year});

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'subject': subject,
    'degreeName': degreeName,
    'semester': semester,
    'year': year,
  };
  static SavedPDF fromJson(Map<String, dynamic> json) => SavedPDF(
    filePath: json['filePath'],
    subject: json['subject'],
    degreeName: json['degreeName'],
    semester: json['semester'],
    year: json['year'],
  );
}

class _QuestionPapersScreenState extends State<QuestionPapersScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<University> _universities = [];
  List<Degree> _degrees = [];
  List<QuestionPaper> _questionPapers = [];
  University? _selectedUniversity;
  Degree? _selectedDegree;
  int? _selectedSemester;
  int? _selectedYear;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isUploading = false;
  List<SavedPDF> _savedPDFs = [];
  int _adCounter = 0;
  RewardedAd? _rewardedAd;
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _loadUniversities();
    _loadSavedPDFs();
    _loadAdCounter();
    _initRewardedAd();
    _loadUserSelections();
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
        _questionPapers = papers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load question papers');
    }
  }

  Future<void> _searchQuestionPapers(String query) async {
    if (query.isEmpty) {
      _loadQuestionPapers();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final papers = await _apiService.searchQuestionPapers(query);
      setState(() {
        _questionPapers = papers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to search question papers');
    }
  }

  Future<void> _loadSavedPDFs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_pdfs') ?? [];
    setState(() {
      _savedPDFs = saved.map((e) => SavedPDF.fromJson(Map<String, dynamic>.from(Uri.splitQueryString(e)))).toList();
    });
  }

  Future<void> _savePDFLocally(QuestionPaper paper) async {
    setState(() => _isUploading = true);
    try {
      // Download PDF
      final dir = await getApplicationDocumentsDirectory();
      final fileName = paper.filePath.split('/').last;
      final filePath = '${dir.path}/$fileName';
      final dio = Dio();
      await dio.download(paper.filePath, filePath);
      // Save metadata
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('saved_pdfs') ?? [];
      final pdf = SavedPDF(
        filePath: filePath,
        subject: paper.subject,
        degreeName: paper.degreeName,
        semester: paper.semester,
        year: paper.year,
      );
      saved.add(Uri(queryParameters: pdf.toJson()).query);
      await prefs.setStringList('saved_pdfs', saved);
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF saved locally!')));
      _loadSavedPDFs();
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
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

  void _viewSavedPDF(SavedPDF pdf) async {
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
          url: pdf.filePath,
          title: pdf.subject,
        ),
      ),
    );
  }

  void _shareQuestionPaper(QuestionPaper paper) {
    Share.share('Check out this question paper: ${paper.subject}\n${paper.filePath}');
  }

  void _shareSavedPDF(SavedPDF pdf) async {
    try {
      final file = XFile(pdf.filePath);
      await Share.shareXFiles([file], text: 'Check out this question paper: ${pdf.subject}');
    } catch (e) {
      // Fallback to sharing text if file sharing fails
      Share.share('Check out this question paper: ${pdf.subject}');
    }
  }

  Future<void> _loadUserSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final universityId = prefs.getInt('selected_university_id');
    final universityName = prefs.getString('selected_university_name');
    final degreeId = prefs.getInt('selected_degree_id');
    final degreeName = prefs.getString('selected_degree_name');
    final semester = prefs.getInt('selected_semester');
    final year = prefs.getInt('selected_year');

    if (universityId != null && universityName != null) {
      setState(() {
        _selectedUniversity = University(id: universityId, name: universityName);
      });
      // Load degrees based on the saved university
      await _loadDegrees();
    }

    if (degreeId != null && degreeName != null && _degrees.isNotEmpty) {
      // Try to find the degree in the loaded degrees
      Degree? foundDegree;
      try {
        foundDegree = _degrees.firstWhere((d) => d.id == degreeId);
      } catch (_) {
        // If not found and we have the university, create a placeholder
        if (universityId != null) {
          foundDegree = Degree(
            id: degreeId, 
            name: degreeName, 
            university: universityId,
            universityName: universityName ?? 'Unknown University'
          );
        }
      }
      
      if (foundDegree != null) {
        setState(() {
          _selectedDegree = foundDegree;
        });
      }
    }

    if (semester != null) {
      setState(() {
        _selectedSemester = semester;
      });
    }

    if (year != null) {
      setState(() {
        _selectedYear = year;
      });
    }

    // If we have all selections, load the question papers
    _loadQuestionPapersIfReady();
  }

  Future<void> _loadQuestionPapersIfReady() async {
    // Only load question papers when all required filters are selected
    if (_selectedUniversity != null && _selectedDegree != null && _selectedSemester != null && _selectedYear != null) {
      _loadQuestionPapers();
    }
  }

  // Modified methods to save selections when they change
  void _onUniversityChanged(University? university) {
    setState(() {
      _selectedUniversity = university;
      _selectedDegree = null;
      _selectedSemester = null;
      _selectedYear = null;
      _questionPapers = [];
    });
    _saveUserSelections();
    _loadDegrees();
  }

  void _onDegreeChanged(Degree? degree) {
    setState(() {
      _selectedDegree = degree;
      _selectedSemester = null;
      _selectedYear = null;
      _questionPapers = [];
    });
    _saveUserSelections();
  }

  void _onSemesterChanged(int? semester) {
    setState(() {
      _selectedSemester = semester;
      _selectedYear = null;
      _questionPapers = [];
    });
    _saveUserSelections();
  }

  void _onYearChanged(int? year) {
    setState(() {
      _selectedYear = year;
      _questionPapers = [];
    });
    _saveUserSelections();
    _loadQuestionPapersIfReady();
  }

  // Save user selections to shared preferences
  Future<void> _saveUserSelections() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedUniversity != null) {
      await prefs.setInt('selected_university_id', _selectedUniversity!.id);
      await prefs.setString('selected_university_name', _selectedUniversity!.name);
    }
    if (_selectedDegree != null) {
      await prefs.setInt('selected_degree_id', _selectedDegree!.id);
      await prefs.setString('selected_degree_name', _selectedDegree!.name);
    }
    if (_selectedSemester != null) {
      await prefs.setInt('selected_semester', _selectedSemester!);
    }
    if (_selectedYear != null) {
      await prefs.setInt('selected_year', _selectedYear!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Question Papers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Online'),
              Tab(text: 'Saved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Online Tab
            Column(
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
                      DropdownButtonFormField<University>(
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
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<Degree>(
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
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<int>(
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
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<int>(
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
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _questionPapers.isEmpty
                          ? const Center(child: Text('No question papers found'))
                          : ListView.builder(
                              itemCount: _questionPapers.length,
                              itemBuilder: (context, index) {
                                final paper = _questionPapers[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: ListTile(
                                    title: Text(paper.subject),
                                    subtitle: Text(
                                      '${paper.degreeName} | Semester ${paper.semester} | ${paper.year}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          tooltip: 'View in app',
                                          onPressed: () => _viewQuestionPaper(paper),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.download),
                                          tooltip: 'Save locally',
                                          onPressed: () => _savePDFLocally(paper),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.share),
                                          tooltip: 'Share',
                                          onPressed: () => _shareQuestionPaper(paper),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.open_in_browser),
                                          tooltip: 'Open in browser',
                                          onPressed: () => _openQuestionPaper(paper.filePath),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
            // Saved Tab
            _savedPDFs.isEmpty
                ? const Center(child: Text('No saved PDFs'))
                : ListView.builder(
                    itemCount: _savedPDFs.length,
                    itemBuilder: (context, index) {
                      final pdf = _savedPDFs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          title: Text(pdf.subject),
                          subtitle: Text(
                            '${pdf.degreeName} | Semester ${pdf.semester} | ${pdf.year}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                tooltip: 'View',
                                onPressed: () => _viewSavedPDF(pdf),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share),
                                tooltip: 'Share',
                                onPressed: () => _shareSavedPDF(pdf),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabIndex = DefaultTabController.of(context).index ?? 0;
            return tabIndex == 0
                ? FloatingActionButton.extended(
                    onPressed: _pickAndUploadPDF,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload PDF'),
                  )
                : const SizedBox.shrink();
          },
        ),
        bottomNavigationBar: widget.showBottomBar
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}