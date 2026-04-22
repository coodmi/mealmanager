import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firebase_mess_service.dart';
import '../../../../core/theme/theme_provider.dart'; // provides themeNotifier
import 'my_requests_page.dart';
import '../../../member/presentation/pages/member_details_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _messData;
  bool _isManager = false;
  bool _isLoading = true;
  String _messId = '';
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _listenPendingCount();
  }

  StreamSubscription<QuerySnapshot>? _pendingSub;

  void _listenPendingCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _pendingSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('invitations')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
          if (mounted) setState(() => _pendingCount = snap.docs.length);
        });
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Wait for Firebase Auth to restore session on web
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
      }

      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch user doc directly using the authenticated UID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final messId = userData?['messId'] as String?;

      Map<String, dynamic>? messData;
      if (messId != null && messId.isNotEmpty) {
        final messDoc = await FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .get();
        messData = messDoc.data();
      }

      final isManager = userData?['role'] == 'manager';

      if (mounted) {
        setState(() {
          _userData = userData;
          _messData = messData;
          _isManager = isManager;
          _messId = messId ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _name => _userData?['name'] ?? 'User';
  String get _email => _userData?['email'] ?? '';
  String get _mobile => _userData?['mobile'] ?? '';
  String get _messName => _messData?['name'] ?? 'No Mess';
  String get _joinDate {
    final ts = _userData?['createdAt'];
    if (ts == null) return 'N/A';
    final dt = (ts as Timestamp).toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // Personal details getters
  String get _gender => _userData?['gender'] as String? ?? '';
  String get _profession => _userData?['profession'] as String? ?? '';
  String get _bloodGroup => _userData?['bloodGroup'] as String? ?? '';
  String get _dob => _userData?['dob'] as String? ?? '';
  String get _division => _userData?['division'] as String? ?? '';
  String get _district => _userData?['district'] as String? ?? '';
  String get _thana => _userData?['thana'] as String? ?? '';

  String get _dobFormatted {
    if (_dob.isEmpty) return '';
    try {
      final dt = DateTime.parse(_dob);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return _dob;
    }
  }

  String get _homeLocation {
    final parts = [
      _thana,
      _district,
      _division,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        final isDark = themeNotifier.isDark;
        final bg = isDark ? const Color(0xFF121212) : AppColors.bgColor;
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : AppColors.textDark;
        final subColor = isDark ? Colors.white60 : AppColors.textLight;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: const Text(
              'Profile',
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
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileCard(cardColor, textColor, subColor),
                      const SizedBox(height: 16),
                      _buildPersonalDetailsCard(cardColor, textColor, subColor),
                      const SizedBox(height: 16),
                      _buildInfoCard(cardColor, textColor, subColor),
                      const SizedBox(height: 16),
                      _buildActionsSection(
                        cardColor,
                        textColor,
                        subColor,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildMessSection(cardColor, textColor, subColor),
                      const SizedBox(height: 16),
                      _buildDangerSection(cardColor),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileCard(Color cardColor, Color textColor, Color subColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.buttonGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Show join date instead of email
          Text(
            'Joined to Meal Manager: $_joinDate',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(
                _isManager ? Icons.manage_accounts : Icons.person,
                _isManager ? 'Manager' : 'Member',
              ),
              const SizedBox(width: 8),
              _chip(Icons.home_work_outlined, _messName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Color cardColor, Color textColor, Color subColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.manage_accounts_outlined,
                size: 16,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 6),
              Text(
                'Account Info',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showEditProfileDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryGreen),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.phone_outlined,
            'Mobile',
            _mobile.isEmpty ? 'Not set' : _mobile,
            subColor,
            textColor,
          ),
          _divider(),
          _infoRow(Icons.email_outlined, 'Email', _email, subColor, textColor),
          _divider(),
          _infoRow(
            Icons.home_outlined,
            'Mess Name',
            _messName,
            subColor,
            textColor,
          ),
          _divider(),
          _infoRow(Icons.tag, 'Mess ID', _messId, subColor, textColor),
          _divider(),
          _infoRow(
            Icons.calendar_today_outlined,
            'Joined Mess',
            _joinDate,
            subColor,
            textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(
    Color cardColor,
    Color textColor,
    Color subColor,
  ) {
    final hasAnyData =
        _gender.isNotEmpty ||
        _profession.isNotEmpty ||
        _bloodGroup.isNotEmpty ||
        _dobFormatted.isNotEmpty ||
        _homeLocation.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Personal Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showEditPersonalDetailsDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryGreen),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasAnyData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Tap Edit to add your personal details',
                  style: TextStyle(fontSize: 13, color: subColor),
                ),
              ),
            )
          else
            // Grid 2 style layout
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: [
                if (_gender.isNotEmpty)
                  _detailGridItem(
                    Icons.wc,
                    'Gender',
                    _gender,
                    textColor,
                    subColor,
                  ),
                if (_profession.isNotEmpty)
                  _detailGridItem(
                    Icons.work_outline,
                    'Profession',
                    _profession,
                    textColor,
                    subColor,
                  ),
                if (_bloodGroup.isNotEmpty)
                  _detailGridItem(
                    Icons.bloodtype_outlined,
                    'Blood Group',
                    _bloodGroup,
                    textColor,
                    subColor,
                  ),
                if (_dobFormatted.isNotEmpty)
                  _detailGridItem(
                    Icons.cake_outlined,
                    'Birth Date',
                    _dobFormatted,
                    textColor,
                    subColor,
                  ),
                if (_homeLocation.isNotEmpty)
                  _detailGridItem(
                    Icons.location_on_outlined,
                    'Home',
                    _homeLocation,
                    textColor,
                    subColor,
                    fullWidth: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _detailGridItem(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subColor, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: subColor)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
    Color subColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: subColor)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15));

  Widget _buildActionsSection(
    Color cardColor,
    Color textColor,
    Color subColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.receipt_long_rounded,
            label: 'Meals & Transactions',
            subtitle: 'View your monthly meals & transactions',
            color: Colors.blue,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            onTap: _showMealsAndTransactions,
          ),
          _divider(),
          _actionTile(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: isDark ? 'Light Mode' : 'Dark Mode',
            subtitle: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            color: isDark ? Colors.orange : Colors.indigo,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            trailing: Switch(
              value: isDark,
              onChanged: (_) => themeNotifier.toggleTheme(),
              activeColor: AppColors.primaryGreen,
            ),
            onTap: () => themeNotifier.toggleTheme(),
          ),
          _divider(),
          _actionTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            subtitle: 'Update your account password',
            color: Colors.teal,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            onTap: _showChangePasswordDialog,
          ),
          _divider(),
          _actionTile(
            icon: Icons.mail_outline_rounded,
            label: 'My Requests',
            subtitle: 'View mess invitations and requests',
            color: Colors.orange,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            badge: _pendingCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRequestsPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessSection(Color cardColor, Color textColor, Color subColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _actionTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Switch Mess',
            subtitle: 'Join or create a different mess',
            color: Colors.purple,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            onTap: _confirmSwitchMess,
          ),
          _divider(),
          _actionTile(
            icon: Icons.exit_to_app_rounded,
            label: 'Leave Mess',
            subtitle: 'Exit from current mess',
            color: Colors.red,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            onTap: _confirmLeaveMess,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(Color cardColor) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _confirmLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
    Widget? trailing,
    int badge = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: subColor,
                ),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _name);
    final mobileCtrl = TextEditingController(text: _mobile);
    bool saving = false;
    String? nameError;
    String? mobileError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                onChanged: (_) => setS(() => nameError = null),
                decoration: InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: nameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setS(() => mobileError = null),
                decoration: InputDecoration(
                  labelText: 'Mobile *',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  errorText: mobileError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                enabled: false,
                controller: TextEditingController(text: _email),
                decoration: InputDecoration(
                  labelText: 'Email (read-only)',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final mobile = mobileCtrl.text.trim();

                      // Validate mandatory fields
                      bool hasError = false;
                      if (name.isEmpty) {
                        setS(() => nameError = 'Name is required');
                        hasError = true;
                      }
                      if (mobile.isEmpty) {
                        setS(() => mobileError = 'Mobile is required');
                        hasError = true;
                      } else if (mobile.length != 11) {
                        setS(() => mobileError = 'Must be 11 digits');
                        hasError = true;
                      }
                      if (hasError) return;

                      setS(() => saving = true);

                      // Check duplicate mobile (only if changed)
                      if (mobile != _mobile) {
                        final uid = FirebaseAuthService.getUserId() ?? '';
                        final variants = [mobile];
                        if (mobile.startsWith('0')) variants.add('+88$mobile');
                        if (mobile.startsWith('+88'))
                          variants.add(mobile.substring(3));

                        for (final v in variants) {
                          final snap = await FirebaseFirestore.instance
                              .collection('users')
                              .where('mobile', isEqualTo: v)
                              .limit(1)
                              .get();
                          final docs = snap.docs
                              .where((d) => d.id != uid)
                              .toList();
                          if (docs.isNotEmpty) {
                            setS(() {
                              saving = false;
                              mobileError =
                                  'This Mobile Number is already using by another user';
                            });
                            return;
                          }
                        }
                      }

                      final ok = await FirebaseAuthService.updateUserData({
                        'name': name,
                        'mobile': mobile,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (ok) {
                        await _load();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPersonalDetailsDialog() {
    // Pre-fill from existing data
    String? gender = _gender.isEmpty ? null : _gender;
    String? profession = _profession.isEmpty ? null : _profession;
    String? bloodGroup = _bloodGroup.isEmpty ? null : _bloodGroup;
    DateTime? dob;
    if (_dob.isNotEmpty) {
      try {
        dob = DateTime.parse(_dob);
      } catch (_) {}
    }
    String? division = _division.isEmpty ? null : _division;
    String? district = _district.isEmpty ? null : _district;
    String? thana = _thana.isEmpty ? null : _thana;
    bool saving = false;

    const genders = ['Male', 'Female', 'Other'];
    const professions = ['Student', 'Job Holder', 'Business', 'Other'];
    const bloodGroups = [
      'A+',
      'A-',
      'B+',
      'B-',
      'O+',
      'O-',
      'AB+',
      'AB-',
      'Unknown',
    ];
    const Map<String, List<String>> divisionDistricts = {
      'Barisal': [
        'Barguna',
        'Barisal',
        'Bhola',
        'Jhalokati',
        'Patuakhali',
        'Pirojpur',
      ],
      'Chittagong': [
        'Bandarban',
        'Brahmanbaria',
        'Chandpur',
        'Chattogram',
        "Cox's Bazar",
        'Cumilla',
        'Feni',
        'Khagrachhari',
        'Lakshmipur',
        'Noakhali',
        'Rangamati',
      ],
      'Dhaka': [
        'Dhaka',
        'Faridpur',
        'Gazipur',
        'Gopalganj',
        'Kishoreganj',
        'Madaripur',
        'Manikganj',
        'Munshiganj',
        'Narayanganj',
        'Narsingdi',
        'Rajbari',
        'Shariatpur',
        'Tangail',
      ],
      'Khulna': [
        'Bagerhat',
        'Chuadanga',
        'Jessore',
        'Jhenaidah',
        'Khulna',
        'Kushtia',
        'Magura',
        'Meherpur',
        'Narail',
        'Satkhira',
      ],
      'Mymensingh': ['Jamalpur', 'Mymensingh', 'Netrokona', 'Sherpur'],
      'Rajshahi': [
        'Bogura',
        'Chapainawabganj',
        'Joypurhat',
        'Naogaon',
        'Natore',
        'Pabna',
        'Rajshahi',
        'Sirajganj',
      ],
      'Rangpur': [
        'Dinajpur',
        'Gaibandha',
        'Kurigram',
        'Lalmonirhat',
        'Nilphamari',
        'Panchagarh',
        'Rangpur',
        'Thakurgaon',
      ],
      'Sylhet': ['Habiganj', 'Moulvibazar', 'Sunamganj', 'Sylhet'],
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final districts = division != null
              ? (divisionDistricts[division] ?? [])
              : <String>[];
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Personal Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogDropdown(
                    'Gender',
                    genders,
                    gender,
                    Icons.wc,
                    (v) => setS(() => gender = v),
                  ),
                  const SizedBox(height: 10),
                  _dialogDropdown(
                    'Profession',
                    professions,
                    profession,
                    Icons.work_outline,
                    (v) => setS(() => profession = v),
                  ),
                  const SizedBox(height: 10),
                  _dialogDropdown(
                    'Blood Group',
                    bloodGroups,
                    bloodGroup,
                    Icons.bloodtype_outlined,
                    (v) => setS(() => bloodGroup = v),
                  ),
                  const SizedBox(height: 10),
                  // DOB picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dob ?? DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primaryGreen,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setS(() => dob = picked);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dob != null
                                  ? '${dob!.day}/${dob!.month}/${dob!.year}'
                                  : 'Birth Date',
                              style: TextStyle(
                                fontSize: 14,
                                color: dob != null
                                    ? AppColors.textDark
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _dialogDropdown(
                    'Division',
                    divisionDistricts.keys.toList(),
                    division,
                    Icons.map_outlined,
                    (v) {
                      setS(() {
                        division = v;
                        district = null;
                        thana = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _dialogDropdown(
                    'District',
                    districts,
                    district,
                    Icons.location_city_outlined,
                    division == null
                        ? null
                        : (v) => setS(() {
                            district = v;
                            thana = null;
                          }),
                    hint: division == null
                        ? 'Select division first'
                        : 'Select district',
                  ),
                  const SizedBox(height: 10),
                  _dialogDropdown(
                    'Thana / Upazila',
                    district != null ? ['${district} Sadar', 'Other'] : [],
                    thana,
                    Icons.place_outlined,
                    district == null ? null : (v) => setS(() => thana = v),
                    hint: district == null
                        ? 'Select district first'
                        : 'Select thana',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        setS(() => saving = true);
                        final ok = await FirebaseAuthService.updateUserData({
                          'gender': gender,
                          'profession': profession,
                          'bloodGroup': bloodGroup,
                          'dob': dob?.toIso8601String(),
                          'division': division,
                          'district': district,
                          'thana': thana,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (ok) {
                          await _load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Personal details updated'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dialogDropdown(
    String label,
    List<String> items,
    String? value,
    IconData icon,
    void Function(String?)? onChanged, {
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
      hint: hint != null
          ? Text(hint, style: const TextStyle(fontSize: 13))
          : null,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    bool showCurrent = false;
    bool showNew = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentCtrl,
                  obscureText: !showCurrent,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showCurrent ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () => setS(() => showCurrent = !showCurrent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newCtrl,
                  obscureText: !showNew,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNew ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      onPressed: () => setS(() => showNew = !showNew),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              if (newCtrl.text != confirmCtrl.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Passwords do not match'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (newCtrl.text.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password must be at least 6 characters',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setS(() => saving = true);
                              try {
                                final user = FirebaseAuthService.currentUser;
                                if (user == null) return;
                                final cred = EmailAuthProvider.credential(
                                  email: user.email!,
                                  password: currentCtrl.text,
                                );
                                await user.reauthenticateWithCredential(cred);
                                await user.updatePassword(newCtrl.text);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password changed successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                setS(() => saving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.message ??
                                            'Failed to change password',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Change',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSwitchMess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Switch Mess',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You will be taken to the mess selection screen. Your current mess data will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRouter.createJoinMess);
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveMess() {
    if (_isManager) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Cannot Leave'),
            ],
          ),
          content: const Text(
            'You are the manager of this mess. Please transfer managership to another member before leaving.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Leave Mess',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to leave "$_messName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkRed),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await FirebaseMessService.leaveMess();
              if (mounted) {
                if (result['success'] == true) {
                  context.go(AppRouter.createJoinMess);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to leave'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuthService.logout();
              if (mounted) context.go(AppRouter.login);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMealsAndTransactions() {
    final uid = FirebaseAuthService.getUserId() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberDetailsPage(memberId: uid, memberName: _name),
      ),
    );
  }
}

// ─── Meal Overview Page ────────────────────────────────────────────────────

class MealOverviewPage extends StatefulWidget {
  final String messId;
  final String memberName;
  final String memberId;

  const MealOverviewPage({
    super.key,
    required this.messId,
    required this.memberName,
    required this.memberId,
  });

  @override
  State<MealOverviewPage> createState() => _MealOverviewPageState();
}

class _MealOverviewPageState extends State<MealOverviewPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;
  List<Map<String, dynamic>> _meals = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

      final snap = await FirebaseFirestore.instance
          .collection('meals')
          .where('messId', isEqualTo: widget.messId)
          .where('memberId', isEqualTo: widget.memberId)
          .get();

      final filtered = snap.docs
          .where((doc) {
            final data = doc.data();
            final ts = data['date'];
            if (ts == null) return false;
            final date = (ts as Timestamp).toDate();
            return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                date.isBefore(end);
          })
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();

      filtered.sort((a, b) {
        final da = (a['date'] as Timestamp).toDate();
        final db = (b['date'] as Timestamp).toDate();
        return da.compareTo(db);
      });

      if (mounted)
        setState(() {
          _meals = filtered;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalMeals =>
      _meals.fold(0.0, (sum, m) => sum + ((m['count'] ?? 1) as num).toDouble());

  String _monthLabel(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadMeals();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
    _loadMeals();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.isDark;
    final bg = isDark ? const Color(0xFF121212) : AppColors.bgColor;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final subColor = isDark ? Colors.white60 : AppColors.textLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Meal Overview',
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
      body: Column(
        children: [
          // Month switcher
          Container(
            color: AppColors.primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                Text(
                  _monthLabel(_selectedMonth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ],
            ),
          ),
          // Summary card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.buttonGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Total Meals', _totalMeals.toStringAsFixed(1)),
                  _vDivider(),
                  _summaryItem('Days', _meals.length.toString()),
                  _vDivider(),
                  _summaryItem(
                    'Avg/Day',
                    _meals.isEmpty
                        ? '0'
                        : (_totalMeals / _meals.length).toStringAsFixed(2),
                  ),
                ],
              ),
            ),
          ),
          // Meal list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : _meals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: subColor),
                        const SizedBox(height: 12),
                        Text(
                          'No meals this month',
                          style: TextStyle(color: subColor, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _meals.length,
                    itemBuilder: (_, i) {
                      final meal = _meals[i];
                      final ts = meal['date'] as Timestamp;
                      final date = ts.toDate();
                      final count = (meal['count'] ?? 1) as num;
                      final isGuest = meal['isGuest'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            _dayLabel(date),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: isGuest
                              ? Text(
                                  'Guest: ${meal['guestName'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                )
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count meal${count != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
    height: 40,
    width: 1,
    color: Colors.white.withValues(alpha: 0.3),
  );

  String _dayLabel(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}
