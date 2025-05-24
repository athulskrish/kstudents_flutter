import 'package:flutter/material.dart';
import 'package:kerala_tech_reach/models/news.dart';
import 'package:kerala_tech_reach/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsSlug;

  const NewsDetailScreen({Key? key, required this.newsSlug}) : super(key: key);

  @override
  _NewsDetailScreenState createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late Future<News> _newsDetailFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _newsDetailFuture = _apiService.getNewsDetail(widget.newsSlug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News Detail'),
      ),
      body: FutureBuilder<News>(
        future: _newsDetailFuture,
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
              child: Text('News not found.'),
            );
          } else {
            // Data has been loaded successfully
            News news = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Published: ${news.createdAt.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                   if (news.image != null && news.image!.isNotEmpty) ...[
                    const SizedBox(height: 16.0),
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: '${ApiService.baseUrl.replaceFirst('/api', '')}${news.image}',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                   ],
                  const SizedBox(height: 16.0),
                  Text(
                    news.content,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  // You can add more details here, like author, views, likes, etc.
                ],
              ),
            );
          }
        },
      ),
    );
  }
} 