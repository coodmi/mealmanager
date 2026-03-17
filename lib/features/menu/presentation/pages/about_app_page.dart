import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'About App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Logo + name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.buttonGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'MM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Meal Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '"Manage Meals, Deposits & Expenses Smartly"',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Version 1.0.0',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _textCard(
              'Meal Manager is a smart and simple mess management app designed for bachelor students and job holders living in shared messes. It helps you manage daily meals, deposits, bazar and house expenses and automatically calculates individual and group balances at the end of the month.',
            ),
            const SizedBox(height: 10),
            _textCard(
              'With Meal Manager, you can create or join a mess, add members, track daily meal entries, record deposits, expenses and view live balance updates at any time. No more manual paper or confusing calculations. Everything stays transparent, accurate and organized.',
            ),
            const SizedBox(height: 10),
            _textCard(
              'The app supports mess-wise management, month closing with balance carry-forward, guest meal handling, meal off, chat with mess members, notifications and secure data storage. Meal Manager is built to make mess life easier, reduce conflicts and save time.',
            ),
            const SizedBox(height: 10),
            _textCard(
              'Whether you are a student or a working professional, Meal Manager helps you keep your mess accounts clear, fair and stress-free.',
            ),
            const SizedBox(height: 20),
            _featureGrid(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _textCard(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
      ],
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: AppColors.textDark,
      ),
    ),
  );

  Widget _featureGrid() {
    final features = [
      ('🍽️', 'Meal Tracking'),
      ('💰', 'Expense Mgmt'),
      ('📊', 'PDF Reports'),
      ('👥', 'Member Mgmt'),
      ('🏠', 'Mess Balance'),
      ('🔒', 'Secure Data'),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: features
          .map(
            (f) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(f.$1, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 6),
                  Text(
                    f.$2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
