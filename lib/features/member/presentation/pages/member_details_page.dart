import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_mess_service.dart';
import '../../../../core/utils/permission_utils.dart';

class MemberDetailsPage extends StatefulWidget {
  final String memberId;
  final String memberName;

  const MemberDetailsPage({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;

  // Member data
  double _balance = 0;
  String _phone = '';
  String _joinedDate = '';

  // Meal summary
  int _totalMeals = 0;
  int _breakfastCount = 0;
  int _lunchCount = 0;
  int _dinnerCount = 0;

  // Transaction summary
  double _totalDeposit = 0;
  double _totalExpense = 0;
  double _totalWithdraw = 0;

  // Lists
  List<Map<String, dynamic>> _meals = [];
  List<Map<String, dynamic>> _transactions = [];

  // Default meal preferences (for auto mode)
  bool _defaultBreakfast = true;
  bool _defaultLunch = true;
  bool _defaultDinner = true;
  bool _isManager = false;
  String _messId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = next);
    _loadData();
  }

  String get _monthLabel {
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
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final messId = await FirebaseMessService.getMessId();
      if (messId.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Check if current user is manager
      final isManager = await FirebaseMessService.isManager();

      // Member doc
      final memberDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('members')
          .doc(widget.memberId)
          .get();
      final mData = memberDoc.data() ?? {};

      // Default meal preferences
      final defaultMeals = mData['defaultMeals'] as Map<String, dynamic>? ?? {};
      final defBreakfast = defaultMeals['breakfast'] as bool? ?? true;
      final defLunch = defaultMeals['lunch'] as bool? ?? true;
      final defDinner = defaultMeals['dinner'] as bool? ?? true;

      // Joined date
      final joinedTs = mData['joinedAt'] as Timestamp?;
      final joinedStr = joinedTs != null
          ? DateFormat('dd-MMM-yyyy').format(joinedTs.toDate())
          : '';

      // Meals this month
      final mealsSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .where('memberId', isEqualTo: widget.memberId)
          .where('monthKey', isEqualTo: _monthKey)
          .get();

      // Transactions (deposits + withdrawals)
      final txSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('transactions')
          .where('memberId', isEqualTo: widget.memberId)
          .get();

      // Withdrawals
      final wdSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('withdrawals')
          .where('memberId', isEqualTo: widget.memberId)
          .where('monthKey', isEqualTo: _monthKey)
          .get();

      // Expenses
      final expSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('expenses')
          .where('monthKey', isEqualTo: _monthKey)
          .get();

      // ── Process meals ──────────────────────────────────────────────────────
      int breakfast = 0, lunch = 0, dinner = 0, totalMeals = 0;
      final mealsByDate = <String, Map<String, dynamic>>{};

      for (final d in mealsSnap.docs) {
        final data = d.data();
        final dateTs = data['date'] as Timestamp?;
        if (dateTs == null) continue;
        final dateStr = DateFormat('yyyy-MM-dd').format(dateTs.toDate());
        mealsByDate.putIfAbsent(
          dateStr,
          () => {
            'date': dateStr,
            'breakfast': 0,
            'lunch': 0,
            'dinner': 0,
            'total': 0,
          },
        );
        final mealType = (data['mealType'] as String? ?? '').toLowerCase();
        final count = (data['count'] as num?)?.toInt() ?? 1;
        if (mealType == 'breakfast') {
          mealsByDate[dateStr]!['breakfast'] =
              (mealsByDate[dateStr]!['breakfast'] as int) + count;
          breakfast += count;
        } else if (mealType == 'lunch') {
          mealsByDate[dateStr]!['lunch'] =
              (mealsByDate[dateStr]!['lunch'] as int) + count;
          lunch += count;
        } else if (mealType == 'dinner') {
          mealsByDate[dateStr]!['dinner'] =
              (mealsByDate[dateStr]!['dinner'] as int) + count;
          dinner += count;
        }
        mealsByDate[dateStr]!['total'] =
            (mealsByDate[dateStr]!['total'] as int) + count;
        totalMeals += count;
      }

      final mealList = mealsByDate.values.toList()
        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      // ── Process transactions ───────────────────────────────────────────────
      double totalDeposit = 0, totalExpense = 0, totalWithdraw = 0;
      final txList = <Map<String, dynamic>>[];

      for (final d in txSnap.docs) {
        final data = d.data();
        final ts = data['createdAt'] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          if (key != _monthKey) continue;
        }
        final amt = (data['amount'] as num?)?.toDouble() ?? 0;
        totalDeposit += amt;
        txList.add({
          'type': 'Deposit',
          'amount': amt,
          'note': data['method'] ?? 'Cash',
          'date': data['createdAt'],
          'color': Colors.green,
          'icon': Icons.arrow_downward_rounded,
        });
      }

      for (final d in wdSnap.docs) {
        final data = d.data();
        final amt = (data['amount'] as num?)?.toDouble() ?? 0;
        final status = data['status'] as String? ?? 'pending';
        totalWithdraw += amt;
        txList.add({
          'type': 'Withdraw',
          'amount': -amt,
          'note': status == 'approved' ? 'Approved' : 'Pending',
          'date': data['createdAt'],
          'color': Colors.orange,
          'icon': Icons.arrow_upward_rounded,
        });
      }

      for (final d in expSnap.docs) {
        final data = d.data();
        final memberIds = List<String>.from(data['memberIds'] ?? []);
        if (memberIds.contains(widget.memberId) || memberIds.isEmpty) {
          final amt = (data['amount'] as num?)?.toDouble() ?? 0;
          final share = memberIds.isNotEmpty ? amt / memberIds.length : amt;
          totalExpense += share;
          txList.add({
            'type': 'Expense',
            'amount': -share,
            'note': data['category'] ?? 'Expense',
            'date': data['createdAt'],
            'color': Colors.red,
            'icon': Icons.remove_circle_outline_rounded,
          });
        }
      }

      txList.sort((a, b) {
        final aDate = a['date'] as Timestamp?;
        final bDate = b['date'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _messId = messId;
          _isManager = isManager;
          _balance = (mData['balance'] as num?)?.toDouble() ?? 0;
          _phone = mData['phone'] as String? ?? '';
          _joinedDate = joinedStr;
          _totalMeals = totalMeals;
          _breakfastCount = breakfast;
          _lunchCount = lunch;
          _dinnerCount = dinner;
          _totalDeposit = totalDeposit;
          _totalExpense = totalExpense;
          _totalWithdraw = totalWithdraw;
          _meals = mealList;
          _transactions = txList;
          _defaultBreakfast = defBreakfast;
          _defaultLunch = defLunch;
          _defaultDinner = defDinner;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMonthSwitcher(),
                        const SizedBox(height: 12),
                        _buildDefaultMealCard(),
                        const SizedBox(height: 12),
                        _buildMealSummaryCard(),
                        const SizedBox(height: 12),
                        _buildTransactionSummaryCard(),
                        const SizedBox(height: 12),
                        _buildTabSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.buttonGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar row
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Member Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Member info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      widget.memberName.isNotEmpty
                          ? widget.memberName[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.memberName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        if (_joinedDate.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Joined Mess: $_joinedDate',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Balance chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '৳${_balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _balance >= 0
                                ? Colors.white
                                : Colors.red.shade200,
                          ),
                        ),
                        const Text(
                          'Balance',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSwitcher() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _prevMonth,
            ),
            Expanded(
              child: Text(
                _monthLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: isCurrentMonth ? Colors.white38 : Colors.white,
              ),
              onPressed: isCurrentMonth ? null : _nextMonth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
            _sectionHeader('Meal Summary', Icons.restaurant_rounded),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Total
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: AppColors.primaryGreen,
                      value: '$_totalMeals',
                      label: 'Total',
                      isTotal: true,
                    ),
                  ),
                  _vDivider(),
                  // Breakfast
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.free_breakfast_rounded,
                      iconColor: Colors.orange,
                      value: '$_breakfastCount',
                      label: 'Breakfast',
                    ),
                  ),
                  _vDivider(),
                  // Lunch
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.lunch_dining_rounded,
                      iconColor: Colors.blue,
                      value: '$_lunchCount',
                      label: 'Lunch',
                    ),
                  ),
                  _vDivider(),
                  // Dinner
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.dinner_dining_rounded,
                      iconColor: Colors.purple,
                      value: '$_dinnerCount',
                      label: 'Dinner',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummaryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
            _sectionHeader(
              'Transaction Summary',
              Icons.account_balance_wallet_rounded,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Balance
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: _balance >= 0
                          ? AppColors.primaryGreen
                          : Colors.red,
                      value: '৳${_balance.toStringAsFixed(0)}',
                      label: 'Balance',
                      isTotal: true,
                    ),
                  ),
                  _vDivider(),
                  // Deposit
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.arrow_downward_rounded,
                      iconColor: Colors.green,
                      value: '৳${_totalDeposit.toStringAsFixed(0)}',
                      label: 'Deposit',
                    ),
                  ),
                  _vDivider(),
                  // Expense
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.remove_circle_outline_rounded,
                      iconColor: Colors.red,
                      value: '৳${_totalExpense.toStringAsFixed(0)}',
                      label: 'Expense',
                    ),
                  ),
                  _vDivider(),
                  // Withdraw
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.arrow_upward_rounded,
                      iconColor: Colors.orange,
                      value: '৳${_totalWithdraw.toStringAsFixed(0)}',
                      label: 'Withdraw',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isTotal = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primaryGreen : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 50, color: Colors.grey.shade200);

  Widget _buildTabSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryGreen,
                indicatorWeight: 3,
                labelColor: AppColors.primaryGreen,
                unselectedLabelColor: AppColors.textLight,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Meal History'),
                  Tab(text: 'Transactions'),
                ],
              ),
            ),
            // Tab content (fixed height)
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [_buildMealHistoryTab(), _buildTransactionTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealHistoryTab() {
    if (_meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No meals recorded this month',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _meals.length,
      itemBuilder: (context, index) {
        final day = _meals[index];
        final date = DateTime.parse(day['date'] as String);
        final breakfast = day['breakfast'] as int;
        final lunch = day['lunch'] as int;
        final dinner = day['dinner'] as int;
        final total = day['total'] as int;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(date),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$total meal${total != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _mealBadge(
                    'Breakfast',
                    breakfast,
                    Icons.free_breakfast_rounded,
                    Colors.orange,
                  ),
                  _mealBadge(
                    'Lunch',
                    lunch,
                    Icons.lunch_dining_rounded,
                    Colors.blue,
                  ),
                  _mealBadge(
                    'Dinner',
                    dinner,
                    Icons.dinner_dining_rounded,
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mealBadge(String label, int count, IconData icon, Color color) {
    final active = count > 0;
    return Column(
      children: [
        Icon(icon, color: active ? color : Colors.grey.shade300, size: 22),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? color : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 28,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active ? color : Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultMealCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
            _sectionHeader('Default Meal (Auto Mode)', Icons.auto_mode),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Text(
                    'When Auto mode is on, meals are added daily based on these defaults.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  _mealToggleRow(
                    'Breakfast',
                    Icons.free_breakfast_rounded,
                    Colors.orange,
                    _defaultBreakfast,
                    (v) => _updateDefaultMeal('breakfast', v),
                  ),
                  _mealToggleRow(
                    'Lunch',
                    Icons.lunch_dining_rounded,
                    Colors.blue,
                    _defaultLunch,
                    (v) => _updateDefaultMeal('lunch', v),
                  ),
                  _mealToggleRow(
                    'Dinner',
                    Icons.dinner_dining_rounded,
                    Colors.purple,
                    _defaultDinner,
                    (v) => _updateDefaultMeal('dinner', v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealToggleRow(
    String label,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Switch(
          value: value,
          onChanged: _isManager ? onChanged : null,
          activeColor: AppColors.primaryGreen,
        ),
      ],
    );
  }

  Future<void> _updateDefaultMeal(String mealType, bool value) async {
    if (!_isManager) {
      showNoPermissionSnack(context);
      return;
    }
    setState(() {
      if (mealType == 'breakfast') _defaultBreakfast = value;
      if (mealType == 'lunch') _defaultLunch = value;
      if (mealType == 'dinner') _defaultDinner = value;
    });
    try {
      await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('members')
          .doc(widget.memberId)
          .update({
            'defaultMeals': {
              'breakfast': _defaultBreakfast,
              'lunch': _defaultLunch,
              'dinner': _defaultDinner,
            },
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Default $mealType ${value ? 'enabled' : 'disabled'}',
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTransactionTab() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions this month',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isPositive = (tx['amount'] as double) >= 0;
        final amount = (tx['amount'] as double).abs();
        final dateTs = tx['date'] as Timestamp?;
        final date = dateTs != null ? dateTs.toDate() : DateTime.now();
        final color = tx['color'] as Color;
        final icon = tx['icon'] as IconData;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['type'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      tx['note'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isPositive ? '+' : '-'}৳${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
