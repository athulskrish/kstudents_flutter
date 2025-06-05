import 'package:flutter/material.dart';
import 'message_us_screen.dart';
import 'news_list_screen.dart';
import 'faq_screen.dart';
import 'entrance_exams_screen.dart';
import 'initiatives_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'tech_picks_screen.dart';
// Import url_launcher for external links, if needed
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.dart';
import 'saved_items_screen.dart';
import '../services/auth_service.dart'; // Import AuthService
import 'login_screen.dart'; // Import LoginScreen

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
          // Account/Profile
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Account'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          // App Settings
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.push(
            context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          // Message/Contact Us (Using existing message option)
          ListTile(
            leading: const Icon(Icons.message_outlined),
            title: const Text('Message Us'),
            onTap: () {
              // TODO: Implement navigation to your existing message/contact screen or action
              // Example using url_launcher to send an email:
              // launchUrl(Uri(scheme: 'mailto', path: 'support@example.com'));
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MessageUsScreen()),
              );
            },
          ),
          // News
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('News'),
            onTap: () {
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewsListScreen()),
              );
            },
          ),
          // FAQ (Using existing FAQ)
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('FAQ'),
            onTap: () {
              // TODO: Implement opening the existing FAQ (external URL or internal route)
              // Example using url_launcher for an external URL:
              // launchUrl(Uri.parse('https://yourwebsite.com/faq'));
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ),
          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Implement opening the existing Privacy Policy (external URL or internal route)
              // Example using url_launcher for an external URL:
              // launchUrl(Uri.parse('https://yourwebsite.com/privacy_policy'));
              Navigator.push(
            context,
                MaterialPageRoute(builder: (context) => const PrivacyScreen()),
              );
            },
          ),
          // About Us/App Info
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Kerala Tech Reach', // Replace with your app name
                applicationVersion: '1.0.0', // Replace with your app version
                // applicationIcon: const FlutterLogo(), // Optional: add an app icon
                // children: <Widget>[
                //   Text('Your app description here.'),
                // ],
              );
            },
          ),
          // Rate App
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('Rate App'),
            onTap: () async {
              final uri = Uri.parse(
                  'market://details?id=your.app.id'); // Replace with your app's package name (Android)
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                // Fallback for iOS or if Play Store not installed
                final fallbackUri = Uri.parse(
                    'https://apps.apple.com/us/app/idYOUR_APP_ID'); // Replace with your app's Apple App Store ID (iOS)
                if (!await launchUrl(fallbackUri, mode: LaunchMode.externalApplication)) {
                  // Handle error, e.g., show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open app store.')),
                  );
                }
              }
            },
          ),
          // Share App
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share App'),
            onTap: () {
              Share.share('Check out this app!'); // You might want to add a real app store link here
            },
          ),
          // Logout (Conditional)
          ListTile(
            leading: _isLoading
                ? const CircularProgressIndicator() // Show loading indicator when logging out
                : const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _isLoading ? null : _logout, // Disable onTap while loading
          ),
        ],
      ),
    );
  }
} 