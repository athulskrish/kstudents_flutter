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
                  'We value your privacy. Your data is never shared with third parties. For the full privacy policy, please visit our website.',
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