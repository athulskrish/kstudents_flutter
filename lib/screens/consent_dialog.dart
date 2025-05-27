import 'package:flutter/material.dart';
import '../utils/consent_util.dart';
import 'privacy_screen.dart';

class ConsentDialog extends StatelessWidget {
  final void Function(ConsentStatus) onAction;
  const ConsentDialog({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Consent Required'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'We value your privacy. To provide and improve our services, we collect the following data:',
            ),
            SizedBox(height: 8),
            Text('• Analytics (usage statistics, crash reports)\n• Uploaded files (PDFs, notes, etc.)\n• Contact form data (name, email, message)\n• Local storage for saved content\n• Ad tracking (rewarded ads)',
                style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text(
              'Your data is used to provide app features, improve user experience, and for security. For more details, please review our privacy policy.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            );
          },
          child: const Text('View Privacy Policy'),
        ),
        TextButton(
          onPressed: () => onAction(ConsentStatus.declined),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () => onAction(ConsentStatus.accepted),
          child: const Text('Accept'),
        ),
      ],
    );
  }
} 