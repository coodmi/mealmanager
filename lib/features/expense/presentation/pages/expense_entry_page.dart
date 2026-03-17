import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_mess_service.dart';
import '../../../../core/services/firebase_auth_service.dart';

class ExpenseEntryPage extends StatefulWidget {
  const ExpenseEntryPage({super.key});

  @override
  State<ExpenseEntryPage> createState() => _ExpenseEntryPageState();
}

class _ExpenseEntryPageState extends State<ExpenseEntryPage> {
  String _messId = '';
  bool _isLoading = true;
  bool _isManager = false;

  String _selectedCategory = 'Daily Bazar';
  List<String> _selectedMembers = [];
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isDepositToBalance = false;

  final List<String> _categories = [
    'Daily Bazar',
    'House Rent',
    'Chef Bill',
    'Electricity Bill',
    'Internet Bill',
    'Water Bill',
    'Dust Bill',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final messId = await FirebaseMessService.getMessId();
    final isManager = await FirebaseMessService.isManager();
    setState(() {
      _messId = messId;
      _isManager = isManager;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Expense Entry'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildMemberSelection(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildNoteField(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged:
              (_isManager ||
                  _selectedCategory == 'Daily Bazar' ||
                  _selectedCategory == 'Other')
              ? (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                }
              : null,
        ),
        if (!_isManager &&
            _selectedCategory != 'Daily Bazar' &&
            _selectedCategory != 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Only manager can add ${_selectedCategory}',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('members')
          .where('messId', isEqualTo: _messId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Member List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedMembers.length == members.length) {
                        _selectedMembers.clear();
                      } else {
                        _selectedMembers = members
                            .map((doc) => doc.id)
                            .toList();
                      }
                    });
                  },
                  child: Text(
                    _selectedMembers.length == members.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: members.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final memberId = doc.id;
                  final isSelected = _selectedMembers.contains(memberId);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedMembers.add(memberId);
                        } else {
                          _selectedMembers.remove(memberId);
                        }
                        // Update deposit toggle visibility
                        _updateDepositToggle();
                      });
                    },
                    title: Text(data['name'] ?? 'Unknown'),
                    subtitle: Text(data['phone'] ?? ''),
                    activeColor: AppColors.primaryGreen,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateDepositToggle() {
    if (_selectedMembers.length != 1) {
      setState(() {
        _isDepositToBalance = false;
      });
    }
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.attach_money),
            hintText: 'Enter amount',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        if (_selectedMembers.length == 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SwitchListTile(
              value: _isDepositToBalance,
              onChanged: (value) {
                setState(() {
                  _isDepositToBalance = value;
                });
              },
              title: const Text('Deposit to member\'s balance'),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primaryGreen,
            ),
          ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note/Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter description (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isManager ? AppColors.primaryGreen : Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isManager ? 'Add Expense' : 'Submit',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _submitExpense() async {
    // Validation
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if normal member trying to add restricted category
    if (!_isManager &&
        _selectedCategory != 'Daily Bazar' &&
        _selectedCategory != 'Other') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only manager can add ${_selectedCategory}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userData = await FirebaseAuthService.getUserData();
      final userId = FirebaseAuthService.currentUser?.uid;

      final expenseData = {
        'messId': _messId,
        'category': _selectedCategory,
        'amount': amount,
        'note': _noteController.text.trim(),
        'memberIds': _selectedMembers,
        'isDepositToBalance': _isDepositToBalance,
        'status': _isManager ? 'approved' : 'pending',
        'submittedBy': userId,
        'submittedByName': userData?['name'] ?? 'Unknown',
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('expenses').add(expenseData);

      // If deposit to balance and single member selected
      if (_isDepositToBalance && _selectedMembers.length == 1 && _isManager) {
        final memberId = _selectedMembers.first;
        final memberDoc = await FirebaseFirestore.instance
            .collection('members')
            .doc(memberId)
            .get();

        if (memberDoc.exists) {
          final currentBalance =
              (memberDoc.data()?['balance'] ?? 0.0) as double;
          await FirebaseFirestore.instance
              .collection('members')
              .doc(memberId)
              .update({'balance': currentBalance + amount});
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isManager
                ? 'Expense added successfully!'
                : 'Expense submitted for approval!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      setState(() {
        _selectedMembers.clear();
        _amountController.clear();
        _noteController.clear();
        _isDepositToBalance = false;
        _selectedCategory = 'Daily Bazar';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
