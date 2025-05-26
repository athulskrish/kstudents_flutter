import 'package:flutter/material.dart';
import '../models/university.dart';
import '../models/degree.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pdf_viewer_screen.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class SavedNote {
  final String filePath;
  final String title;
  final String module;
  final String degreeName;
  final int semester;
  final int year;
  SavedNote({required this.filePath, required this.title, required this.module, required this.degreeName, required this.semester, required this.year});

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'title': title,
    'module': module,
    'degreeName': degreeName,
    'semester': semester,
    'year': year,
  };
  static SavedNote fromJson(Map<String, dynamic> json) => SavedNote(
    filePath: json['filePath'],
    title: json['title'],
    module: json['module'],
    degreeName: json['degreeName'],
    semester: json['semester'],
    year: json['year'],
  );
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<University> _universities = [];
  List<Degree> _degrees = [];
  List<Note> _notes = [];
  University? _selectedUniversity;
  Degree? _selectedDegree;
  int? _selectedSemester;
  int? _selectedYear;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isUploading = false;
  List<SavedNote> _savedNotes = [];
  int _adCounter = 0;
  RewardedAd? _rewardedAd;
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _loadUniversities();
    _loadSavedNotes();
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

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await _apiService.getNotes(
        degreeId: _selectedDegree?.id,
        semester: _selectedSemester,
        year: _selectedYear,
        universityId: _selectedUniversity?.id,
      );
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load notes');
    }
  }

  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      _loadNotes();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final notes = await _apiService.searchNotes(query);
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to search notes');
    }
  }

  Future<void> _loadSavedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_notes') ?? [];
    setState(() {
      _savedNotes = saved.map((e) => SavedNote.fromJson(Map<String, dynamic>.from(Uri.splitQueryString(e)))).toList();
    });
  }

  Future<void> _saveNoteLocally(Note note) async {
    setState(() => _isUploading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = note.file.split('/').last;
      final filePath = '${dir.path}/$fileName';
      final dio = Dio();
      await dio.download(note.file, filePath);
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('saved_notes') ?? [];
      final savedNote = SavedNote(
        filePath: filePath,
        title: note.title,
        module: note.module,
        degreeName: note.degreeName,
        semester: note.semester,
        year: note.year,
      );
      saved.add(Uri(queryParameters: savedNote.toJson()).query);
      await prefs.setStringList('saved_notes', saved);
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved locally!')));
      _loadSavedNotes();
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _pickAndUploadPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      await _uploadPDF(file,
        title: _searchController.text.isNotEmpty ? _searchController.text : 'Untitled',
        module: '',
        degree: _selectedDegree?.id,
        semester: _selectedSemester,
        year: _selectedYear,
        university: _selectedUniversity?.id,
      );
    }
  }

  Future<void> _uploadPDF(File file, {String? title, String? module, int? degree, int? semester, int? year, int? university}) async {
    setState(() => _isUploading = true);
    try {
      final dio = Dio();
      const apiUrl = 'https://keralify.com/api/notes/upload/';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        if (title != null) 'title': title,
        if (module != null) 'module': module,
        if (degree != null) 'degree': degree,
        if (semester != null) 'semester': semester,
        if (year != null) 'year': year,
        if (university != null) 'university': university,
      });
      final response = await dio.post(apiUrl, data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note uploaded successfully!')));
        _loadNotes();
      } else {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${response.statusMessage}')));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  void _viewNoteInApp(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          url: note.file,
          title: note.title,
        ),
      ),
    );
  }

  void _viewSavedNote(SavedNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          url: note.filePath,
          title: note.title,
        ),
      ),
    );
  }

  void _shareNote(Note note) {
    Share.share('Check out this note: ${note.title}\n${note.file}');
  }

void _shareSavedNote(SavedNote note) async {
  try {
    // Create XFile from the local file path
    final xFile = XFile(note.filePath);
    
    // Use shareXFiles with XFile object
    await Share.shareXFiles(
      [xFile], 
      text: 'Check out this note: ${note.title}',
      subject: note.title, // Optional: add subject for email sharing
    );
  } catch (e) {
    // Handle any sharing errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to share note: $e')),
    );
  }
}
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openNote(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Could not open the file');
    }
  }

  Future<void> _loadAdCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adCounter = prefs.getInt('note_ad_counter') ?? 0;
    });
  }

  Future<void> _saveAdCounter(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('note_ad_counter', value);
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

  void _viewNoteOnline(Note note) async {
    int newCounter = _adCounter + 1;
    if (newCounter % 5 == 0) {
      _showRewardedAd();
      newCounter = 0;
    }
    await _saveAdCounter(newCounter);
    setState(() => _adCounter = newCounter);
    await _saveNoteLocally(note);
    _viewNoteInApp(note);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Notes'),
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
                          hintText: 'Search notes...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onChanged: _searchNotes,
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
                                _loadNotes();
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
                                _loadNotes();
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
                                _loadNotes();
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
                      : _notes.isEmpty
                          ? const Center(child: Text('No notes found'))
                          : ListView.builder(
                              itemCount: _notes.length,
                              itemBuilder: (context, index) {
                                final note = _notes[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: ListTile(
                                    title: Text(note.title),
                                    subtitle: Text(
                                      '${note.module}\n${note.degreeName} | Semester ${note.semester} | ${note.year}',
                                    ),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          tooltip: 'View in app',
                                          onPressed: () => _viewNoteOnline(note),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.download),
                                          tooltip: 'Save locally',
                                          onPressed: () => _saveNoteLocally(note),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.share),
                                          tooltip: 'Share',
                                          onPressed: () => _shareNote(note),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.open_in_browser),
                                          tooltip: 'Open in browser',
                                          onPressed: () => _openNote(note.file),
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
            _savedNotes.isEmpty
                ? const Center(child: Text('No saved notes'))
                : ListView.builder(
                    itemCount: _savedNotes.length,
                    itemBuilder: (context, index) {
                      final note = _savedNotes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: ListTile(
                          title: Text(note.title),
                          subtitle: Text(
                            '${note.module}\n${note.degreeName} | Semester ${note.semester} | ${note.year}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                tooltip: 'View',
                                onPressed: () => _viewSavedNote(note),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share),
                                tooltip: 'Share',
                                onPressed: () => _shareSavedNote(note),
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
            final tabIndex = DefaultTabController.of(context)?.index ?? 0;
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