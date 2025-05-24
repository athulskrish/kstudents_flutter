import 'package:flutter/material.dart';
import 'question_papers_screen.dart';
import 'notes_screen.dart';
import 'profile_screen.dart';
import 'news_list_screen.dart';
import 'job_list_screen.dart';
import 'initiatives_screen.dart';
import 'entrance_exams_screen.dart';
import 'faq_screen.dart';
import 'privacy_screen.dart';
import 'message_us_screen.dart';
import 'tech_picks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kerala Tech Reach'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Explore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('News'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsListScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Jobs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JobListScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: [
          _buildFeatureCard(
            context,
            'Question Papers',
            Icons.description,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuestionPapersScreen(),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            'Study Notes',
            Icons.note,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotesScreen(),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            'Govt. Initiatives',
            Icons.flag,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InitiativesScreen(),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            'Entrance Exams',
            Icons.school,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EntranceExamsScreen(),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            'FAQ',
            Icons.help_outline,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FAQScreen(),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            'Privacy Policy',
            Icons.privacy_tip,
            Colors.grey,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyScreen(),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            'Message Us',
            Icons.mail_outline,
            Colors.indigo,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MessageUsScreen(),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            'Student Tech Picks',
            Icons.devices_other,
            Colors.deepOrange,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TechPicksScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
              color: color,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 