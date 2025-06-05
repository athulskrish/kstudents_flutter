import 'package:flutter/material.dart';
import '../models/university.dart';
import '../models/degree.dart';
import '../models/note.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pdf_viewer_screen.dart';
import 'note_upload_screen.dart';
import 'dart:convert'; // Import for json encoding/decoding

class SavedNote {
  final Note note;
  SavedNote(this.note);
  Map<String, dynamic> toJson() => note.toJson();
  static SavedNote fromJson(Map<String, dynamic> json) => SavedNote(Note.fromJson(json));
}

class NotesScreen extends StatefulWidget {
  final bool showBottomBar;
  final bool showSavedOnly;
  final bool showUploadFab;
  
  const NotesScreen({
    super.key,
    this.showBottomBar = true,
    this.showSavedOnly = false,
    this.showUploadFab = true,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ApiService _apiService = ApiService();
  List<University> _universities = [];
  List<Degree> _degrees = [];
  List<Note> _allNotes = []; // Renamed from _notes
  List<SavedNote> _savedNotes = []; // List for saved notes
  University? _selectedUniversity;
  Degree? _selectedDegree;
  int? _selectedSemester;
  int? _selectedYear;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showSavedNotes = false; // State variable to toggle view

  @override
  void initState() {
    super.initState();
    _loadUniversities();
    _loadUserSelections();
    _loadSavedNotes(); // Load saved notes on init
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
        _allNotes = notes; // Update _allNotes
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load notes');
    }
  }

  Future<void> _searchNotes(String query) async {
    if (query.isEmpty) {
      _loadNotes(); // Search applies to all notes
      return;
    }
    setState(() => _isLoading = true);
    try {
      final notes = await _apiService.searchNotes(query);
      setState(() {
        _allNotes = notes; // Search results update _allNotes
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to search notes');
    }
  }

  Future<void> _pickAndUploadPDF() async {
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

  void _shareNote(Note note) {
    Share.share('Check out this note: ${note.title}\n${note.file}');
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

  Future<void> _loadNotesIfReady() async {
    if (_selectedUniversity != null && _selectedDegree != null && _selectedSemester != null && _selectedYear != null) {
      if (!_showSavedNotes) { // Only load all notes if not in saved view
      _loadNotes();
      }
    }
  }

  Future<void> _saveUserSelections() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedUniversity != null) {
      await prefs.setInt('selected_university_id', _selectedUniversity!.id);
      await prefs.setString('selected_university_name', _selectedUniversity!.name);
    } else {
       await prefs.remove('selected_university_id');
       await prefs.remove('selected_university_name');
    }
    if (_selectedDegree != null) {
      await prefs.setInt('selected_degree_id', _selectedDegree!.id);
      await prefs.setString('selected_degree_name', _selectedDegree!.name);
    } else {
      await prefs.remove('selected_degree_id');
      await prefs.remove('selected_degree_name');
    }
    if (_selectedSemester != null) {
      await prefs.setInt('selected_semester', _selectedSemester!);
    } else {
      await prefs.remove('selected_semester');
    }
    if (_selectedYear != null) {
      await prefs.setInt('selected_year', _selectedYear!);
    } else {
      await prefs.remove('selected_year');
    }
  }

  Future<void> _loadUserSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final universityId = prefs.getInt('selected_university_id');
    final degreeId = prefs.getInt('selected_degree_id');
    final semester = prefs.getInt('selected_semester');
    final year = prefs.getInt('selected_year');

    // Load universities first
    await _loadUniversities();

    // Find and set saved university after universities are loaded
    University? initialUniversity;
    if (universityId != null && _universities.isNotEmpty) {
      try {
        initialUniversity = _universities.firstWhere((university) => university.id == universityId);
      } catch (e) {
        print('Saved university with ID $universityId not found.');
      }
    }

    // Set the initial university and load degrees based on it
      setState(() {
      _selectedUniversity = initialUniversity;
      });

    // Load degrees if a university was loaded and found
    if (initialUniversity != null) { // Use initialUniversity to check if degrees should be loaded
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
      
    // Set the initial degree and other selections
      setState(() {
      _selectedDegree = savedDegree;
        _selectedSemester = semester;
        _selectedYear = year;
      });

    _loadNotesIfReady();
  }

  void _onUniversityChanged(University? university) {
    setState(() {
      _selectedUniversity = university;
      _selectedDegree = null;
      _selectedSemester = null;
      _selectedYear = null;
      _allNotes = []; // Clear all notes on filter change
      _degrees = []; // Clear degrees when university changes
    });
    _saveUserSelections();
    if (university != null) {
    _loadDegrees();
    }
  }

  void _onDegreeChanged(Degree? degree) {
    setState(() {
      _selectedDegree = degree;
      _selectedSemester = null;
      _selectedYear = null;
      _allNotes = []; // Clear all notes on filter change
    });
    _saveUserSelections();
  }

  void _onSemesterChanged(int? semester) {
    setState(() {
      _selectedSemester = semester;
      _selectedYear = null;
      _allNotes = []; // Clear all notes on filter change
    });
    _saveUserSelections();
  }

  void _onYearChanged(int? year) {
    setState(() {
      _selectedYear = year;
      _allNotes = []; // Clear all notes on filter change
    });
    _saveUserSelections();
    _loadNotesIfReady();
  }

  Future<void> _loadSavedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_notes') ?? [];
    print('[_loadSavedNotes] Raw saved notes from SharedPreferences: $saved'); // Debug print
    setState(() {
      _savedNotes = saved.map((e) => SavedNote.fromJson(json.decode(e))).toList();
      print('[_loadSavedNotes] Decoded saved notes list: ${_savedNotes.map((sn) => 'id: ${sn.note.id}, title: ${sn.note.title}').toList()}'); // Debug print
    });
  }

  Future<void> _saveNote(Note note) async {
    print('[_saveNote] Attempting to save note with id: ${note.id}, title: ${note.title}'); // Debug print
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_notes') ?? [];
    print('[_saveNote] Current saved notes before adding: $saved'); // Debug print
    if (!saved.any((e) => Note.fromJson(json.decode(e)).id == note.id)) {
      saved.add(json.encode(note.toJson()));
      await prefs.setStringList('saved_notes', saved);
      print('[_saveNote] Saved notes after adding: $saved'); // Debug print
      _loadSavedNotes(); // Refresh saved list
      // Optionally show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved!')));
    }
  }

  Future<void> _removeSavedNote(Note note) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_notes') ?? [];
    saved.removeWhere((e) => Note.fromJson(json.decode(e)).id == note.id);
    await prefs.setStringList('saved_notes', saved);
    _loadSavedNotes(); // Refresh saved list
    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note removed from saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.showSavedOnly)
            // Display saved notes list when showSavedOnly is true
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _savedNotes.isEmpty
                      ? const Center(child: Text('No saved notes yet.'))
                      : ListView.builder(
                          itemCount: _savedNotes.length,
                          itemBuilder: (context, index) {
                            final note = _savedNotes[index].note; // Get Note from SavedNote
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: ListTile(
                                onTap: () => _viewNoteInApp(note), // View PDF
                                title: Text(note.title, style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Subject: ${note.subject}\n${note.degreeName} | Semester ${note.semester} | ${note.year}'),
                                isThreeLine: true,
                                trailing: Container(
                                  width: 120, // Adjusted width for saved view icons
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.bookmark), // Always show filled bookmark for saved
                                        tooltip: 'Remove from saved',
                                        onPressed: () => _removeSavedNote(note), // Remove functionality
                                      ),
            IconButton(
                                        icon: const Icon(Icons.share), // Share icon
                                        tooltip: 'Share',
                                        onPressed: () => _shareNote(note), // Share functionality
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
            // Display all notes list with filters and search when showSavedOnly is false
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
                        : _allNotes.isEmpty
                          ? const Center(child: Text('No notes found'))
                          : ListView.builder(
                                itemCount: _allNotes.length,
                              itemBuilder: (context, index) {
                                  final note = _allNotes[index];
                                  final isSaved = _savedNotes.any((sn) => sn.note.id == note.id); // Check if note is saved
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: ListTile(
                                      onTap: () => _viewNoteInApp(note),
                                    title: Text(note.title, style: TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Subject: ${note.subject}\n${note.degreeName} | Semester ${note.semester} | ${note.year}'),
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
                                              tooltip: isSaved ? 'Remove from saved' : 'Save note', // Toggle tooltip
                                              onPressed: () => isSaved ? _removeSavedNote(note) : _saveNote(note), // Toggle save/remove functionality
                                        ),
                                        IconButton(
                                              icon: const Icon(Icons.share), // Share icon
                                          tooltip: 'Share',
                                              onPressed: () => _shareNote(note), // Share functionality
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 