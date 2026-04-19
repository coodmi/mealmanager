import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _messId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadIds();
  }

  Future<void> _loadIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final messId = userDoc.data()?['messId'] as String? ?? '';
    if (mounted)
      setState(() {
        _messId = messId;
      });
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
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Deposits'),
                      Tab(text: 'Expenses'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _messId.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllTab(),
                      _buildDepositsTab(),
                      _buildExpensesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, txSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messes')
              .doc(_messId)
              .collection('expenses')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, expSnap) {
            if (!txSnap.hasData || !expSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Combine deposits + expenses into one list sorted by date
            final items = <Map<String, dynamic>>[];

            for (final doc in txSnap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              items.add({...d, '_type': 'deposit', '_id': doc.id});
            }
            for (final doc in expSnap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              items.add({...d, '_type': 'expense', '_id': doc.id});
            }

            // Sort by createdAt descending
            items.sort((a, b) {
              final aTs = a['createdAt'] as Timestamp?;
              final bTs = b['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

            // Compute totals
            double totalDep = 0, totalExp = 0;
            for (final item in items) {
              final amt = (item['amount'] as num?)?.toDouble() ?? 0;
              if (item['_type'] == 'deposit')
                totalDep += amt;
              else
                totalExp += amt;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(totalDep - totalExp, totalDep, totalExp),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  )
                else
                  ...items.map((item) => _buildTxCard(item)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDepositsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('transactions')
          .where('type', isEqualTo: 'deposit')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No deposits yet',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _buildTxCard({...d, '_type': 'deposit'});
          }).toList(),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No expenses yet',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _buildTxCard({...d, '_type': 'expense'});
          }).toList(),
        );
      },
    );
  }

  Widget _buildTxCard(Map<String, dynamic> data) {
    final isDeposit = data['_type'] == 'deposit';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final color = isDeposit ? Colors.green : Colors.red;
    final icon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;

    String title = isDeposit
        ? (data['memberName'] as String? ?? 'Deposit')
        : (data['category'] as String? ?? 'Expense');
    String subtitle = isDeposit
        ? (data['method'] as String? ?? 'Cash')
        : (data['submittedByName'] as String? ?? '');
    if ((data['note'] as String? ?? '').isNotEmpty) {
      subtitle += subtitle.isNotEmpty ? ' · ${data['note']}' : data['note'];
    }

    String timeStr = '';
    final ts = data['createdAt'] as Timestamp?;
    if (ts != null) {
      timeStr = DateFormat('MMM dd, yyyy · hh:mm a').format(ts.toDate());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ],
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ],
        ),
        trailing: Text(
          '${isDeposit ? '+' : '-'}৳${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double balance, double income, double expense) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.buttonGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Net Balance',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '৳${balance.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Deposits',
                  '৳${income.toStringAsFixed(0)}',
                  Icons.arrow_downward,
                ),
                Container(height: 40, width: 1, color: Colors.white30),
                _buildSummaryItem(
                  'Expenses',
                  '৳${expense.toStringAsFixed(0)}',
                  Icons.arrow_upward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
