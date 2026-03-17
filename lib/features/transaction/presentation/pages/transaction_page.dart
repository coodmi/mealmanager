import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            color: AppColors.primaryGreen,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTransactions(),
                _buildDeposits(),
                _buildExpenses(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildAllTransactions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildTransactionItem(
          'Deposit',
          'John Doe deposited money',
          '৳5,000',
          Icons.arrow_downward,
          Colors.green,
          'Today, 10:30 AM',
        ),
        _buildTransactionItem(
          'Expense',
          'Grocery shopping',
          '৳2,500',
          Icons.arrow_upward,
          Colors.red,
          'Today, 9:15 AM',
        ),
        _buildTransactionItem(
          'Deposit',
          'Jane Smith deposited money',
          '৳3,000',
          Icons.arrow_downward,
          Colors.green,
          'Yesterday, 6:00 PM',
        ),
        _buildTransactionItem(
          'Expense',
          'Electricity bill',
          '৳1,200',
          Icons.arrow_upward,
          Colors.red,
          'Yesterday, 2:30 PM',
        ),
      ],
    );
  }

  Widget _buildDeposits() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTransactionItem(
          'Deposit',
          'John Doe deposited money',
          '৳5,000',
          Icons.arrow_downward,
          Colors.green,
          'Today, 10:30 AM',
        ),
        _buildTransactionItem(
          'Deposit',
          'Jane Smith deposited money',
          '৳3,000',
          Icons.arrow_downward,
          Colors.green,
          'Yesterday, 6:00 PM',
        ),
        _buildTransactionItem(
          'Deposit',
          'Mike Johnson deposited money',
          '৳4,500',
          Icons.arrow_downward,
          Colors.green,
          '2 days ago, 11:00 AM',
        ),
      ],
    );
  }

  Widget _buildExpenses() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTransactionItem(
          'Expense',
          'Grocery shopping',
          '৳2,500',
          Icons.arrow_upward,
          Colors.red,
          'Today, 9:15 AM',
        ),
        _buildTransactionItem(
          'Expense',
          'Electricity bill',
          '৳1,200',
          Icons.arrow_upward,
          Colors.red,
          'Yesterday, 2:30 PM',
        ),
        _buildTransactionItem(
          'Expense',
          'Gas bill',
          '৳800',
          Icons.arrow_upward,
          Colors.red,
          '2 days ago, 3:45 PM',
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.buttonGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Total Balance',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '৳12,500',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Income', '৳15,000', Icons.arrow_downward),
                Container(height: 40, width: 1, color: Colors.white30),
                _buildSummaryItem('Expense', '৳2,500', Icons.arrow_upward),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    String type,
    String description,
    String amount,
    IconData icon,
    Color color,
    String time,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          type,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: AppColors.textLight, fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '৳',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'deposit', child: Text('Deposit')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction added successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
