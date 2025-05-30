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
import 'note_upload_screen.dart';
import '../utils/secure_file_util.dart';

class NotesScreen extends StatefulWidget {
  final bool showBottomBar;
  
  const NotesScreen({
    super.key,
    this.showBottomBar = true,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class SavedNote {
  final String filePath;
  final String title;
  final String subject;
  final String degreeName;
  final int semester;
  final int year;
  SavedNote({required this.filePath, required this.title, required this.subject, required this.degreeName, required this.semester, required this.year});

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'title': title,
    'subject': subject,
    'degreeName': degreeName,
    'semester': semester.toString(),
    'year': year.toString(),
  };
  static SavedNote fromJson(Map<String, dynamic> json) => SavedNote(
    filePath: json['filePath'],
    title: json['title'],
    subject: json['module'] ?? json['subject'], // Support both old and new format
    degreeName: json['degreeName'],
    semester: int.parse(json['semester']),
    year: int.parse(json['year']),
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
        subject: note.subject,
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
    // Navigate to upload screen instead of showing dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteUploadScreen(
          initialUniversity: _selectedUniversity,
          initialDegree: _selectedDegree,
          initialSemester: _selectedSemester,
          initialYear: _selectedYear,
        ),
      ),
    ).then((result) {
      // If we got a true result, refresh the notes list
      if (result == true) {
        _loadNotes();
      }
    });
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

Future<void> _deleteSavedNote(SavedNote note) async {
  // Show confirmation dialog
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Note'),
      content: Text('Are you sure you want to delete "${note.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  
  if (confirm != true) return;
  
  try {
    // Delete the file from storage
    final file = File(note.filePath);
    if (await file.exists()) {
      await SecureFileUtil.secureDelete(note.filePath);
    }
    
    // Remove from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_notes') ?? [];
    
    // Find and remove the item
    final queryString = Uri(queryParameters: {
      'filePath': note.filePath,
      'title': note.title,
      'subject': note.subject,
      'degreeName': note.degreeName,
      'semester': note.semester.toString(),
      'year': note.year.toString(),
    }).query;
    
    saved.remove(queryString);
    
    // Save the updated list
    await prefs.setStringList('saved_notes', saved);
    
    // Update the UI
    setState(() {
      _savedNotes.removeWhere((item) => item.filePath == note.filePath);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete note: $e')),
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

  Future<void> _loadNotesIfReady() async {
    // Only load notes when all required filters are selected
    if (_selectedUniversity != null && _selectedDegree != null && _selectedSemester != null && _selectedYear != null) {
      _loadNotes();
    }
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

  // Load user selections from shared preferences
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

    // If we have all selections, load the notes
    _loadNotesIfReady();
  }

  // Modified methods to save selections when they change
  void _onUniversityChanged(University? university) {
    setState(() {
      _selectedUniversity = university;
      _selectedDegree = null;
      _selectedSemester = null;
      _selectedYear = null;
      _notes = [];
    });
    _saveUserSelections();
    _loadDegrees();
  }

  void _onDegreeChanged(Degree? degree) {
    setState(() {
      _selectedDegree = degree;
      _selectedSemester = null;
      _selectedYear = null;
      _notes = [];
    });
    _saveUserSelections();
  }

  void _onSemesterChanged(int? semester) {
    setState(() {
      _selectedSemester = semester;
      _selectedYear = null;
      _notes = [];
    });
    _saveUserSelections();
  }

  void _onYearChanged(int? year) {
    setState(() {
      _selectedYear = year;
      _notes = [];
    });
    _saveUserSelections();
    _loadNotesIfReady();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Notes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug API',
              onPressed: () {
                Navigator.pushNamed(context, '/debug_notes');
              },
            ),
          ],
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
                              onChanged: _onUniversityChanged,
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
                              value: _selectedSemester,
                              decoration: const InputDecoration(
                                labelText: 'Semester',
                                border: OutlineInputBorder(),
                              ),
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
                              value: _selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(10, (index) => DateTime.now().year - index).map((year) {
                                return DropdownMenuItem(
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
                                    title: Text(note.title, style: TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Subject: ${note.subject}\n${note.degreeName} | Semester ${note.semester} | ${note.year}'),
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
                          title: Text(note.title, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Subject: ${note.subject}\n${note.degreeName} | Semester ${note.semester} | ${note.year}'),
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
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete',
                                onPressed: () => _deleteSavedNote(note),
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
        // Only show bottom navigation bar if showBottomBar is true
        bottomNavigationBar: widget.showBottomBar
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: 4, // Set to 4 for Notes
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
                  if (index != 4) { // If not Notes tab
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