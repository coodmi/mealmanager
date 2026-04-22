import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/test_account_creator.dart';

class DebugTestAccountPage extends StatefulWidget {
  const DebugTestAccountPage({super.key});

  @override
  State<DebugTestAccountPage> createState() => _DebugTestAccountPageState();
}

class _DebugTestAccountPageState extends State<DebugTestAccountPage> {
  bool _isCreating = false;
  String _status = '';
  Map<String, dynamic> _results = {};

  @override
  void initState() {
    super.initState();
    TestAccountCreator.printTestAccounts();
  }

  Future<void> _createAllAccounts() async {
    setState(() {
      _isCreating = true;
      _status = 'Creating test accounts...';
      _results = {};
    });

    try {
      final results = await TestAccountCreator.createAllTestAccounts();

      setState(() {
        _results = results;
        _status = 'Test accounts creation completed!';
        _isCreating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test accounts created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Test Accounts'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Account Creator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Click the button below to create 3 test accounts:',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Super Admin (superadmin@mealmanager.com)',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '2. Normal User (user@mealmanager.com)',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '3. Mess Admin (messadmin@mealmanager.com)',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createAllAccounts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: Colors.grey,
                ),
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isCreating ? 'Creating...' : 'Create Test Accounts',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            if (_status.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      _status.contains('Error') ? Colors.red : Colors.green,
                ),
              ),
            ],

            // Results Section
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._results.entries.map((entry) {
                final accountType = entry.key;
                final result = entry.value as Map<String, dynamic>;
                final isSuccess = result['status'] == 'created';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle : Icons.error,
                            color: isSuccess ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              accountType.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSuccess ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isSuccess) ...[
                        Text('Email: ${result['email']}'),
                        const SizedBox(height: 4),
                        Text('Password: ${_getPassword(accountType)}'),
                        const SizedBox(height: 4),
                        Text('Role: ${result['role']}'),
                      ] else
                        Text('Error: ${result['message'] ?? 'Unknown error'}'),
                    ],
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 24),

            // Test Credentials Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Test Credentials',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCredentialItem(
                    'Super Admin',
                    'superadmin@mealmanager.com',
                    'SuperAdmin@123',
                  ),
                  const SizedBox(height: 12),
                  _buildCredentialItem(
                    'Normal User',
                    'user@mealmanager.com',
                    'NormalUser@123',
                  ),
                  const SizedBox(height: 12),
                  _buildCredentialItem(
                    'Mess Admin',
                    'messadmin@mealmanager.com',
                    'MessAdmin@123',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialItem(String role, String email, String password) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Email: $email',
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          'Password: $password',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  String _getPassword(String accountType) {
    final accounts = TestAccountCreator.testAccounts;
    return accounts[accountType]?['password'] ?? 'Unknown';
  }
}

