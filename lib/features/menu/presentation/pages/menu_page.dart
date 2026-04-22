import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import 'user_guide_page.dart';
import 'suggestion_page.dart';
import 'contact_us_page.dart';
import 'about_app_page.dart';
import 'donation_page.dart';
import 'conditions_policies_page.dart';
import 'mess_requests_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _messId = '';
  String _role = 'member';

  static const _adminRoles = [
    'superAdmin',
    'systemAdmin',
    'supportAdmin',
    'contentAdmin',
  ];

  bool get _isAdmin => _adminRoles.contains(_role);
  bool get _isManager => _role == 'manager';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (mounted) {
      setState(() {
        _messId = doc.data()?['messId'] as String? ?? '';
        _role = doc.data()?['role'] as String? ?? 'member';
      });
    }
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Menu',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Admin Panel — only visible to admins, not manager/member
          if (_isAdmin) ...[
            _section('Admin', [
              _item(
                context,
                '🛡️  Admin Panel',
                Icons.admin_panel_settings_rounded,
                Colors.deepPurple,
                () => context.push('/admin'),
              ),
            ]),
            const SizedBox(height: 14),
          ],

          // Help & Info section
          _section('Help & Info', [
            _item(
              context,
              'App User Guide',
              Icons.menu_book,
              Colors.indigo,
              () => _go(context, const UserGuidePage()),
            ),
            _item(
              context,
              'Suggestion Box',
              Icons.lightbulb_outline,
              Colors.teal,
              () => _go(context, const SuggestionPage()),
            ),
            _item(
              context,
              'Rate & Review Us',
              Icons.star_outline,
              Colors.orange,
              () => _rateApp(context),
            ),
            _item(
              context,
              'Contact Us',
              Icons.contact_support,
              Colors.cyan,
              () => _go(context, const ContactUsPage()),
            ),
            _item(
              context,
              'Conditions & Policies',
              Icons.gavel_rounded,
              Colors.indigo,
              () => _go(context, const ConditionsPoliciesPage()),
            ),
            _item(
              context,
              'About App',
              Icons.info_outline,
              Colors.grey,
              () => _go(context, const AboutAppPage()),
            ),
            if (_isManager && _messId.isNotEmpty) _requestsItem(context),
          ]),
          const SizedBox(height: 14),

          // Show Your Love + Share App
          Row(
            children: [
              Expanded(
                child: _bigBtn(
                  context,
                  Icons.favorite_rounded,
                  'Show Your Love',
                  const Color(0xFFE91E63),
                  () => _go(context, const DonationPage()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bigBtn(
                  context,
                  Icons.share_rounded,
                  'Share App',
                  Colors.blue.shade600,
                  () => _shareApp(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Follow Us
          _section('Follow Us', [_followRow(context)]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _requestsItem(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('joinRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return InkWell(
          onTap: () => _go(context, const MessRequestsPage()),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Mess Requests',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigBtn(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _followRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _followBtn(
              'Facebook',
              Icons.facebook,
              Colors.blue.shade700,
              () => _launchUrl('https://www.facebook.com'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _followBtn(
              'Website',
              Icons.language_rounded,
              Colors.teal.shade700,
              () => _launchUrl('https://mealmanager.app'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _followBtn(
              'YouTube',
              Icons.smart_display_rounded,
              Colors.red,
              () => _launchUrl('https://www.youtube.com'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _followBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rateApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rate & Review Us',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⭐⭐⭐⭐⭐',
              style: TextStyle(fontSize: 32),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Enjoying Meal Manager?\nLeave us a review.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.example.mealmanager',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Next', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    const text =
        '🍽️ Manage your mess smartly with Meal Manager!\n\n'
        'Track meals, expenses, deposits and generate reports easily.\n\n'
        '📱 Download now:\n'
        'Play Store: https://play.google.com/store\n'
        'iOS: https://apps.apple.com\n\n'
        '#MealManager #MessManagement';
    Share.share(text, subject: 'Meal Manager App');
  }
}
