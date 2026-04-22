import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_mess_service.dart';
import '../../../../core/services/firebase_auth_service.dart';

class ExpenseEntryPage extends StatefulWidget {
  final String? selectedMonthKey;
  const ExpenseEntryPage({super.key, this.selectedMonthKey});

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            const SizedBox(height: 12),
            _buildImportantInfo(),
            const SizedBox(height: 24),
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
          initialValue: _selectedCategory,
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
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) => setState(() => _selectedCategory = value!),
        ),
        if (!_isManager &&
            _selectedCategory != 'Daily Bazar' &&
            _selectedCategory != 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Only manager can add $_selectedCategory',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberSelection() {
    return StreamBuilder<QuerySnapshot>(
      // Fixed: query messes/{messId}/members subcollection
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
                  onPressed: () => setState(() {
                    if (_selectedMembers.length == members.length) {
                      _selectedMembers.clear();
                    } else {
                      _selectedMembers = members.map((d) => d.id).toList();
                    }
                  }),
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
              child: members.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No members found',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    )
                  : Column(
                      children: members.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isSelected = _selectedMembers.contains(doc.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) => setState(() {
                            if (value == true) {
                              _selectedMembers.add(doc.id);
                            } else {
                              _selectedMembers.remove(doc.id);
                            }
                          }),
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

  Widget _buildImportantInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Important Information:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 6),
          _infoLine(
            '· Selected Expense will be deducted from their individual balance.',
          ),
          const SizedBox(height: 4),
          _infoLine(
            '· Only Daily Bazar expenses are not deducted directly from balance; '
            'they are adjusted through the meal rate based on each member\'s meal consumption.',
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.orange.shade800,
        height: 1.4,
      ),
    );
  }

  void _showSuccessPopup({required bool isManager}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryGreen,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isManager
                    ? 'Expense Entry successful.'
                    : 'Expense Entry request sent.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isManager) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Important Information:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _infoLine(
                        '· You will receive notification when this request is accepted/rejected by Manager.',
                      ),
                      const SizedBox(height: 4),
                      _infoLine(
                        '· Approved Expense will be reflected in balance.',
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    if (_selectedMembers.isEmpty) {
      _showSnack('Please select at least one member', Colors.orange);
      return;
    }
    if (_amountController.text.trim().isEmpty) {
      _showSnack('Please enter amount', Colors.orange);
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack('Please enter valid amount', Colors.orange);
      return;
    }
    if (!_isManager &&
        _selectedCategory != 'Daily Bazar' &&
        _selectedCategory != 'Other') {
      _showSnack('Only manager can add $_selectedCategory', Colors.red);
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final userData = await FirebaseAuthService.getUserData();

      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Save to messes/{messId}/expenses subcollection with monthKey
      await FirebaseFirestore.instance
          .collection('messes')
          .doc(_messId)
          .collection('expenses')
          .add({
            'category': _selectedCategory,
            'amount': amount,
            'note': _noteController.text.trim(),
            'memberIds': _selectedMembers,
            'status': _isManager ? 'approved' : 'pending',
            'submittedBy': userId,
            'submittedByName': userData?['name'] ?? 'Unknown',
            'monthKey': monthKey,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      _showSuccessPopup(isManager: _isManager);

      setState(() {
        _selectedMembers.clear();
        _amountController.clear();
        _noteController.clear();
        _selectedCategory = 'Daily Bazar';
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
