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
  String _uid = '';
  bool _isManager = false;

  // Running month key e.g. "2026-04"
  String get _monthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final role = userDoc.data()?['role'] as String? ?? 'member';
    if (mounted) {
      setState(() {
        _messId = messId;
        _uid = user.uid;
        _isManager = role == 'manager';
      });
    }
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
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                    isScrollable: false,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Deposits'),
                      Tab(text: 'Expenses'),
                      Tab(text: 'Withdraws'),
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
                      _AllTab(
                        messId: _messId,
                        monthKey: _monthKey,
                        uid: _uid,
                        isManager: _isManager,
                      ),
                      _DepositsTab(
                        messId: _messId,
                        monthKey: _monthKey,
                        uid: _uid,
                        isManager: _isManager,
                      ),
                      _ExpensesTab(
                        messId: _messId,
                        monthKey: _monthKey,
                        uid: _uid,
                        isManager: _isManager,
                      ),
                      _WithdrawsTab(
                        messId: _messId,
                        monthKey: _monthKey,
                        uid: _uid,
                        isManager: _isManager,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(double v) => '৳${v.toStringAsFixed(0)}';

String _fmtDate(Timestamp? ts) {
  if (ts == null) return '';
  return DateFormat('MMM dd, yyyy · hh:mm a').format(ts.toDate());
}

bool _inMonth(Timestamp? ts, String monthKey) {
  if (ts == null) return false;
  final dt = ts.toDate();
  final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  return key == monthKey;
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double deposits;
  final double expenses;
  final double withdraws;
  final double bazarExpense;

  const _SummaryCard({
    required this.deposits,
    required this.expenses,
    required this.withdraws,
    required this.bazarExpense,
  });

  @override
  Widget build(BuildContext context) {
    final net = deposits - expenses - withdraws;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.buttonGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Net Balance',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(net),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(
                'Deposits',
                _fmt(deposits),
                Icons.arrow_downward,
                Colors.greenAccent,
              ),
              _divider(),
              _item(
                'Expenses',
                _fmt(expenses),
                Icons.arrow_upward,
                Colors.redAccent,
              ),
              _divider(),
              _item(
                'Withdraws',
                _fmt(withdraws),
                Icons.account_balance_wallet_rounded,
                Colors.orangeAccent,
              ),
            ],
          ),
          if (bazarExpense > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bazar Expense (included)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _fmt(bazarExpense),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _item(String label, String value, IconData icon, Color color) =>
      Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  Widget _divider() => Container(height: 36, width: 1, color: Colors.white24);
}

// ─── Transaction Card ─────────────────────────────────────────────────────────

