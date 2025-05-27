import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const String privacyUrl = 'https://keralify.com/privacy-policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''We value your privacy and are committed to protecting your personal data. This policy explains what data we collect, how we use it, and your rights regarding your information.\n\nWhat We Collect:\n• Analytics: We collect anonymous usage statistics and crash reports to improve app performance and user experience.\n• Uploaded Files: Files you upload (such as PDFs, notes) are stored securely and used only for providing app features.\n• Contact Form Data: If you use the contact form, we collect your name, email, subject, and message to respond to your inquiry.\n• Local Storage: Data you choose to save locally (e.g., saved PDFs, jobs, events, notes) is stored on your device for offline access.\n• Ad Tracking: We use ad tracking to provide rewarded ads. No personally identifiable information is shared with advertisers.\n\nHow We Use Your Data:\n- To provide and improve app features\n- To respond to your requests\n- To analyze usage and fix issues\n- To show rewarded ads (if you consent)\n\nYour Choices:\n- You can decline data collection on first launch. If declined, analytics and crash reporting are disabled, and some features may be limited.\n- You can review this policy anytime from the app menu.\n\nFor more details, visit our full privacy policy online or contact us via the app.\n''',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Full Privacy Policy'),
                onPressed: () async {
                  if (await canLaunch(privacyUrl)) {
                    await launch(privacyUrl);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 