import 'package:flutter/material.dart';
import 'package:kerala_tech_reach/models/news.dart';
import 'package:kerala_tech_reach/services/api_service.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  late Future<List<News>> _newsListFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _newsListFuture = _apiService.getNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News'),
      ),
      body: FutureBuilder<List<News>>(
        future: _newsListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No news available.'),
            );
          } else {
            // Data has been loaded successfully
            List<News> newsList = snapshot.data!;
            return ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                News news = newsList[index];
                return ListTile(
                  title: Text(news.title),
                  subtitle: Text(news.excerpt ?? news.content),
                  // You can add onTap to navigate to a detail screen later
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => NewsDetailScreen(newsId: news.id),
                  //     ),
                  //   );
                  // },
                );
              },
            );
          }
        },
      ),
    );
  }
} 