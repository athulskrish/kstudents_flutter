import 'package:flutter/material.dart';
import 'package:kerala_tech_reach/models/news.dart';
import 'package:kerala_tech_reach/services/api_service.dart';
import 'news_detail_screen.dart'; // Import the news detail screen
import 'package:cached_network_image/cached_network_image.dart'; // Import cached_network_image
// import 'package:intl/intl.dart'; // Import for date formatting if needed

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
                // Use Card and InkWell for a visually appealing and tappable list item
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      // Navigate to NewsDetailScreen, passing the news slug
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailScreen(newsSlug: news.slug!),
                        ),
                      );
                    },
                    // Use Padding for internal spacing
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display thumbnail if available using CachedNetworkImage
                          if (news.thumbnail != null && news.thumbnail!.isNotEmpty)
                            Container(
                              width: 100,
                              height: 80,
                              margin: const EdgeInsets.only(right: 12.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(news.thumbnail!), // Use thumbnail URL with CachedNetworkImage
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ) else
                            // Placeholder if no thumbnail
                            Container(
                              width: 100,
                              height: 80,
                              margin: const EdgeInsets.only(right: 12.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Icon(Icons.article_outlined, size: 40, color: Colors.grey[600]),
                            ),
                          
                          // Expanded column for text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // News Title
                                Text(
                                  news.title,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                // News Excerpt or Content (truncated)
                                Text(
                                  news.excerpt ?? news.content, // Use excerpt if available, otherwise content
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                // Optional: Add date or other info below the excerpt
                                // if (news.createdAt != null) Text(
                                //   'Published: ${DateFormat('MMM dd, yyyy').format(news.createdAt)}',
                                //   style: TextStyle(
                                //     fontSize: 12.0,
                                //     color: Colors.grey[500],
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
} 