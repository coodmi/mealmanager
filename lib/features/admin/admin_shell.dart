import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _sidebarCollapsed = false;
  String _adminName = '';
  String _adminRole = '';
  String _adminEmail = '';

  final List<_NavItem> _navItems = [
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

  final List<Widget> _pages = const [
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          _Sidebar(
            items: _navItems,
            selectedIndex: _selectedIndex,
            collapsed: !isWide || _sidebarCollapsed,
            adminName: _adminName,
            adminRole: _roleLabel(_adminRole),
            onSelect: (i) => setState(() => _selectedIndex = i),
            onToggle: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: _navItems[_selectedIndex].label,
                  adminName: _adminName,
                  adminRole: _roleLabel(_adminRole),
                  adminEmail: _adminEmail,
                  onMenuTap: () =>
                      setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                ),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
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

// ─── Sidebar ───────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool collapsed;
  final String adminName;
  final String adminRole;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.collapsed,
    required this.adminName,
    required this.adminRole,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final w = collapsed ? 64.0 : 220.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: w,
      color: const Color(0xFF1A2035),
      child: Column(
        children: [
          // Logo area
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Meal Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Admin info
          if (!collapsed)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryGreen.withValues(
                      alpha: 0.3,
                    ),
                    child: Text(
                      adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          adminRole,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (!collapsed) const Divider(color: Colors.white12, height: 1),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final selected = i == selectedIndex;
                return Tooltip(
                  message: collapsed ? items[i].label : '',
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: collapsed ? 12 : 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryGreen.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.4,
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
                          if (!collapsed) ...[
                            const SizedBox(width: 12),
                            Text(
                              items[i].label,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Collapse toggle
          InkWell(
            onTap: onToggle,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Icon(
                collapsed ? Icons.chevron_right : Icons.chevron_left,
                color: Colors.white38,
              ),
            ),
          ),
        ],
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: onMenuTap,
            color: AppColors.textDark,
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
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textDark,
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Profile menu
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryGreen.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      adminRole,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textLight,
                ),
              ],
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: _menuItem(Icons.person_outline, 'My Profile'),
              ),
              PopupMenuItem(
                value: 'password',
                child: _menuItem(Icons.lock_outline, 'Change Password'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: _menuItem(Icons.logout, 'Logout', color: Colors.red),
              ),
            ],
            onSelected: (val) async {
              if (val == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted)
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textDark),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color ?? AppColors.textDark, fontSize: 13),
        ),
      ],
    );
  }
}
