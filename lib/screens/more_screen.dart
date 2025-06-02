import 'package:flutter/material.dart';
import 'message_us_screen.dart';
import 'news_list_screen.dart';
import 'faq_screen.dart';
import 'entrance_exams_screen.dart';
import 'initiatives_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'tech_picks_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
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
      body: ListView(
        children: [
          _buildListTile(
            context,
            'Messages',
            Icons.message,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessageUsScreen()),
            ),
          ),
          _buildListTile(
            context,
            'News',
            Icons.article,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewsListScreen()),
            ),
          ),
          _buildListTile(
            context,
            'FAQ',
            Icons.help_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FAQScreen()),
            ),
          ),
          _buildListTile(
            context,
            'Entrance Exams',
            Icons.school,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EntranceExamsScreen()),
            ),
          ),
          _buildListTile(
            context,
            'Govt. Initiatives',
            Icons.flag,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InitiativesScreen()),
            ),
          ),
          _buildListTile(
            context,
            'Student Tech Picks',
            Icons.devices_other,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TechPicksScreen()),
            ),
          ),
          _buildListTile(
            context,
            'Privacy Policy',
            Icons.privacy_tip,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
} 