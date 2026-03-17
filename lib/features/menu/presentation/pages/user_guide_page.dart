import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'User Guide',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBox(
              'Learn how to use Meal Manager step by step and manage your mess easily.',
            ),
            const SizedBox(height: 20),
            _sectionTitle('Video Tutorials'),
            const SizedBox(height: 12),
            _videoCard(
              'Getting Started',
              'How to create or join a mess',
              'https://youtube.com',
            ),
            const SizedBox(height: 10),
            _videoCard(
              'Meal Management',
              'How to add and track daily meals',
              'https://youtube.com',
            ),
            const SizedBox(height: 10),
            _videoCard(
              'Expenses & Reports',
              'Manage expenses and generate reports',
              'https://youtube.com',
            ),
            const SizedBox(height: 24),
            _sectionTitle('Quick Tips'),
            const SizedBox(height: 12),
            _tipCard(
              '🍽️',
              'Add Meals',
              'Tap the Meal tab to add daily meals for members.',
            ),
            _tipCard(
              '💰',
              'Track Expenses',
              'Use Expense section to record bazar, rent and bills.',
            ),
            _tipCard(
              '📊',
              'View Reports',
              'Generate monthly PDF reports from the Reports section.',
            ),
            _tipCard(
              '👥',
              'Manage Members',
              'Add or remove members from the Members tab.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryGreen.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.menu_book, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  Widget _videoCard(
    String title,
    String subtitle,
    String url,
  ) => GestureDetector(
    onTap: () => launchUrl(Uri.parse(url)),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.play_circle_fill,
              color: Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, size: 16, color: AppColors.textLight),
        ],
      ),
    ),
  );

  Widget _tipCard(String emoji, String title, String desc) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
