import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_users_page.dart';
import 'pages/admin_mess_page.dart';
import 'pages/admin_payments_page.dart';
import 'pages/admin_subscriptions_page.dart';
import 'pages/admin_notifications_page.dart';
import 'pages/admin_suggestions_page.dart';
import 'pages/admin_settings_page.dart';
import 'pages/admin_logs_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  String _adminName = '';
  String _adminRole = '';
  String _adminEmail = '';

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.people_alt_rounded, 'Users'),
    _NavItem(Icons.home_work_rounded, 'Mess / Groups'),
    _NavItem(Icons.payments_rounded, 'Payments'),
    _NavItem(Icons.workspace_premium_rounded, 'Subscriptions'),
    _NavItem(Icons.notifications_rounded, 'Notifications'),
    _NavItem(Icons.lightbulb_rounded, 'Suggestion Box'),
    _NavItem(Icons.settings_rounded, 'Settings'),
    _NavItem(Icons.history_rounded, 'User Logs'),
  ];

  static const _pages = [
    AdminDashboardPage(),
    AdminUsersPage(),
    AdminMessPage(),
    AdminPaymentsPage(),
    AdminSubscriptionsPage(),
    AdminNotificationsPage(),
    AdminSuggestionsPage(),
    AdminSettingsPage(),
    AdminLogsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (mounted) {
      setState(() {
        _adminName = doc.data()?['name'] as String? ?? 'Admin';
        _adminRole = doc.data()?['role'] as String? ?? 'admin';
        _adminEmail = doc.data()?['email'] as String? ?? '';
      });
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'superAdmin':
        return 'Super Admin';
      case 'systemAdmin':
        return 'System Admin';
      case 'supportAdmin':
        return 'Support Admin';
      case 'contentAdmin':
        return 'Content Admin';
      case 'manager':
        return 'Super Admin';
      default:
        return 'Admin';
    }
  }

  void _openDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _DrawerContent(
              items: _navItems,
              selectedIndex: _selectedIndex,
              adminName: _adminName,
              adminRole: _roleLabel(_adminRole),
              onSelect: (i) {
                Navigator.pop(ctx);
                setState(() => _selectedIndex = i);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _TopBar(
            title: _navItems[_selectedIndex].label,
            adminName: _adminName,
            adminRole: _roleLabel(_adminRole),
            adminEmail: _adminEmail,
            onMenuTap: () => _openDrawer(context),
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// ─── Nav Item Model ────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ─── Drawer Content ────────────────────────────────────────────────────────
class _DrawerContent extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final String adminName;
  final String adminRole;
  final ValueChanged<int> onSelect;

  const _DrawerContent({
    required this.items,
    required this.selectedIndex,
    required this.adminName,
    required this.adminRole,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1A2035),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Logo + close
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Meal Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Admin info card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryGreen.withValues(
                        alpha: 0.3,
                      ),
                      child: Text(
                        adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adminName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              adminRole,
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NAVIGATION',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Nav items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final selected = i == selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onSelect(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryGreen.withValues(
                                      alpha: 0.2,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? Border.all(
                                      color: AppColors.primaryGreen.withValues(
                                        alpha: 0.35,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  items[i].icon,
                                  color: selected
                                      ? AppColors.primaryGreen
                                      : Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  items[i].label,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (selected) ...[
                                  const Spacer(),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Logout
              Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) context.go('/');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 14),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar ───────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final String adminName;
  final String adminRole;
  final String adminEmail;
  final VoidCallback onMenuTap;

  const _TopBar({
    required this.title,
    required this.adminName,
    required this.adminRole,
    required this.adminEmail,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Hamburger menu button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onMenuTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textDark,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Logo dot + title
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          // Notification bell
          Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textDark,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Profile chip
          PopupMenuButton<String>(
            offset: const Offset(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        adminRole,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ],
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: _menuRow(
                  Icons.person_outline_rounded,
                  'My Profile',
                  Colors.blue,
                ),
              ),
              PopupMenuItem(
                value: 'password',
                child: _menuRow(
                  Icons.lock_outline_rounded,
                  'Change Password',
                  Colors.orange,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: _menuRow(Icons.logout_rounded, 'Logout', Colors.red),
              ),
            ],
            onSelected: (val) async {
              if (val == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) context.go('/');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
