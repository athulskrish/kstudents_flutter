import 'package:flutter/material.dart';
import 'package:kerala_tech_reach/models/job.dart';
import 'package:kerala_tech_reach/services/api_service.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class JobDetailScreen extends StatefulWidget {
  final int jobId;

  const JobDetailScreen({Key? key, required this.jobId}) : super(key: key);

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Future<Job> _jobDetailFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _jobDetailFuture = _apiService.getJobDetail(widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Detail'),
      ),
      body: FutureBuilder<Job>(
        future: _jobDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text('Job not found.'),
            );
          } else {
            // Data has been loaded successfully
            Job job = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Last Date to Apply: ${DateFormat('MMM dd, yyyy').format(job.lastDate)}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    job.description,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  // You can add more details here
                ],
              ),
            );
          }
        },
      ),
    );
  }
} 