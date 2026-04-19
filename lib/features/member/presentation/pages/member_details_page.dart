import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_mess_service.dart';

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
  bool _isLoading = true;

  // Member data
  double _balance = 0;
  String _phone = '';
  bool _isActive = true;

  // Stats
  int _totalMeals = 0;
  double _totalDeposit = 0;

  // Lists
  List<Map<String, dynamic>> _meals = [];
  List<Map<String, dynamic>> _transactions = [];

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

  Future<void> _loadData() async {
    try {
      final messId = await FirebaseMessService.getMessId();
      if (messId.isEmpty) return;

      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Member doc
      final memberDoc = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('members')
          .doc(widget.memberId)
          .get();
      final mData = memberDoc.data() ?? {};

      // Meals this month
      final mealsSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('meals')
          .where('memberId', isEqualTo: widget.memberId)
          .where('monthKey', isEqualTo: monthKey)
          .get();

      // Transactions (deposits) for this member
      final txSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('transactions')
          .where('memberId', isEqualTo: widget.memberId)
          .get();

      // Expenses where this member is included
      final expSnap = await FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('expenses')
          .where('monthKey', isEqualTo: monthKey)
          .get();

      double totalDeposit = 0;

      final txList = <Map<String, dynamic>>[];
      for (final d in txSnap.docs) {
        final data = d.data();
        final amt = (data['amount'] as num?)?.toDouble() ?? 0;
        totalDeposit += amt;
        txList.add({
          'type': 'Deposit',
          'amount': amt,
          'note': data['method'] ?? 'Cash',
          'date': data['createdAt'],
        });
      }

      for (final d in expSnap.docs) {
        final data = d.data();
        final memberIds = List<String>.from(data['memberIds'] ?? []);
        if (memberIds.contains(widget.memberId) || memberIds.isEmpty) {
          final amt = (data['amount'] as num?)?.toDouble() ?? 0;
          final share = memberIds.isNotEmpty ? amt / memberIds.length : amt;
          txList.add({
            'type': 'Expense',
            'amount': -share,
            'note': data['category'] ?? 'Expense',
            'date': data['createdAt'],
          });
        }
      }

      // Sort transactions by date desc
      txList.sort((a, b) {
        final aDate = a['date'] as Timestamp?;
        final bDate = b['date'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      // Group meals by date
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
        } else if (mealType == 'lunch') {
          mealsByDate[dateStr]!['lunch'] =
              (mealsByDate[dateStr]!['lunch'] as int) + count;
        } else if (mealType == 'dinner') {
          mealsByDate[dateStr]!['dinner'] =
              (mealsByDate[dateStr]!['dinner'] as int) + count;
        }
        mealsByDate[dateStr]!['total'] =
            (mealsByDate[dateStr]!['total'] as int) + count;
      }

      final mealList = mealsByDate.values.toList()
        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      if (mounted) {
        setState(() {
          _balance = (mData['balance'] as num?)?.toDouble() ?? 0;
          _phone = mData['phone'] as String? ?? '';
          _isActive = mData['isActive'] as bool? ?? true;
          _totalMeals = mealsSnap.docs.fold(
            0,
            (sum, d) => sum + ((d.data()['count'] as num?)?.toInt() ?? 1),
          );
          _totalDeposit = totalDeposit;
          _meals = mealList;
          _transactions = txList;
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
      backgroundColor: AppColors.bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildMemberInfo(),
                _buildStatsRow(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildMealHistoryTab(), _buildTransactionTab()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primaryGreen,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  Widget _buildMemberInfo() {
    return Container(
      color: AppColors.primaryGreen,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              widget.memberName
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.memberName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _phone,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isActive
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isActive ? Colors.green : Colors.orange,
              ),
            ),
            child: Text(
              _isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isActive ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Meals',
              '$_totalMeals',
              Icons.restaurant,
              AppColors.primaryGreen,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Expanded(
            child: _buildStatItem(
              'Deposit',
              '৳${_totalDeposit.toStringAsFixed(0)}',
              Icons.payments,
              Colors.green,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Expanded(
            child: _buildStatItem(
              'Balance',
              '৳${_balance.toStringAsFixed(0)}',
              Icons.account_balance_wallet,
              _balance >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryGreen,
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: AppColors.textLight,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        tabs: const [
          Tab(text: 'Meal History'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  Widget _buildMealHistoryTab() {
    if (_meals.isEmpty) {
      return const Center(
        child: Text(
          'No meals recorded this month',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _meals.length,
      itemBuilder: (context, index) {
        final day = _meals[index];
        final date = DateTime.parse(day['date'] as String);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(date),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${day['total']} meals',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMealBadge(
                      'Breakfast',
                      day['breakfast'] as int,
                      Icons.free_breakfast,
                      Colors.orange,
                    ),
                    _buildMealBadge(
                      'Lunch',
                      day['lunch'] as int,
                      Icons.lunch_dining,
                      Colors.blue,
                    ),
                    _buildMealBadge(
                      'Dinner',
                      day['dinner'] as int,
                      Icons.dinner_dining,
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealBadge(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: count > 0 ? color : Colors.grey.shade300, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: count > 0 ? color : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: count > 0
                ? color.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: count > 0 ? color : Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTab() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions found',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isDeposit = tx['type'] == 'Deposit';
        final amount = (tx['amount'] as double).abs();
        final dateTs = tx['date'] as Timestamp?;
        final date = dateTs != null ? dateTs.toDate() : DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDeposit
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isDeposit ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              tx['type'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  tx['note'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            trailing: Text(
              '৳${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDeposit ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}
