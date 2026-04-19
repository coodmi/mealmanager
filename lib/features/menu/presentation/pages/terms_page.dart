import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
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
            _header('Terms & Conditions'),
            _sub('Last updated: April 2026'),
            const SizedBox(height: 20),
            _section(
              '1. Acceptance of Terms',
              'By registering and using Meal Manager, you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the app.',
            ),
            _section(
              '2. Use of the App',
              'Meal Manager is designed for managing mess/shared household meals, expenses, and deposits. You agree to use the app only for lawful purposes and in a manner that does not infringe the rights of others.',
            ),
            _section(
              '3. User Accounts',
              'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account.',
            ),
            _section(
              '4. Data Accuracy',
              'You are responsible for the accuracy of data you enter into the app, including meal records, deposits, and expenses.',
            ),
            _section(
              '5. Privacy',
              'Your use of the app is also governed by our Privacy Policy, which is incorporated into these Terms by reference.',
            ),
            _section(
              '6. Modifications',
              'We reserve the right to modify these Terms at any time. Continued use of the app after changes constitutes acceptance of the new Terms.',
            ),
            _section(
              '7. Limitation of Liability',
              'Meal Manager is provided "as is" without warranties of any kind. We are not liable for any damages arising from your use of the app.',
            ),
            _section(
              '8. Contact',
              'For questions about these Terms, contact us at mealmanagerapps@gmail.com',
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
