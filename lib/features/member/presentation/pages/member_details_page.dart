import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class MemberDetailsPage extends StatefulWidget {
  final Map<String, String> member;

  const MemberDetailsPage({super.key, required this.member});

  @override
  State<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample meal history data - এটা Firebase থেকে আসবে
  final List<Map<String, dynamic>> _mealHistory = [
    {'date': '2026-03-12', 'breakfast': 1, 'lunch': 1, 'dinner': 1, 'total': 3},
    {'date': '2026-03-11', 'breakfast': 1, 'lunch': 1, 'dinner': 0, 'total': 2},
    {'date': '2026-03-10', 'breakfast': 0, 'lunch': 1, 'dinner': 1, 'total': 2},
    {'date': '2026-03-09', 'breakfast': 1, 'lunch': 1, 'dinner': 1, 'total': 3},
    {'date': '2026-03-08', 'breakfast': 1, 'lunch': 0, 'dinner': 1, 'total': 2},
  ];

  // Sample transaction history
  final List<Map<String, dynamic>> _transactions = [
    {
      'date': '2026-03-10',
      'type': 'Deposit',
      'amount': 3000,
      'note': 'Monthly deposit',
    },
    {
      'date': '2026-03-05',
      'type': 'Expense',
      'amount': -1500,
      'note': 'Meal cost',
    },
    {
      'date': '2026-02-28',
      'type': 'Deposit',
      'amount': 2000,
      'note': 'Initial deposit',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Column(
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {},
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
              widget.member['name']!.split(' ').map((e) => e[0]).take(2).join(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.member['name']!,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.member['phone']!,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: widget.member['status'] == 'Active'
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.member['status'] == 'Active'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            child: Text(
              widget.member['status']!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.member['status'] == 'Active'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalMeals = _mealHistory.fold(
      0,
      (sum, day) => sum + (day['total'] as int),
    );
    final mealRate = 45; // ৳45 per meal
    final totalMealCost = totalMeals * mealRate;
    final balance = int.parse(
      widget.member['balance']!
          .replaceAll('৳', '')
          .replaceAll(',', '')
          .replaceAll('-', ''),
    );
    final isNegative = widget.member['balance']!.contains('-');

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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Meals',
                  totalMeals.toString(),
                  Icons.restaurant,
                  AppColors.primaryGreen,
                ),
              ),
              Container(width: 1, height: 50, color: Colors.grey.shade300),
              Expanded(
                child: _buildStatItem(
                  'Meal Cost',
                  '৳$totalMealCost',
                  Icons.payments,
                  Colors.orange,
                ),
              ),
              Container(width: 1, height: 50, color: Colors.grey.shade300),
              Expanded(
                child: _buildStatItem(
                  'Balance',
                  widget.member['balance']!,
                  Icons.account_balance_wallet,
                  isNegative ? Colors.red : Colors.green,
                ),
              ),
            ],
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
            fontSize: 18,
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
        tabs: const [
          Tab(text: 'Meal History'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  Widget _buildMealHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mealHistory.length,
      itemBuilder: (context, index) {
        final day = _mealHistory[index];
        final date = DateTime.parse(day['date']);

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
                        style: TextStyle(
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
                      day['breakfast'],
                      Icons.free_breakfast,
                      Colors.orange,
                    ),
                    _buildMealBadge(
                      'Lunch',
                      day['lunch'],
                      Icons.lunch_dining,
                      Colors.blue,
                    ),
                    _buildMealBadge(
                      'Dinner',
                      day['dinner'],
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final date = DateTime.parse(transaction['date']);
        final isDeposit = transaction['type'] == 'Deposit';

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
              transaction['type'],
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
                  transaction['note'],
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
              '৳${transaction['amount'].abs()}',
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
