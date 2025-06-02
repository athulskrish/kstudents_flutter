import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<Event> _eventDetailFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _eventDetailFuture = _apiService.getEventDetail(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Detail'),
      ),
      body: FutureBuilder<Event>(
        future: _eventDetailFuture,
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
              child: Text('Event not found.'),
            );
          } else {
            // Data has been loaded successfully
            Event event = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Date: ${event.date.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      'Location: ${event.location}',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  if (event.category != null && event.category!.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      'Category: ${event.category}',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  if (event.description != null && event.description!.isNotEmpty)
                    Text(
                      event.description!,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  const SizedBox(height: 16.0),
                  if (event.link != null && event.link!.isNotEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('Event Link'),
                      onPressed: () async {
                        if (await canLaunch(event.link!)) {
                          await launch(event.link!);
                        }
                      },
                    ),
                  if (event.map_link != null && event.map_link!.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text('View on Map'),
                      onPressed: () async {
                        if (await canLaunch(event.map_link!)) {
                          await launch(event.map_link!);
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }
} 