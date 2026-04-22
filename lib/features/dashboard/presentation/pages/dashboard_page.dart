import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/deletion_scheduler.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../transaction/presentation/pages/transaction_page.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../expense/presentation/pages/expense_entry_page.dart';
import '../../../withdraw/presentation/pages/withdraw_request_page.dart';
import '../../../reports/presentation/pages/reports_pdf_page.dart';
import '../../../menu/presentation/pages/mess_requests_page.dart';
import '../../../menu/presentation/pages/mess_settings_page.dart';
import '../../../menu/presentation/pages/menu_page.dart';
import '../../../deposit/presentation/pages/deposit_page.dart';
import '../widgets/ads_banner.dart';
import '../widgets/ads_config.dart';
import '../../../bazar/presentation/pages/bazar_schedule_page.dart';
import '../../../task/presentation/pages/task_schedule_page.dart';
import '../../../chat/services/chat_service.dart';
import '../../../../core/services/auto_meal_service.dart';

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
  double _messExpense = 0; // Bazar only (for meal rate)
  double _mealRate = 0;
  int _myMeals = 0;
  int _messMeals = 0;

  bool _invitationChecked = false;
  DateTime? _lastBackPressTime;

  // Today's schedule data
  double _todayMyMeals = 0;
  double _todayMessMeals = 0;
  int _todayMembersCount = 0;
  List<String> _todayBazarNames = [];
  List<String> _tomorrowBazarNames = [];
  List<Map<String, dynamic>> _todayTasks = [];
  List<Map<String, dynamic>> _tomorrowTasks = [];

  // Chat unread count
  int _chatUnreadCount = 0;

  // Pending requests count (invitations)
  int _pendingRequestCount = 0;

  // Real-time stream subscriptions
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = '${_monthName(now.month)} ${now.year}';
    // ignore: unawaited_futures
    DeletionScheduler.runIfNeeded();
    // ignore: unawaited_futures
    AutoMealService.runIfNeeded();
    _initRealtimeDashboard();
    _checkPendingInvitations();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
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

  Future<void> _initRealtimeDashboard() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      user ??= await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final messId = userDoc.data()?['messId'] as String? ?? '';
      if (messId.isEmpty) return;

      final uid = user.uid;
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // ── Mess info (one-time) ──────────────────────────────────────────────
      final messDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .get();
      if (mounted) {
        setState(() {
          _messName = messDoc.data()?['name'] as String? ?? '';
          _plan = messDoc.data()?['subscription'] as String? ?? 'free';
        });
      }

      // ── My balance (real-time) ────────────────────────────────────────────
      _subs.add(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('members')
            .doc(uid)
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              setState(() {
                _myBalance = (snap.data()?['balance'] as num?)?.toDouble() ?? 0;
              });
            }),
      );

      // ── Mess balance = sum of all active members' balances (real-time) ────
      _subs.add(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('members')
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              double messBal = 0;
              for (final m in snap.docs) {
                messBal += (m.data()['balance'] as num?)?.toDouble() ?? 0;
              }
              setState(() => _messBalance = messBal);
            }),
      );

      // ── Deposits (real-time) ──────────────────────────────────────────────
      _subs.add(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('transactions')
            .where('type', isEqualTo: 'deposit')
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              double myDep = 0, messDep = 0;
              for (final doc in snap.docs) {
                final d = doc.data();
                final ts = d['createdAt'] as Timestamp?;
                if (ts != null) {
                  final dt = ts.toDate();
                  final key =
                      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
                  if (key != monthKey) continue;
                }
                final amt = (d['amount'] as num?)?.toDouble() ?? 0;
                messDep += amt;
                if (d['memberId'] == uid) myDep += amt;
              }
              setState(() {
                _myDeposit = myDep;
                _messDeposit = messDep;
              });
            }),
      );

      // ── Expenses (real-time) — Bazar only for meal rate ───────────────────
      _subs.add(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('expenses')
            .where('monthKey', isEqualTo: monthKey)
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              double myExp = 0, bazarExp = 0;
              for (final doc in snap.docs) {
                final d = doc.data();
                final amt = (d['amount'] as num?)?.toDouble() ?? 0;
                final cat = (d['category'] as String? ?? '').toLowerCase();
                // Only Bazar expenses count toward meal rate
                if (cat.contains('bazar') || cat.contains('daily')) {
                  bazarExp += amt;
                }
                if (d['submittedBy'] == uid) myExp += amt;
              }
              setState(() {
                _myExpense = myExp;
                _messExpense = bazarExp; // only bazar for meal rate
              });
              _recalcMealRate();
            }),
      );

      // ── Meals (real-time) ─────────────────────────────────────────────────
      _subs.add(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('meals')
            .where('monthKey', isEqualTo: monthKey)
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              int myMeals = 0, messMeals = 0;
              for (final doc in snap.docs) {
                final d = doc.data();
                final count = (d['count'] as num?)?.toInt() ?? 1;
                messMeals += count;
                if (d['memberId'] == uid) myMeals += count;
              }
              setState(() {
                _myMeals = myMeals;
                _messMeals = messMeals;
              });
              _recalcMealRate();
            }),
      );

      // ── Today's meals (real-time) ─────────────────────────────────────────
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _subs.add(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('meals')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(now.year, now.month, now.day),
              ),
            )
            .where(
              'date',
              isLessThan: Timestamp.fromDate(
                DateTime(now.year, now.month, now.day + 1),
              ),
            )
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              double myT = 0, messT = 0;
              final memberSet = <String>{};
              for (final doc in snap.docs) {
                final d = doc.data();
                final count = (d['count'] as num?)?.toDouble() ?? 1.0;
                messT += count;
                memberSet.add(d['memberId'] as String? ?? '');
                if (d['memberId'] == uid) myT += count;
              }
              setState(() {
                _todayMyMeals = myT;
                _todayMessMeals = messT;
                _todayMembersCount = memberSet.length;
              });
            }),
      );

      // ── Bazar schedule (real-time) ────────────────────────────────────────
      _subs.add(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              final rawSchedule = List<Map<String, dynamic>>.from(
                (snap.data()?['bazarScheduleDetailed'] as List<dynamic>? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map)),
              );
              final tomorrow = now.add(const Duration(days: 1));
              final tomorrowStr =
                  '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

              final todayEntry = rawSchedule.firstWhere(
                (e) => e['date'] == todayStr,
                orElse: () => {},
              );
              final tomorrowEntry = rawSchedule.firstWhere(
                (e) => e['date'] == tomorrowStr,
                orElse: () => {},
              );

              setState(() {
                _todayBazarNames = [];
                _tomorrowBazarNames = [];
              });

              // Resolve member names
              _resolveBazarNames(messId, todayEntry, tomorrowEntry);
            }),
      );

      // ── Task schedule (real-time) ─────────────────────────────────────────
      final tomorrow = now.add(const Duration(days: 1));
      _subs.add(
        FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('taskSchedule')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(now.year, now.month, now.day),
              ),
            )
            .where(
              'date',
              isLessThan: Timestamp.fromDate(
                DateTime(tomorrow.year, tomorrow.month, tomorrow.day + 1),
              ),
            )
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              final todayTasks = <Map<String, dynamic>>[];
              final tomorrowTasks = <Map<String, dynamic>>[];
              for (final doc in snap.docs) {
                final d = doc.data();
                final date = (d['date'] as Timestamp).toDate();
                final entry = {
                  'taskName': d['taskName'] ?? '',
                  'memberName': d['memberName'] ?? '',
                  'isCompleted': d['isCompleted'] ?? false,
                };
                if (date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day) {
                  todayTasks.add(entry);
                } else {
                  tomorrowTasks.add(entry);
                }
              }
              setState(() {
                _todayTasks = todayTasks;
                _tomorrowTasks = tomorrowTasks;
              });
            }),
      );

      // ── Chat unread count (real-time) ─────────────────────────────────────
      _subs.add(
        ChatService().unreadCountStream(messId, uid).listen((count) {
          if (!mounted) return;
          setState(() => _chatUnreadCount = count);
        }),
      );

      // ── Pending requests count (real-time) ────────────────────────────────
      _subs.add(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('invitations')
            .where('status', isEqualTo: 'pending')
            .snapshots()
            .listen((snap) {
              if (!mounted) return;
              setState(() => _pendingRequestCount = snap.docs.length);
            }),
      );
    } catch (_) {}
  }

  Future<void> _resolveBazarNames(
    String messId,
    Map<String, dynamic> todayEntry,
    Map<String, dynamic> tomorrowEntry,
  ) async {
    try {
      final membersSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('members')
          .get();
      final nameMap = {
        for (final d in membersSnap.docs)
          d.id: d.data()['name'] as String? ?? '',
      };
      if (!mounted) return;
      setState(() {
        _todayBazarNames = (todayEntry['memberIds'] as List<dynamic>? ?? [])
            .map((id) => nameMap[id as String] ?? id.toString())
            .toList();
        _tomorrowBazarNames =
            (tomorrowEntry['memberIds'] as List<dynamic>? ?? [])
                .map((id) => nameMap[id as String] ?? id.toString())
                .toList();
      });
    } catch (_) {}
  }

  void _recalcMealRate() {
    if (_messMeals > 0) {
      setState(() => _mealRate = _messExpense / _messMeals);
    } else {
      setState(() => _mealRate = 0);
    }
  }

  // Keep for compatibility (called from invitation accept)
  Future<void> _loadDashboardData() async {
    // Cancel existing subs and reinitialize
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    await _initRealtimeDashboard();
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                // Ads Banner - 320x50 standard size
                const AdsBanner(
                  height: AdsConfig.bannerHeight320x50,
                  autoScrollDuration: AdsConfig.autoScrollDuration,
                ),
                const SizedBox(height: 16),
                _buildTodaysMealCard(),
                const SizedBox(height: 12),
                _buildBazarScheduleCard(),
                const SizedBox(height: 12),
                _buildTaskScheduleCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      automaticallyImplyLeading: false,
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mess name + plan badge + month selector
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _messName.isEmpty ? 'My Mess' : _messName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _plan.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Month dropdown
                        GestureDetector(
                          onTap: () => _showMonthPicker(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _displayMonth,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 2 icons: Language + Notification
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.language, size: 22),
                        color: Colors.white,
                        onPressed: () {},
                        tooltip: 'Language',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          size: 22,
                        ),
                        color: Colors.white,
                        onPressed: () {},
                        tooltip: 'Notifications',
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

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    // Build last 6 months list
    final months = <Map<String, dynamic>>[];
    for (int i = 0; i < 6; i++) {
      final dt = DateTime(now.year, now.month - i);
      final key = i == 0
          ? null
          : '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      final label = '${_monthName(dt.month)} ${dt.year}';
      months.add({'key': key, 'label': label});
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select Month',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...months.map((m) {
            final isSelected = _selectedMonthKey == m['key'];
            return ListTile(
              leading: Icon(
                Icons.calendar_month_rounded,
                color: isSelected ? AppColors.primaryGreen : Colors.grey,
              ),
              title: Text(
                m['label'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.textDark,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primaryGreen)
                  : null,
              onTap: () {
                setState(() => _selectedMonthKey = m['key'] as String?);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
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
                  'Meals',
                  '${_selectedTab == 'My' ? _myMeals : _messMeals}',
                  Icons.fastfood,
                  Colors.orange,
                  const Color(0xFFFFF3E0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Meal Rate',
                  '৳ ${_mealRate.toStringAsFixed(2)}',
                  Icons.restaurant,
                  Colors.grey.shade600,
                  const Color(0xFFF5F5F5),
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
                  'Meal',
                  Icons.restaurant_rounded,
                  AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Members',
                  Icons.people_rounded,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Mess Requests',
                  Icons.mark_email_unread_rounded,
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Reports',
                  Icons.assessment_rounded,
                  Colors.deepPurple,
                ),
              ),
              Expanded(
                child: _buildActionButton(
                  'Mess Setting',
                  Icons.settings_rounded,
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
      case 'Members':
        setState(() => _selectedIndex = 0);
        break;
      case 'Meal':
        setState(() => _selectedIndex = 0);
        break;
      case 'Mess Requests':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessRequestsPage()),
        );
        break;
      case 'Mess Setting':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessSettingsPage()),
        );
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

  Widget _buildTodaysMealCard() {
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
          // Header with arrow link
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Today's Meals",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _onActionTap('Meal'),
                child: Row(
                  children: [
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryGreen,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              _mealStatChip(
                'My',
                _todayMyMeals == 0
                    ? '0'
                    : _todayMyMeals % 1 == 0
                    ? _todayMyMeals.toInt().toString()
                    : _todayMyMeals.toString(),
                'meals',
                AppColors.primaryGreen,
              ),
              const SizedBox(width: 10),
              _mealStatChip(
                'Mess',
                _todayMessMeals == 0
                    ? '0'
                    : _todayMessMeals % 1 == 0
                    ? _todayMessMeals.toInt().toString()
                    : _todayMessMeals.toString(),
                'meals',
                Colors.blue,
              ),
              const SizedBox(width: 10),
              _mealStatChip(
                'Members',
                '$_todayMembersCount',
                'persons',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mealStatChip(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBazarScheduleCard() {
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
          // Header with arrow link
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  color: Colors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Bazar Schedule',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BazarSchedulePage()),
                ),
                child: const Row(
                  children: [
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Today row
          _scheduleRow(
            'Today',
            _todayBazarNames.isEmpty ? null : _todayBazarNames.join(', '),
            Colors.orange,
          ),
          const SizedBox(height: 8),
          // Tomorrow row
          _scheduleRow(
            'Tomorrow',
            _tomorrowBazarNames.isEmpty ? null : _tomorrowBazarNames.join(', '),
            Colors.orange.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskScheduleCard() {
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
          // Header with arrow link
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Colors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Task Schedule',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskSchedulePage()),
                ),
                child: const Row(
                  children: [
                    Text(
                      'View',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.teal,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Today tasks
          _taskRow('Today', _todayTasks),
          if (_tomorrowTasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            _taskRow('Tomorrow', _tomorrowTasks),
          ],
        ],
      ),
    );
  }

  Widget _scheduleRow(String label, String? names, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            names ?? 'Not assigned',
            style: TextStyle(
              fontSize: 13,
              fontWeight: names != null ? FontWeight.w600 : FontWeight.normal,
              color: names != null ? color : Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _taskRow(String label, List<Map<String, dynamic>> tasks) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Text(
                  'No tasks',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasks.map((t) {
                    final done = t['isCompleted'] as bool? ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Icon(
                            done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color: done ? Colors.teal : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${t['taskName']} · ${t['memberName']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: done
                                    ? Colors.grey.shade400
                                    : AppColors.textDark,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
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
              _buildNavItem(
                3,
                Icons.chat_bubble_outline_rounded,
                'Chat',
                badge: _chatUnreadCount,
              ),
              _buildNavItem(
                4,
                Icons.person_outline_rounded,
                'Profile',
                badge: _pendingRequestCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    int badge = 0,
  }) {
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.grey.shade400,
                ),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
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