class _TxCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String type; // 'deposit' | 'expense' | 'withdraw'
  final bool isManager;
  final String messId;

  const _TxCard({
    required this.data,
    required this.docId,
    required this.type,
    required this.isManager,
    required this.messId,
  });

  Color get _color => type == 'deposit'
      ? Colors.green
      : type == 'withdraw'
      ? Colors.orange
      : Colors.red;

  IconData get _icon => type == 'deposit'
      ? Icons.arrow_downward
      : type == 'withdraw'
      ? Icons.account_balance_wallet_rounded
      : Icons.arrow_upward;

  String get _sign => type == 'deposit' ? '+' : '-';

  String get _title {
    if (type == 'deposit') return data['memberName'] as String? ?? 'Deposit';
    if (type == 'withdraw') return data['memberName'] as String? ?? 'Withdraw';
    return data['category'] as String? ?? 'Expense';
  }

  String get _subtitle {
    final parts = <String>[];
    if (type == 'deposit') {
      final m = data['method'] as String? ?? '';
      if (m.isNotEmpty) parts.add(m);
    } else if (type == 'withdraw') {
      final m = data['paymentMethod'] as String? ?? '';
      if (m.isNotEmpty) parts.add(m);
    } else {
      final by = data['submittedByName'] as String? ?? '';
      if (by.isNotEmpty) parts.add(by);
    }
    final note = data['note'] as String? ?? '';
    if (note.isNotEmpty) parts.add(note);
    return parts.join(' · ');
  }

  bool get _isEdited => data['edited'] == true;

  void _showEditDialog(BuildContext context) {
    if (!isManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the manager can edit transactions.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final amountCtrl = TextEditingController(
      text: ((data['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0),
    );
    final noteCtrl = TextEditingController(text: data['note'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit ${type[0].toUpperCase()}${type.substring(1)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '৳ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final newAmt = double.tryParse(amountCtrl.text.trim());
              if (newAmt == null || newAmt <= 0) return;
              final collection = type == 'expense'
                  ? 'expenses'
                  : 'transactions';
              await FirebaseFirestore.instance
                  .collection('messes')
                  .doc(messId)
                  .collection(collection)
                  .doc(docId)
                  .update({
                    'amount': newAmt,
                    'note': noteCtrl.text.trim(),
                    'edited': true,
                    'editedAt': FieldValue.serverTimestamp(),
                  });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final ts = data['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_isEdited)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Edited',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (ts != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _fmtDate(ts),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_sign${_fmt(amount)}',
                  style: TextStyle(
                    color: _color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showEditDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isManager
                          ? AppColors.primaryGreen.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: isManager
                              ? AppColors.primaryGreen
                              : Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            color: isManager
                                ? AppColors.primaryGreen
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}

// ─── All Tab ──────────────────────────────────────────────────────────────────

class _AllTab extends StatelessWidget {
  final String messId;
  final String monthKey;
  final String uid;
  final bool isManager;

  const _AllTab({
    required this.messId,
    required this.monthKey,
    required this.uid,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, txSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messes')
              .doc(messId)
              .collection('expenses')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, expSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messes')
                  .doc(messId)
                  .collection('withdrawals')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, wdSnap) {
                if (!txSnap.hasData || !expSnap.hasData || !wdSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = <Map<String, dynamic>>[];
                double totalDep = 0, totalExp = 0, totalWd = 0, bazarExp = 0;

                for (final doc in txSnap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  if (!_inMonth(d['createdAt'] as Timestamp?, monthKey))
                    continue;
                  if ((d['type'] as String? ?? '') != 'deposit') continue;
                  totalDep += (d['amount'] as num?)?.toDouble() ?? 0;
                  items.add({...d, '_type': 'deposit', '_id': doc.id});
                }
                for (final doc in expSnap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  if (!_inMonth(d['createdAt'] as Timestamp?, monthKey))
                    continue;
                  final amt = (d['amount'] as num?)?.toDouble() ?? 0;
                  totalExp += amt;
                  if ((d['category'] as String? ?? '').toLowerCase().contains(
                    'bazar',
                  ))
                    bazarExp += amt;
                  items.add({...d, '_type': 'expense', '_id': doc.id});
                }
                for (final doc in wdSnap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  if (!_inMonth(d['createdAt'] as Timestamp?, monthKey))
                    continue;
                  totalWd += (d['amount'] as num?)?.toDouble() ?? 0;
                  items.add({...d, '_type': 'withdraw', '_id': doc.id});
                }

                items.sort((a, b) {
                  final aTs = a['createdAt'] as Timestamp?;
                  final bTs = b['createdAt'] as Timestamp?;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SummaryCard(
                      deposits: totalDep,
                      expenses: totalExp,
                      withdraws: totalWd,
                      bazarExpense: bazarExp,
                    ),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No transactions this month',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                      )
                    else
                      ...items.map(
                        (item) => _TxCard(
                          data: item,
                          docId: item['_id'] as String,
                          type: item['_type'] as String,
                          isManager: isManager,
                          messId: messId,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Deposits Tab ─────────────────────────────────────────────────────────────

class _DepositsTab extends StatelessWidget {
  final String messId;
  final String monthKey;
  final String uid;
  final bool isManager;

  const _DepositsTab({
    required this.messId,
    required this.monthKey,
    required this.uid,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return (d['type'] as String? ?? '') == 'deposit' &&
              _inMonth(d['createdAt'] as Timestamp?, monthKey);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No deposits this month',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _TxCard(
              data: d,
              docId: doc.id,
              type: 'deposit',
              isManager: isManager,
              messId: messId,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Expenses Tab ─────────────────────────────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  final String messId;
  final String monthKey;
  final String uid;
  final bool isManager;

  const _ExpensesTab({
    required this.messId,
    required this.monthKey,
    required this.uid,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return _inMonth(d['createdAt'] as Timestamp?, monthKey);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No expenses this month',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _TxCard(
              data: d,
              docId: doc.id,
              type: 'expense',
              isManager: isManager,
              messId: messId,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Withdraws Tab ────────────────────────────────────────────────────────────

class _WithdrawsTab extends StatelessWidget {
  final String messId;
  final String monthKey;
  final String uid;
  final bool isManager;

  const _WithdrawsTab({
    required this.messId,
    required this.monthKey,
    required this.uid,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(messId)
          .collection('withdrawals')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return _inMonth(d['createdAt'] as Timestamp?, monthKey);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No withdrawals this month',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _TxCard(
              data: d,
              docId: doc.id,
              type: 'withdraw',
              isManager: isManager,
              messId: messId,
            );
          }).toList(),
        );
      },
    );
  }
}
