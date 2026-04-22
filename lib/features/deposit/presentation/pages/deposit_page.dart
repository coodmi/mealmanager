import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class DepositPage extends StatefulWidget {
  final String? selectedMonthKey;
  const DepositPage({super.key, this.selectedMonthKey});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedMethod = 'Cash';
  bool _isLoading = false;
  double _currentBalance = 0;
  double _monthlyDeposit = 0;
  String _memberName = '';
  String _messId = '';
  String _currentUid = '';
  bool _isManager = false;

  DateTime _depositDate = DateTime.now();

  String _depositForUid = '';
  String _depositForName = '';
  List<Map<String, dynamic>> _members = [];

  static const List<Map<String, dynamic>> _methods = [
    {'name': 'Cash', 'icon': Icons.money, 'color': Color(0xFF2E7D32)},
    {'name': 'bKash', 'icon': Icons.phone_android, 'color': Color(0xFFE2136E)},
    {
      'name': 'Nagad',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFFF6821F),
    },
    {'name': 'Bank', 'icon': Icons.account_balance, 'color': Color(0xFF1565C0)},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
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
      final data = userDoc.data();
      if (data == null) return;

      final messId = data['messId'] as String? ?? '';
      final name = data['name'] as String? ?? 'Member';
      final role = data['role'] as String? ?? 'member';
      final isManager = role == 'manager';

      double balance = 0;
      double monthlyDeposit = 0;
      List<Map<String, dynamic>> members = [];

      if (messId.isNotEmpty) {
        final memberDoc = await FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('members')
            .doc(user.uid)
            .get();
        balance = (memberDoc.data()?['balance'] as num?)?.toDouble() ?? 0;

        final now = DateTime.now();
        final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final txSnap = await FirebaseFirestore.instance
            .collection('messes')
            .doc(messId)
            .collection('transactions')
            .where('type', isEqualTo: 'deposit')
            .where('memberId', isEqualTo: user.uid)
            .get();
        for (final d in txSnap.docs) {
          final ts = d.data()['createdAt'] as Timestamp?;
          if (ts != null) {
            final dt = ts.toDate();
            final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            if (key == monthKey) {
              monthlyDeposit += (d.data()['amount'] as num?)?.toDouble() ?? 0;
            }
          }
        }

        if (isManager) {
          final snap = await FirebaseFirestore.instance
              .collection('messes')
              .doc(messId)
              .collection('members')
              .get();
          members = snap.docs
              .map(
                (d) => {
                  'uid': d.id,
                  'name': d.data()['name'] as String? ?? 'Member',
                },
              )
              .toList();
          members.sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );
        }
      }

      if (mounted) {
        setState(() {
          _messId = messId;
          _memberName = name;
          _currentUid = user!.uid;
          _isManager = isManager;
          _currentBalance = balance;
          _monthlyDeposit = monthlyDeposit;
          _depositForUid = user.uid;
          _depositForName = name;
          _members = members;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: _depositDate,
      firstDate: firstDay,
      lastDate: lastDay,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _depositDate = picked);
  }

  void _showMethodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._methods.map((m) {
                final isSelected = _selectedMethod == m['name'];
                final color = m['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMethod = m['name'] as String);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            m['icon'] as IconData,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          m['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? color : AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: color,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitDeposit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_messId.isEmpty) throw Exception('No mess found');

      final txData = {
        'type': 'deposit',
        'amount': amount,
        'memberId': _depositForUid,
        'memberName': _depositForName,
        'method': _selectedMethod,
        'note': _noteController.text.trim(),
        'depositDate': Timestamp.fromDate(_depositDate),
        'createdAt': FieldValue.serverTimestamp(),
        'status': _isManager ? 'approved' : 'pending',
        'submittedBy': _currentUid,
      };

      if (_isManager) {
        final batch = FirebaseFirestore.instance.batch();
        final txRef = FirebaseFirestore.instance
            .collection('messes')
            .doc(_messId)
            .collection('transactions')
            .doc();
        batch.set(txRef, txData);
        batch.update(
          FirebaseFirestore.instance
              .collection('messes')
              .doc(_messId)
              .collection('members')
              .doc(_depositForUid),
          {'balance': FieldValue.increment(amount)},
        );
        await batch.commit();
        if (mounted) {
          if (_depositForUid == _currentUid) {
            setState(() {
              _currentBalance += amount;
              _monthlyDeposit += amount;
            });
          }
          _amountController.clear();
          _noteController.clear();
          _showSuccess(amount, isManager: true);
        }
      } else {
        await FirebaseFirestore.instance
            .collection('messes')
            .doc(_messId)
            .collection('transactions')
            .add(txData);
        if (mounted) {
          _amountController.clear();
          _noteController.clear();
          _showSuccess(amount, isManager: false);
        }
      }
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(double amount, {required bool isManager}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 52,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isManager ? 'Deposit Successful!' : 'Deposit Request Sent.',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isManager
                    ? '৳${amount.toStringAsFixed(2)} added to ${_depositForName}\'s balance.'
                    : '৳${amount.toStringAsFixed(2)} deposit request submitted.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              if (!isManager) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Important Information:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _infoPoint(
                        'You will receive a notification when this request is accepted/rejected by the Manager.',
                      ),
                      _infoPoint(
                        'Approved deposit will be added to your balance.',
                      ),
                      _infoPoint(
                        'Contact your Manager if not approved within 24 hours.',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPoint(String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade800,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selectedMethodData = _methods.firstWhere(
      (m) => m['name'] == _selectedMethod,
    );
    final methodColor = selectedMethodData['color'] as Color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Deposit Money',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Balance card ─────────────────────────────────────────────
            Container(
              width: double.infinity,
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${_currentBalance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _memberName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'This Month',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${_monthlyDeposit.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Deposited',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Main form card ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                  // ── 1) Deposit Date ──────────────────────────────────
                  _sectionLabel('Deposit Date'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primaryGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat(
                              'dd MMM yyyy (EEEE)',
                            ).format(_depositDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.edit_calendar_rounded,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 2) Deposit For ───────────────────────────────────
                  _sectionLabel('Deposit For'),
                  const SizedBox(height: 8),
                  if (_isManager && _members.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _depositForUid,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade500,
                          ),
                          items: _members
                              .map(
                                (m) => DropdownMenuItem<String>(
                                  value: m['uid'] as String,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primaryGreen
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          (m['name'] as String).isNotEmpty
                                              ? (m['name'] as String)[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        m['name'] as String,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if (m['uid'] == _currentUid) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGreen
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'You',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (uid) {
                            if (uid == null) return;
                            final member = _members.firstWhere(
                              (m) => m['uid'] == uid,
                            );
                            setState(() {
                              _depositForUid = uid;
                              _depositForName = member['name'] as String;
                            });
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade100,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryGreen.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              _memberName.isNotEmpty
                                  ? _memberName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _memberName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // ── Amount input ─────────────────────────────────────
                  _sectionLabel('Deposit Amount'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '৳  ',
                      prefixStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        color: Colors.grey.shade300,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── 4) Quick amounts — 5 in one row ─────────────────
                  Row(
                    children: [500, 1000, 1500, 2000, 3000]
                        .map(
                          (amt) => Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  _amountController.text = amt.toString(),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '$amt',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // ── 5) Payment method — tap to open popup ────────────
                  _sectionLabel('Payment Method'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showMethodPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: methodColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: methodColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: methodColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              selectedMethodData['icon'] as IconData,
                              color: methodColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedMethod,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: methodColor,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Note ─────────────────────────────────────────────
                  _sectionLabel('Note (Optional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 6) Submit button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _submitDeposit,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _isManager ? 'Deposit Now' : 'Submit Request',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: AppColors.textDark,
    ),
  );
}
