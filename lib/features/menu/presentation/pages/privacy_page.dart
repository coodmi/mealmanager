import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header('Privacy Policy'),
            _sub('Last updated: April 2026'),
            const SizedBox(height: 20),
            _section(
              '1. Information We Collect',
              'We collect information you provide during registration (name, email, mobile number) and information you enter while using the app (meal records, expenses, deposits).',
            ),
            _section(
              '2. How We Use Your Information',
              'We use your information to provide and improve the Meal Manager service, to communicate with you, and to ensure the security of your account.',
            ),
            _section(
              '3. Data Storage',
              'Your data is stored securely using Firebase (Google Cloud). We do not sell your personal information to third parties.',
            ),
            _section(
              '4. Data Sharing',
              'Your mess data is shared only with members of your mess group. We do not share your personal data with external parties except as required by law.',
            ),
            _section(
              '5. Data Security',
              'We implement industry-standard security measures to protect your data. However, no method of transmission over the internet is 100% secure.',
            ),
            _section(
              '6. Your Rights',
              'You have the right to access, correct, or delete your personal data. Contact us at mealmanagerapps@gmail.com to exercise these rights.',
            ),
            _section(
              '7. Cookies',
              'The web version of Meal Manager may use cookies to maintain your session. You can disable cookies in your browser settings.',
            ),
            _section(
              '8. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of significant changes through the app.',
            ),
            _section(
              '9. Contact',
              'For privacy-related questions, contact us at mealmanagerapps@gmail.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark,
    ),
  );

  Widget _sub(String text) =>
      Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade500));

  Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textDark,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}
