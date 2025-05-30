import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'models/note.dart';

class DebugNoteApiScreen extends StatefulWidget {
  const DebugNoteApiScreen({Key? key}) : super(key: key);

  @override
  State<DebugNoteApiScreen> createState() => _DebugNoteApiScreenState();
}

class _DebugNoteApiScreenState extends State<DebugNoteApiScreen> {
  String _response = 'No data yet';
  String _parsedNotes = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Notes API'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fetchNotes,
                    child: const Text('Fetch Notes'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _fetchAndParseNotes,
                    child: const Text('Fetch & Parse'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _createTestNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Test Note'),
            ),
            const SizedBox(height: 16),
            const Text('API Response:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _response,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            if (_parsedNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Parsed Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _parsedNotes,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
      _response = 'Loading...';
      _parsedNotes = '';
    });

    try {
      // Replace with your actual API URL
      String url = 'http://103.235.106.114:8000/api/notes/';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Pretty print the JSON response
        final jsonResponse = json.decode(response.body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonResponse);
        
        setState(() {
          _response = 'Status code: ${response.statusCode}\n\n$prettyJson';
        });
      } else {
        setState(() {
          _response = 'Status code: ${response.statusCode}\n\nError: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAndParseNotes() async {
    setState(() {
      _isLoading = true;
      _response = 'Loading...';
      _parsedNotes = '';
    });

    try {
      // Replace with your actual API URL
      String url = 'http://103.235.106.114:8000/api/notes/';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Pretty print the JSON response
        final jsonResponse = json.decode(response.body);
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonResponse);
        
        // Parse the response into Note objects
        List<dynamic> notesJson = jsonResponse;
        StringBuffer parsedNotesBuffer = StringBuffer();
        
        for (var noteJson in notesJson) {
          try {
            Note note = Note.fromJson(noteJson);
            parsedNotesBuffer.writeln('ID: ${note.id}');
            parsedNotesBuffer.writeln('Title: ${note.title}');
            parsedNotesBuffer.writeln('Subject: ${note.subject}');
            parsedNotesBuffer.writeln('Degree: ${note.degreeName} (${note.degree})');
            parsedNotesBuffer.writeln('Semester: ${note.semester}');
            parsedNotesBuffer.writeln('Year: ${note.year}');
            parsedNotesBuffer.writeln('University: ${note.universityName} (${note.university})');
            parsedNotesBuffer.writeln('File: ${note.file}');
            parsedNotesBuffer.writeln('---');
          } catch (e) {
            parsedNotesBuffer.writeln('Error parsing note: $e');
            parsedNotesBuffer.writeln('JSON: ${json.encode(noteJson)}');
            parsedNotesBuffer.writeln('---');
          }
        }
        
        setState(() {
          _response = 'Status code: ${response.statusCode}\n\n$prettyJson';
          _parsedNotes = parsedNotesBuffer.toString();
        });
      } else {
        setState(() {
          _response = 'Status code: ${response.statusCode}\n\nError: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestNote() async {
    setState(() {
      _isLoading = true;
      _response = 'Creating test note...';
      _parsedNotes = '';
    });

    try {
      // Replace with your actual API URL
      String url = 'http://103.235.106.114:8000/api/notes/upload/';
      
      // Create a test note with hardcoded values
      // You'll need to update these with valid IDs from your database
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['title'] = 'Test Note ${DateTime.now().millisecondsSinceEpoch}'
        ..fields['subject'] = 'Test Subject'
        ..fields['degree'] = '1'  // Use a valid degree ID
        ..fields['semester'] = '1'
        ..fields['year'] = '2023'
        ..fields['university'] = '1'  // Use a valid university ID
        ..fields['uploaded_by'] = '1';  // Use a valid user ID
      
      // We need a file to upload
      // For testing, create a simple text file with some content
      final bytes = utf8.encode('This is a test file content');
      final file = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'test_note.txt',
        contentType: MediaType('application', 'text'),
      );
      request.files.add(file);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        setState(() {
          _response = 'Note created successfully!\n\n${response.body}';
        });
        
        // Fetch the notes again to see the new one
        await _fetchNotes();
      } else {
        setState(() {
          _response = 'Failed to create note. Status code: ${response.statusCode}\n\nError: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error creating note: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 