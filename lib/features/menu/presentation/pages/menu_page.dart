import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../expense/presentation/pages/expense_entry_page.dart';
import '../../../withdraw/presentation/pages/withdraw_request_page.dart';
import '../../../reports/presentation/pages/reports_pdf_page.dart';
import '../../../member/presentation/pages/member_page.dart';
import '../../../deposit/presentation/pages/deposit_page.dart';
import 'subscription_page.dart';
import 'user_guide_page.dart';
import 'suggestion_page.dart';
import 'contact_us_page.dart';
import 'about_app_page.dart';
import 'donation_page.dart';
import 'mess_settings_page.dart';
import 'mess_requests_page.dart';
import 'terms_page.dart';
import 'privacy_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _messId = '';
  bool _isManager = false;

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
      final role = doc.data()?['role'] as String? ?? 'member';
      setState(() {
        _messId = doc.data()?['messId'] as String? ?? '';
        _isManager = role == 'manager' || role == 'admin';
      });
    }
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isManager)
            _item(
              context,
              '🛡️  Admin Panel',
              Icons.admin_panel_settings_rounded,
              Colors.deepPurple,
              () => context.push('/admin'),
            ),
          if (_isManager) const SizedBox(height: 14),
          _section('Mess Management', [
            _item(
              context,
              'Subscription',
              Icons.workspace_premium,
              Colors.amber.shade700,
              () => _go(context, const SubscriptionPage()),
            ),
            _item(
              context,
              'Mess Settings',
              Icons.settings,
              AppColors.primaryGreen,
              () => _go(context, const MessSettingsPage()),
            ),
            _item(
              context,
              'Members',
              Icons.people,
              Colors.blue,
              () => _go(context, const MemberPage()),
            ),
            if (_isManager && _messId.isNotEmpty) _requestsItem(context),
          ]),
          const SizedBox(height: 14),
          _section('Transactions', [
            _item(
              context,
              'Deposit Money',
              Icons.add_circle,
              Colors.green,
              () => _go(context, const DepositPage()),
            ),
            _item(
              context,
              'Add Expense',
              Icons.remove_circle,
              Colors.red,
              () => _go(context, const ExpenseEntryPage()),
            ),
            _item(
              context,
              'Withdraw Request',
              Icons.account_balance_wallet,
              Colors.purple,
              () => _go(context, const WithdrawRequestPage()),
            ),
          ]),
          const SizedBox(height: 14),
          _section('Reports', [
            _item(
              context,
              'Generate Reports & PDF',
              Icons.assessment,
              Colors.deepPurple,
              () => _go(context, const ReportsPdfPage()),
            ),
          ]),
          const SizedBox(height: 14),
          _section('Help & Support', [
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
              'About App',
              Icons.info_outline,
              Colors.grey,
              () => _go(context, const AboutAppPage()),
            ),
            _item(
              context,
              'Terms & Conditions',
              Icons.gavel,
              Colors.indigo,
              () => _go(context, const TermsPage()),
            ),
            _item(
              context,
              'Privacy Policy',
              Icons.privacy_tip_outlined,
              Colors.teal,
              () => _go(context, const PrivacyPage()),
            ),
          ]),
          const SizedBox(height: 14),
          // Donation + Share row
          Row(
            children: [
              Expanded(
                child: _bigBtn(
                  context,
                  '❤️',
                  'Show Your Love',
                  const Color(0xFFE91E63),
                  () => _go(context, const DonationPage()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bigBtn(
                  context,
                  '📤',
                  'Share App',
                  Colors.blue.shade600,
                  () => _shareApp(context),
                ),
              ),
            ],
          ),
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
    String emoji,
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
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
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
              'Enjoying Meal Manager? Leave us a review!',
              textAlign: TextAlign.center,
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Rate Now',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    const text =
        '🍽️ Manage your mess smartly with Meal Manager!\n\nTrack meals, expenses, deposits and generate reports easily.\n\n📱 Download now:\nPlay Store: https://play.google.com/store\niOS: https://apps.apple.com\n\n#MealManager #MessManagement';
    Clipboard.setData(const ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share text copied to clipboard!'),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
