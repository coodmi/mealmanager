tyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, s   ],
        ),
      ),
    ));
  }

  Widget _tipCard(String emoji, String title, String desc) {
    return Container(
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
            child: Column(n_in_new, size: 16, color: AppColors.textLight),
       fill, color: Colors.red, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            const Icon(Icons.ope       borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_Uri.parse(url)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
         Builder(builder: (context) => GestureDetector(
      onTap: () => launchUrl(AppColors.primaryGreen.withValues(alpha: 0.08),
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
  }

  Widget _videoCard(String title, String subtitle, String url) {
    return ion(
        color:           _tipCard('💰', 'Track Expenses', 'Use Expense section to record bazar, rent and bills.'),
            _tipCard('📊', 'View Reports', 'Generate monthly PDF reports from the Reports section.'),
            _tipCard('👥', 'Manage Members', 'Add or remove members from the Members tab.'),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecorat            'https://youtube.com'),
            const SizedBox(height: 10),
            _videoCard('Expenses & Reports',
                'How to manage expenses and generate reports',
                'https://youtube.com'),
            const SizedBox(height: 24),
            const Text('Quick Tips',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _tipCard('🍽️', 'Add Meals', 'Tap the Meal tab to add daily meals for members.'),
         _videoCard('Meal Management', 'How to add and track daily meals',
          _header('Learn how to use Meal Manager step by step and manage your mess easily.'),
            const SizedBox(height: 20),
            const Text('Video Tutorials',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _videoCard('Getting Started', 'How to create or join a mess',
                'https://youtube.com'),
            const SizedBox(height: 10),
     imaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
       Text('User Guide',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.prlor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: constget {
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundCoal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

// ─── User Guide Page ──────────────────────────────────────────────────────────
class UserGuidePage extends StatelessWidort 'package:flutter/materiimp