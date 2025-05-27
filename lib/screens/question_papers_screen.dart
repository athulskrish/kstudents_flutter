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

class QuestionPapersScreen extends StatefulWidget {
  const QuestionPapersScreen({super.key});

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
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await _uploadPDF(file,
        subject: _searchController.text.isNotEmpty ? _searchController.text : 'Unknown',
        degree: _selectedDegree?.id,
        semester: _selectedSemester,
        year: _selectedYear,
        universityId: _selectedUniversity?.id,
      );
    }
  }

  Future<void> _uploadPDF(File file, {String? subject, int? degree, int? semester, int? year, int? universityId}) async {
    setState(() => _isUploading = true);
    try {
      final dio = Dio();
      const apiUrl = 'https://keralify.com/api/question-papers/upload/';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        if (subject != null) 'subject': subject,
        if (degree != null) 'degree': degree,
        if (semester != null) 'semester': semester,
        if (year != null) 'year': year,
        if (universityId != null) 'university_id': universityId,
      });
      final response = await dio.post(apiUrl, data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF uploaded successfully!')));
        _loadQuestionPapers();
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${response.statusMessage}')));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
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
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<University>(
                              value: _selectedUniversity,
                              decoration: const InputDecoration(
                                labelText: 'University',
                                border: OutlineInputBorder(),
                              ),
                              items: _universities.map((university) {
                                return DropdownMenuItem(
                                  value: university,
                                  child: Text(university.name),
                                );
                              }).toList(),
                              onChanged: (university) {
                                setState(() {
                                  _selectedUniversity = university;
                                  _selectedDegree = null;
                                  _degrees = [];
                                });
                                _loadDegrees();
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: DropdownButtonFormField<Degree>(
                              value: _selectedDegree,
                              decoration: const InputDecoration(
                                labelText: 'Degree',
                                border: OutlineInputBorder(),
                              ),
                              items: _degrees.map((degree) {
                                return DropdownMenuItem(
                                  value: degree,
                                  child: Text(degree.name),
                                );
                              }).toList(),
                              onChanged: (degree) {
                                setState(() => _selectedDegree = degree);
                                _loadQuestionPapers();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedSemester,
                              decoration: const InputDecoration(
                                labelText: 'Semester',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(8, (index) {
                                return DropdownMenuItem(
                                  value: index + 1,
                                  child: Text('Semester ${index + 1}'),
                                );
                              }),
                              onChanged: (semester) {
                                setState(() => _selectedSemester = semester);
                                _loadQuestionPapers();
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(10, (index) {
                                final year = DateTime.now().year - index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (year) {
                                setState(() => _selectedYear = year);
                                _loadQuestionPapers();
                              },
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}