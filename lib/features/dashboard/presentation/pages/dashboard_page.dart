import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/deletion_scheduler.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../transaction/presentation/pages/transaction_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../expense/presentation/pages/expense_entry_page.dart';
import '../../../withdraw/presentation/pages/withdraw_request_page.dart';
import '../../../reports/presentation/pages/reports_pdf_page.dart';
import '../../../menu/presentation/pages/mess_settings_page.dart';
import '../../../menu/presentation/pages/menu_page.dart';
import '../../../deposit/presentation/pages/deposit_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 2;
  String _selectedTab = 'My';
  String _messName = '';
  String _plan = 'free';
  String _currentMonth = '';

  /// null = use running month from ActiveMonthService
  /// non-null = user has switched to this month (format: "YYYY-MM")
  String? _selectedMonthKey;

  // Real data from Firestore
  double _myBalance = 0;
  double _messBalance = 0;
  double _myDeposit = 0;
  double _myExpense = 0;
  double _messDeposit = 0;
  double _messExpense = 0;
  double _mealRate = 0;
  int _myMeals = 0;
  int _messMeals = 0;

  bool _invitationChecked = false;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = '${_monthName(now.month)} ${now.year}';
    // ignore: unawaited_futures
    DeletionScheduler.runIfNeeded();
    _loadDashboardData();
    _checkPendingInvitations();
  }

  Future<void> _checkPendingInvitations() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('invitations')
          .where('status', isEqualTo: 'pending')
          .get();
      if (snap.docs.isEmpty || !mounted || _invitationChecked) return;
      _invitationChecked = true;
      // Show popup for first pending invitation
      final inv = {...snap.docs.first.data(), 'id': snap.docs.first.id};
      _showInvitationPopup(inv);
    } catch (_) {}
  }

  void _showInvitationPopup(Map<String, dynamic> inv) {
    final messName = inv['messName'] as String? ?? 'Unknown Mess';
    final managerName = inv['managerName'] as String? ?? 'Manager';
    final invId = inv['id'] as String? ?? '';
    final messId = inv['messId'] as String? ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mail_rounded,
                color: AppColors.primaryGreen,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mess Invitation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'You have got an invitation to join "$messName" from the manager $managerName',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _rejectInvitation(invId, messId);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _acceptInvitation(inv);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'JOIN',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(Map<String, dynamic> inv) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final messId = inv['messId'] as String? ?? '';
    final invId = inv['id'] as String? ?? '';
    final memberName = inv['memberName'] as String? ?? '';
    final memberPhone = inv['memberPhone'] as String? ?? '';
    final initialBalance = (inv['initialBalance'] as num?)?.toDouble() ?? 0;

    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('members')
            .doc(uid),
        {
          'name': memberName,
          'phone': memberPhone,
          'balance': initialBalance,
          'isActive': true,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('invitations')
            .doc(invId),
        {'status': 'accepted'},
      );

      // Update user's messIds
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final existing = List<String>.from(
        userDoc.data()?['messIds'] as List? ?? [],
      );
      if (!existing.contains(messId)) existing.add(messId);
      batch.update(FirebaseFirestore.instance.collection('users').doc(uid), {
        'messIds': existing,
        'messId': messId,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined mess successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvitation(String invId, String messId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('invitations')
          .doc(invId)
          .update({'status': 'rejected'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation rejected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  String _monthName(int m) => const [
    '',
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
  ][m];

  /// Returns the display label for the currently selected month.
  /// If _selectedMonthKey is null, shows _currentMonth (running month label).
  String get _displayMonth {
    if (_selectedMonthKey == null) return _currentMonth;
    final parts = _selectedMonthKey!.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return '${_monthName(month)} $year';
  }

  void _switchToPreviousMonth() {
    setState(() {
      if (_selectedMonthKey == null) {
        // Start from current month and go back one
        final now = DateTime.now();
        final prev = DateTime(now.year, now.month - 1);
        _selectedMonthKey =
            '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
      } else {
        final parts = _selectedMonthKey!.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final prev = DateTime(year, month - 1);
        _selectedMonthKey =
            '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
      }
    });
  }

  void _switchToNextMonth() {
    setState(() {
      if (_selectedMonthKey == null) return;
      final parts = _selectedMonthKey!.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final now = DateTime.now();
      final currentKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      // Don't go beyond current calendar month
      if (_selectedMonthKey == currentKey) {
        _selectedMonthKey = null; // back to running month
        return;
      }
      final next = DateTime(year, month + 1);
      final nextKey = '${next.year}-${next.month.toString().padLeft(2, '0')}';
      // If next month reaches current month, reset to null (running month)
      if (nextKey == currentKey) {
        _selectedMonthKey = null;
      } else {
        _selectedMonthKey = nextKey;
      }
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
      }
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final messId = userDoc.data()?['messId'] as String? ?? '';
      if (messId.isEmpty) return;

      final messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .get();
      final messData = messDoc.data() ?? {};

      // Current month key e.g. "2026-03"
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // My balance from messes/{messId}/members/{uid}
      final memberDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('members')
          .doc(user.uid)
          .get();
      final myBal = (memberDoc.data()?['balance'] as num?)?.toDouble() ?? 0;

      // Mess balance = sum of all members' balances
      double messBal = 0;
      final allMembersSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('members')
          .get();
      for (final m in allMembersSnap.docs) {
        messBal += (m.data()['balance'] as num?)?.toDouble() ?? 0;
      }

      double myDep = 0, messDep = 0;
      double myExp = 0, messExp = 0;
      int myMeals = 0, messMeals = 0;
      double mealRate = 0;

      // Deposits: from messes/{messId}/transactions where type=='deposit'
      // Filter by month from createdAt in-memory (avoid composite index)
      final txSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('transactions')
          .where('type', isEqualTo: 'deposit')
          .get();
      for (final d in txSnap.docs) {
        final data = d.data();
        final createdAt = data['createdAt'];
        if (createdAt != null) {
          final dt = (createdAt as Timestamp).toDate();
          final docMonth = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          if (docMonth != monthKey) continue;
        }
        final amt = (data['amount'] as num?)?.toDouble() ?? 0;
        messDep += amt;
        if (data['memberId'] == user.uid) myDep += amt;
      }

      // Expenses: from messes/{messId}/expenses with monthKey
      final expSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('expenses')
          .where('monthKey', isEqualTo: monthKey)
          .get();
      for (final d in expSnap.docs) {
        final amt = (d.data()['amount'] as num?)?.toDouble() ?? 0;
        messExp += amt;
        if (d.data()['submittedBy'] == user.uid) myExp += amt;
      }

      // Meals: from messes/{messId}/meals with monthKey
      final mealSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .where('monthKey', isEqualTo: monthKey)
          .get();
      for (final d in mealSnap.docs) {
        final count = (d.data()['count'] as num?)?.toDouble() ?? 1.0;
        messMeals += count.toInt();
        if (d.data()['memberId'] == user.uid) myMeals += count.toInt();
      }

      // Meal rate = total expense / total meals
      if (messMeals > 0) mealRate = messExp / messMeals;

      if (mounted) {
        setState(() {
          _messName = messData['name'] as String? ?? '';
          _plan = messData['subscription'] as String? ?? 'free';
          _myBalance = myBal;
          _messBalance = messBal;
          _myDeposit = myDep;
          _myExpense = myExp;
          _messDeposit = messDep;
          _messExpense = messExp;
          _mealRate = mealRate;
          _myMeals = myMeals;
          _messMeals = messMeals;
        });
      }
    } catch (_) {}
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Press back again to exit app'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MenuPage(),
      const TransactionPage(),
      _buildHomePage(),
      const ChatPage(),
      const ProfilePage(),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        body: pages[_selectedIndex],
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 16),
                _buildMonthlyOverview(),
                const SizedBox(height: 16),
                _buildQuickActions(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTodaysMeal()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildBazarSchedule()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryGreen, AppColors.buttonGreen],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _messName.isEmpty ? 'My Mess' : _messName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _plan.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _switchToPreviousMonth,
                                  child: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _displayMonth,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                GestureDetector(
                                  onTap: _selectedMonthKey == null
                                      ? null
                                      : _switchToNextMonth,
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: _selectedMonthKey == null
                                        ? Colors.white30
                                        : Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.language, size: 22),
                            color: Colors.white,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              size: 22,
                            ),
                            color: Colors.white,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, size: 22),
                            color: Colors.white,
                            tooltip: 'Mess Settings',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MessSettingsPage(),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.account_circle_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                            tooltip: 'Profile',
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfilePage(),
                                  ),
                                );
                              } else if (value == 'logout') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Logout'),
                                    content: const Text(
                                      'Are you sure you want to logout?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Logout',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseAuth.instance.signOut();
                                  if (context.mounted) {
                                    context.go('/');
                                  }
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: AppColors.primaryGreen,
                                    ),
                                    SizedBox(width: 10),
                                    Text('Profile'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '৳${_myBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mess Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '৳ ${_messBalance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  _buildTabButton('My'),
                  const SizedBox(width: 8),
                  _buildTabButton('Mess'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Deposit',
                  '৳ ${_selectedTab == 'My' ? _myDeposit.toStringAsFixed(0) : _messDeposit.toStringAsFixed(0)}',
                  Icons.arrow_downward,
                  Colors.green,
                  const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Expense',
                  '৳ ${_selectedTab == 'My' ? _myExpense.toStringAsFixed(0) : _messExpense.toStringAsFixed(0)}',
                  Icons.arrow_upward,
                  Colors.red,
                  const Color(0xFFFFEBEE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Meal Rate',
                  '৳ ${_mealRate.toStringAsFixed(1)}',
                  Icons.restaurant,
                  Colors.grey.shade600,
                  const Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Meals',
                  '${_selectedTab == 'My' ? _myMeals : _messMeals}',
                  Icons.fastfood,
                  Colors.orange,
                  const Color(0xFFFFF3E0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Deposit',
                  Icons.add_circle_rounded,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Expense',
                  Icons.remove_circle_rounded,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Withdraw',
                  Icons.account_balance_wallet_rounded,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Members',
                  Icons.people_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Reports',
                  Icons.assessment_rounded,
                  Colors.deepPurple,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Meal',
                  Icons.restaurant_rounded,
                  AppColors.primaryGreen,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Transaction',
                  Icons.receipt_long_rounded,
                  Colors.indigo,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Menu',
                  Icons.grid_view_rounded,
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onActionTap(String label) async {
    switch (label) {
      case 'Deposit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DepositPage(selectedMonthKey: _selectedMonthKey),
          ),
        );
        _loadDashboardData();
        break;
      case 'Expense':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ExpenseEntryPage(selectedMonthKey: _selectedMonthKey),
          ),
        );
        _loadDashboardData();
        break;
      case 'Withdraw':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WithdrawRequestPage(selectedMonthKey: _selectedMonthKey),
          ),
        );
        _loadDashboardData();
        break;
      case 'Reports':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsPdfPage()),
        );
        break;
      case 'Menu':
        setState(() => _selectedIndex = 0);
        break;
      case 'Members':
        // Members no longer a footer tab — no-op
        break;
      case 'Meal':
        // Meal no longer a footer tab — no-op
        break;
      case 'Transaction':
        setState(() => _selectedIndex = 1);
        break;
    }
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _onActionTap(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
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

  Widget _buildTodaysMeal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: AppColors.primaryGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Today's Meals",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_myMeals == 0)
            Text(
              'No meals recorded today',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            )
          else ...[
            _buildMealRow(
              'This Month',
              '$_myMeals meals',
              Icons.free_breakfast,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealRow(String meal, String count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            meal,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildBazarSchedule() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Bazar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'No schedule set',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            'Set up in Mess Settings',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, 'Menu'),
              _buildNavItem(1, Icons.receipt_long, 'Transaction'),
              _buildNavItem(2, Icons.home_rounded, 'Home'),
              _buildNavItem(3, Icons.chat_bubble_outline_rounded, 'Chat'),
              _buildNavItem(4, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primaryGreen : Colors.grey.shade400,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppColors.primaryGreen
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
