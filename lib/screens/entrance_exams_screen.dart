import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EntranceExamsScreen extends StatefulWidget {
  const EntranceExamsScreen({Key? key}) : super(key: key);

  @override
  State<EntranceExamsScreen> createState() => _EntranceExamsScreenState();
}

class _EntranceExamsScreenState extends State<EntranceExamsScreen> {
  final ApiService _apiService = ApiService();
  List<Exam> _exams = [];
  List<Exam> _filtered = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final exams = await _apiService.getExams();
    setState(() {
      _exams = exams;
      _filtered = exams;
      _isLoading = false;
    });
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filtered = _exams.where((e) => e.examName.toLowerCase().contains(value.toLowerCase())).toList();
    });
  }

  void _onTap(Exam exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntranceExamDetailScreen(exam: exam),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrance Exams')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Exams',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearch,
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No entrance exams found.'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final exam = _filtered[index];
                            return ListTile(
                              title: Text(exam.examName),
                              subtitle: Text('${DateFormat('yyyy-MM-dd').format(exam.examDate)} | ${exam.degreeNameStr} | ${exam.universityName}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _onTap(exam),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class EntranceExamDetailScreen extends StatelessWidget {
  final Exam exam;
  const EntranceExamDetailScreen({Key? key, required this.exam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exam.examName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam.examName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Date: ${DateFormat('yyyy-MM-dd').format(exam.examDate)}'),
            const SizedBox(height: 8),
            Text('Degree: ${exam.degreeNameStr}'),
            const SizedBox(height: 8),
            Text('University: ${exam.universityName}'),
            const SizedBox(height: 8),
            Text('Semester: ${exam.semester}'),
            const SizedBox(height: 8),
            Text('Admission Year: ${exam.admissionYear}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Official Website'),
              onPressed: () async {
                final url = exam.examUrl;
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link.')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 