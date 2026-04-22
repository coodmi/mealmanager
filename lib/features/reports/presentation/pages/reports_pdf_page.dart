import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_mess_service.dart';

class ReportsPdfPage extends StatefulWidget {
  const ReportsPdfPage({super.key});

  @override
  State<ReportsPdfPage> createState() => _ReportsPdfPageState();
}

class _ReportsPdfPageState extends State<ReportsPdfPage> {
  String _messId = '';
  bool _isLoading = true;
  String _reportType = 'full'; // 'full' or 'individual'
  String? _selectedMemberId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _showComparison = false;

  Map<String, dynamic>? _reportData;
  Map<String, dynamic>? _comparisonData;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadData();
  }

  void _initializeDates() {
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _loadData() async {
    final messId = await FirebaseMessService.getMessId();
    setState(() {
      _messId = messId;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reports & PDF'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportTypeSelector(),
            const SizedBox(height: 16),
            if (_reportType == 'individual') _buildMemberSelector(),
            if (_reportType == 'individual') const SizedBox(height: 16),
            _buildDateRangeSelector(),
            const SizedBox(height: 16),
            _buildComparisonToggle(),
            const SizedBox(height: 24),
            _buildGenerateButton(),
            const SizedBox(height: 24),
            if (_reportData != null) _buildReportView(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildReportTypeOption(
                  'Full Mess Report',
                  'full',
                  Icons.groups,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReportTypeOption(
                  'Individual Report',
                  'individual',
                  Icons.person,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeOption(String label, String value, IconData icon) {
    final isSelected = _reportType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _reportType = value;
          _reportData = null;
          _comparisonData = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryGreen : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Member',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedMemberId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                hint: const Text('Select a member'),
                items: members.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(data['name'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMemberId = value;
                    _reportData = null;
                    _comparisonData = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField('Start Date', _startDate, (date) {
                  setState(() {
                    _startDate = date;
                    _reportData = null;
                    _comparisonData = null;
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField('End Date', _endDate, (date) {
                  setState(() {
                    _endDate = date;
                    _reportData = null;
                    _comparisonData = null;
                  });
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickDateButton('This Month', () {
                final now = DateTime.now();
                setState(() {
                  _startDate = DateTime(now.year, now.month, 1);
                  _endDate = DateTime(now.year, now.month + 1, 0);
                  _reportData = null;
                  _comparisonData = null;
                });
              }),
              _buildQuickDateButton('Last Month', () {
                final now = DateTime.now();
                setState(() {
                  _startDate = DateTime(now.year, now.month - 1, 1);
                  _endDate = DateTime(now.year, now.month, 0);
                  _reportData = null;
                  _comparisonData = null;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime date,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.primaryGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildComparisonToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        value: _showComparison,
        onChanged: (value) {
          setState(() {
            _showComparison = value;
            _comparisonData = null;
          });
        },
        title: const Text(
          'Show Previous Month Comparison',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: const Text(
          'Compare with previous month data',
          style: TextStyle(fontSize: 12),
        ),
        activeColor: AppColors.primaryGreen,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate = _reportType == 'full' || _selectedMemberId != null;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: canGenerate ? _generateReport : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.assessment, color: Colors.white),
        label: const Text(
          'Generate Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_reportType == 'full') {
        await _generateFullMessReport();
      } else {
        await _generateIndividualReport();
      }

      if (_showComparison) {
        await _generateComparisonData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateFullMessReport() async {
    // Get all members from subcollection
    final membersSnapshot = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('members')
        .get();

    // Get all meals from subcollection, filter dates in-memory
    final mealsSnapshot = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('meals')
        .get();

    // Get all expenses from subcollection
    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('expenses')
        .get();

    // Get all withdrawals from subcollection
    final withdrawalsSnapshot = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('withdrawals')
        .get();

    // Filter meals by date range in-memory
    final filteredMeals = mealsSnapshot.docs.where((doc) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      return !date.isBefore(_startDate) &&
          date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Filter expenses by date range in-memory
    final filteredExpenses = expensesSnapshot.docs.where((doc) {
      final data = doc.data();
      if (data['status'] != 'approved') return false;
      final date = (data['createdAt'] as Timestamp).toDate();
      return !date.isBefore(_startDate) &&
          date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    // Filter withdrawals by date range in-memory
    final filteredWithdrawals = withdrawalsSnapshot.docs.where((doc) {
      final data = doc.data();
      if (data['status'] != 'approved') return false;
      final date = (data['requestedAt'] as Timestamp).toDate();
      return !date.isBefore(_startDate) &&
          date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    double totalDeposit = 0;
    double totalExpense = 0;
    double totalWithdraw = 0;
    int totalMeals = filteredMeals.length;
    double totalBalance = 0;

    final memberData = <String, Map<String, dynamic>>{};

    for (final memberDoc in membersSnapshot.docs) {
      final data = memberDoc.data();
      final memberId = memberDoc.id;

      final memberMeals = filteredMeals.where((meal) {
        return meal.data()['memberId'] == memberId;
      }).length;

      memberData[memberId] = {
        'name': data['name'],
        'balance': data['balance'] ?? 0.0,
        'mealCount': memberMeals,
      };

      totalBalance += (data['balance'] ?? 0.0) as double;
    }

    for (final expense in filteredExpenses) {
      totalExpense += (expense.data()['amount'] ?? 0.0) as double;
    }

    for (final withdrawal in filteredWithdrawals) {
      totalWithdraw += (withdrawal.data()['amount'] ?? 0.0) as double;
    }

    final mealRate = totalMeals > 0 ? totalExpense / totalMeals : 0.0;

    setState(() {
      _reportData = {
        'type': 'full',
        'startDate': _startDate,
        'endDate': _endDate,
        'totalMembers': membersSnapshot.docs.length,
        'totalMeals': totalMeals,
        'totalDeposit': totalDeposit,
        'totalExpense': totalExpense,
        'totalWithdraw': totalWithdraw,
        'totalBalance': totalBalance,
        'mealRate': mealRate,
        'memberData': memberData,
      };
    });
  }

  Future<void> _generateIndividualReport() async {
    if (_selectedMemberId == null) return;

    final memberDoc = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('members')
        .doc(_selectedMemberId)
        .get();

    if (!memberDoc.exists) return;
    final memberData = memberDoc.data()!;

    // Fetch from subcollections, date-filter in-memory
    final mealsSnapshot = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('meals')
        .where('memberId', isEqualTo: _selectedMemberId)
        .get();

    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('expenses')
        .get();

    final withdrawalsSnapshot = await FirebaseFirestore.instance
        .collection('messes')
        .doc(_messId)
        .collection('withdrawals')
        .where('memberId', isEqualTo: _selectedMemberId)
        .get();

    // Filter in-memory
    final filteredMeals = mealsSnapshot.docs.where((doc) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      return !date.isBefore(_startDate) &&
          date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredExpenses = expensesSnapshot.docs.where((doc) {
      final data = doc.data();
      if (data['status'] != 'approved') return false;
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      if (!memberIds.contains(_selectedMemberId)) return false;
      final date = (data['createdAt'] as Timestamp).toDate();
      return !date.isBefore(_startDate) &&
          date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredWithdrawals = withdrawalsSnapshot.docs.where((doc) {
      final data = doc.data();
      if (data['status'] != 'approved') return false;
      final date = (data['requestedAt'] as Timestamp).toDate();
      return !date.isBefore(_startDate) &&
          date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    final totalMeals = filteredMeals.length;
    double totalExpense = 0;
    double totalWithdraw = 0;

    for (final expense in filteredExpenses) {
      final data = expense.data();
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final amount = (data['amount'] ?? 0.0) as double;
      totalExpense += memberIds.isNotEmpty ? amount / memberIds.length : amount;
    }

    for (final withdrawal in filteredWithdrawals) {
      totalWithdraw += (withdrawal.data()['amount'] ?? 0.0) as double;
    }

    final mealRate = totalMeals > 0 && totalExpense > 0
        ? totalExpense / totalMeals
        : 0.0;

    setState(() {
      _reportData = {
        'type': 'individual',
        'startDate': _startDate,
        'endDate': _endDate,
        'memberName': memberData['name'],
        'totalMeals': totalMeals,
        'totalExpense': totalExpense,
        'totalWithdraw': totalWithdraw,
        'balance': memberData['balance'] ?? 0.0,
        'mealRate': mealRate,
      };
    });
  }

  Future<void> _generateComparisonData() async {
    final prevStartDate = DateTime(_startDate.year, _startDate.month - 1, 1);
    final prevEndDate = DateTime(_startDate.year, _startDate.month, 0);

    if (_reportType == 'full') {
      final prevMealsSnapshot = await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('meals')
          .get();

      final prevExpensesSnapshot = await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('expenses')
          .get();

      final filteredMeals = prevMealsSnapshot.docs.where((doc) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        return !date.isBefore(prevStartDate) &&
            date.isBefore(prevEndDate.add(const Duration(days: 1)));
      }).toList();

      final filteredExpenses = prevExpensesSnapshot.docs.where((doc) {
        final data = doc.data();
        if (data['status'] != 'approved') return false;
        final date = (data['createdAt'] as Timestamp).toDate();
        return !date.isBefore(prevStartDate) &&
            date.isBefore(prevEndDate.add(const Duration(days: 1)));
      }).toList();

      double prevTotalExpense = 0;
      for (final expense in filteredExpenses) {
        prevTotalExpense += (expense.data()['amount'] ?? 0.0) as double;
      }

      final prevTotalMeals = filteredMeals.length;
      final prevMealRate = prevTotalMeals > 0
          ? prevTotalExpense / prevTotalMeals
          : 0.0;

      setState(() {
        _comparisonData = {
          'totalMeals': prevTotalMeals,
          'totalExpense': prevTotalExpense,
          'mealRate': prevMealRate,
        };
      });
    } else if (_selectedMemberId != null) {
      final prevMealsSnapshot = await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('meals')
          .where('memberId', isEqualTo: _selectedMemberId)
          .get();

      final filteredMeals = prevMealsSnapshot.docs.where((doc) {
        final date = (doc.data()['date'] as Timestamp).toDate();
        return !date.isBefore(prevStartDate) &&
            date.isBefore(prevEndDate.add(const Duration(days: 1)));
      }).toList();

      setState(() {
        _comparisonData = {'totalMeals': filteredMeals.length};
      });
    }
  }

  Widget _buildReportView() {
    if (_reportData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReportHeader(),
        const SizedBox(height: 16),
        if (_reportType == 'full')
          _buildFullMessReportContent()
        else
          _buildIndividualReportContent(),
        const SizedBox(height: 16),
        if (_showComparison && _comparisonData != null)
          _buildComparisonSection(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _reportType == 'full' ? Icons.groups : Icons.person,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reportType == 'full'
                          ? 'Full Mess Report'
                          : 'Individual Report',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_reportType == 'individual')
                      Text(
                        _reportData!['memberName'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${DateFormat('MMM dd, yyyy').format(_reportData!['startDate'])} - ${DateFormat('MMM dd, yyyy').format(_reportData!['endDate'])}',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFullMessReportContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Total Members',
            '${_reportData!['totalMembers']}',
            Icons.people,
          ),
          _buildSummaryRow(
            'Total Meals',
            '${_reportData!['totalMeals']}',
            Icons.restaurant,
          ),
          _buildSummaryRow(
            'Total Expense',
            '৳ ${_reportData!['totalExpense'].toStringAsFixed(2)}',
            Icons.money_off,
          ),
          _buildSummaryRow(
            'Total Withdraw',
            '৳ ${_reportData!['totalWithdraw'].toStringAsFixed(2)}',
            Icons.account_balance_wallet,
          ),
          _buildSummaryRow(
            'Meal Rate',
            '৳ ${_reportData!['mealRate'].toStringAsFixed(2)}',
            Icons.calculate,
          ),
          _buildSummaryRow(
            'Total Balance',
            '৳ ${_reportData!['totalBalance'].toStringAsFixed(2)}',
            Icons.account_balance,
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualReportContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Total Meals',
            '${_reportData!['totalMeals']}',
            Icons.restaurant,
          ),
          _buildSummaryRow(
            'Meal Rate',
            '৳ ${_reportData!['mealRate'].toStringAsFixed(2)}',
            Icons.calculate,
          ),
          _buildSummaryRow(
            'Total Expense',
            '৳ ${_reportData!['totalExpense'].toStringAsFixed(2)}',
            Icons.money_off,
          ),
          _buildSummaryRow(
            'Total Withdraw',
            '৳ ${_reportData!['totalWithdraw'].toStringAsFixed(2)}',
            Icons.account_balance_wallet,
          ),
          _buildSummaryRow(
            'Current Balance',
            '৳ ${_reportData!['balance'].toStringAsFixed(2)}',
            Icons.account_balance,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection() {
    final currentMeals = _reportData!['totalMeals'] as int;
    final prevMeals = _comparisonData!['totalMeals'] as int;
    final mealDiff = currentMeals - prevMeals;
    final mealPercentage = prevMeals > 0 ? ((mealDiff / prevMeals) * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Previous Month Comparison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(
            'Meals',
            prevMeals,
            currentMeals,
            mealDiff,
            mealPercentage,
          ),
          if (_reportType == 'full' &&
              _comparisonData!.containsKey('totalExpense')) ...[
            const SizedBox(height: 12),
            _buildComparisonRow(
              'Expense',
              (_comparisonData!['totalExpense'] as double).toInt(),
              (_reportData!['totalExpense'] as double).toInt(),
              ((_reportData!['totalExpense'] as double) -
                      (_comparisonData!['totalExpense'] as double))
                  .toInt(),
              (_comparisonData!['totalExpense'] as double) > 0
                  ? (((_reportData!['totalExpense'] as double) -
                            (_comparisonData!['totalExpense'] as double)) /
                        (_comparisonData!['totalExpense'] as double) *
                        100)
                  : 0.0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    int prevValue,
    int currentValue,
    int diff,
    double percentage,
  ) {
    final isIncrease = diff > 0;
    final color = isIncrease ? Colors.red : Colors.green;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$prevValue → $currentValue',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${percentage.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _generatePdf,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareReport,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text(
              'Share Report',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generatePdf() async {
    if (_reportData == null) return;

    final pdf = pw.Document();
    final isFullReport = _reportType == 'full';
    final title = isFullReport ? 'Full Mess Report' : 'Individual Report';
    final dateRange =
        '${DateFormat('MMM dd, yyyy').format(_reportData!['startDate'])} - ${DateFormat('MMM dd, yyyy').format(_reportData!['endDate'])}';
    final generatedOn = DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now());

    const primaryGreen = PdfColor.fromInt(0xFF2E7D32);
    const lightGreen = PdfColor.fromInt(0xFFE8F5E9);
    const darkText = PdfColor.fromInt(0xFF212121);
    const borderColor = PdfColor.fromInt(0xFFE0E0E0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 20, 40, 40),
        header: (pw.Context ctx) => _buildPdfHeader(
          title: title,
          dateRange: dateRange,
          isFullReport: isFullReport,
          primaryGreen: primaryGreen,
          lightGreen: lightGreen,
          darkText: darkText,
        ),
        footer: (pw.Context ctx) => _buildPdfFooter(
          generatedOn: generatedOn,
          pageNum: ctx.pageNumber,
          totalPages: ctx.pagesCount,
          borderColor: borderColor,
        ),
        build: (pw.Context ctx) => [
          pw.SizedBox(height: 20),
          _buildPdfSectionTitle('Summary', primaryGreen),
          pw.SizedBox(height: 8),
          _buildPdfSummaryTable(
            isFullReport: isFullReport,
            primaryGreen: primaryGreen,
            lightGreen: lightGreen,
            darkText: darkText,
            borderColor: borderColor,
          ),
          if (isFullReport &&
              (_reportData!['memberData'] as Map).isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildPdfSectionTitle('Member Breakdown', primaryGreen),
            pw.SizedBox(height: 8),
            _buildPdfMemberTable(
              primaryGreen: primaryGreen,
              lightGreen: lightGreen,
              darkText: darkText,
              borderColor: borderColor,
            ),
          ],
          if (_showComparison && _comparisonData != null) ...[
            pw.SizedBox(height: 20),
            _buildPdfSectionTitle('Previous Month Comparison', primaryGreen),
            pw.SizedBox(height: 8),
            _buildPdfComparisonTable(
              primaryGreen: primaryGreen,
              lightGreen: lightGreen,
              darkText: darkText,
              borderColor: borderColor,
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          '${title.replaceAll(' ', '_')}_${DateFormat('yyyy_MM').format(_reportData!['startDate'])}.pdf',
    );
  }

  pw.Widget _buildPdfHeader({
    required String title,
    required String dateRange,
    required bool isFullReport,
    required PdfColor primaryGreen,
    required PdfColor lightGreen,
    required PdfColor darkText,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: pw.BoxDecoration(color: primaryGreen),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 34,
                    height: 34,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'MM',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Meal Manager',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Manage Meals, Deposits & Expenses Smartly',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Text(
                'OFFICIAL REPORT',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: lightGreen,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: primaryGreen, width: 0.5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  if (!isFullReport)
                    pw.Text(
                      _reportData!['memberName'],
                      style: pw.TextStyle(
                        fontSize: 13,
                        color: darkText,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Period: $dateRange',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: primaryGreen,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  isFullReport ? 'FULL MESS' : 'INDIVIDUAL',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  pw.Widget _buildPdfFooter({
    required String generatedOn,
    required int pageNum,
    required int totalPages,
    required PdfColor borderColor,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: borderColor),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated: $generatedOn  |  Meal Manager App',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
            pw.Text(
              'Page $pageNum of $totalPages',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfSectionTitle(String title, PdfColor primaryGreen) {
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 18, color: primaryGreen),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: primaryGreen,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummaryTable({
    required bool isFullReport,
    required PdfColor primaryGreen,
    required PdfColor lightGreen,
    required PdfColor darkText,
    required PdfColor borderColor,
  }) {
    final rows = isFullReport
        ? [
            ['Total Members', '${_reportData!['totalMembers']} members'],
            ['Total Meals', '${_reportData!['totalMeals']} meals'],
            [
              'Total Expense',
              'BDT ${(_reportData!['totalExpense'] as double).toStringAsFixed(2)}',
            ],
            [
              'Total Withdraw',
              'BDT ${(_reportData!['totalWithdraw'] as double).toStringAsFixed(2)}',
            ],
            [
              'Meal Rate',
              'BDT ${(_reportData!['mealRate'] as double).toStringAsFixed(2)} / meal',
            ],
            [
              'Total Balance',
              'BDT ${(_reportData!['totalBalance'] as double).toStringAsFixed(2)}',
            ],
          ]
        : [
            ['Member Name', _reportData!['memberName']],
            ['Total Meals', '${_reportData!['totalMeals']} meals'],
            [
              'Meal Rate',
              'BDT ${(_reportData!['mealRate'] as double).toStringAsFixed(2)} / meal',
            ],
            [
              'Total Expense',
              'BDT ${(_reportData!['totalExpense'] as double).toStringAsFixed(2)}',
            ],
            [
              'Total Withdraw',
              'BDT ${(_reportData!['totalWithdraw'] as double).toStringAsFixed(2)}',
            ],
            [
              'Current Balance',
              'BDT ${(_reportData!['balance'] as double).toStringAsFixed(2)}',
            ],
          ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryGreen),
          children: [
            _pdfCell('Item', isHeader: true, textColor: PdfColors.white),
            _pdfCell('Value', isHeader: true, textColor: PdfColors.white),
          ],
        ),
        ...rows.asMap().entries.map((entry) {
          final isEven = entry.key % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : lightGreen,
            ),
            children: [
              _pdfCell(entry.value[0], textColor: darkText),
              _pdfCell(
                entry.value[1],
                textColor: darkText,
                isBold: entry.key == rows.length - 1,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildPdfMemberTable({
    required PdfColor primaryGreen,
    required PdfColor lightGreen,
    required PdfColor darkText,
    required PdfColor borderColor,
  }) {
    final memberData = _reportData!['memberData'] as Map<String, dynamic>;
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryGreen),
          children: [
            _pdfCell('Member Name', isHeader: true, textColor: PdfColors.white),
            _pdfCell('Meals', isHeader: true, textColor: PdfColors.white),
            _pdfCell(
              'Balance (BDT)',
              isHeader: true,
              textColor: PdfColors.white,
            ),
          ],
        ),
        ...memberData.entries.toList().asMap().entries.map((entry) {
          final isEven = entry.key % 2 == 0;
          final data = entry.value.value as Map<String, dynamic>;
          final balance = (data['balance'] ?? 0.0) as double;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : lightGreen,
            ),
            children: [
              _pdfCell(data['name'] ?? '', textColor: darkText),
              _pdfCell('${data['mealCount'] ?? 0}', textColor: darkText),
              _pdfCell(
                'BDT ${balance.toStringAsFixed(2)}',
                textColor: balance >= 0 ? PdfColors.green800 : PdfColors.red700,
                isBold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildPdfComparisonTable({
    required PdfColor primaryGreen,
    required PdfColor lightGreen,
    required PdfColor darkText,
    required PdfColor borderColor,
  }) {
    final currentMeals = _reportData!['totalMeals'] as int;
    final prevMeals = _comparisonData!['totalMeals'] as int;
    final diff = currentMeals - prevMeals;
    final pct = prevMeals > 0
        ? (diff / prevMeals * 100).toStringAsFixed(1)
        : '0.0';
    final trend = diff >= 0 ? '+$pct%' : '$pct%';

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryGreen),
          children: [
            _pdfCell('Metric', isHeader: true, textColor: PdfColors.white),
            _pdfCell('Previous', isHeader: true, textColor: PdfColors.white),
            _pdfCell('Current', isHeader: true, textColor: PdfColors.white),
            _pdfCell('Change', isHeader: true, textColor: PdfColors.white),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _pdfCell('Total Meals', textColor: darkText),
            _pdfCell('$prevMeals', textColor: darkText),
            _pdfCell('$currentMeals', textColor: darkText),
            _pdfCell(
              trend,
              textColor: diff >= 0 ? PdfColors.green800 : PdfColors.red700,
              isBold: true,
            ),
          ],
        ),
        if (_reportType == 'full' &&
            _comparisonData!.containsKey('totalExpense'))
          pw.TableRow(
            decoration: pw.BoxDecoration(color: lightGreen),
            children: [
              _pdfCell('Total Expense', textColor: darkText),
              _pdfCell(
                'BDT ${(_comparisonData!['totalExpense'] as double).toStringAsFixed(2)}',
                textColor: darkText,
              ),
              _pdfCell(
                'BDT ${(_reportData!['totalExpense'] as double).toStringAsFixed(2)}',
                textColor: darkText,
              ),
              () {
                final prevExp = _comparisonData!['totalExpense'] as double;
                final curExp = _reportData!['totalExpense'] as double;
                final expDiff = curExp - prevExp;
                final expPct = prevExp > 0
                    ? (expDiff / prevExp * 100).toStringAsFixed(1)
                    : '0.0';
                final expTrend = expDiff >= 0 ? '+$expPct%' : '$expPct%';
                return _pdfCell(
                  expTrend,
                  textColor: expDiff <= 0
                      ? PdfColors.green800
                      : PdfColors.red700,
                  isBold: true,
                );
              }(),
            ],
          ),
      ],
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool isHeader = false,
    PdfColor textColor = PdfColors.black,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: (isHeader || isBold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          fontSize: 10,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _shareReport() async {
    if (_reportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a report first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await _generatePdf();
  }
}
