import 'package:flutter/material.dart';

class EmailVerificationPendingScreen extends StatelessWidget {
  final String email;

  const EmailVerificationPendingScreen({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Please Verify Your Email Address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A verification email has been sent to $email. Please click the link in the email to activate your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement resend email verification logic (call backend API)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resend verification email functionality to be implemented.')),
                  );
                   // Optionally, guide user back to login after resending
                   // Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 16),
               TextButton(
                 onPressed: () {
                   // Guide user back to login screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                 },
                 child: const Text('Back to Login'),
               ),
            ],
          ),
        ),
      ),
    );
  }
} 