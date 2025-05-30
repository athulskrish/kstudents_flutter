import 'package:flutter/material.dart';
import '../models/university.dart';
import '../models/degree.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';  // Import for IOHttpClientAdapter

class QuestionPaperUploadScreen extends StatefulWidget {
  final University? initialUniversity;
  final Degree? initialDegree;
  final int? initialSemester;
  final int? initialYear;

  const QuestionPaperUploadScreen({
    super.key, 
    this.initialUniversity,
    this.initialDegree,
    this.initialSemester,
    this.initialYear,
  });

  @override
  State<QuestionPaperUploadScreen> createState() => _QuestionPaperUploadScreenState();
}

class _QuestionPaperUploadScreenState extends State<QuestionPaperUploadScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _subjectController = TextEditingController();
  
  List<University> _universities = [];
  List<Degree> _degrees = [];
  University? _selectedUniversity;
  Degree? _selectedDegree;
  int? _selectedSemester;
  int? _selectedYear;
  bool _isLoading = false;
  bool _isUploading = false;
  File? _selectedFile;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    // Initialize with values passed from the question papers screen
    _selectedUniversity = widget.initialUniversity;
    _selectedDegree = widget.initialDegree;
    _selectedSemester = widget.initialSemester;
    _selectedYear = widget.initialYear;
    
    _loadUniversities();
    if (_selectedUniversity != null) {
      _loadDegrees();
    }
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadPDF() async {
    // Validate all required fields
    if (_selectedUniversity == null) {
      _showError('Please select a university');
      return;
    }
    if (_selectedDegree == null) {
      _showError('Please select a degree');
      return;
    }
    if (_selectedSemester == null) {
      _showError('Please select a semester');
      return;
    }
    if (_selectedYear == null) {
      _showError('Please select a year');
      return;
    }
    if (_selectedFile == null) {
      _showError('Please select a PDF file');
      return;
    }
    if (_subjectController.text.isEmpty) {
      _showError('Please enter a subject name');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final dio = Dio();
      
      // Disable SSL validation for the upload request
      (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          return true; // Accept all certificates
        };
        return client;
      };
      
      const apiUrl = 'http://103.235.106.114:8000/api/question-papers/upload/';
      
      // Create a FormData instance with all required fields
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _selectedFile!.path, 
          filename: _selectedFile!.path.split('/').last
        ),
        'subject': _subjectController.text,
        'degree': _selectedDegree!.id.toString(),
        'semester': _selectedSemester.toString(),
        'year': _selectedYear.toString(),
        'university_id': _selectedUniversity!.id.toString(),
        'created_by': '1', // Using admin user ID as default
      });
      
      // Add headers to specify content type
      final response = await dio.post(
        apiUrl, 
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF uploaded successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate successful upload
      } else {
        setState(() => _isUploading = false);
        _showError('Upload failed: ${response.statusMessage}');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('Upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Question Paper'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  onChanged: (university) {
                    setState(() {
                      _selectedUniversity = university;
                      _selectedDegree = null;
                    });
                    _loadDegrees();
                  },
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
                  onChanged: (degree) {
                    setState(() {
                      _selectedDegree = degree;
                    });
                  },
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
                  onChanged: (semester) {
                    setState(() {
                      _selectedSemester = semester;
                    });
                  },
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
                  onChanged: (year) {
                    setState(() {
                      _selectedYear = year;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24.0),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected File:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          _selectedFileName ?? 'No file selected',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: _pickPDF,
                  icon: const Icon(Icons.file_present),
                  label: const Text('Select PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadPDF,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading...'),
                          ],
                        )
                      : const Text('Upload Question Paper'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }
} 